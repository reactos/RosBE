#
# PROJECT:     RosBE - ReactOS Build Environment for Windows
# LICENSE:     GNU General Public License v2. (see LICENSE.txt)
# FILE:        Root/RosBE.ps1
# PURPOSE:     This script provides/sets up various build environments for
#              ReactOS. Currently it provides a GCC 4.7.2 build environment.
# COPYRIGHT:   Copyright 2016 Daniel Reimer <reimer.daniel@freenet.de>
#

$host.ui.RawUI.WindowTitle = "ReactOS Build Environment $_ROSBE_VERSION"

# Set defaults to work with and override them if edited by the options utility.

# Web Downloader in a function.

function global:Get-WebFile {
    param(
        $url = $null,
        $file = $null
    )
    $local:ErrorActionPreference = "SilentlyContinue"
    $clnt = new-object System.Net.WebClient
    $global:_ROSBE_DWERRLVL = "0"
    trap [Exception] {
        $global:_ROSBE_DWERRLVL = "1"
    }
    $clnt.DownloadFile($url,$file)
    $local:ErrorActionPreference = "Continue"
}

# Set defaults to work with and override them if edited by
# the options utility.
if ("$args" -eq "") {
    $ENV:ROS_ARCH = "i386"
} else {
    $ENV:ROS_ARCH = "$($args)"
}
if ("$ENV:ROS_ARCH" -eq "amd64") {
    (Get-Host).UI.RawUI.ForegroundColor = 0xB
} elseif ("$ENV:ROS_ARCH" -eq "arm") {
    (Get-Host).UI.RawUI.ForegroundColor = 0xE
} else {
    (Get-Host).UI.RawUI.ForegroundColor = 0xA
}
(Get-Host).UI.RawUI.BackgroundColor = 0x0
clear-host

if ("$ENV:_ROSBE_CMAKE_DIFF" -ne "") {
    $ENV:_ROSBE_CMAKE_DIFF_= "_$ENV:_ROSBE_CMAKE_DIFF"
}

$global:BUILD_ENVIRONMENT = "MinGW"
$global:0 = $myInvocation.MyCommand.Definition
$global:_ROSBE_BASEDIR = [System.IO.Path]::GetDirectoryName($0)
$global:_ROSBE_PREFIX = $null
$global:_ROSBE_VERSION = "2.1.5"
$global:_ROSBE_ROSSOURCEDIR = "$pwd"
$global:_ROSBE_SHOWTIME = 1
$global:_ROSBE_WRITELOG = 1
$global:_ROSBE_USECCACHE = 0
$global:_ROSBE_SHOWVERSION = 0
$global:_ROSBE_SYSPATH = 1
$global:_ROSBE_NOSOUND = 0
$global:_ROSBE_NOSYSPATH = 1
$global:_ROSBE_LOGDIR = "RosBE-Logs"
$global:_ROSBE_HOST_MINGWPATH = "$_ROSBE_BASEDIR\i386"
$global:_ROSBE_TARGET_MINGWPATH = "$_ROSBE_BASEDIR\$ENV:ROS_ARCH"
$global:_BUILDBOT_SVNSKIPMAINTRUNK = "0"
$ENV:CCACHE_SLOPPINESS = "time_macros"

# Fix Bison package path (just in case RosBE is installed in a path which contains spaces)
$ENV:BISON_PKGDATADIR = ((New-Object -ComObject Scripting.FileSystemObject).GetFolder("$_ROSBE_HOST_MINGWPATH\share\bison")).ShortPath

# Get the number of CPUs in the system so we know how many jobs to execute.
# To modify the number used, see the cpucount usage for getting to know about the possible options
$global:_ROSBE_MAKEX_JOBS = [Int]$ENV:NUMBER_OF_PROCESSORS + 1

if ("$ENV:_ROSBE_CCACHE_DIR" -eq "") {
    $ENV:CCACHE_DIR = "$ENV:APPDATA\RosBE\.ccache"
} else {
    $ENV:CCACHE_DIR = "$_ROSBE_CCACHE_DIR"
}

$global:_ROSBE_CACHESIZE = "4"

$ENV:C_INCLUDE_PATH = $null
$ENV:CPLUS_INCLUDE_PATH = $null
$ENV:LIBRARY_PATH = $null

# Flash Tool in a Function.

function New-PInvoke {
    param(
        $Library,
        $Signature
    )
    $local:ErrorActionPreference = "SilentlyContinue"
    $name = $($signature -replace "^.*?\s(\w+)\(.*$",'$1')
    $MemberDefinition = "[DllImport(`"$Library`")]`n$Signature"

    $type = Add-Type -PassThru -Name "PInvoke$(Get-Random)" -MemberDefinition $MemberDefinition
    $null = iex "New-Item Function:Global:$name -Value { [$($type.FullName)]::$name.Invoke( `$args ) }"
    $local:ErrorActionPreference = "Continue"
}

New-PInvoke user32.dll "public static extern void FlashWindow(IntPtr hwnd, bool bInvert);"

# Load the doskey macros and delete any macros for components
# that are not actually present.
function LoadAliases {
    function global:BASEDIR {
        set-location "$_ROSBE_ROSSOURCEDIR"
    }
    if (Test-Path "$_ROSBE_BASEDIR\chdefdir.ps1") {
        set-alias CHDEFDIR "$_ROSBE_BASEDIR\chdefdir.ps1" -scope Global
    }

    if (Test-Path "$_ROSBE_BASEDIR\chdefgcc.ps1") {
        set-alias CHDEFGCC "$_ROSBE_BASEDIR\chdefgcc.ps1" -scope Global
    }

    if (Test-Path "$_ROSBE_BASEDIR\charch.ps1") {
        set-alias CHARCH "$_ROSBE_BASEDIR\charch.ps1" -scope Global
    }

    set-alias CLEAN "$_ROSBE_BASEDIR\Clean.ps1" -scope Global

    set-alias HELP "$_ROSBE_BASEDIR\Help.ps1" -scope Global

    function global:MAKE {
        IEX "&'$_ROSBE_BASEDIR\Build.ps1' $args"
    }

    function global:MAKEX {
        IEX "&'$_ROSBE_BASEDIR\Build.ps1' multi $args"
    }

    if (Test-Path "$_ROSBE_BASEDIR\playwav.ps1") {
        set-alias PLAYWAV "$_ROSBE_BASEDIR\playwav.ps1" -scope Global
    }

    if (Test-Path "$_ROSBE_BASEDIR\reladdr2line.ps1") {
        set-alias RADDR2LINE "$_ROSBE_BASEDIR\reladdr2line.ps1" -scope Global
    }

    if (Test-Path "$_ROSBE_BASEDIR\Remake.ps1") {
        set-alias REMAKE "$_ROSBE_BASEDIR\Remake.ps1" -scope Global
    }

    if (Test-Path "$_ROSBE_BASEDIR\Remakex.ps1") {
        set-alias REMAKEX "$_ROSBE_BASEDIR\Remakex.ps1" -scope Global
    }

    if (Test-Path "$_ROSBE_BASEDIR\scut.ps1") {
        set-alias SCUT "$_ROSBE_BASEDIR\scut.ps1" -scope Global
    }

    if (Test-Path "$_ROSBE_BASEDIR\kdbg.ps1") {
        set-alias KDBG "$_ROSBE_BASEDIR\kdbg.ps1" -scope Global
    }

    if (Test-Path "$_ROSBE_BASEDIR\sSVN.ps1") {
        set-alias SSVN "$_ROSBE_BASEDIR\sSVN.ps1" -scope Global
    }
    if (Test-Path "$_ROSBE_BASEDIR\update.ps1") {
        set-alias UPDATE "$_ROSBE_BASEDIR\update.ps1" -scope Global
    }

    set-alias VERSION "$_ROSBE_BASEDIR\version.ps1" -scope Global

    if (Test-Path "$_ROSBE_BASEDIR\options.ps1") {
        set-alias OPTIONS "$_ROSBE_BASEDIR\options.ps1" -scope Global
    }
}

# Check if RosBE data directory exists, if not, create it.
if (!(Test-Path "$ENV:APPDATA\RosBE")) {
    New-Item -path "$ENV:APPDATA" -name "RosBE" -type directory
}

# Load the user's options if any
if ("$args" -eq "") {
    if (Test-Path "$ENV:APPDATA\RosBE\rosbe-options-$_ROSBE_VERSION.ps1") {
        & "$ENV:APPDATA\RosBE\rosbe-options-$_ROSBE_VERSION.ps1"
    }
}

if (Test-Path "$ENV:APPDATA\RosBE\rosbe-options-$ENV:ROS_ARCH.ps1") {
    & "$ENV:APPDATA\RosBE\rosbe-options-$ENV:ROS_ARCH.ps1"
}

if (Test-Path "$ENV:APPDATA\RosBE\RBUILDFLAGS-$_ROSBE_VERSION.FLG") {
    $ENV:ROS_RBUILDFLAGS = get-content "$ENV:APPDATA\RosBE\RBUILDFLAGS-$_ROSBE_VERSION.FLG"
}

$global:_ROSBE_ORIGINALPATH = "$_ROSBE_BASEDIR;$_ROSBE_BASEDIR\bin;$_ROSBE_BASEDIR\samples;$ENV:PATH"

if ("$_ROSBE_SYSPATH" -eq "0") {
    $global:_ROSBE_ORIGINALPATH = "$_ROSBE_BASEDIR;$_ROSBE_BASEDIR\bin;$ENV:SystemRoot\system32;$ENV:SystemRoot;$ENV:SystemRoot\System32\Wbem;$ENV:SYSTEMROOT\System32\WindowsPowerShell\v1.0"
}

# Load the doskey macros that serve as our commands.
LoadAliases

& "$_ROSBE_BASEDIR\rosbe-gcc-env.ps1"

clear-host
"*******************************************************************************"
"*                                                                             *"
"*                        ReactOS Build Environment $_ROSBE_VERSION                      *"
"*                                                                             *"
"*******************************************************************************"
""

# Load the base directory from srclist.txt and set it as the
# new source directory.
if (Test-Path "$_ROSBE_BASEDIR\scut.ps1") {
    & "$_ROSBE_BASEDIR\scut.ps1"
}
if ($_ROSBE_SHOWVERSION -eq 1) {
    & "$_ROSBE_BASEDIR\version.ps1"
}

""
& "$_ROSBE_BASEDIR\update.ps1" verstatus

# Tell how to display the available commands.
""
"For a list of all included commands, type: ""help"""
"-------------------------------------------------"
""

# Look if the ReactOS source directory is empty.
if ((get-childitem $_ROSBE_ROSSOURCEDIR).Count -le 0) {
    "No ReactOS source detected. Please use ""ssvn create"" to download it."
}
