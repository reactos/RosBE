::
:: PROJECT:     RosBE - ReactOS Build Environment for Windows
:: LICENSE:     GNU General Public License v2. (see LICENSE.txt)
:: FILE:        Root/version.cmd
:: PURPOSE:     Display the current version of GCC, NASM, ld and make.
:: COPYRIGHT:   Copyright 2011 Daniel Reimer <reimer.daniel@freenet.de>
::                             Colin Finck <colin@reactos.org>
::

@echo off
if not defined _ROSBE_DEBUG set _ROSBE_DEBUG=0
if %_ROSBE_DEBUG% == 1 (
    @echo on
)

ver

:: GCC
"%_ROSBE_TARGET_MINGWPATH%\bin\%_ROSBE_PREFIX%gcc" -v 2>&1 | find "gcc version"
echo gcc target^: %ROS_ARCH%

:: LD
"%_ROSBE_TARGET_MINGWPATH%\bin\%_ROSBE_PREFIX%ld" -v

:: Bison, Flex and Make
bison --version | find "GNU Bison"
flex --version
mingw32-make.exe -v | find "GNU Make"
cmake.exe --version
