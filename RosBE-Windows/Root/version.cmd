::
:: PROJECT:     RosBE - ReactOS Build Environment for Windows
:: LICENSE:     GNU General Public License v2. (see LICENSE.txt)
:: FILE:        Root/version.cmd
:: PURPOSE:     Display the current version of GCC, NASM, ld and make.
:: COPYRIGHT:   Copyright 2016 Daniel Reimer <reimer.daniel@freenet.de>
::                             Colin Finck <colin@reactos.org>
::

@echo off
if not defined _ROSBE_DEBUG set _ROSBE_DEBUG=0
if %_ROSBE_DEBUG% == 1 (
    @echo on
)

for /f "usebackq" %%i in (`"%_ROSBE_BASEDIR%\bin\ninja.exe" --version`) do set _ROSBE_NINJAVER=%%i

ver

if not "%ROS_ARCH%" == "" (
    echo gcc target^: %ROS_ARCH%
    "%_ROSBE_TARGET_MINGWPATH%\bin\%_ROSBE_PREFIX%gcc.exe" -v 2>&1 | find "gcc version"
    "%_ROSBE_TARGET_MINGWPATH%\bin\%_ROSBE_PREFIX%ld.exe" -v
    "%_ROSBE_BASEDIR%\bin\mingw32-make.exe" -v | find "GNU Make"
) else (
    echo MSVC target^: %_ROSBE_MSVCARCH%
    cl.exe 2>&1 | find "Version"
    mc.exe 2>&1 | find "Version"
    rc.exe 2>&1 | find "Version"
    ml.exe 2>&1 | find "Version"
)

:: Bison, Flex and Make
"%_ROSBE_BASEDIR%\bin\bison.exe" --version | find "GNU Bison"
"%_ROSBE_BASEDIR%\bin\flex.exe" --version
echo Ninja %_ROSBE_NINJAVER%
"%_ROSBE_BASEDIR%\bin\cmake.exe" --version | find "version"
