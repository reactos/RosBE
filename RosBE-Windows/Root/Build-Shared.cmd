::
:: PROJECT:     RosBE - ReactOS Build Environment for Windows
:: LICENSE:     GNU General Public License v2. (see LICENSE.txt)
:: FILE:        Root/Build-Shared.cmd
:: PURPOSE:     Perform the build of ReactOS - Shared commands.
:: COPYRIGHT:   Copyright 2016 Daniel Reimer <daniel.reimer@reactos.org>
::                             Colin Finck <colin@reactos.org>
::                             Peter Ward <dralnix@gmail.com>
::

@echo off
if not defined _ROSBE_DEBUG set _ROSBE_DEBUG=0
if %_ROSBE_DEBUG% == 1 (
    @echo on
)

if "%_ROSBE_USECCACHE%" == "1" (
    if not "%_ROSBE_CACHESIZE%" == "" (
        ccache -M %_ROSBE_CACHESIZE%G
    )
    set _ROSBE_CCACHE=ccache 
) else (
    set _ROSBE_CCACHE=
)

set HOST_CC=%_ROSBE_CCACHE%gcc
set HOST_CPP=%_ROSBE_CCACHE%g++
set TARGET_CC=%_ROSBE_CCACHE%%_ROSBE_PREFIX%gcc
set TARGET_CPP=%_ROSBE_CCACHE%%_ROSBE_PREFIX%g++

if not exist "%_ROSBE_ROSSOURCEDIR%\output-MinGW-i386\*" (
    if not exist "%_ROSBE_ROSSOURCEDIR%\output-MinGW-amd64\*" (
        if not exist "%_ROSBE_ROSSOURCEDIR%\output-VS-i386\*" (
            if not exist "%_ROSBE_ROSSOURCEDIR%\output-VS-amd64\*" (
                echo No Build Files found. You may want to use "configure" first.
                goto :EOF
            )
        )
    )
)

if exist "*.ninja" (
    set MAKE_INT=ninja.exe
) else (
    set MAKE_INT=mingw32-make.exe
)

:: Get the current date and time for use in in our build log's file name.
call "%_ROSBE_BASEDIR%\TimeDate.cmd"

if not "%ROS_ARCH%" == "" (
    title '%TITLE_COMMAND%' build started: %TIMERAW%   [%ROS_ARCH%]
) else (
    title '%TITLE_COMMAND%' build started: %TIMERAW%   [MSVC %_ROSBE_MSVCARCH%]
)

:: Do the actual building
if %_ROSBE_SHOWTIME% == 1 (
    set BUILDTIME_COMMAND=buildtime.exe
) else (
    set BUILDTIME_COMMAND=
)

if %_ROSBE_WRITELOG% == 1 (
    if not exist "%_ROSBE_LOGDIR%\." (
        mkdir "%_ROSBE_LOGDIR%" 1> NUL 2> NUL
    )
    %BUILDTIME_COMMAND% %MAKE_INT% -j %MAKE_JOBS% %* 2>&1 | tee.exe "%_ROSBE_LOGDIR%\BuildLog-%ROS_ARCH%-%datename%-%timename%.txt"
) else (
    %BUILDTIME_COMMAND% %MAKE_INT% -j %MAKE_JOBS% %*
)

:EOC
:: Highlight the fact that building has ended.

if not %_ROSBE_NOSOUND% == 1 (
    if !errorlevel! GEQ 1 (
        playwav.exe error.wav
    ) else (
        playwav.exe notification.wav
    )
)

flash.exe

:EOF
title ReactOS Build Environment %_ROSBE_VERSION%
echo.
