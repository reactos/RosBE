#!/bin/bash
#
# ReactOS Build Environment for Windows - Script for building a RosBE toolchain for Windows
# Partly based on RosBE-Unix' "RosBE-Builder.sh"
# Copyright 2009-2019 Colin Finck <colin@reactos.org>
#
# Released under GPL-2.0-or-later (https://spdx.org/licenses/GPL-2.0-or-later)
#
# Run "buildtoolchain.sh" first, then this script.
# This script must be run under "MSYS2 MSYS"!

########################################################################################################################
# Package "rosbe_2.2"
#
# This script was built for the following toolchain versions:
# - Flex 2.6.4+ (revision 8b1fbf674f2e038df9cf1fe7725617e3837ae2a9)
#
# These tools have to be compiled using
# - http://repo.msys2.org/distrib/i686/msys2-i686-20190524.exe
#
# These versions are used in RosBE-Windows 2.2 and RosBE-Unix 2.2.
# Get the toolchain packages from http://svn.reactos.org/RosBE-Sources/rosbe_2.2
########################################################################################################################

# Hardcoded values for buildtoolchain/MSYS2
CC=gcc
CXX=g++
rs_makecmd=make

# Ensure similar error messages on all platforms, especially when we parse them (e.g. for pacman).
export LANG=C

# Make MSYS use native NTFS links for "ln -s"
export MSYS=winsymlinks:nativestrict

# Get the absolute path to the script directory
cd `dirname $0`
rs_scriptdir="$PWD"

# buildtoolchain Constants
# Use the GCC building for MSYS, not for MinGW. This is required for POSIX-specific packages like Flex.
HOST_GCC_VERSION="gcc version 9.1.0 (GCC)"
MODULES="flex"

source "$rs_scriptdir/scripts/setuplibrary.sh"


echo "*******************************************************************************"
echo "*     Buildtoolchain script for the ReactOS Build Environment for Windows     *"
echo "*                             Package \"rosbe_2.2\"                             *"
echo "*                                  MSYS part                                  *"
echo "*                      by Colin Finck <colin@reactos.org>                     *"
echo "*******************************************************************************"

echo
echo "This script builds a RosBE toolchain for Windows."
echo

if [ "$MSYSTEM" != "MSYS" ]; then
	echo "Please run this script in an \"MSYS2 MSYS\" environment!"
	exit 1
fi

# We don't want too less parameters
if [ "$2" == "" ]; then
	echo -n "Syntax: ./buildtoolchain-msys.sh <sources> <workdir>"

	for module in $MODULES; do
		echo -n " [$module]"
	done

	echo
	echo
	echo "Use the same <sources> and <workdir> parameters that you used for buildtoolchain.sh!"
	echo
	echo "The rest of the arguments are optional. You specify them if you want to prevent a component"
	echo "from being (re)built. Do this by passing 0 as the argument of the appropriate component."
	echo "Pass 1 if you want them to be built."
	echo "By default, all of these components are built, so you don't need to pass any of these parameters."
	exit 1
fi

# Install required tools in MSYS2
rs_boldmsg "Running MSYS pacman..."
pacman -S --quiet --noconfirm --needed base-devel msys2-devel | tee /tmp/buildtoolchain-msys-pacman.log

if grep installation /tmp/buildtoolchain-msys-pacman.log >& /dev/null; then
	# See e.g. https://sourceforge.net/p/msys2/tickets/74/
	echo
	rs_boldmsg "Installed MSYS packages have changed!"
	echo "For a successful toolchain build, this requires you to close all MSYS windows and run \"autorebase.bat\" in the MSYS installation directory."
	echo "After you have done so, please rerun \"buildtoolchain-msys.sh\"."
	exit 1
fi

echo

# Check for the correct GCC version
echo -n "Checking for the correct GCC version... "

if gcc -v 2>&1 | grep "$HOST_GCC_VERSION" >& /dev/null; then
	rs_greenmsg "OK"
else
	rs_redmsg "MISSING"
	echo "Correct GCC version is missing, aborted!"
	exit 1
fi

echo

# Get the absolute path to the source directory
cd "$1"
rs_sourcedir="$PWD"
shift

# Verify the work directory path style
if [ "${1:0:1}" != "/" ] || [ "${1:2:1}" != "/" ]; then
	echo "Please specify an absolute path in Unix style as the work directory!"
	exit 1
fi

rs_workdir="$1"
shift

rs_prefixdir="$rs_workdir/RosBE"

# Set the rs_process_* variables based on the parameters
for module in $MODULES; do
	if [ "$1" = "0" ]; then
		eval "rs_process_$module=false"
	else
		eval "rs_process_$module=true"
	fi

	shift
done


##### BEGIN almost shared buildtoolchain/RosBE-Unix building part #############
rs_boldmsg "Building..."

CFLAGS="-pipe -O2 -Wl,-S -g0 -march=core2 -mfpmath=sse -msse2"
CXXFLAGS="-pipe -O2 -Wl,-S -g0 -march=core2 -mfpmath=sse -msse2"

export CFLAGS
export CXXFLAGS
echo
echo "Using CFLAGS=\"$CFLAGS\""
echo "Using CXXFLAGS=\"$CXXFLAGS\""
echo

rs_cpucount=`$rs_prefixdir/bin/cpucount -x1`

if rs_prepare_module "flex"; then
	rs_do_command ../flex/configure --prefix="$rs_prefixdir" --disable-nls
	rs_do_command $rs_makecmd -j $rs_cpucount
	rs_do_command $rs_makecmd install
	rs_clean_module "flex"
fi

# Final actions
echo
rs_boldmsg "Final actions"

echo "Removing unneeded files..."
cd "$rs_prefixdir"
rm -rf doc man share/doc share/info share/man
##### END almost shared buildtoolchain/RosBE-Unix building part ###############

echo "Removing debugging symbols..."
cd "$rs_prefixdir/bin"
strip -s flex.exe
strip -s flex++.exe

echo "Copying additional dependencies from MSYS..."
cd "$rs_prefixdir/bin"
cp /usr/bin/msys-2.0.dll .

echo "Finished!"
