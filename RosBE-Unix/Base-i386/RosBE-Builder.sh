#!/bin/bash
#
# ReactOS Build Environment for Unix-based Operating Systems - Builder Tool for the Base package
# Copyright 2007-2011 Colin Finck <colin@reactos.org>
# partially based on the BuildMingwCross script (http://www.mingw.org/MinGWiki/index.php/BuildMingwCross)
#
# Released under GNU GPL v2 or any later version.

if [ -z "$BASH_VERSION" ]; then
    exec bash "$0"
fi

if [ "x$CC" == "x" ]; then
	CC=gcc
fi

if [ "x$CXX" == "x" ]; then
	CXX=g++
fi

if [ "x$CFLAGS" != "x" ]; then
	use_cflags=1
else
	use_cflags=0
fi

# RosBE Setup Variables
rs_host_cflags="-pipe -O2 -Wl,-S -g0"
rs_needed_tools="as bison flex $CC $CXX grep makeinfo python"        # GNU Make has a special check
rs_needed_libs="zlib"
rs_target="i686-w64-mingw32"
rs_target_cflags="-pipe -O2 -Wl,-S -g0 -march=pentium -mtune=i686"

# Get the absolute path to the script directory
cd `dirname $0`
rs_scriptdir="$PWD"
rs_workdir="$rs_scriptdir/sources"
rs_sourcedir="$rs_scriptdir/sources"

# RosBE-Unix Constants
DEFAULT_INSTALL_DIR="/usr/local/RosBE"
KNOWN_ROSBE_VERSIONS="0.3.6 1.1 1.4 1.4.2 1.5 2.0 2.1 2.1.1 2.1.2"
ROSBE_VERSION="2.1.2"
TARGET_ARCH="i386"

source "$rs_scriptdir/scripts/rosbelibrary.sh"
source "$rs_scriptdir/scripts/setuplibrary.sh"


echo "*******************************************************************************"
echo "*         ReactOS Build Environment for Unix-based Operating Systems          *"
echo "*                      Builder Tool for the Base package                      *"
echo "*                      by Colin Finck <colin@reactos.org>                     *"
echo "*                                                                             *"
echo "*                                 Version $ROSBE_VERSION                               *"
echo "*******************************************************************************"

echo
echo "This script compiles and installs a complete Build Environment for building"
echo "ReactOS."
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

check_root
rs_check_requirements

reinstall=false
update=false

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
					choice=""

					# Allow the user to update an already installed RosBE version
					installed_version=`cat "$installdir/RosBE-Version"`

					for known_version in $KNOWN_ROSBE_VERSIONS; do
						if [ "$known_version" = "$installed_version" ]; then
							if [ "$installed_version" = "$ROSBE_VERSION" ]; then
								echo "The current version of the Build Environment is already installed in this directory."
								echo "Please choose one of the following options:"
								echo
								echo " (R)einstall all components of the Build Environment"
								echo " (C)hoose a different installation directory"
								echo

								rs_showchoice "R" "r R c C"
							else
								echo "An older version of the Build Environment has been found in this directory."
								echo "Please choose one of the following options:"
								echo
								echo " (U)pdate/(r)einstall the Build Environment"
								echo " (C)hoose a different installation directory"
								echo

								rs_showchoice "U" "u U r R c C"
							fi

							break
						fi
					done

					if [ "$choice" = "" ]; then
						# We found no known version, so this could be for example a Release Candidate.
						# Only offer the reinstallation option.
						echo "Another version of the Build Environment is already installed in this directory."
						echo "Please choose one of the following options:"
						echo
						echo " (R)einstall all components of the Build Environment"
						echo " (C)hoose a different installation directory"
						echo

						rs_showchoice "R" "r R c C"
					fi

					case "$choice" in
						"U"|"u")
							# We only allow update from 2.1 to 2.1.1 or 2.1.2
							# For other releases:
							# We don't support update in this version due to lots of changes
							# To reenable updating, change this to "update=true"
							if [ "$installed_version" = "2.1" ] && [ "$ROSBE_VERSION" = "2.1.2" ]; then
								update=true
							elif [ "$installed_version" = "2.1.1" ] && [ "$ROSBE_VERSION" = "2.1.2" ]; then
								update=true
							else
								reinstall=true
							fi
							;;
						"R"|"r")
							reinstall=true
							;;
						"C"|"c")
							echo "Please enter another directory!"
							installdir=""
							;;
					esac
				else
					echo "The directory \"$installdir\" is not empty. Do you really want to continue? (yes/no)"
					read -p "[no] " answer
					echo

					if [ "$answer" != "yes" ]; then
						echo "Please enter another directory!"
						installdir=""
					fi
				fi
			fi
		else
			echo "The directory \"$installdir\" does not exist. The installation script will create it for you."
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

if $update; then
	# For 2.1 -> 2.1.1 or 2.1.1 -> 2.1.2
	rs_process_cmake=true
	rs_process_ninja=true
	# We don't force GCC update for 2.1.1 -> 2.1.2, changes are too minor
else
	rs_process_binutils=true
	rs_process_buildtime=true
	rs_process_cmake=true
	rs_process_cpucount=true
	rs_process_gcc=true
	rs_process_gmp=true
	rs_process_make=true
	rs_process_ninja=true
	rs_process_mingw_w64_headers=true
	rs_process_mingw_w64_crt=true
	rs_process_mpfr=true
	rs_process_mpc=true
	rs_process_scut=true

	if $reinstall; then
		# Empty the directory if we're reinstalling
		rs_mkdir_empty "$installdir"
	else
		# Otherwise just create the directory if it does not exist
		rs_mkdir_if_not_exists "$installdir"
	fi
fi

# Test if the installation directory is writable
if [ ! -w "$installdir" ]; then
	rs_redmsg "Installation directory \"$installdir\" is not writable, aborted!"
	exit 1
fi

rs_prefixdir="$installdir"
rs_archprefixdir="$installdir/$TARGET_ARCH"

##### BEGIN almost shared buildtoolchain/RosBE-Unix building part #############
rs_boldmsg "Building..."

rs_mkdir_if_not_exists "$rs_prefixdir/bin"
rs_mkdir_if_not_exists "$rs_archprefixdir/$rs_target"

if [ $use_cflags -eq 0 ]; then
	# Use -march=native if the host compiler supports it
	echo -n "Checking if the host compiler supports -march=native... "

	if `$CC -march=native -o "$rs_workdir/dummy" "$rs_scriptdir/tools/dummy.c" >& /dev/null`; then
		echo "yes"
		rs_host_cflags+=" -march=native"
		rm "$rs_workdir/dummy"
	else
		echo "no"
	fi
fi

if $rs_process_buildtime; then
	rs_do_command $CC -s -o "$rs_prefixdir/bin/buildtime" "$rs_scriptdir/tools/buildtime.c"
fi

if $rs_process_cpucount; then
	rs_do_command $CC -s -o "$rs_prefixdir/bin/cpucount" "$rs_scriptdir/tools/cpucount.c"
fi

rs_cpucount=`$rs_prefixdir/bin/cpucount -x1`

if $rs_process_scut; then
	rs_do_command $CC -s -o "$rs_prefixdir/bin/scut" "$rs_scriptdir/tools/scut.c"
fi

if rs_prepare_module "cmake"; then
	if [ $use_cflags -eq 0 ]; then
		export CFLAGS="$rs_host_cflags"
	fi

	rs_do_command ../cmake/bootstrap --prefix="$rs_prefixdir" --parallel=$rs_cpucount
	rs_do_command $rs_makecmd -j $rs_cpucount
	rs_do_command $rs_makecmd install
	rs_clean_module "cmake"

	if [ $use_cflags -eq 0 ]; then
		unset CFLAGS
	fi
fi

if rs_prepare_module "binutils"; then
	if [ $use_cflags -eq 0 ]; then
		export CFLAGS="$rs_host_cflags"
	fi

	rs_do_command ../binutils/configure --prefix="$rs_archprefixdir" --with-sysroot="$rs_archprefixdir" --target="$rs_target" --disable-multilib --disable-werror --enable-lto --enable-plugins --with-zlib=yes
	# HUGE HACK!!!
	# It "manually" disable doc generation for binutils
	# This is required because our binutils are really old and
	# New distributions come with texinfo 1.5 that cannot handle
	# Current docs
	echo "MAKEINFO = :" >> Makefile
	rs_do_command $rs_makecmd -j $rs_cpucount
	rs_do_command $rs_makecmd install
	rs_clean_module "binutils"

	if [ $use_cflags -eq 0 ]; then
		unset CFLAGS
	fi
fi

if rs_prepare_module "mingw_w64_headers"; then
	if [ $use_cflags -eq 0 ]; then
		export CFLAGS="$rs_host_cflags"
	fi

	rs_do_command ../mingw_w64_headers/configure --prefix="$rs_archprefixdir/$rs_target" --host="$rs_target"
	rs_do_command $rs_makecmd -j $rs_cpucount
	rs_do_command $rs_makecmd install
	rs_do_command ln -s -f $rs_archprefixdir/$rs_target $rs_archprefixdir/mingw
	rs_do_command mkdir -p $rs_archprefixdir/$rs_target/lib
	rs_clean_module "mingw_w64_headers"

	if [ $use_cflags -eq 0 ]; then
		unset CFLAGS
	fi
fi

if rs_prepare_module "gcc"; then
	if [ $use_cflags -eq 0 ]; then
		export CFLAGS="$rs_host_cflags"
	fi

	rs_extract_module gmp $PWD/../gcc
	rs_extract_module mpc $PWD/../gcc
	rs_extract_module mpfr $PWD/../gcc

	cd ../gcc-build

	rs_do_command ln -s "$rs_archprefixdir" ../gcc/winsup

	export old_path=$PATH
	export PATH="$PATH:$rs_archprefixdir/bin"

	export CFLAGS_FOR_TARGET="$rs_target_cflags"
	export CXXFLAGS_FOR_TARGET="$rs_target_cflags"

	rs_do_command ../gcc/configure --target="$rs_target" --prefix="$rs_archprefixdir" --with-sysroot="$rs_archprefixdir" --with-pkgversion="RosBE-Unix" --enable-languages=c,c++ --enable-fully-dynamic-string --enable-checking=release --enable-version-specific-runtime-libs --enable-plugins --disable-shared --disable-multilib --disable-nls --disable-werror --with-gnu-ld --with-gnu-as
	# HUGE HACK!!!
	# It "manually" disable doc generation for gcc
	# This is required because our gcc is really old and
	# New distributions come with texinfo 1.5 that cannot handle
	# Current docs
	echo "MAKEINFO = :" >> Makefile
	rs_do_command $rs_makecmd -j $rs_cpucount all-gcc
	rs_do_command $rs_makecmd install-gcc
	rs_do_command_can_fail $rs_makecmd install-lto-plugin

	if rs_prepare_module "mingw_w64_crt"; then
		if [ $use_cflags -eq 0 ]; then
			export CFLAGS="$rs_host_cflags"
		fi

		rs_do_command ../mingw_w64_crt/configure --prefix="$rs_archprefixdir/$rs_target" --with-sysroot="$rs_archprefixdir/$rs_target" --host="$rs_target"
		rs_do_command $rs_makecmd -j $rs_cpucount
		rs_do_command $rs_makecmd install
		rs_clean_module "mingw_w64_crt"

		if [ $use_cflags -eq 0 ]; then
			unset CFLAGS
		fi
	fi

	cd "$rs_workdir/gcc-build"
	rs_do_command $rs_makecmd -j $rs_cpucount
	rs_do_command $rs_makecmd install

	rs_clean_module "gcc"

	if [ $use_cflags -eq 0 ]; then
		unset CFLAGS
	fi
	unset CFLAGS_FOR_TARGET
	unset CXXFLAGS_FOR_TARGET

	export PATH=$old_path
	unset old_path
fi

if rs_prepare_module "ninja"; then
	if [ $use_cflags -eq 0 ]; then
		export CFLAGS="$rs_host_cflags"
	fi
	rs_do_command cd ../ninja
	rs_do_command ./configure.py --bootstrap
	rs_do_command cd ../ninja-build
	rs_do_command install ../ninja/ninja $rs_prefixdir/bin/ninja
	rs_clean_module "ninja"

	if [ $use_cflags -eq 0 ]; then
		unset CFLAGS
	fi
fi

# Final actions
echo
rs_boldmsg "Final actions"

echo "Removing unneeded files..."
cd "$rs_prefixdir"
rm -rf doc man share/info share/man

cd "$rs_archprefixdir"
rm -rf $rs_target/doc $rs_target/share include info man share
rm -f lib/* >& /dev/null

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
		$rs_archprefixdir/bin/i686-w64-mingw32-objcopy --only-keep-debug $exe $exe.dbg 2>/dev/null
		$rs_archprefixdir/bin/i686-w64-mingw32-objcopy --strip-debug $exe 2>/dev/null
		$rs_archprefixdir/bin/i686-w64-mingw32-objcopy --add-gnu-debuglink=$exe.dbg $exe 2>/dev/null
	done

	for exe in `find -name "*.o" -type f -print`; do
		$rs_archprefixdir/bin/i686-w64-mingw32-objcopy --only-keep-debug $exe $exe.dbg 2>/dev/null
		$rs_archprefixdir/bin/i686-w64-mingw32-objcopy --strip-debug $exe 2>/dev/null
		$rs_archprefixdir/bin/i686-w64-mingw32-objcopy --add-gnu-debuglink=$exe.dbg $exe 2>/dev/null
	done
fi
##### END almost shared buildtoolchain/RosBE-Unix building part ###############


echo "Copying scripts..."
cp -R "$rs_scriptdir/scripts/"* "$installdir"

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
