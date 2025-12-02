@echo off
setlocal enabledelayedexpansion

REM Templated values:
REM TODO: maybe do somethign a bit smarter about this, like in UNIX ones
SET "clang_executable=%~dp0../../../%{toolchain_path_prefix}/bin/clang-cl.exe"
"!clang_executable!" %*

set "exit_code=%errorlevel%"
endlocal & exit /b %exit_code%
