#
# PROJECT:     RosBE - ReactOS Build Environment for Windows
# LICENSE:     GNU General Public License v2. (see LICENSE.txt)
# FILE:        Root/Clean.ps1
# PURPOSE:     Clean the ReactOS source directory.
# COPYRIGHT:   Copyright 2010 Daniel Reimer <reimer.daniel@freenet.de>
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

    # Check if the user set any custom filenames or pathes, otherwise locally set the appropriate variables.

    if (!(Test-Path "CMakeLists.txt")) {
        if ("$ENV:ROS_AUTOMAKE" -eq "") {
            $ENV:ROS_AUTOMAKE = "makefile-$ENV:ROS_ARCH.auto"
        }
        if ("$ENV:ROS_INTERMEDIATE" -eq "") {
            $ENV:ROS_INTERMEDIATE = "obj-$ENV:ROS_ARCH"
        }
        if ("$ENV:ROS_OUTPUT" -eq "") {
            $ENV:ROS_OUTPUT = "output-$ENV:ROS_ARCH"
        }
        if ("$ENV:ROS_CDOUTPUT" -eq "") {
            $ENV:ROS_CDOUTPUT = "reactos"
        }
    } else {
        $ENV:ROS_INTERMEDIATE = "host-tools"
        $ENV:ROS_OUTPUT = "reactos"
    }
        

    if (Test-Path "$ENV:ROS_INTERMEDIATE\.") {
        "Cleaning ReactOS $ENV:ROS_ARCH source directory..."

        if (!(Test-Path "CMakeLists.txt")) {
            $null = (Remove-Item "$ENV:ROS_AUTOMAKE" -force)
            $null = (Remove-Item "$ENV:ROS_CDOUTPUT" -recurse -force)
        }
        $null = (Remove-Item "$ENV:ROS_INTERMEDIATE" -recurse -force)
        $null = (Remove-Item "$ENV:ROS_OUTPUT" -recurse -force)

        "Done cleaning ReactOS $ENV:ROS_ARCH source directory."
    } else {
        throw {"ERROR: This directory contains no $ENV:ROS_ARCH compiler output to clean."}
    }
}

function end {
    $host.ui.RawUI.WindowTitle = "ReactOS Build Environment $_ROSBE_VERSION"
    exit
}

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
