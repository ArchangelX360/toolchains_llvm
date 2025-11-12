@echo off
setlocal enabledelayedexpansion

set "toolchain_path_prefix=%{toolchain_path_prefix}"
shift

set "result="

:process_args
if "%~1"=="" goto execute
set "arg=%~1"

REM Replace unsupported by clang-cl `--sysroot=` with -Xlinker /LIBPATH:
echo !arg! | findstr /b /c:"--sysroot=" >nul
if !errorlevel! equ 0 (
    for /f "tokens=2 delims==" %%p in ("!arg!") do set "result=!result! -Xlinker /LIBPATH:%%~p"
    shift
    goto process_args
)

REM TODO: could we be a bit smarter than an hardcoded list here? And if not, we must add all MSVC flags that `clang-cl` supports here

REM Prefix linker flags with -Xlinker
set "needs_xlinker=0"

REM Check exact matches
if /i "!arg!"=="/NOLOGO" set "needs_xlinker=1"
if /i "!arg!"=="/NXCOMPAT" set "needs_xlinker=1"
if /i "!arg!"=="/DYNAMICBASE" set "needs_xlinker=1"
if /i "!arg!"=="/DEBUG" set "needs_xlinker=1"

REM Check prefixes
if "!needs_xlinker!"=="0" echo !arg! | findstr /i /b ^
  /c:"/OPT:" ^
  /c:"/LIBPATH:" ^
  /c:"/PDBALTPATH:" ^
  /c:"/SUBSYSTEM:" ^
  /c:"/OUT:" ^
  /c:"/MACHINE:" ^
  /c:"/defaultlib:" ^
  /c:"/INCREMENTAL:" ^
  >nul && set "needs_xlinker=1"

if "!needs_xlinker!"=="1" (
    set "result=!result! -Xlinker !arg!"
) else (
    set "result=!result! !arg!"
)

shift
goto process_args

:execute
set "result=!result:~1!"

"%toolchain_path_prefix%\bin\clang-cl.exe" !result!

set "exit_code=%errorlevel%"
endlocal & exit /b %exit_code%
