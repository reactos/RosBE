#
# PROJECT:     RosBE - ReactOS Build Environment for Windows
# LICENSE:     GNU General Public License v2. (see LICENSE.txt)
# PURPOSE:     Perform the build of ReactOS.
# COPYRIGHT:   Copyright 2020 Daniel Reimer <reimer.daniel@freenet.de>
#

if ($_ROSBE_USECCACHE -eq 1) {
    if ("$_ROSBE_CACHESIZE" -ne "") {
    $_ROSBE_CACHESIZEG = "$_ROSBE_CACHESIZE" + "G"
        &{IEX "&'ccache.exe' -M $_ROSBE_CACHESIZEG"}
    }
    $_ROSBE_CCACHE = "ccache "
} else {
    $_ROSBE_CCACHE = $null
}
    $ENV:HOST_CC = "$_ROSBE_CCACHE" + "gcc"
    $ENV:HOST_CPP = "$_ROSBE_CCACHE" + "g++"
    $ENV:TARGET_CC = "$_ROSBE_CCACHE" + "$_ROSBE_PREFIX" + "gcc"
    $ENV:TARGET_CPP = "$_ROSBE_CCACHE" + "$_ROSBE_PREFIX" + "g++"

# Get the current date and time for use in in our build log's file name.
$TIMERAW = get-date -f t
$DATENAME = get-date -f dMMyyyy
$TIMENAME = get-date -f Hms

# Check whether we were called as "makex" or "make"
if ("$($args[0])" -eq "multi") {
    $args.setvalue($null, 0)
    $MAKE_JOBS = "$_ROSBE_MAKEX_JOBS"
    $TITLE_COMMAND = "makex $($args)"
} else {
    $MAKE_JOBS = 1
    $TITLE_COMMAND = "make $($args)"
}

if (Test-Path "*.ninja") {
    $MAKE_INT = "ninja.exe"
} else {
    $MAKE_INT = "mingw32-make.exe"
}

$host.ui.RawUI.WindowTitle = "'$TITLE_COMMAND' build started: $TIMERAW   ($ENV:ROS_ARCH)"

# Do the actual building
if ($_ROSBE_SHOWTIME -eq 1) {
    [System.Diagnostics.Stopwatch] $sw;
    $sw = New-Object System.Diagnostics.StopWatch
    $sw.Start()
}

if ($_ROSBE_WRITELOG -eq 1) {
    if (!(Test-Path "$_ROSBE_LOGDIR")) {
        New-Item -path "$_ROSBE_LOGDIR" -type directory
    }
    $file = "$_ROSBE_LOGDIR\BuildLog-$ENV:ROS_ARCH-$DATENAME-$TIMENAME.txt"
    &{IEX "&'$MAKE_INT' -j $MAKE_JOBS $($args)"} $($args) 2>&1 | tee-object $file
} else {
    &{IEX "&'$MAKE_INT' -j $MAKE_JOBS $($args)"} $($args)
}
if ($_ROSBE_SHOWTIME -eq 1) {
    $sw.Stop()
    write-host "Total Build Time:" $sw.Elapsed.ToString()
}

# Highlight the fact that building has ended.
FlashWindow (ps -id $pid).MainWIndowHandle $true

if ($_ROSBE_NOSOUND -ne 1) {
    $sound = new-Object System.Media.SoundPlayer;

    if ($LASTEXITCODE -ne 0) {
        $sound.SoundLocation="$_ROSBE_BASEDIR\samples\error.wav";
    } else {
        $sound.SoundLocation="$_ROSBE_BASEDIR\samples\notification.wav";
    }
    $sound.Play();
}

$host.ui.RawUI.WindowTitle = "ReactOS Build Environment $_ROSBE_VERSION"
