#!/bin/bash
#
# ReactOS Build Environment for Windows - Script for building a RosBE toolchain for Windows
# Partly based on RosBE-Unix' "RosBE-Builder.sh"
# Copyright 2009-2019 Colin Finck <colin@reactos.org>
#
# Released under GPL-2.0-or-later (https://spdx.org/licenses/GPL-2.0-or-later)
#
# Run "buildtoolchain-msys.sh" after this script.
# This script must be run under "MSYS2 MinGW 32-bit"!

########################################################################################################################
# Package "rosbe_2.2"
#
# This script was built for the following toolchain versions:
# - Binutils 2.32
# - Bison 3.5
#   patched with:
#     * https://raw.githubusercontent.com/reactos/RosBE/master/Patches/bison-3.5-reactos-fix-win32-build.patch
# - CMake 3.16.2
# - GCC 8.3.0
# - GMP 6.1.2
# - Mingw-w64 6.0.0
# - MPC 1.1.0
# - MPFR 4.0.2
# - Ninja 1.9.0
#   patched with:
#      * https://raw.githubusercontent.com/reactos/RosBE/master/Patches/ninja-v1.9.0-Fix-MinGW-bootstrap-build.patch
#
# These tools have to be compiled using
# - http://repo.msys2.org/distrib/i686/msys2-i686-20190524.exe
# - https://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win32/Personal%20Builds/mingw-builds/8.1.0/threads-posix/dwarf/i686-8.1.0-release-posix-dwarf-rt_v6-rev0.7z
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

# RosBE Setup Variables
rs_needed_tools="as bzip2 find $CC $CXX grep help2man m4 makeinfo python re2c tar"        # GNU Make has a special check
rs_target="i686-w64-mingw32"
rs_target_cflags="-pipe -O2 -Wl,-S -g0 -march=pentium -mtune=i686"

# Get the absolute path to the script directory
cd `dirname $0`
rs_scriptdir="$PWD"

# buildtoolchain Constants
# Use the GCC with POSIX Thread Model! CMake uses C++11 threads, which are not supported in GCC's Win32 Thread Model (yet).
HOST_GCC_VERSION="gcc version 8.1.0 (i686-posix-dwarf-rev0, Built by MinGW-W64 project)"

# We ship the host M4 version along with Bison, so it should be the expected one.
HOST_M4_VERSION="m4 (GNU M4) 1.4.18"

MODULES="bison cmake binutils mingw_w64 gcc ninja"

source "$rs_scriptdir/scripts/setuplibrary.sh"


echo "*******************************************************************************"
echo "*     Buildtoolchain script for the ReactOS Build Environment for Windows     *"
echo "*                             Package \"rosbe_2.2\"                             *"
echo "*                                  MinGW part                                 *"
echo "*                      by Colin Finck <colin@reactos.org>                     *"
echo "*******************************************************************************"

echo
echo "This script builds a RosBE toolchain for Windows."
echo

if [ "`uname -o`" != "Msys" ]; then
	echo "You can only run this script under a MSYS environment!"
	exit 1
fi

# We don't want too less parameters
if [ "$2" == "" ]; then
	echo -n "Syntax: ./buildtoolchain.sh <sources> <workdir>"

	for module in $MODULES; do
		echo -n " [$module]"
	done

	echo
	echo
	echo " sources  - Path to the directory containing RosBE-Unix toolchain packages (.tar.bz2 files)"
	echo " workdir  - Path to the directory used for building. Will contain the final executables and"
	echo "            temporary files."
	echo "            The path must be an absolute one in Unix style, e.g. /d/buildtoolchain"
	echo
	echo "The rest of the arguments are optional. You specify them if you want to prevent a component"
	echo "from being (re)built. Do this by passing 0 as the argument of the appropriate component."
	echo "Pass 1 if you want them to be built."
	echo "By default, all of these components are built, so you don't need to pass any of these parameters."
	exit 1
fi

# Install required tools in MSYS2
rs_boldmsg "Running MSYS pacman..."
pacman -S --quiet --noconfirm --needed diffutils help2man make msys2-runtime-devel python re2c texinfo | tee /tmp/buildtoolchain-pacman.log

if grep installation /tmp/buildtoolchain-pacman.log >& /dev/null; then
	# See e.g. https://sourceforge.net/p/msys2/tickets/74/
	echo
	rs_boldmsg "Installed MSYS packages have changed!"
	echo "For a successful toolchain build, this requires you to close all MSYS windows and run \"autorebase.bat\" in the MSYS installation directory."
	echo "After you have done so, please rerun \"buildtoolchain.sh\"."
	exit 1
fi

echo

rs_check_requirements

# Check for the correct GCC version
echo -n "Checking for the correct GCC version... "

if gcc -v 2>&1 | grep "$HOST_GCC_VERSION" >& /dev/null; then
	rs_greenmsg "OK"
else
	rs_redmsg "MISSING"
	echo "Correct GCC version is missing, aborted!"
	exit 1
fi

# Check for the correct M4 version
echo -n "Checking for the correct M4 version... "

if /usr/bin/m4 --version 2>&1 | grep "$HOST_M4_VERSION" >& /dev/null; then
	rs_greenmsg "OK"
else
	rs_redmsg "MISSING"
	echo "Correct M4 version is missing, aborted!"
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
rs_archprefixdir="$rs_prefixdir/i386"

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

rs_mkdir_if_not_exists "$rs_prefixdir/bin"
rs_mkdir_if_not_exists "$rs_archprefixdir/$rs_target"

CFLAGS="-pipe -O2 -Wl,-S -g0 -march=core2 -mfpmath=sse -msse2"
CXXFLAGS="-pipe -O2 -Wl,-S -g0 -march=core2 -mfpmath=sse -msse2"

export CFLAGS
export CXXFLAGS
echo
echo "Using CFLAGS=\"$CFLAGS\""
echo "Using CXXFLAGS=\"$CXXFLAGS\""
echo

rs_do_command $CC -s -o "$rs_prefixdir/bin/cpucount.exe" "$rs_scriptdir/tools/cpucount.c"
rs_cpucount=`$rs_prefixdir/bin/cpucount -x1`

if rs_prepare_module "bison"; then
	rs_do_command ../bison/configure --prefix="$rs_prefixdir" --disable-nls
	rs_do_command $rs_makecmd -j $rs_cpucount
	rs_do_command $rs_makecmd install
	rs_clean_module "bison"
fi

# flex is handled in buildtoolchain-msys.sh

if rs_prepare_module "cmake"; then
	rs_do_command ../cmake/bootstrap --prefix="$rs_prefixdir" --parallel=$rs_cpucount -- -DCMAKE_USE_OPENSSL=OFF
	rs_do_command $rs_makecmd -j $rs_cpucount
	rs_do_command $rs_makecmd install
	rs_clean_module "cmake"
fi

if rs_prepare_module "binutils"; then
	rs_do_command ../binutils/configure --prefix="$rs_archprefixdir" --host="$rs_target" --build="$rs_target" --target="$rs_target" --with-sysroot="$rs_archprefixdir" --disable-multilib --disable-werror --enable-lto --enable-plugins --with-zlib=yes --disable-nls
	rs_do_command $rs_makecmd -j $rs_cpucount
	rs_do_command $rs_makecmd install
	rs_clean_module "binutils"
fi

if rs_prepare_module "mingw_w64"; then
	rs_do_command ../mingw_w64/mingw-w64-headers/configure --prefix="$rs_archprefixdir/$rs_target" --host="$rs_target"
	rs_do_command $rs_makecmd -j $rs_cpucount
	rs_do_command $rs_makecmd install
	rs_do_command ln -s -f $rs_archprefixdir/$rs_target $rs_archprefixdir/mingw
	rs_clean_module "mingw_w64"
fi

if rs_prepare_module "gcc"; then
	rs_extract_module gmp $PWD/../gcc
	rs_extract_module mpc $PWD/../gcc
	rs_extract_module mpfr $PWD/../gcc

	cd ../gcc-build

	export old_path=$PATH
	export PATH="$PATH:$rs_archprefixdir/bin"

	export CFLAGS_FOR_TARGET="$rs_target_cflags"
	export CXXFLAGS_FOR_TARGET="$rs_target_cflags"

	rs_do_command ../gcc/configure --prefix="$rs_archprefixdir" --host="$rs_target" --build="$rs_target" --target="$rs_target" --with-sysroot="$rs_archprefixdir" --with-pkgversion="RosBE-Windows" --enable-languages=c,c++ --enable-fully-dynamic-string --enable-checking=release --enable-version-specific-runtime-libs --enable-plugins --disable-shared --disable-multilib --disable-nls --disable-werror --disable-win32-registry --disable-sjlj-exceptions --disable-libstdcxx-verbose
	rs_do_command $rs_makecmd -j $rs_cpucount all-gcc
	rs_do_command $rs_makecmd install-gcc
	rs_do_command_can_fail $rs_makecmd install-lto-plugin

	if rs_prepare_module "mingw_w64"; then
		rs_do_command ../mingw_w64/mingw-w64-crt/configure --prefix="$rs_archprefixdir/$rs_target" --host="$rs_target" --with-sysroot="$rs_archprefixdir/$rs_target"
		rs_do_command $rs_makecmd -j $rs_cpucount
		rs_do_command $rs_makecmd install
		rs_clean_module "mingw_w64"
	fi

	cd "$rs_workdir/gcc-build"
	rs_do_command $rs_makecmd -j $rs_cpucount
	rs_do_command $rs_makecmd install

	rs_clean_module "gcc"

	unset CFLAGS_FOR_TARGET
	unset CXXFLAGS_FOR_TARGET

	export PATH=$old_path
	unset old_path
fi

if rs_prepare_module "ninja"; then
	export old_path=$PATH
	export PATH=".:$PATH"

	rs_do_command cd ../ninja
	rs_do_command ./configure.py --bootstrap --platform mingw
	rs_do_command install ninja "$rs_prefixdir/bin"
	rs_clean_module "ninja"

	export PATH=$old_path
	unset old_path
fi

# Final actions
echo
rs_boldmsg "Final actions"

echo "Removing unneeded files..."
cd "$rs_prefixdir"
rm bin/yacc
rm -rf doc man share/doc share/info share/man

cd "$rs_archprefixdir"
rm -rf $rs_target/doc $rs_target/share include info man mingw share
rm -f lib/* >& /dev/null
##### END almost shared buildtoolchain/RosBE-Unix building part ###############

echo "Removing debugging symbols..."
cd "$rs_workdir"
find -executable -type f -exec strip -s {} ";" >& /dev/null
find -name "*.a" -type f -exec strip -d {} ";" >& /dev/null
find -name "*.o" -type f -exec strip -d {} ";" >& /dev/null

echo "Copying additional dependencies from MSYS..."
cd "$rs_prefixdir/bin"
cp /mingw32/bin/libgcc_s_dw2-1.dll .
cp /mingw32/bin/libstdc++-6.dll .
cp /mingw32/bin/libwinpthread-1.dll .
cp /usr/bin/m4.exe .
cp /usr/bin/msys-2.0.dll .
cp /usr/bin/msys-gcc_s-1.dll .

echo "Finished!"
