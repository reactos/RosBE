::
:: PROJECT:     RosBE - ReactOS Build Environment for Windows
:: LICENSE:     GNU General Public License v2. (see LICENSE.txt)
:: FILE:        Root/options.cmd
:: PURPOSE:     Starts options.exe and restarts RosBE afterwards.
:: COPYRIGHT:   Copyright 2018 Daniel Reimer <reimer.daniel@freenet.de>
::

@echo off
if not defined _ROSBE_DEBUG set _ROSBE_DEBUG=0
if %_ROSBE_DEBUG% == 1 (
    @echo on
)

title Options

if not "%ROS_ARCH%" == "i386" (
    set param=%ROS_ARCH%
    set cfgfile=%APPDATA%\RosBE\rosbe-options-%ROS_ARCH%.cmd
) else (
    set param=
    set cfgfile=%APPDATA%\RosBE\rosbe-options-%_ROSBE_VERSION%.cmd
)

:: Run options.exe
if exist "%_ROSBE_BASEDIR%\bin\options.exe" (
    pushd "%_ROSBE_BASEDIR%"
    call options.exe %param%
    popd

    if exist "%cfgfile%" (
        call "%cfgfile%"
    )
) else (
    echo ERROR: options executable was not found.
)

title ReactOS Build Environment %_ROSBE_VERSION%
