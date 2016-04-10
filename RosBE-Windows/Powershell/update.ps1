#
# PROJECT:     RosBE - ReactOS Build Environment for Windows
# LICENSE:     GNU General Public License v2. (see LICENSE.txt)
# FILE:        Root/update.ps1
# PURPOSE:     RosBE Updater.
# COPYRIGHT:   Copyright 2016 Daniel Reimer <reimer.daniel@freenet.de>
#

$host.ui.RawUI.WindowTitle = "Updating..."

# Web Downloader in a function.

function get-webfile {
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

function EOC {
    set-location "$_ROSBE_OPATH"
    $host.ui.RawUI.WindowTitle = "ReactOS Build Environment $_ROSBE_VERSION"
    exit
}

function UPDCHECK {
    set-location "$ENV:APPDATA\RosBE\Updates"

    if (Test-Path "$_ROSBE_VERSION-$_ROSBE_STATCOUNT.txt") {
        return
    } else {
        get-webfile $_ROSBE_URL/$_ROSBE_VERSION-$_ROSBE_STATCOUNT.txt $PWD\$_ROSBE_VERSION-$_ROSBE_STATCOUNT.txt
    }
    if (Test-Path "$_ROSBE_VERSION-$_ROSBE_STATCOUNT.txt") {
        get-Content "$_ROSBE_VERSION-$_ROSBE_STATCOUNT.txt"
        ""
        "Install?"
        $YESNO = Read-Host "(yes), (no)"
        if (("$YESNO" -eq "yes") -or ("$YESNO" -eq "y")) {
            if (!(Test-Path "$_ROSBE_VERSION-$_ROSBE_STATCOUNT.7z")) {
                get-webfile $_ROSBE_URL/$_ROSBE_VERSION-$_ROSBE_STATCOUNT.7z $PWD\$_ROSBE_VERSION-$_ROSBE_STATCOUNT.7z
            }
            if (Test-Path "$_ROSBE_VERSION-$_ROSBE_STATCOUNT.7z") {
                remove-item "$_ROSBE_VERSION-$_ROSBE_STATCOUNT\*.*" -force -EA SilentlyContinue
                IEX "& 7z.exe x '$_ROSBE_VERSION-$_ROSBE_STATCOUNT.7z'"
                set-location "$_ROSBE_VERSION-$_ROSBE_STATCOUNT"
                IEX "& .\$_ROSBE_VERSION-$_ROSBE_STATCOUNT.ps1"
                return
            } else {
                throw {"ERROR: This Update does not seem to exist or the Internet connection is not working correctly."}
                return
            }
        } elseif (("$YESNO" -eq "no") -or ("$YESNO" -eq "n")) {
            "Do you want to be asked again to install this update?"
            $YESNO = Read-Host "(yes), (no)"
            if (("$YESNO" -eq "yes") -or ("$YESNO" -eq "y")) {
                remove-item "$_ROSBE_VERSION-$_ROSBE_STATCOUNT.txt" -force -EA SilentlyContinue
            }
            return
        }
    } else {
        if ($_ROSBE_MULTIUPD -ne 1) {
            throw {"ERROR: This Update does not seem to exist or the Internet connection is not working correctly."}
        }
        $_ROSBE_STATCOUNT = 9
        return
    }
}

# The Update Server.
$_ROSBE_URL = "http://svn.reactos.org/downloads/rosbe"

# Save the recent dir to cd back there at the end.
$_ROSBE_OPATH = "$pwd"

set-location $_ROSBE_BASEDIR

# First check for a new Updater.
rename-item update.ps1 update2.ps1
get-webfile $_ROSBE_URL/update.ps1 $PWD\update.ps1
if (((gi .\update.ps1).length -ne (gi .\update2.ps1).length) -and ((gi .\update.ps1).length -gt 0)) {
    clear-host
    "Updater got updated and needs to be restarted."
    remove-item update2.ps1 -force
    EOC
} else {
    remove-item update.ps1 -force
    rename-item update2.ps1 update.ps1
}
# Get to the Updates Subfolder.
if (!(Test-Path "$ENV:APPDATA\RosBE\Updates")) {New-Item -path "$ENV:APPDATA\RosBE" -name "Updates" -type directory}
set-location "$ENV:APPDATA\RosBE\Updates"

if ("$($args[0])" -eq "") {
    $_ROSBE_MULTIUPD = 1
    $_ROSBE_STATCOUNT = 1
    while ($_ROSBE_STATCOUNT -lt 10) {
        UPDCHECK
        $_ROSBE_STATCOUNT += 1
    }
    "Update finished..."
} elseif ("$($args[0])" -eq "reset") {
    remove-item "$ENV:APPDATA\RosBE\Updates\*.*" -force -recurse -EA SilentlyContinue
    remove-item "$ENV:APPDATA\RosBE\Updates\tmp\*.*" -force -recurse -EA SilentlyContinue
    "Update Statistics resetted..."
} elseif ("$($args[0])" -eq "nr") {
    $_ROSBE_STATCOUNT = $($args[1])
    UPDCHECK
    echo Update Nr:$($args[1]) installed...
} elseif ("$($args[0])" -eq "delete") {
    $_ROSBE_STATCOUNT = $($args[1])
    remove-item "$ENV:APPDATA\RosBE\Updates\$_ROSBE_VERSION-$_ROSBE_STATCOUNT.*" -force -recurse -EA SilentlyContinue
    remove-item "$ENV:APPDATA\RosBE\Updates\tmp\$_ROSBE_VERSION-$_ROSBE_STATCOUNT.*" -force -recurse -EA SilentlyContinue
    "Update-$($args[1]) Statistics resetted..."
} elseif ("$($args[0])" -eq "info") {
    $_ROSBE_STATCOUNT = $($args[1])
    if (!(test-path "tmp")) {New-Item -name "tmp" -type directory}
    set-location tmp
    if (!(Test-Path "$_ROSBE_VERSION-$_ROSBE_STATCOUNT.txt")) {
        get-webfile $_ROSBE_URL/$_ROSBE_VERSION-$_ROSBE_STATCOUNT.txt $PWD\$_ROSBE_VERSION-$_ROSBE_STATCOUNT.txt
        if (Test-Path "$_ROSBE_VERSION-$_ROSBE_STATCOUNT.txt") {
            get-content "$_ROSBE_VERSION-$_ROSBE_STATCOUNT.txt"
        } else {
            throw {"ERROR: This Update does not seem to exist or the Internet connection is not working correctly."}
        }
    }
    set-location ..
    remove-item "tmp\*.*" -force -EA SilentlyContinue
} elseif ("$($args[0])" -eq "status") {
    $_ROSBE_STATCOUNT = 1
    if (!(test-path "tmp")) {New-Item -name "tmp" -type directory}
    copy-item *.txt .\tmp\.
    set-location tmp
    while ($_ROSBE_STATCOUNT -lt 10) {
        if (!(Test-Path "$_ROSBE_VERSION-$_ROSBE_STATCOUNT.txt")) {
            get-webfile $_ROSBE_URL/$_ROSBE_VERSION-$_ROSBE_STATCOUNT.txt $PWD\$_ROSBE_VERSION-$_ROSBE_STATCOUNT.txt
            if (Test-Path "$_ROSBE_VERSION-$_ROSBE_STATCOUNT.txt") {
                 $_ROSBE_UPDATES += "$_ROSBE_STATCOUNT "
            } else {
                 $_ROSBE_STATCOUNT = 9
            }
        }
        $_ROSBE_STATCOUNT += 1
    }
    set-location ..
    remove-item "tmp\*.*" -force -EA SilentlyContinue
    if ("$_ROSBE_UPDATES" -ne "") {
        "Following Updates available: $_ROSBE_UPDATES"
    } else {
        "RosBE is up to Date."
    }
} elseif ("$($args[0])" -eq "verstatus") {
    if (!(test-path "tmp")) {New-Item -name "tmp" -type directory}
    copy-item *.txt .\tmp\.
    set-location tmp
    if (!(Test-Path "ver.txt")) {
        get-webfile $_ROSBE_URL/ver.txt $PWD\ver.txt
        if (Test-Path "ver.txt") {
            $_ROSBE_NEWVER = get-content ver.txt
        }
        if ("$_ROSBE_NEWVER" -ne "$_ROSBE_VERSION") {
            "RosBE is outdated. Installed version: $_ROSBE_VERSION Recent version: $_ROSBE_NEWVER."
        } else {
            "RosBE is up to Date."
        }
    }
    set-location ..
    remove-item "tmp\*.*" -force -EA SilentlyContinue
} else {
    "Unknown parameter specified. Try 'help update'."
}

EOC
