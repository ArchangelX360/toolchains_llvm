@echo off
setlocal enabledelayedexpansion

set "toolchain_path_prefix=%{toolchain_path_prefix}"

REM Create a temporary file for the processed arguments
for /f %%i in ('powershell -command "[guid]::NewGuid().ToString()"') do (
    mkdir !TEMP!\toolchains_llvm\argfiles
    set "OUTPUT_FILE=!TEMP!\toolchains_llvm\argfiles\args_%%i.txt"
)
if exist "!OUTPUT_FILE!" (
    echo Error: Could not generate unique args filename "!OUTPUT_FILE!"
    exit /b 1
)

REM Process all command line arguments
:process_cmdline_args
if "%~1"=="" goto done
call :process_single_arg "%~1"
shift
goto process_cmdline_args

REM Process a single argument (either from command line or from argfile)
:process_single_arg
set "arg=%~1"

REM Check if it's an argfile (starts with @)
if "!arg:~0,1!"=="@" (
    set "argfile=!arg:~1!"
    call :process_argfile "!argfile!"
    exit /b 0
)

REM Apply transformations and write to output
call :transform_and_write "!arg!"
exit /b 0

REM Read an argfile and process each line recursively
:process_argfile
set "file=%~1"
if exist "%file%" (
	for /F "tokens=* delims=" %%a in ('Type "%file%"') do (
		call :process_single_arg %%a
	)
)
exit /b 0

REM Apply transformation rules and write to output file
REM This is where you add new transformation cases
:transform_and_write
set "arg=%~1"
set "needs_xlinker=0"

REM Special case: --sysroot=path -> -Xlinker /LIBPATH:path
echo !arg! | findstr /b /c:"--sysroot=" >nul
if !errorlevel! equ 0 (
    for /f "tokens=2 delims==" %%p in ("!arg!") do (
        set "sysroot_path=%%p"
        call set "sysroot_path=!sysroot_path!"
        echo "-Xlinker" "/LIBPATH:!sysroot_path!" >> "!OUTPUT_FILE!"
    )
    exit /b 0
)

REM Check for prefix matches (arguments starting with these strings)
echo !arg! | findstr /b ^
  /c:"/MACHINE:" ^
  /c:"/OPT:" ^
  /c:"/DEF:" ^
  /c:"/LIBPATH:" ^
  /c:"/PDBALTPATH:" ^
  /c:"/NATVIS:" ^
  /c:"/SUBSYSTEM:"  ^
  /c:"/OUT:" ^
  /c:"/defaultlib:" ^
  /c:"/STD:" ^
  /c:"/IMPLIB:" ^
  /c:"/INCREMENTAL:" >nul
if !errorlevel! equ 0 set "needs_xlinker=1"

REM Check for exact matches
if "!arg!"=="/NOLOGO" set "needs_xlinker=1"
if "!arg!"=="/NXCOMPAT" set "needs_xlinker=1"
if "!arg!"=="/DYNAMICBASE" set "needs_xlinker=1"
if "!arg!"=="/DLL" set "needs_xlinker=1"
if "!arg!"=="/DEBUG" set "needs_xlinker=1"

REM TODO: seems like PDBALTPATH's value `%_PDB%` is being evalutated in this script instead of by the linker
REM Write -Xlinker and argument on same line if rule matched, otherwise just argument
if "!needs_xlinker!"=="1" (
    echo "-Xlinker" "!arg!" >> "!OUTPUT_FILE!"
) else (
    echo "!arg!" >> "!OUTPUT_FILE!"
)
exit /b 0

:done

if exist "!OUTPUT_FILE!" (
	"!toolchain_path_prefix!\bin\clang-cl.exe" -v -Xlinker -verbose "@!OUTPUT_FILE!"
)

set "exit_code=%errorlevel%"
endlocal & exit /b %exit_code%
