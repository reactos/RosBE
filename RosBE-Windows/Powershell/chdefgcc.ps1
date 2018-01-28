#
# PROJECT:     RosBE - ReactOS Build Environment for Windows
# LICENSE:     GNU General Public License v2. (see LICENSE.txt)
# FILE:        Root/chdefgcc.ps1
# PURPOSE:     Tool to change the current gcc in RosBE.
# COPYRIGHT:   Copyright 2018 Daniel Reimer <reimer.daniel@freenet.de>
#

$host.ui.RawUI.WindowTitle = "Change the current MinGW/GCC Host/Target directory..."

function settitle {
    $host.ui.RawUI.WindowTitle = "ReactOS Build Environment $_ROSBE_VERSION"
    exit
}

function EOA {
    IEX "&'$_ROSBE_BASEDIR\rosbe-gcc-env.ps1'"
    version
    settitle
}

# Parse the command line arguments. Ask the user if certain parameters are missing.
$TOOLPATH = $args[0]
$TOOLMODE = $args[1]
if ("$TOOLPATH" -eq "") {
    $TOOLPATH = Read-Host "Please enter a MinGW/GCC directory (don't use quotes): "
    if ($TOOLPATH.length -eq 0) {
        throw {"ERROR: You must enter a MinGW/GCC directory."}
        settitle
    }
}
if ("$TOOLMODE" -eq "") {
    $TOOLMODE = Read-Host "Please specify, if this will be the Target or Host GCC: "
    if ($TOOLMODE.length -eq 0) {
        throw {"ERROR: You must enter ""target"" or ""host""."}
        settitle
    }
}

# Verify the entered values
$local:ErrorActionPreference = "SilentlyContinue"
if (Test-Path "$_ROSBE_BASEDIR\$TOOLPATH\.") {
    $TOOLPATH = "$_ROSBE_BASEDIR\$TOOLPATH"
} elseif (!(Test-Path "$TOOLPATH\.")) {
    throw {"ERROR: The path specified doesn't seem to exist."}
    settitle
}
$local:ErrorActionPreference = "Continue"
if (!(Test-Path "$TOOLPATH\bin\*gcc.exe")) {
    throw {"ERROR: No MinGW/GCC found in the specified path."}
    settitle
}

# Set the values
if ("$TOOLMODE" -eq "target") {
    $_ROSBE_TARGET_MINGWPATH = $TOOLPATH
    "Target Location: $_ROSBE_TARGET_MINGWPATH"
    EOA
} elseif ("$TOOLMODE" -eq "host") {
    $_ROSBE_HOST_MINGWPATH = $TOOLPATH
    "Host Location: $_ROSBE_HOST_MINGWPATH"
    EOA
} else {
    throw {"ERROR: You specified wrong parameters."}
    settitle
}
