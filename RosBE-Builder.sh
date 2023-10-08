#!/usr/bin/env bash
#
# ReactOS Build Environment for Unix-based Operating Systems - Builder Tool for the Base package
# Copyright 2007-2020 Colin Finck <colin@reactos.org>
# partially based on the BuildMingwCross script (http://www.mingw.org/MinGWiki/index.php/BuildMingwCross)
#
# Released under GNU GPL v2 or any later version.

if [ -z "$BASH_VERSION" ]; then
    exec bash "$0"
fi

# MSYS2 specific values
if [ "$MSYSTEM" ] ; then
	# Hardcoded values for buildtoolchain/MSYS2
	rs_makecmd=make

	# Make MSYS use native NTFS links for "ln -s"
	export MSYS=winsymlinks:nativestrict

	# Ensure similar error messages on all platforms, especially when we parse them (e.g. for pacman).
	export LANG=C

	rs_suffix=".exe"
else
	rs_suffix=""
fi

# RosBE Setup Variables
rs_host_cc="${CC:-gcc}"
rs_host_strip="${STRIP:-strip}"
rs_host_cflags="${CFLAGS:--pipe -O2 -g0 -march=native}"
rs_host_cxx="${CXX:-g++}"
rs_host_cxxflags="${CXXFLAGS:-$rs_host_cflags}"
rs_needed_tools="as find $CC $CXX grep m4 makeinfo python tar wget patch libtool autoconf automake"        # GNU Make has a special check
rs_needed_libs="zlib"
rs_target_cflags="-pipe -O2 -Wl,-S -g0"
rs_target_cxxflags="$rs_target_cflags"

export STRIP="$rs_host_strip"
export CC="$rs_host_cc"
export CFLAGS="$rs_host_cflags"
export CXX="$rs_host_cxx"
export CXXFLAGS="$rs_host_cxxflags"

# Get the absolute path to the script directory
cd `dirname $0`
rs_rootdir="$PWD"
rs_scriptdir="$rs_rootdir/scripts"
rs_workdir="$rs_rootdir/build"
rs_tcdir="$rs_rootdir/toolchain"
rs_tooldir="$rs_rootdir/tools"
rs_sourcedir="$rs_workdir/sources"
rs_patches="$rs_tcdir/patches"
rs_pkgdir="$rs_tcdir/packages"
rs_rm_installdir=true

# RosBE-Unix Constants
DEFAULT_INSTALL_DIR="/usr/local/RosBE"
ROSBE_VERSION="merge-fork (2.2.1)"

rs_modules=( # note: dependency order
	"bison"
	"flex"
	"cmake"
	"ninja"
	# target specific
	"binutils"
	"mingw_w64"
	"gcc"
)

rs_archs=( 
	"i386"
	"amd64"
)

rs_tools=(
	"scut"
	"cpucount"
	"chknewer"
	"chkslash"
	"echoh"
	"rquote"
	"getdate"
	"buildtime"
)

rs_tools_win=(
	"flash" # unix have the bash script
	"tee" # unix have it already
	"config"
	"playwav" # unix have the bash script
)

declare -A rs_triplets=(
	["i386"]="i686-w64-mingw32"
	["amd64"]="x86_64-w64-mingw32"
)

for module in ${rs_modules[@]}; do
	declare rs_process_$module=true
done

for arch in ${rs_archs[@]}; do
	declare rs_arch_$arch=true
done

for tool in ${rs_tools[@]}; do
	declare rs_tool_$tool=true
done

for tool in ${rs_tools_win[@]}; do
	declare rs_tool_$tool=true
done

rs_xp=false

source "$rs_scriptdir/bash/rosbelibrary.sh"
source "$rs_scriptdir/setuplibrary.sh"


echo "*******************************************************************************"
echo "*                          ReactOS Build Environment                          *"
echo "*                      Builder Tool for the Base package                      *"
echo "*                      by Colin Finck <colin@reactos.org>                     *"
echo "*                                                                             *"
echo "*                           Version $ROSBE_VERSION                               *"
echo "*******************************************************************************"

echo
echo "This script compiles and installs a complete Build Environment for building"
echo "ReactOS."
echo

if [ "$1" = "-h" ] || [ "$1" = "-?" ] || [ "$1" = "--help" ]; then
	echo "Syntax: ./RosBE-Builder.sh [options] [installdir]"
	echo
	echo " installdir    - Optional parameter to specify an installation directory. If you"
	echo "                 do this, the script will check whether this directory does not"
	echo "                 yet exist and in this case, it will perform an unattended"
	echo "                 installation to this directory."
	echo
	echo " options:"
	echo "  --exclude-module  [module]   Exclude one module from the toolchain compilation"
	echo "  --exclude-arch    [arch]     Exclude one architecture from the toolchain compilation"
	echo "  --exclude-tools              Exclude building of all provided tools"
	echo "  --enable-xp-mode             Build RosBe with XP-host compatible host"
	echo "  --resume                     Resumes the compilation of Rosbe, this can be usefull with passing different commands to continue building the environment"
	echo 
	echo " List of available modules:"
	for module in ${rs_modules[@]}; do
	echo "  $module"
	done
	echo
	echo " List of available architectures:"
	for arch in ${rs_archs[@]}; do
	echo "  $arch"
	done
	echo
	echo "Usually, you just call the script without any parameters and it will guide you"
	echo "through all possible installation options."
	exit 0
fi

for var in "$@"; do
	case "${var}" in
		--exclude-module)
			shift
			declare rs_process_$1=false
			shift
		;;

		--exclude-arch)
			shift
			declare rs_arch_$1=false
			shift
		;;

		--exclude-tools)
			shift
			rs_process_tools=false
		;;

		--enable-xp-mode)
			shift
			rs_xp=true
		;;

		--resume)
			shift
			rs_rm_installdir=false
		;;

		-*)
			echo "Invalid argument\"$1\" specified, ignoring..."
			shift
		;;
	esac
done

# temp...
if [ "$MSYSTEM" ] ; then
	# Install required tools in MSYS2
#	rs_boldmsg "Running MSYS pacman..."
#	pacman -S --quiet --noconfirm --needed diffutils help2man make msys2-runtime-devel python texinfo tar | tee /tmp/buildtoolchain-pacman.log
#
#	if grep installation /tmp/buildtoolchain-pacman.log >& /dev/null; then
#		# See e.g. https://sourceforge.net/p/msys2/tickets/74/
#		echo
#		rs_boldmsg "Installed MSYS packages have changed!"
#		echo "For a successful toolchain build, this requires you to close all MSYS windows and run \"autorebase.bat\" in the MSYS installation directory."
#		echo "After you have done so, please rerun \"buildtoolchain-mingw32.sh\"."
#		exit 1
#	fi
#
#	if [ "$MSYSTEM" = "MINGW64" ] ; then
#		pacman -S --quiet --noconfirm --needed mingw-w64-x86_64-libsystre | tee /tmp/buildtoolchain-pacman.log
#	elif [ "$MSYSTEM" = "MINGW32" ] ; then
#		pacman -S --quiet --noconfirm --needed mingw-w64-i686-libsystre | tee /tmp/buildtoolchain-pacman.log
#	fi
	echo

# Only check for root on an interactive installation.
elif [ "$1" = "" ] ; then
	check_root
fi

rs_check_requirements

if [ $rs_abi = 32 ]; then
	# Append i686 cflags on 32-bit x86
	rs_host_cflags= "$rs_host_cflags -march=pentium -mtune=i686"
fi

reinstall=false
update=false

rs_boldmsg "Modules to compile: "
for module in ${rs_modules[@]}; do
	var=rs_process_$module
	echo "$module: ${!var}"
done
echo

rs_boldmsg "Architectures to target: "
for arch in ${rs_archs[@]}; do
	var=rs_arch_$arch
	echo "$arch: ${!var}"
done
echo

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

	rs_boldmsg "Ready to start"

	echo "Ready to build and install the ReactOS Build Environment."
	echo "Press Return to continue or Ctrl+C to exit."
	read
else
	installdir=`eval echo $1`

	if [ -e "$installdir" ] && [ $rs_rm_installdir = true ]; then
		rs_redmsg "Installation directory \"$installdir\" already exists, aborted!"
		exit 1
	fi

	echo "Using \"$installdir\""
	echo
	shift
fi

if [ $rs_rm_installdir = true ]; then
	rm -rf "$installdir" || exit 1
fi

mkdir -p "$installdir" 2>/dev/null || exit 1
mkdir "$rs_workdir" 2>/dev/null

rs_prefixdir="$installdir"

##### BEGIN almost shared buildtoolchain/RosBE-Unix building part #############
rs_boldmsg "Building..."

mkdir -p "$rs_prefixdir/bin" 2>/dev/null

#for arch in ${!ARCH[@]}; do
#	if [ ${ARCH[$arch]} ]; then
#		mkdir -p "$installdir/$arch/${GCC_TRIPLETS[$arch]}"
#	fi
#done

echo "Using CFLAGS=\"$CFLAGS\""
echo "Using CXXFLAGS=\"$CXXFLAGS\""
echo

if $rs_process_tools ; then
	for tool in ${rs_tools[@]} ; do
		var=rs_process_$tool
		if [ ${!var} ]; then
			rs_do_command $CC -s -o "${rs_prefixdir}/bin/${tool}" "${rs_tooldir}/${tool}.c"
			rs_do_command $STRIP "${rs_prefixdir}/bin/${tool}${rs_suffix}"
		fi
	done

	if [ "$MSYSTEM" ] ; then
		for tool in ${rs_tools_win[@]} ; do
			var=rs_process_$tool
			if [ ${!var} ]; then
				if [ $tool = "flash" ] ; then
					rs_do_command $CC -D_WIN32_WINNT=0x500 -s -o "$rs_prefixdir/bin/flash" "$rs_tooldir/windows/flash.c"
				elif [ $tool = "playwav" ] ; then
					rs_do_command $CXX -D_UNICODE -s -o "$rs_prefixdir/bin/playwav" "$rs_tooldir/windows/playwav.cpp" -lwinmm -municode
				elif [ $tool = "config" ] ; then
					rs_do_command $rs_makecmd -C "$rs_tooldir/windows/config" install
				else
					rs_do_command $CC -s -o "${rs_prefixdir}/bin/${tool}" "$rs_tooldir/windows/${tool}.c"
				fi

				rs_do_command $STRIP "${rs_prefixdir}/bin/${tool}${rs_suffix}"
			fi
		done
	fi
fi

echo

rs_cpucount=`$rs_prefixdir/bin/cpucount -x1`

for module in ${rs_modules[@]}; do
	var=rs_process_$module
	if [ ${!var} = true ]; then
		rs_boldmsg "Building $module..."

		if [ ! -e "$rs_pkgdir/$module" ] ; then
			rs_redmsg "Unable to find package definition for the module!"
			exit 1
		fi

		source "$rs_pkgdir/$module"

		rm -rf "$rs_workdir/$module"
		mkdir -p "$rs_workdir/$module"

		for file in ${!rs_sources[@]} ; do
			rs_download_module "$rs_sourcedir" "${rs_sources[$file]}" "$file"
			rs_sha256_compare "$rs_sourcedir/$file" "${rs_sha256sums[$file]}"

			if [ "$?" = "1" ] ; then
				rs_redmsg "Invalid checksum for file $file, please check your internet connection and try again"
				hash=`eval sha256sum -- "$rs_sourcedir/$file" | cut -d " " -f 1`
				echo "Downloaded file checksum: $hash"
				exit 1
			fi
		done

		rs_prepare
		rs_build
		rs_clean_module "$module"
	fi
done

exit 0 # TODO

if rs_prepare_module "cmake"; then
	rs_do_command ../cmake/bootstrap --prefix="$rs_prefixdir" --parallel=$rs_cpucount -- -DCMAKE_USE_OPENSSL=OFF
	rs_do_command $rs_makecmd -j $rs_cpucount
	rs_do_command $rs_makecmd install
	rs_clean_module "cmake"
fi

if rs_prepare_module "ninja"; then
	if [ "$MSYSTEM" ] ; then
		$rs_ninja_args = "--platform mingw"
	fi
	rs_do_command python ../ninja/configure.py --bootstrap $rs_ninja_args
	rs_do_command install ninja "$rs_prefixdir/bin"
	rs_clean_module "ninja"
fi

for arch in ${!ARCH[@]}; do
	if [ ${ARCH[$arch]} ]; then
		rs_target=${GCC_TRIPLETS[$arch]}
		rs_archprefixdir="$installdir/$arch/$rs_target"

		# This is a cross-compiler with prefix.
		rs_target_tool_prefix="${rs_target}-"

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

			rs_do_command ../gcc/configure --prefix="$rs_archprefixdir" --target="$rs_target" --with-sysroot="$rs_archprefixdir" --with-pkgversion="ReactOS" --enable-languages=c,c++ --enable-fully-dynamic-string --enable-version-specific-runtime-libs --disable-shared --disable-multilib --disable-nls --disable-werror --disable-win32-registry --enable-sjlj-exceptions --disable-libstdcxx-verbose
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
	fi
done

# Final actions
echo
rs_boldmsg "Final actions"

echo "Removing unneeded files..."
cd "$rs_prefixdir"
rm bin/yacc
rm -rf doc man share/info share/man

for arch in ${!ARCH[@]}; do
	if [ ${ARCH[$arch]} ]; then
		rs_target=${GCC_TRIPLETS[$arch]}
		rs_archprefixdir="$installdir/$arch/$rs_target"
		cd "$rs_archprefixdir"
		rm -rf $rs_target/doc $rs_target/share include info man mingw share
		rm -f lib/* >& /dev/null
	fi
done
##### END almost shared buildtoolchain/RosBE-Unix building part ###############

# See: https://jira.reactos.org/browse/ROSBE-35
osname=`uname`
if [ "$osname" != "Darwin" ]; then
	echo "Removing debugging symbols..."
	cd "$rs_prefixdir"
	for exe in `find -executable -type f -print`; do
		rs_strip_os_module $exe
	done

	# Executables are created for the host system while most libraries are linked to target components
	for exe in `find -name "*.a" -type f -print`; do
		rs_strip_target_module $exe
	done

	for exe in `find -name "*.o" -type f -print`; do
		rs_strip_target_module $exe
	done
fi

if [ "$MSYSTEM" ]; then
	echo "Copying additional dependencies from MSYS..."
	cd "$rs_prefixdir/bin"
	cp /mingw32/bin/libgcc_s_dw2-1.dll .
	cp /mingw32/bin/libstdc++-6.dll .
	cp /mingw32/bin/libwinpthread-1.dll .
else
	echo "Copying scripts..."
	cp -R "$rs_scriptdir/scripts/bash"* "$installdir"

	echo "Writing version..."
	echo "$ROSBE_VERSION" > "$installdir/RosBE-Version"
	echo
fi

# Finish
rs_boldmsg "Finished successfully!"

if [ -z "$MSYSTEM" ]; then
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
fi
