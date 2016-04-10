::
:: PROJECT:     RosBE - ReactOS Build Environment for Windows
:: LICENSE:     GNU General Public License v2. (see LICENSE.txt)
:: FILE:        Root/raddr2line.cmd
:: PURPOSE:     Converts a value to hex and displays it.
:: COPYRIGHT:   Copyright 2016 Christoph von Wittich <Christoph_vW@reactos.org>
::                             Daniel Reimer <reimer.daniel@freenet.de>
::                             Peter Ward <dralnix@gmail.com>
::                             Colin Finck <colin@reactos.org>
::                             Thomas Faber
::

@echo off
if not defined _ROSBE_DEBUG set _ROSBE_DEBUG=0
if %_ROSBE_DEBUG% == 1 (
    @echo on
)

setlocal enabledelayedexpansion
title reladdr2line...

if not "%3" == "" (
    echo ERROR: Too many parameters specified.
    goto :EOC
)

:: Receive all parameters
if "%1" == "" (
    set /p FILEPATH="Please enter the path/file to be examined: "
) else (
    set FILEPATH=%1
)

if "%2" == "" (
    set /p ADDRESS="Please enter the address you would like to analyze: "
) else (
    set ADDRESS=%2
)

:: Check if parameters were really given
if "%FILEPATH%" == "" (
    echo ERROR: You must specify a path/file to examine.
    goto :EOC
)
if "%ADDRESS%" == "" (
    echo ERROR: You must specify a address to analyze.
    goto :EOC
)

:: Check if the user supplied a path, if they didn't look for
:: the specified file in the current directory and any
:: sub-directories.
chkslash.exe "%FILEPATH%"
if errorlevel 2 (
    for /f "usebackq" %%i in (`"dir /a:-d /s /b "%FILEPATH%" 2>NUL | findstr "%FILEPATH%""`) do set FILEPATH=%%i
)

for /f "tokens=2" %%a in ('objdump -p %FILEPATH% ^| find "ImageBase"') do set BASE=0x%%a

if not "%ADDRESS:~0,2%" =="0x" (
    set ADDRESS=0x%ADDRESS%
)

set /a ADDRESS+=%BASE%
for /f %%i in ('"echoh.exe !ADDRESS!"') do set RELBASE=%%i
addr2line.exe -p -f -a -e !FILEPATH! !RELBASE!

:EOC
title ReactOS Build Environment %_ROSBE_VERSION%
endlocal
