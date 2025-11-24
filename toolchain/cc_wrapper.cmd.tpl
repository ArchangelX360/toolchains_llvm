@echo off
setlocal
REM Templated values:
REM TODO: maybe do somethign a bit smarter about this, like in UNIX ones
set "clang_executable=%~dp0../../../%{toolchain_path_prefix}/bin/clang-cl.exe"
Powershell.exe -executionpolicy remotesigned -File %~dp0/cc_wrapper.ps1 -- "%clang_executable%" %*
set "exit_code=%errorlevel%"
endlocal & exit /b %exit_code%
