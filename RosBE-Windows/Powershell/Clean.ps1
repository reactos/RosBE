#
# PROJECT:     RosBE - ReactOS Build Environment for Windows
# LICENSE:     GNU General Public License v2. (see LICENSE.txt)
# FILE:        Root/Clean.ps1
# PURPOSE:     Clean the ReactOS source directory.
# COPYRIGHT:   Copyright 2016 Daniel Reimer <reimer.daniel@freenet.de>
#

$host.ui.RawUI.WindowTitle = "Cleaning..."

function remlog {
    # Check if we have any logs to clean, if so, clean them.
    if (Test-Path "$_ROSBE_LOGDIR") {
        "Cleaning build logs..."
        $null = (Remove-Item -path "$_ROSBE_LOGDIR\*.txt" -force)
        "Done cleaning build logs."
    } else {
        throw {"ERROR: There are no logs to clean."}
    }
}

function rembin {
    # Check if we have any binaries to clean, if so, clean them.

    if (Test-Path "CMakeLists.txt") {
        "Cleaning ReactOS $ENV:ROS_ARCH source directory..."
        $null = (Remove-Item "$ENV:ROS_CMAKE_HOST" -recurse -force)
        $null = (Remove-Item "$ENV:ROS_CMAKE_BUILD" -recurse -force)
        "Done cleaning ReactOS $ENV:ROS_ARCH source directory."
    } else {
        throw {"ERROR: This directory contains no $ENV:ROS_ARCH compiler output to clean."}
    }
}

function remhost {
    $null = (Remove-Item "$ENV:ROS_CMAKE_HOST" -recurse -force)
}

function end {
    $host.ui.RawUI.WindowTitle = "ReactOS Build Environment $_ROSBE_VERSION"
    exit
}

$ENV:ROS_CMAKE_HOST = "output-$BUILD_ENVIRONMENT-$ENV:ROS_ARCH\host-tools"
$ENV:ROS_CMAKE_BUILD = "output-$BUILD_ENVIRONMENT-$ENV:ROS_ARCH\reactos"

if ("$args" -eq "") {
    rembin
}
elseif ("$args" -eq "logs") {
    remlog
}
elseif ("$args" -eq "all") {
    rembin
    remlog
}
elseif ("$args" -eq "host-tools") {
    remhost
}
elseif ("$args" -ne "") {
    $argindex = 0
    while ( "$($args[$argindex])" -ne "") {
        $cl = "$($args[$argindex])" + "_clean"
        make $cl
        $argindex += 1
    }
    remove-variable cl
}
end
