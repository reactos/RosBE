::
:: PROJECT:     RosBE - ReactOS Build Environment for Windows
:: LICENSE:     GNU General Public License v2. (see LICENSE.txt)
:: FILE:        Root/Clean.cmd
:: PURPOSE:     Clean the ReactOS source directory.
:: COPYRIGHT:   Copyright 2018 Daniel Reimer <reimer.daniel@freenet.de>
::                             Peter Ward <dralnix@gmail.com>
::                             Colin Finck <colin@reactos.org>
::

@echo off
if not defined _ROSBE_DEBUG set _ROSBE_DEBUG=0
if %_ROSBE_DEBUG% == 1 (
    @echo on
)

setlocal enabledelayedexpansion
title Cleaning...

set ROS_CMAKE_BUILD=output-%BUILD_ENVIRONMENT%-%ROS_ARCH%

if "%1" == "" (
    call :BIN
) else if /i "%1" == "logs" (
    call :LOG
) else if /i "%1" == "all" (
    call :BIN
) else (
    call :MODULE %*
)
goto :EOC

:MODULE
    if "%1" == "" goto :EOF
    call "%_ROSBE_BASEDIR%\Make.cmd" %1_clean
    shift /1
    echo.
    GOTO :MODULE %*

:: Check if we have any logs to clean, if so, clean them.
:LOG
if exist "%ROS_CMAKE_BUILD%\%_ROSBE_LOGDIR%\*.txt" (
    echo Cleaning build logs...
    del /f "%ROS_CMAKE_BUILD%\%_ROSBE_LOGDIR%\*.txt" 1> NUL 2> NUL
    echo Done cleaning build logs.
) else (
    echo ERROR: There are no logs to clean.
)
goto :EOF


:: Check if we have any binaries to clean, if so, clean them.
:BIN
:: Do some basic sanity checks to verify that we are working in a ReactOS source tree.
:: Consider that we also want to clean half-complete builds, so don't depend on too many existing files.

if exist "CMakeLists.txt" (
    echo Cleaning ReactOS %ROS_ARCH% source directory...
    rd /s /q "%ROS_CMAKE_BUILD%" 1>NUL 2>NUL
    echo Done cleaning ReactOS %ROS_ARCH% source directory.
) else (
    echo ERROR: This directory contains no %ROS_ARCH% compiler output to clean.
)
goto :EOF

:EOC
title ReactOS Build Environment %_ROSBE_VERSION%
endlocal
