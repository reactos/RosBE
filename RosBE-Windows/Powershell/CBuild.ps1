#
# PROJECT:     RosBE - ReactOS Build Environment for Windows
# LICENSE:     GNU General Public License v2. (see LICENSE.txt)
# FILE:        Root/CBuild.ps1
# PURPOSE:     Perform the CMake build of ReactOS.
# COPYRIGHT:   Copyright 2011 Daniel Reimer <reimer.daniel@freenet.de>
#

$null = "$ENV:PATH" | select-string -pattern "cmake"
if ($LASTEXITCODE -ne 0) {
    "CMake not found. Build cant be continued, until a CMake version of 2.6 or newer"
    "is properly installed on this system. The newest Version can be found here:"
    "http://www.cmake.org/cmake/resources/software.html"
    exit
}

if ($_ROSBE_WRITELOG -eq 1) {
    if (!(Test-Path "$_ROSBE_LOGDIR")) {
        New-Item -path "$_ROSBE_LOGDIR" -type directory
    }
    $file1 = "..\$_ROSBE_LOGDIR\BuildToolLog-$ENV:ROS_ARCH-$DATENAME-$TIMENAME.txt"
    $file2 = "..\$_ROSBE_LOGDIR\BuildROSLog-$ENV:ROS_ARCH-$DATENAME-$TIMENAME.txt"
}

# Get the current date and time for use in in our build log's file name.
$TIMERAW = get-date -f t
$DATENAME = get-date -f dMMyyyy
$TIMENAME = get-date -f Hms

# Setting for MinGW Compiler in CMake
$ENV:BUILD_ENVIRONMENT = "MINGW"

# Check whether we were called as "makex" or "make"
if ("$($args[0])" -eq "multi") {
    $args.setvalue($null, 0)
    $MAKE_JOBS = "$_ROSBE_MAKEX_JOBS"
    $TITLE_COMMAND = "makex $($args)"
} else {
    $MAKE_JOBS = 1
    $TITLE_COMMAND = "make $($args)"
}

$host.ui.RawUI.WindowTitle = "'$TITLE_COMMAND' cmake build started: $TIMERAW   ($ENV:ROS_ARCH)"

# Do the actual building
if ($_ROSBE_SHOWTIME -eq 1) {
    [System.Diagnostics.Stopwatch] $sw;
    $sw = New-Object System.Diagnostics.StopWatch
    $sw.Start()
}

if (!(Test-Path "host-tools")) {
        New-Item -path "host-tools" -type directory
    }

cd host-tools

# Variable with the Host Tools Path
$REACTOS_BUILD_TOOLS_DIR = "$pwd"

&{IEX "&'cmake.exe' -G 'MinGW Makefiles' '-DARCH=$ENV:ROS_ARCH' ..\"}

if ($_ROSBE_WRITELOG -eq 1) {
    &{IEX "&'mingw32-make.exe' -j $MAKE_JOBS $($args)"} $($args) 2>&1 | tee-object $file1
} else {
    &{IEX "&'mingw32-make.exe' -j $MAKE_JOBS $($args)"} $($args)
}

cd..
""

if (!(Test-Path "reactos")) {
        New-Item -path "reactos" -type directory
    }

cd reactos
&{IEX "&'cmake.exe' -G 'MinGW Makefiles' '-DCMAKE_TOOLCHAIN_FILE=toolchain-mingw32.cmake' '-DARCH=$ENV:ROS_ARCH' '-DREACTOS_BUILD_TOOLS_DIR:DIR=""$REACTOS_BUILD_TOOLS_DIR""' ..\"}

if ($_ROSBE_WRITELOG -eq 1) {
    &{IEX "&'mingw32-make.exe' -j $MAKE_JOBS $($args)"} $($args) 2>&1 | tee-object $file2
} else {
    &{IEX "&'mingw32-make.exe' -j $MAKE_JOBS $($args)"} $($args)
}

cd..

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
