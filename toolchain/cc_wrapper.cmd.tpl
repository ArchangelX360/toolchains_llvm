@echo off
setlocal enabledelayedexpansion

REM Templated values:
REM TODO: maybe do somethign a bit smarter about this, like in UNIX ones
set "toolchain_path_prefix=%~dp0../../../%{toolchain_path_prefix}"

REM Create a temporary directory for argfiles if not existing
set "ARGFILES_DIR=!TEMP!\toolchains_llvm\argfiles"
if not exist "!ARGFILES_DIR!" (
    mkdir "!ARGFILES_DIR!"
)

REM Create a temporary argfile for that linker call
:create_temp_argfile
for /f %%i in ('powershell -command "[guid]::NewGuid().ToString()"') do (
    set "OUTPUT_FILE=!ARGFILES_DIR!\%%i_args.txt"
)
if exist "!OUTPUT_FILE!" (
    goto create_temp_argfile
)

REM Process all command line arguments
:process_cmdline_args
if "%~1"=="" goto call_linker
call :process_single_arg "%~1"
shift
goto process_cmdline_args

REM --------------------------------------------
REM Helper functions [START]
REM --------------------------------------------

REM Process a single argument, dealing with argfile argument recursively
:process_single_arg
set "arg=%~1"
if "!arg:~0,1!"=="@" (
    set "argfile=!arg:~1!"
    call :process_argfile "!argfile!"
) else (
    call :transform_and_write_argument_to_argfile "!arg!"
)
exit /b 0

REM Read an argfile and process each line recursively
:process_argfile
set "file=%~1"
if exist "!file!" (
	for /F "tokens=* delims=" %%a in ('Type "!file!"') do (
        set "argfile_arg=%%~a"
		call :process_single_arg "!argfile_arg!"
	)
)
exit /b 0

REM Apply transformation rules and write to output file
:transform_and_write_argument_to_argfile
set "arg=%~1"
set "needs_xlinker=0"

REM Special case: --sysroot=path -> -Xlinker /LIBPATH:path
echo !arg! | findstr /b /c:"--sysroot=" >nul
if !errorlevel! equ 0 (
    for /f "tokens=2 delims==" %%p in ("!arg!") do (
        set "sysroot_path=%%~p"
        set "arg=/LIBPATH:!sysroot_path!"
    )
)

REM Check for prefix matches
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
    echo -Xlinker !arg! >> "!OUTPUT_FILE!"
) else (
    echo !arg! >> "!OUTPUT_FILE!"
)
exit /b 0

REM --------------------------------------------
REM Helper functions [END]
REM --------------------------------------------

:call_linker
if exist "!OUTPUT_FILE!" (
	"!toolchain_path_prefix!\bin\clang-cl.exe" -v -Xlinker -verbose "@!OUTPUT_FILE!"
)
set "exit_code=%errorlevel%"
endlocal & exit /b %exit_code%
