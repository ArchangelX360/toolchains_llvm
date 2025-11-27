@echo off
setlocal enabledelayedexpansion

REM Templated values:
REM TODO: maybe do somethign a bit smarter about this, like in UNIX ones
SET "clang_executable=%~dp0../../../%{toolchain_path_prefix}/bin/clang-cl.exe"

SET "add_libpath=0"

REM Create a temporary directory for argfiles if not existing
set "ARGFILES_DIR=!TEMP!\toolchains_llvm\argfiles"
if not exist "!ARGFILES_DIR!" (
    mkdir "!ARGFILES_DIR!"
)

REM Create a temporary argfile for that linker call
:create_temp_argfile
for /f %%i in ('powershell -command "[guid]::NewGuid().ToString()"') do (
    set "TMP_ARGFILE=!ARGFILES_DIR!\%%i_args.txt"
)
if exist "!TMP_ARGFILE!" (
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
REM Use string substitution to avoid echo issues with special characters
set "check_sysroot=!arg:--sysroot==!"
if not "!check_sysroot!"=="!arg!" (
    set "outline=/imsvc C:\Users\titouan.bion\Developer_windows\sdk\10\Include\10.0.26100.0\um"
    <nul set /p "=!outline!">> "!TMP_ARGFILE!"
    echo.>> "!TMP_ARGFILE!"

    set "outline=/imsvc C:\Users\titouan.bion\Developer_windows\sdk\10\Include\10.0.26100.0\ucrt"
    <nul set /p "=!outline!">> "!TMP_ARGFILE!"
    echo.>> "!TMP_ARGFILE!"

    set "outline=/imsvc C:\Users\titouan.bion\Developer_windows\sdk\10\Include\10.0.26100.0\shared"
    <nul set /p "=!outline!">> "!TMP_ARGFILE!"
    echo.>> "!TMP_ARGFILE!"

    set "outline=/imsvc C:\Users\titouan.bion\Developer_windows\sdk\MSVC\14.50.35717\include"
    <nul set /p "=!outline!">> "!TMP_ARGFILE!"
    echo.>> "!TMP_ARGFILE!"

    exit /b 0
)

REM Check for prefix matches using string substitution instead of echo | findstr
REM This avoids issues with special characters like commas
set "needs_xlinker=0"
if not "!arg:/MACHINE:=!"=="!arg!" set "needs_xlinker=1"
if not "!arg:/OPT:=!"=="!arg!" set "needs_xlinker=1"
if not "!arg:/DEF:=!"=="!arg!" set "needs_xlinker=1"
if not "!arg:/LIBPATH:=!"=="!arg!" set "needs_xlinker=1"
if not "!arg:/LIBPATH:=!"=="!arg!" set "add_libpath=1"
if not "!arg:/PDBALTPATH:=!"=="!arg!" set "needs_xlinker=1"
if not "!arg:/NATVIS:=!"=="!arg!" set "needs_xlinker=1"
if not "!arg:/SUBSYSTEM:=!"=="!arg!" set "needs_xlinker=1"
if not "!arg:/OUT:=!"=="!arg!" set "needs_xlinker=1"
if not "!arg:/defaultlib:=!"=="!arg!" set "needs_xlinker=1"
if not "!arg:/IMPLIB:=!"=="!arg!" set "needs_xlinker=1"
if not "!arg:/INCREMENTAL:=!"=="!arg!" set "needs_xlinker=1"

REM Check for exact matches
if "!arg!"=="/NOLOGO" set "needs_xlinker=1"
if "!arg!"=="/NXCOMPAT" set "needs_xlinker=1"
if "!arg!"=="/DYNAMICBASE" set "needs_xlinker=1"
if "!arg!"=="/DLL" set "needs_xlinker=1"
if "!arg!"=="/DEBUG" set "needs_xlinker=1"

REM TODO: seems like PDBALTPATH's value `%_PDB%` is being evalutated in this script instead of by the linker
REM Write -Xlinker and argument on same line if rule matched, otherwise just argument
if "!needs_xlinker!"=="1" (
    set "outline=-Xlinker !arg!"
) else (
    set "outline=!arg!"
)
REM Use set /p with NUL input to write without newline interpretation issues
REM The <nul provides empty input, and set /p outputs the prompt string as-is
REM IMPORTANT: No space between the closing quote and >> or it will be included in output
<nul set /p "=!outline!">> "!TMP_ARGFILE!"
echo.>> "!TMP_ARGFILE!"
exit /b 0

REM --------------------------------------------
REM Helper functions [END]
REM --------------------------------------------

:call_linker

if "%add_libpath%"=="1" (
    set "outline=-Xlinker /LIBPATH:C:\Users\titouan.bion\Developer_windows\sdk\10\Lib\10.0.26100.0\um\arm64"
    <nul set /p "=!outline!">> "!TMP_ARGFILE!"
    echo.>> "!TMP_ARGFILE!"

    set "outline=-Xlinker /LIBPATH:C:\Users\titouan.bion\Developer_windows\sdk\10\Lib\10.0.26100.0\ucrt\arm64"
    <nul set /p "=!outline!">> "!TMP_ARGFILE!"
    echo.>> "!TMP_ARGFILE!"

    set "outline=-Xlinker /LIBPATH:C:\Users\titouan.bion\Developer_windows\sdk\MSVC\14.50.35717\lib\arm64"
    <nul set /p "=!outline!">> "!TMP_ARGFILE!"
    echo.>> "!TMP_ARGFILE!"
)

if exist "!TMP_ARGFILE!" (
	"!clang_executable!" "@!TMP_ARGFILE!" && DEL "!TMP_ARGFILE!"
)
set "exit_code=%errorlevel%"
endlocal & exit /b %exit_code%
