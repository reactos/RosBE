#!/bin/bash
#
# ReactOS Build Environment for Windows - Script for building a binutils/GCC/mingw-runtime/w32api toolchain for Windows
# Partly based on RosBE-Unix' "RosBE-Builder.sh"
# Copyright 2009-2011 Colin Finck <colin@reactos.org>
#
# Released under GNU GPL v2 or any later version.

########################################################################################################################
# Package "rosbe_2.0"
#
# This script was built for the following toolchain versions:
# - Binutils 2.20.51-20091222 (snapshot)
# - CMake 2.8.5
#   patched with:
#      * http://svn.reactos.org/project-tools/trunk/RosBE/Patches/CMake-jgardou-changes-against-2.8.5.patch?p=1320
# - GCC 4.4.3
#   patched with:
#      * http://gcc.gnu.org/bugzilla/attachment.cgi?id=18882&action=view (committed in GCC r153606)
# - GMP 5.0.2
#   patched with:
#      * http://svn.reactos.org/project-tools/trunk/RosBE/Patches/GMP-OSX-10.7-fixes-against-5.0.2.patch?p=1322
# - Make 3.82
#   patched with:
#      * http://svn.reactos.org/project-tools/trunk/RosBE/Patches/Make-Windows-jobserver-against-3.8.2.patch?p=1321
# - MinGW-Runtime 3.17
# - MPFR 3.0.1
# - W32api 3.14
#
# These tools have to be compiled under MSYS with "gcc version 3.4.5 (mingw-vista special r3)"
#
# These versions are used in RosBE-Windows 2.0 and RosBE-Unix 2.0.
# Get the toolchain packages from http://svn.reactos.org/RosBE-Sources/rosbe_2.0
########################################################################################################################


# RosBE Setup Variables
rs_host_cflags="-pipe -fno-common -O2 -march=pentium3 -mfpmath=sse"   # -fno-common needed for native builds due to GCC 4.4 bug according to Dmitry Gorbachev
rs_needed_tools="bison flex gcc g++ grep makeinfo"                    # GNU Make has a special check
rs_target="mingw32"
rs_target_cflags="-pipe -O2 -march=pentium -mtune=i686"

# Get the absolute path to the script directory
cd `dirname $0`
rs_scriptdir="$PWD"

# buildtoolchain Constants
HOST_GCC_VERSION="gcc version 3.4.5 (mingw-vista special r3)"
MODULES="w32api mingw_runtime cmake gmp mpfr binutils gcc make"
SYSHEADERDIR="/mingw/include"

source "$rs_scriptdir/scripts/setuplibrary.sh"


echo "*******************************************************************************"
echo "*     Buildtoolchain script for the ReactOS Build Environment for Windows     *"
echo "*                             Package \"rosbe_2.0\"                             *"
echo "*                      by Colin Finck <colin@reactos.org>                     *"
echo "*******************************************************************************"

echo
echo "This script builds a binutils/GCC/mingw-runtime/w32api toolchain for Windows."
echo

if [ "`uname -o`" != "Msys" ]; then
	echo "You can only run this script under a MSYS environment!"
	exit 1
fi

# We don't want too less parameters
if [ "$2" == "" ]; then
	echo -n "Syntax: ./buildtoolchain.sh <sources> <workdir> [make_dev]"
	
	for module in $MODULES; do
		echo -n " [$module]"
	done
	
	echo
	echo
	echo " sources  - Path to the directory containing RosBE-Unix toolchain packages (.tar.bz2 files)"
	echo " workdir  - Path to the directory used for building. Will contain the final executables and"
	echo "            temporary files."
	echo "            The path must be an absolute one in Unix style, e.g. /d/buildtoolchain."
	echo " make_dev - Pass 1 here if you want to build the \"mingw_runtime_dev\" package required for"
	echo "            RosBE-Unix. All following options will be ignored in this case."
	echo "            Otherwise pass 0, which is the default option."
	echo
	echo "The rest of the arguments are optional. You specify them if you want to prevent a component"
	echo "from being (re)built. Do this by passing 0 as the argument of the appropriate component."
	echo "Pass 1 if you want them to be built."
	echo "By default, all of these components are built, so you don't need to pass any of these parameters."
	exit 1
fi

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
rs_supportprefixdir="$rs_workdir/support"

# Also get an almost Windows style path (e.g. d:/buildtoolchain) out of the Unix style path (e.g. /d/buildtoolchain)
windows_prefixdir="${rs_prefixdir:1:1}:${rs_prefixdir:2}"

# Find out if we just want to build the "mingw_runtime_dev" package
if [ "$1" = "1" ]; then
	make_dev_package=true
else
	make_dev_package=false
fi

shift

if $make_dev_package; then
	# Disable processing all modules
	for module in $MODULES; do
		eval "rs_process_$module=false"
	done

	# Only process w32api and mingw_runtime
	rs_process_w32api=true
	rs_process_mingw_runtime=true

	# Set a prefix different to the one used for w32api, so that we can later package the built files
	mingw_runtime_prefix="$rs_workdir/mingw_runtime_dev"
	rs_mkdir_if_not_exists "$mingw_runtime_prefix"
else
	# Set the rs_process_* variables based on the parameters
	for module in $MODULES; do
		if [ "$1" = "0" ]; then
			eval "rs_process_$module=false"
		else
			eval "rs_process_$module=true"
		fi
		
		shift
	done

	mingw_runtime_prefix="$rs_archprefixdir/$rs_target"
fi

rs_mkdir_empty "$SYSHEADERDIR"


##### BEGIN almost shared buildtoolchain/RosBE-Unix building part #############
rs_boldmsg "Building..."

rs_mkdir_if_not_exists "$rs_prefixdir/bin"
rs_mkdir_if_not_exists "$rs_archprefixdir/$rs_target"
rs_mkdir_if_not_exists "$rs_supportprefixdir"

rs_extract_module "w32api" "$rs_archprefixdir/$rs_target"

rs_do_command gcc -s -o "$rs_prefixdir/bin/cpucount.exe" "$rs_scriptdir/tools/cpucount.c"
rs_cpucount=`$rs_prefixdir/bin/cpucount.exe -x1`

if rs_prepare_module "mingw_runtime"; then
	export CFLAGS="$rs_target_cflags"
	export C_INCLUDE_PATH="$rs_archprefixdir/$rs_target/include"
	
	rs_do_command ../mingw_runtime/configure --prefix="$mingw_runtime_prefix" --host="$rs_target" --build="$rs_target" --disable-werror
	rs_do_command $rs_makecmd -j $rs_cpucount
	rs_do_command $rs_makecmd install
	rs_clean_module "mingw_runtime"
	
	unset CFLAGS
	unset C_INCLUDE_PATH
fi

if rs_prepare_module "cmake"; then
	export CFLAGS="$rs_host_cflags"

	# MSYS path translation doesn't seem to work well for CMake, but Windows-style pathes work
	rs_do_command ../cmake/bootstrap --prefix="$windows_prefixdir" --parallel=$rs_cpucount
	rs_do_command $rs_makecmd -j $rs_cpucount
	rs_do_command $rs_makecmd install
	rs_clean_module "cmake"

	unset CFLAGS
fi

if rs_prepare_module "gmp"; then
	export CFLAGS="$rs_host_cflags"

	rs_do_command ../gmp/configure --prefix="$rs_supportprefixdir" --host="$rs_target" --build="$rs_target" --disable-shared --disable-werror
	rs_do_command $rs_makecmd -j $rs_cpucount
	rs_do_command $rs_makecmd check
	rs_do_command $rs_makecmd install
	rs_clean_module "gmp"

	unset CFLAGS
fi

if rs_prepare_module "mpfr"; then
	export CFLAGS="$rs_host_cflags"

	rs_do_command ../mpfr/configure --prefix="$rs_supportprefixdir" --host="$rs_target" --build="$rs_target" --with-gmp="$rs_supportprefixdir" --disable-shared --disable-werror
	rs_do_command $rs_makecmd -j $rs_cpucount
	rs_do_command $rs_makecmd check
	rs_do_command $rs_makecmd install
	rs_clean_module "mpfr"

	unset CFLAGS
fi

if rs_prepare_module "binutils"; then
	export CFLAGS="$rs_host_cflags"
	
	rs_do_command ../binutils/configure --prefix="$rs_archprefixdir" --host="$rs_target" --build="$rs_target" --target="$rs_target" --disable-nls --disable-werror
	rs_do_command $rs_makecmd -j $rs_cpucount
	rs_do_command $rs_makecmd install
	rs_clean_module "binutils"
	
	unset CFLAGS
fi

if rs_prepare_module "gcc"; then
	export STAGE1_CFLAGS="$rs_host_cflags"
	export BOOT_CFLAGS="$rs_host_cflags"
	export CFLAGS_FOR_TARGET="$rs_target_cflags"
	export CXXFLAGS_FOR_TARGET="$rs_target_cflags"
	export C_INCLUDE_PATH="$rs_archprefixdir/$rs_target/include"
	export LIBRARY_PATH="$rs_archprefixdir/$rs_target/lib"
	
	rs_do_command ../gcc/configure --prefix="$rs_archprefixdir" --host="$rs_target" --build="$rs_target" --target="$rs_target" --with-gmp="$rs_supportprefixdir" --with-mpfr="$rs_supportprefixdir" --with-pkgversion="RosBE-Windows" --enable-languages=c,c++ --enable-checking=release --enable-version-specific-runtime-libs --disable-win32-registry --disable-shared --disable-nls --disable-werror
	rs_do_command $rs_makecmd profiledbootstrap
	rs_do_command $rs_makecmd install
	rs_clean_module "gcc"
	
	unset STAGE1_CFLAGS
	unset BOOT_CFLAGS
	unset CFLAGS_FOR_TARGET
	unset CXXFLAGS_FOR_TARGET
	unset C_INCLUDE_PATH
	unset LIBRARY_PATH
fi

if rs_prepare_module "make"; then
	export CFLAGS="$rs_host_cflags"

	rs_do_command ../make/configure --prefix="$rs_prefixdir" --program-prefix="mingw32-" --disable-nls --disable-werror
	rs_do_command $rs_makecmd -j $rs_cpucount
	rs_do_command $rs_makecmd install
	rs_clean_module "make"

	unset CFLAGS
fi

# Final actions
echo
rs_boldmsg "Final actions"

echo "Removing unneeded files..."
cd "$rs_prefixdir"
rm -rf doc man share/info share/man

cd "$rs_archprefixdir"
rm -rf $rs_target/bin $rs_target/doc $rs_target/share include info man share
rm -f lib/* >& /dev/null
rm -f bin/c++.exe bin/gccbug bin/$rs_target-*

# Keep the "include" and "lib" directories of the support files in case a subsequent RosBE-Unix package needs them
cd "$rs_supportprefixdir"
rm -rf info share

echo "Removing debugging symbols..."
cd "$rs_workdir"
find -executable -type f -exec strip -s {} ";" >& /dev/null
find -name "*.a" -type f -exec strip -d {} ";" >& /dev/null
find -name "*.o" -type f -exec strip -d {} ";" >& /dev/null
##### END almost shared buildtoolchain/RosBE-Unix building part ###############

# Create the package out of the built files if we want to build the "mingw_runtime_dev" package
if $make_dev_package; then
	echo "Creating the \"mingw_runtime_dev.tar.bz2\" archive..."
	cd "$mingw_runtime_prefix"
	tar -cjf "mingw_runtime_dev.tar.bz2" include lib
fi

echo "Finished!"
