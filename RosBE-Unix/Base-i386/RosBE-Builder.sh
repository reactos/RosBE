#!/usr/bin/env bash
#
# ReactOS Build Environment for Unix-based Operating Systems - Builder Tool for the base package and i386 compiler
# Copyright 2007-2021 Colin Finck <colin@reactos.org>
# partially based on the BuildMingwCross script (http://www.mingw.org/MinGWiki/index.php/BuildMingwCross)
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
rs_target="i686-w64-mingw32"
rs_target_cflags="-pipe -O2 -Wl,-S -g0 -march=pentium -mtune=i686"
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
TARGET_ARCH="i386"

source "$rs_scriptdir/scripts/rosbelibrary.sh"
source "$rs_scriptdir/scripts/setuplibrary.sh"


echo "*******************************************************************************"
echo "*         ReactOS Build Environment for Unix-based Operating Systems          *"
echo "*             Builder Tool for the Base package and i386 compiler             *"
echo "*                      by Colin Finck <colin@reactos.org>                     *"
echo "*                                                                             *"
printf "*                                 Version %-8s                            *\n" $ROSBE_VERSION
echo "*******************************************************************************"

echo
echo "This script compiles and installs a complete Build Environment for building"
echo "ReactOS for i386 (x86) processors."
echo

if [ "$1" = "-h" ] || [ "$1" = "-?" ] || [ "$1" = "--help" ]; then
	echo "Syntax: ./RosBE-Builder.sh [installdir]"
	echo
	echo " installdir - Optional parameter to specify an installation directory. If you"
	echo "              do this, the script will check whether this directory does not"
	echo "              yet exist and in this case, it will perform an unattended"
	echo "              installation to this directory."
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

	echo "In which directory do you want to install it?"
	echo "Enter the path to the directory here or simply press ENTER to install it into the default directory."

	while [ "$installdir" = "" ]; do
		read -p "[$DEFAULT_INSTALL_DIR] " installdir
		echo

		if [ "$installdir" = "" ]; then
			installdir=$DEFAULT_INSTALL_DIR
		fi

		# Make sure we have the absolute path to the installation directory
		installdir=`eval echo $installdir`

		# Check if the installation directory already exists
		if [ -f "$installdir" ]; then
			echo "The directory \"$installdir\" is a file! Please enter another directory!"
			echo
			installdir=""
		elif [ -d "$installdir" ]; then
			# Check if the directory is empty
			if [ ! "`ls $installdir`" = "" ]; then
				if [ -f "$installdir/RosBE-Version" ]; then
					installed_version=`cat "$installdir/RosBE-Version"`
					echo "ReactOS Build Environment $installed_version is already installed in this directory."
				else
					echo "The directory \"$installdir\" is not empty."
				fi

				echo "Do you want to remove this directory and install the new Build Environment into it? (yes/no)"
				read -p "[no] " answer
				echo

				if [[ "$answer" != [yY][eE][sS] ]]; then
					echo "Please enter another directory!"
					installdir=""
				fi
			fi
		else
			echo "The directory \"$installdir\" does not exist. It will be created for you."
			echo
		fi
	done

	# Ready to start
	rs_boldmsg "Ready to start"

	echo "Ready to build and install the ReactOS Build Environment."
	echo "Press Return to continue or Ctrl+C to exit."
	read
else
	installdir=`eval echo $1`

	if [ -e "$installdir" ]; then
		rs_redmsg "Installation directory \"$installdir\" already exists, aborted!"
		exit 1
	fi

	echo "Using \"$installdir\""
	echo
fi

rs_process_binutils=true
rs_process_bison=true
rs_process_cmake=true
rs_process_cpucount=true
rs_process_flex=true
rs_process_gcc=true
rs_process_mingw_w64=true
rs_process_ninja=true
rs_process_scut=true

rm -rf "$installdir" || exit 1
mkdir -p "$installdir" || exit 1

rs_prefixdir="$installdir"
rs_archprefixdir="$installdir/$TARGET_ARCH"

##### BEGIN almost shared buildtoolchain/RosBE-Unix building part #############
rs_boldmsg "Building..."

mkdir -p "$rs_prefixdir/bin"
mkdir -p "$rs_archprefixdir/$rs_target"

echo "Using CFLAGS=\"$CFLAGS\""
echo "Using CXXFLAGS=\"$CXXFLAGS\""
echo

if $rs_process_cpucount; then
	rs_do_command $CC -s -o "$rs_prefixdir/bin/cpucount" "$rs_scriptdir/tools/cpucount.c"
fi

rs_cpucount=`$rs_prefixdir/bin/cpucount -x1`

if $rs_process_scut; then
	rs_do_command $CC -s -o "$rs_prefixdir/bin/scut" "$rs_scriptdir/tools/scut.c"
fi

if rs_prepare_module "bison"; then
	rs_do_command ../bison/configure --prefix="$rs_prefixdir" --disable-nls
	rs_do_command $rs_makecmd -j $rs_cpucount
	rs_do_command $rs_makecmd install
	rs_clean_module "bison"
fi

if rs_prepare_module "flex"; then
	rs_do_command ../flex/configure --prefix="$rs_prefixdir" --disable-nls
	rs_do_command $rs_makecmd -j $rs_cpucount
	rs_do_command $rs_makecmd install
	rs_clean_module "flex"
fi

if rs_prepare_module "cmake"; then
	rs_do_command ../cmake/bootstrap --prefix="$rs_prefixdir" --parallel=$rs_cpucount -- -DCMAKE_USE_OPENSSL=OFF
	rs_do_command $rs_makecmd -j $rs_cpucount
	rs_do_command $rs_makecmd install
	rs_clean_module "cmake"
fi

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

if rs_prepare_module "ninja"; then
	rs_do_command python ../ninja/configure.py --bootstrap
	rs_do_command install ninja "$rs_prefixdir/bin"
	rs_clean_module "ninja"
fi

# Final actions
echo
rs_boldmsg "Final actions"

echo "Removing unneeded files..."
cd "$rs_prefixdir"
rm -rf doc man share/info share/man

cd "$rs_archprefixdir"
rm -rf $rs_target/doc $rs_target/share include info man mingw share
rm -f lib/* >& /dev/null
##### END almost shared buildtoolchain/RosBE-Unix building part ###############

# See: https://jira.reactos.org/browse/ROSBE-35
osname=`uname`
if [ "$osname" != "Darwin" ]; then
	echo "Removing debugging symbols..."
	cd "$rs_prefixdir"
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
cp "$rs_scriptdir/scripts/"* "$installdir" 2>/dev/null
cp "$rs_scriptdir/scripts/i386/"* "$installdir/i386"

echo "Writing version..."
echo "$ROSBE_VERSION" > "$installdir/RosBE-Version"
echo

# Finish
rs_boldmsg "Finished successfully!"
echo "To create a shortcut to the Build Environment on the Desktop, please switch back to your"
echo "normal User Account (I assume you ran this script as \"root\")."
echo "Then execute the following command:"
echo
echo "  $installdir/createshortcut.sh"
echo
echo "If you just want to start the Build Environment without using a shortcut, execute the"
echo "following command:"
echo
echo "  $installdir/RosBE.sh [source directory] [color code] [architecture]"
echo
echo "All parameters for that script are optional."
