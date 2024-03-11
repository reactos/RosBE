#!/usr/bin/env bash
# This is a sample script to setup configuration variables for building ReactOS
#  on a custom-made RosBE, please note that this should be used only for testing
#  and not on an actual production environment
# Use it like this: "source Setup-test.sh i386 /usr/local/RosBE"

if [ "$1" = "i386" ]; then
    export ROS_ARCH="i386"
elif [ "$1" = "amd64" ]; then
    export ROS_ARCH="amd64"
else    
    echo "Please specify an architecture"
    exit 1
fi

if [ "$2" = "" ]; then
    echo "Please specify your RosBE directory"
    exit 1
fi

rs_triplet_path=$2/$ROS_ARCH/bin

declare -A rs_triplets=(
	["i386"]="i686-w64-mingw32"
	["amd64"]="x86_64-w64-mingw32"
)

rs_triplet=${rs_triplets[$ROS_ARCH]}

export PATH=${PATH}:${2}/bin:${rs_triplet_path}
export CC=$rs_triplet_path/$rs_triplet-gcc.exe
export CXX=$rs_triplet_path/$rs_triplet-g++.exe
export LD=$rs_triplet_path/$rs_triplet-ld.exe
export EXTRA_ARGS="-DCMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX"

echo "Ok!"
