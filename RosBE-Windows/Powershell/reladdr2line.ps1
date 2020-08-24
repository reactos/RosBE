#
# PROJECT:     RosBE - ReactOS Build Environment for Windows
# LICENSE:     GNU General Public License v2. (see LICENSE.txt)
# PURPOSE:     Converts a value to hex and displays it.
# COPYRIGHT:   Copyright 2020 Daniel Reimer <reimer.daniel@freenet.de>
#

$host.ui.RawUI.WindowTitle = "reladdr2line..."

# Receive all parameters.
$FILEPATH = $args[0]
$ADDRESS = $args[1]
if ($args.length -lt 1) {
    if ("$FILEPATH" -eq "") {
        $FILEPATH = Read-Host "Please enter the path/file to be examined: "
        if ($FILEPATH.Contains("\")) {
            $FILEPATH = get-childitem "$FILEPATH\*" -name -recurse 2>NUL | select-string "$FILEPATH"
        }
    }
}
elseif ($args.length -lt 2) {
    if ("$ADDRESS" -eq "") {
        $ADDRESS = Read-Host "Please enter the address you would like to analyze: "
    }
}

# Check if parameters were really given
if ("$FILEPATH" -eq "") {
    throw {"ERROR: You must specify a path/file to examine."}
}
if ("$ADDRESS" -eq "") {
    throw {"ERROR: You must specify a address to analyze."}
}

$output = "output-$global:BUILD_ENVIRONMENT-$ENV:ROS_ARCH"

if ("$output" -ne "") {
    IEX "& log2lines.exe -d '$output' '$FILEPATH' '$ADDRESS'"
} else {
    IEX "& log2lines.exe '$FILEPATH' '$ADDRESS'"
}

$host.ui.RawUI.WindowTitle = "ReactOS Build Environment $_ROSBE_VERSION"
