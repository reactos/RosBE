#
# PROJECT:     RosBE - ReactOS Build Environment for Windows
# LICENSE:     GNU General Public License v2. (see LICENSE.txt)
# PURPOSE:     Clean the ReactOS source directory.
# COPYRIGHT:   Copyright 2020 Daniel Reimer <reimer.daniel@freenet.de>
#

$host.ui.RawUI.WindowTitle = "Cleaning..."

function remlog {
    # Check if we have any logs to clean, if so, clean them.
    if (Test-Path "$ENV:ROS_CMAKE_BUILD\$_ROSBE_LOGDIR") {
        "Cleaning build logs..."
        $null = (Remove-Item -path "$ENV:ROS_CMAKE_BUILD\$_ROSBE_LOGDIR\*.txt" -force)
        "Done cleaning build logs."
    } else {
        throw {"ERROR: There are no logs to clean."}
    }
}

function rembin {
    # Check if we have any binaries to clean, if so, clean them.

    if (Test-Path "CMakeLists.txt") {
        "Cleaning ReactOS $ENV:ROS_ARCH source directory..."
        $null = (Remove-Item "$ENV:ROS_CMAKE_BUILD" -recurse -force)
        "Done cleaning ReactOS $ENV:ROS_ARCH source directory."
    } else {
        throw {"ERROR: This directory contains no $ENV:ROS_ARCH compiler output to clean."}
    }
}

function end {
    $host.ui.RawUI.WindowTitle = "ReactOS Build Environment $_ROSBE_VERSION"
    exit
}

$ENV:ROS_CMAKE_BUILD = "output-$BUILD_ENVIRONMENT-$ENV:ROS_ARCH"

if ("$args" -eq "") {
    rembin
}
elseif ("$args" -eq "logs") {
    remlog
}
elseif ("$args" -eq "all") {
    rembin
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
