::
:: PROJECT:     RosBE - ReactOS Build Environment for Windows
:: LICENSE:     GNU General Public License v2. (see LICENSE.txt)
:: FILE:        Root/RosBE.cmd
:: PURPOSE:     This script provides/sets up various build environments for
::              ReactOS. Currently it provides a GCC 4.7.2 build environment.
:: COPYRIGHT:   Copyright 2016 Daniel Reimer <reimer.daniel@freenet.de>
::                             Peter Ward <dralnix@gmail.com>
::                             Colin Finck <colin@reactos.org>
::

@echo off
if not defined _ROSBE_DEBUG set _ROSBE_DEBUG=0
if %_ROSBE_DEBUG% == 1 (
    @echo on
)

title ReactOS Build Environment %_ROSBE_VERSION%

set platform=false
set _ROSBE_MSVCARCH=%2
if /i "%PROCESSOR_ARCHITECTURE%" == "amd64" set platform=true
if /i "%PROCESSOR_ARCHITEW6432%" == "amd64" set platform=true
if defined VS90COMNTOOLS (
    if exist "%VS90COMNTOOLS%\..\..\VC\vcvarsall.bat" (
        set _ROSBE_MSVCVERS=%_ROSBE_MSVCVERS% 9.0
    )
)
if defined VS100COMNTOOLS (
    if exist "%VS100COMNTOOLS%\..\..\VC\vcvarsall.bat" (
        set _ROSBE_MSVCVERS=%_ROSBE_MSVCVERS% 10.0
    )
)
if defined VS110COMNTOOLS (
    if exist "%VS110COMNTOOLS%\..\..\VC\vcvarsall.bat" (
        set _ROSBE_MSVCVERS=%_ROSBE_MSVCVERS% 11.0
    )
)
if defined VS120COMNTOOLS (
    if exist "%VS120COMNTOOLS%\..\..\VC\vcvarsall.bat" (
        set _ROSBE_MSVCVERS=%_ROSBE_MSVCVERS% 12.0
    )
)
if defined VS140COMNTOOLS (
    if exist "%VS140COMNTOOLS%\..\..\VC\vcvarsall.bat" (
        set _ROSBE_MSVCVERS=%_ROSBE_MSVCVERS% 14.0
    )
)

for %%A in (%_ROSBE_MSVCVERS%) do set _ROSBE_MSVCVER=%%A

if "%1" == "vs" (
    if "%platform%" == "true" (
        for /f "usebackq skip=2 tokens=2,*" %%A in (`"reg query HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\%_ROSBE_MSVCVER% /v ShellFolder"`) do set VSINSTALLDIR=%%B
    ) else (
        for /f "usebackq skip=2 tokens=2,*" %%A in (`"reg query HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\VisualStudio\%_ROSBE_MSVCVER% /v ShellFolder"`) do set VSINSTALLDIR=%%B
    )
)

:: Set defaults to work with and override them if edited by
:: the options utility.
if "%1" == "" (
    set ROS_ARCH=i386
) else if "%1" == "vs" (
    set ROS_ARCH=
    call "%VSINSTALLDIR%\VC\vcvarsall.bat" %_ROSBE_MSVCARCH%
) else (
    set ROS_ARCH=%1
)

if defined _ROSBE_CMAKE_DIFF (
    set _ROSBE_CMAKE_DIFF_=_%_ROSBE_CMAKE_DIFF%
)

set BUILD_ENVIRONMENT=MinGW
set _ROSBE_BASEDIR=%~dp0
set _ROSBE_BASEDIR=%_ROSBE_BASEDIR:~0,-1%
set _ROSBE_VERSION=2.1.6
set _ROSBE_ROSSOURCEDIR=%CD%
set _ROSBE_SHOWTIME=1
set _ROSBE_WRITELOG=1
set _ROSBE_USECCACHE=0
set _ROSBE_LOGDIR=RosBE-Logs
set _ROSBE_SHOWVERSION=0
set _ROSBE_SYSPATH=1
set _ROSBE_NOSOUND=0
set _ROSBE_HOST_MINGWPATH=%_ROSBE_BASEDIR%\i386
set _ROSBE_TARGET_MINGWPATH=%_ROSBE_BASEDIR%\%ROS_ARCH%
set _BUILDBOT_SVNSKIPMAINTRUNK=0
set CCACHE_SLOPPINESS=time_macros

:: Fix Bison package path (just in case RosBE is installed in a path which contains spaces)
set BISON_PKGDATADIR=%~ds0%~sp0%i386\share\bison

:: Get the number of CPUs in the system so we know how many jobs to execute.
:: To modify the number used, see the cpucount usage for getting to know about the possible options
for /f "usebackq" %%i in (`"%_ROSBE_BASEDIR%\bin\cpucount.exe" -x1`) do set _ROSBE_MAKEX_JOBS=%%i

if "%_ROSBE_CCACHE_DIR%" == "" (
    set CCACHE_DIR=%APPDATA%\RosBE\.ccache
) else (
    set CCACHE_DIR=%_ROSBE_CCACHE_DIR%
)

set _ROSBE_CACHESIZE=4

set C_INCLUDE_PATH=
set CPLUS_INCLUDE_PATH=
set LIBRARY_PATH=

if "%ROS_ARCH%" == "amd64" (
    color 0B
)
if "%ROS_ARCH%" == "arm" (
    color 0E
)

:: Check if RosBE data directory exists, if not, create it.
if not exist "%APPDATA%\RosBE\." (
    mkdir "%APPDATA%\RosBE" 1> NUL 2> NUL
)

:: Load the user's options if any
if exist "%APPDATA%\RosBE\rosbe-options-%_ROSBE_VERSION%.cmd" (
    call "%APPDATA%\RosBE\rosbe-options-%_ROSBE_VERSION%.cmd"
)

if exist "%APPDATA%\RosBE\rosbe-options-%1.cmd" (
    call "%APPDATA%\RosBE\rosbe-options-%1.cmd"
)

set _ROSBE_ORIGINALPATH=%_ROSBE_BASEDIR%;%_ROSBE_BASEDIR%\bin;%_ROSBE_BASEDIR%\samples;%PATH%

if "%_ROSBE_SYSPATH%" == "0" (
    set "_ROSBE_ORIGINALPATH=%_ROSBE_BASEDIR%;%_ROSBE_BASEDIR%\bin;%_ROSBE_BASEDIR%\samples;%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem"
)

call "%_ROSBE_BASEDIR%\rosbe-gcc-env.cmd"
doskey update="%_ROSBE_BASEDIR%\update.cmd" $*

:: Use the default prompt
prompt

cls
echo *******************************************************************************
echo *                                                                             *
echo *                        ReactOS Build Environment %_ROSBE_VERSION%                      *
echo *                                                                             *
echo *******************************************************************************
echo.

:: Load the base directory from srclist.txt and set it as the
:: new source directory.
if exist "%_ROSBE_BASEDIR%\scut.cmd" (
    call "%_ROSBE_BASEDIR%\scut.cmd"
)
if "%_ROSBE_SHOWVERSION%" == "1" (
    call "%_ROSBE_BASEDIR%\version.cmd"
)

call "%_ROSBE_BASEDIR%\update.cmd" verstatus

:: Tell how to display the available commands.
echo.
echo For a list of all included commands, type: "help"
echo -------------------------------------------------
echo.

:: Look if the ReactOS source directory is empty.
setlocal enabledelayedexpansion
dir /b "%_ROSBE_ROSSOURCEDIR%" 2>nul | findstr "." >nul
if !errorlevel! == 1 (
    echo No ReactOS source detected. Please check https://reactos.org/wiki/ReactOS_Git_For_Dummies to download it.
)
endlocal
