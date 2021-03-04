#!/usr/bin/env bash
#
# ReactOS Build Environment for Unix-based Operating Systems - Builder Tool for the amd64 compiler add-on
# Copyright 2021 Colin Finck <colin@reactos.org>
#
# Released under GPL-2.0-or-later (https://spdx.org/licenses/GPL-2.0-or-later)

if [ -z "$BASH_VERSION" ]; then
    exec bash "$0"
fi

# RosBE Setup Variables
rs_host_cc="${CC:-gcc}"
rs_host_cflags="${CFLAGS:--pipe -O2 -g0 -march=native}"
rs_host_cxx="${CXX:-g++}"
rs_host_cxxflags="${CXXFLAGS:-$rs_host_cflags}"
rs_needed_tools="as bzip2 find $CC $CXX grep m4 makeinfo python tar"        # GNU Make has a special check
rs_needed_libs="zlib"
rs_target="x86_64-w64-mingw32"
rs_target_cflags="-pipe -O2 -Wl,-S -g0"
rs_target_cxxflags="$rs_target_cflags"

# This is a cross-compiler with prefix.
rs_target_tool_prefix="${rs_target}-"

export CC="$rs_host_cc"
export CFLAGS="$rs_host_cflags"
export CXX="$rs_host_cxx"
export CXXFLAGS="$rs_host_cxxflags"

# Get the absolute path to the script directory
cd `dirname $0`
rs_scriptdir="$PWD"
rs_workdir="$rs_scriptdir/sources"
rs_sourcedir="$rs_scriptdir/sources"

# RosBE-Unix Constants
DEFAULT_INSTALL_DIR="/usr/local/RosBE"
ROSBE_VERSION="2.3"
TARGET_ARCH="amd64"

source "$rs_scriptdir/scripts/rosbelibrary.sh"
source "$rs_scriptdir/scripts/setuplibrary.sh"


echo "*******************************************************************************"
echo "*         ReactOS Build Environment for Unix-based Operating Systems          *"
echo "*                  Builder Tool for the amd64 compiler add-on                 *"
echo "*                      by Colin Finck <colin@reactos.org>                     *"
echo "*                                                                             *"
printf "*                                 Version %-8s                            *\n" $ROSBE_VERSION
echo "*******************************************************************************"

echo
echo "This script compiles and installs the optional compiler add-on for building"
echo "ReactOS for amd64 (x86_64) processors."
echo

if [ "$1" = "-h" ] || [ "$1" = "-?" ] || [ "$1" = "--help" ]; then
	echo "Syntax: ./RosBE-Builder-amd64.sh [installdir]"
	echo
	echo " installdir - Optional parameter to specify the installation directory and"
	echo "              perform an unattended installation."
	echo "              This directory must contain a ReactOS Build Environment"
	echo "              installation of the same version (created by"
	echo "              ./RosBE-Builder.sh)"
	echo
	echo "Usually, you just call the script without any parameters and it will guide you"
	echo "through all possible installation options."
	exit 0
fi

# Only check for root on an interactive installation.
if [ "$1" = "" ]; then
	check_root
fi

rs_check_requirements

# Select the installation directory
rs_boldmsg "Installation Directory"

if [ "$1" = "" ]; then
	installdir=""

	echo "Where is your ReactOS Build Environment installation?"
	echo "Enter the path to the directory here or simply press ENTER to accept the default directory."

	while [ "$installdir" = "" ]; do
		read -p "[$DEFAULT_INSTALL_DIR] " installdir
		echo

		if [ "$installdir" = "" ]; then
			installdir=$DEFAULT_INSTALL_DIR
		fi

		# Make sure we have the absolute path to the installation directory
		installdir=`eval echo $installdir`

		# Check if the installation directory is valid and points to the same RosBE version
		installed_rosbe_version=`cat $installdir/RosBE-Version 2>/dev/null`
		if [ "$installed_rosbe_version" = "" ]; then
			echo "The directory \"$installdir\" does not contain a ReactOS Build Environment installation."
			echo "Please enter another directory."
			echo
			installdir=""
		elif [ "$installed_rosbe_version" != "$ROSBE_VERSION" ]; then
			echo "The installed ReactOS Build Environment version ($installed_rosbe_version) does not match"
			echo "the version of this add-on ($ROSBE_VERSION)."
			echo "Please install the proper base package first or enter another directory."
			echo
			installdir=""
		fi
	done

	# Ready to start
	rs_boldmsg "Ready to start"

	echo "Ready to build and install this ReactOS Build Environment add-on."
	echo "Press Return to continue or Ctrl+C to exit."
	read
else
	installdir=`eval echo $1`
	installed_rosbe_version=`cat $installdir/RosBE-Version 2>/dev/null`

	if [ "$installed_rosbe_version" != "$ROSBE_VERSION" ]; then
		rs_redmsg "Installation directory \"$installdir\" contains ReactOS Build Environment version $installed_rosbe_version,"
		rs_redmsg "which doesn't match the version of this add-on ($ROSBE_VERSION). Aborted."
		exit 1
	fi

	echo "Using \"$installdir\""
	echo
fi

rs_process_binutils=true
rs_process_gcc=true
rs_process_mingw_w64=true

rs_prefixdir="$installdir"
rs_archprefixdir="$installdir/$TARGET_ARCH"

##### BEGIN almost shared buildtoolchain/RosBE-Unix building part #############
rs_boldmsg "Building..."

mkdir -p "$rs_archprefixdir/$rs_target"

echo "Using CFLAGS=\"$CFLAGS\""
echo "Using CXXFLAGS=\"$CXXFLAGS\""
echo

rs_cpucount=`$rs_prefixdir/bin/cpucount -x1`

if rs_prepare_module "binutils"; then
	rs_do_command ../binutils/configure --prefix="$rs_archprefixdir" --target="$rs_target" --with-sysroot="$rs_archprefixdir" --disable-multilib --disable-werror --enable-lto --enable-plugins --with-zlib=yes --disable-nls
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

	export CFLAGS_FOR_TARGET="$rs_target_cflags"
	export CXXFLAGS_FOR_TARGET="$rs_target_cxxflags"

	rs_do_command ../gcc/configure --prefix="$rs_archprefixdir" --target="$rs_target" --with-sysroot="$rs_archprefixdir" --with-pkgversion="RosBE-Unix" --enable-languages=c,c++ --enable-fully-dynamic-string --enable-version-specific-runtime-libs --disable-shared --disable-multilib --disable-nls --disable-werror --disable-win32-registry --enable-sjlj-exceptions --disable-libstdcxx-verbose
	rs_do_command $rs_makecmd -j $rs_cpucount all-gcc
	rs_do_command $rs_makecmd install-gcc
	rs_do_command $rs_makecmd install-lto-plugin

	if rs_prepare_module "mingw_w64"; then
		export AR="$rs_archprefixdir/bin/${rs_target_tool_prefix}ar"
		export AS="$rs_archprefixdir/bin/${rs_target_tool_prefix}as"
		export CC="$rs_archprefixdir/bin/${rs_target_tool_prefix}gcc"
		export CFLAGS="$rs_target_cflags"
		export CXX="$rs_archprefixdir/bin/${rs_target_tool_prefix}g++"
		export CXXFLAGS="$rs_target_cxxflags"
		export DLLTOOL="$rs_archprefixdir/bin/${rs_target_tool_prefix}dlltool"
		export RANLIB="$rs_archprefixdir/bin/${rs_target_tool_prefix}ranlib"
		export STRIP="$rs_archprefixdir/bin/${rs_target_tool_prefix}strip"

		rs_do_command ../mingw_w64/mingw-w64-crt/configure --prefix="$rs_archprefixdir/$rs_target" --host="$rs_target" --with-sysroot="$rs_archprefixdir"
		rs_do_command $rs_makecmd -j $rs_cpucount
		rs_do_command $rs_makecmd install
		rs_clean_module "mingw_w64"

		unset AR
		unset AS
		export CC="$rs_host_cc"
		export CFLAGS="$rs_host_cflags"
		export CXX="$rs_host_cxx"
		export CXXFLAGS="$rs_host_cxxflags"
		unset DLLTOOL
		unset RANLIB
		unset STRIP
	fi

	cd "$rs_workdir/gcc-build"
	rs_do_command $rs_makecmd -j $rs_cpucount
	rs_do_command $rs_makecmd install
	rs_clean_module "gcc"

	unset CFLAGS_FOR_TARGET
	unset CXXFLAGS_FOR_TARGET
fi

# Final actions
echo
rs_boldmsg "Final actions"

echo "Removing unneeded files..."
cd "$rs_archprefixdir"
rm -rf $rs_target/doc $rs_target/share include info man mingw share
rm -f lib/* >& /dev/null
##### END almost shared buildtoolchain/RosBE-Unix building part ###############

# See: https://jira.reactos.org/browse/ROSBE-35
osname=`uname`
if [ "$osname" != "Darwin" ]; then
	echo "Removing debugging symbols..."
	cd "$rs_archprefixdir"
	for exe in `find -executable -type f -print`; do
		objcopy --only-keep-debug $exe $exe.dbg 2>/dev/null
		objcopy --strip-debug $exe 2>/dev/null
		objcopy --add-gnu-debuglink=$exe.dbg $exe 2>/dev/null
	done

	# Executables are created for the host system while most libraries are linked to target components
	for exe in `find -name "*.a" -type f -print`; do
		$rs_archprefixdir/bin/${rs_target_tool_prefix}objcopy --only-keep-debug $exe $exe.dbg 2>/dev/null
		$rs_archprefixdir/bin/${rs_target_tool_prefix}objcopy --strip-debug $exe 2>/dev/null
		$rs_archprefixdir/bin/${rs_target_tool_prefix}objcopy --add-gnu-debuglink=$exe.dbg $exe 2>/dev/null
	done

	for exe in `find -name "*.o" -type f -print`; do
		$rs_archprefixdir/bin/${rs_target_tool_prefix}objcopy --only-keep-debug $exe $exe.dbg 2>/dev/null
		$rs_archprefixdir/bin/${rs_target_tool_prefix}objcopy --strip-debug $exe 2>/dev/null
		$rs_archprefixdir/bin/${rs_target_tool_prefix}objcopy --add-gnu-debuglink=$exe.dbg $exe 2>/dev/null
	done
fi

echo "Copying scripts..."
cp "$rs_scriptdir/scripts/amd64/"* "$installdir/amd64"
echo

# Finish
rs_boldmsg "Finished successfully!"
echo "You can switch to the amd64 compiler within the Build Environment by typing:"
echo
echo "  charch amd64"
echo
