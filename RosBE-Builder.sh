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

# test for bash4 (avoid macosx default vesion to be used)
declare -A test=(
  ["a"]="test"
  ["b"]="test2"
)

if ! [ "${test["a"]}" = "test" ]; then
  echo "This script requires bash 4.0 or greater"
  exit 0
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
rs_host_cflags="${CFLAGS:--pipe -O2 -g0 -march=native}"

rs_host_ar="${AR:-ar}"
rs_host_as="${AS:-as}"
rs_host_cc="${CC:-gcc}"
rs_host_cxx="${CXX:-g++}"
rs_host_dlltool="${DLLTOOL:-dlltool}"
rs_host_ranlib="${RANLIB:-ranlib}"
rs_host_strip="${STRIP:-strip}"

rs_needed_tools="as find $CC $CXX grep m4 makeinfo python tar wget patch libtool autoconf automake autopoint unzip sha256sum"        # GNU Make has a special check
rs_needed_libs="zlib"
rs_target_cflags="-pipe -O2 -Wl,-S -g0"
rs_target_cxxflags="$rs_target_cflags"

export AR="$rs_host_ar"
export AS="$rs_host_as"
export CC="$rs_host_cc"
export CXX="$rs_host_cxx"
export DLLTOOL="$rs_host_dlltool"
export RANLIB="$rs_host_ranlib"
export STRIP="$rs_host_strip"

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
rs_resume=false
rs_process_tools=true
rs_cpucount=0

# RosBE-Unix Constants
DEFAULT_INSTALL_DIR="/usr/local/RosBE"
ROSBE_VERSION="merge-fork (2.2.1)"

rs_modules=( # note: dependency order
	"bison"
	"flex"
	"cmake"
	"ninja"
	# gmp, mpfr and mpc are built before mingw_headers so we avoid prefix configuration issues with mpfr under linux
	"gmp"
	"mpfr"
	"mpc"
	# target specific
	"binutils"
	"mingw_headers"
	# gcc specific
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
	"options"
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

rs_arch_amd64=false # amd64 seems broken

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
	echo "  --include-arch    [arch]     Include one architecture from the toolchain compilation"
	echo "  --include-module  [module]   Include one module from the toolchain compilation"
	echo "  --resume                     Resumes the compilation of RosBE, this can be usefull with passing different commands to continue building the environment"
	echo "  --jobs [jobs]                Override jobs compilation"
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

		--include-module)
			shift
			declare rs_process_$1=true
			shift
		;;

		--include-arch)
			shift
			declare rs_arch_$1=true
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
			rs_resume=true
		;;

		--jobs)
			shift
			rs_cpucount=$1
			shift
		;;

		-*)
			echo "Invalid argument\"$1\" specified, ignoring..."
			shift
		;;
	esac
done

if [ "$MSYSTEM" = "MSYS" ] ; then
	rs_redmsg "This script cannot be executed from an MSYS command line"
	exit 1
fi

# Only check for root on an interactive installation.
if [ "$1" = "" ] && [ ! "$MSYSTEM" ] ; then
	check_root
fi

rs_check_requirements

# update c and cxxflags here

if [ $rs_abi = 32 ]; then
	# Append i686 cflags on 32-bit x86
	rs_host_cflags= "$rs_host_cflags -march=pentium -mtune=i686"
fi

# gmp fails to build under MINGW/MSYS if we don't specify host and target
if [ "$MSYSTEM" = "MINGW32" ] ; then
	rs_host_autoconf="--host=i686-w64-mingw32 --build=i686-w64-mingw32"
elif [ "$MSYSTEM" = "MINGW64" ] ; then
	rs_host_autoconf="--host=x86_64-w64-mingw32 --build=x86_64-w64-mingw32"
else
	rs_host_autoconf=""
fi

rs_host_cxxflags="${CXXFLAGS:-$rs_host_cflags}"
export CXXFLAGS="$rs_host_cxxflags"
export CFLAGS="$rs_host_cflags"

reinstall=false
update=false

rs_boldmsg "Modules to compile: "
for module in ${rs_modules[@]}; do
	var=rs_process_$module
	echo -n "$module: "
	rs_boldmsg "${!var}"
done
echo

rs_boldmsg "Architectures to target: "
for arch in ${rs_archs[@]}; do
	var=rs_arch_$arch
	echo -n "$arch: " 
	rs_boldmsg "${!var}"
done
echo

echo -n "Compile tools: "
rs_boldmsg "$rs_process_tools"
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
			if [ ! "`ls $installdir`" = "" ] && [ $rs_resume = false ]; then
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

	if [ -e "$installdir" ] && [ $rs_resume = false ]; then
		rs_redmsg "Installation directory \"$installdir\" already exists, aborted!"
		exit 1
	fi

	echo "Using \"$installdir\""
	echo
	shift
fi

if [ $rs_resume = false ]; then
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

if [ $rs_process_tools = true ] ; then
	for tool in ${rs_tools[@]} ; do
		var=rs_tool_$tool
		if [ ${!var} ]; then
			if [ ! -f "${rs_prefixdir}/bin/${tool}" ] || [ $rs_resume = false ]; then
				rs_do_command $CC -s -o "${rs_prefixdir}/bin/${tool}" "${rs_tooldir}/${tool}.c"
				rs_do_command $STRIP "${rs_prefixdir}/bin/${tool}${rs_suffix}"
			fi
		fi
	done

	if [ "$MSYSTEM" ] ; then
		for tool in ${rs_tools_win[@]} ; do
			var=rs_tool_$tool
			if [ ${!var} ]; then
				if [ ! -f "${rs_prefixdir}/bin/${tool}" ] || [ $rs_resume = false ]; then
					if [ $tool = "flash" ] ; then
						rs_do_command $CC -D_WIN32_WINNT=0x500 -s -o "$rs_prefixdir/bin/flash" "$rs_tooldir/windows/flash.c"
					elif [ $tool = "playwav" ] ; then
						rs_do_command $CXX -D_UNICODE -s -o "$rs_prefixdir/bin/playwav" "$rs_tooldir/windows/playwav.cpp" -lwinmm -municode
					elif [ $tool = "options" ] ; then
						export PREFIX=$rs_prefixdir
						rs_do_command $rs_makecmd -C "$rs_tooldir/windows/config" install
					else
						rs_do_command $CC -s -o "${rs_prefixdir}/bin/${tool}" "$rs_tooldir/windows/${tool}.c"
					fi

					rs_do_command $STRIP "${rs_prefixdir}/bin/${tool}${rs_suffix}"
				fi
			fi
		done
	fi
fi

echo

if [ "$rs_cpucount" = "0" ] ; then
	rs_cpucount=`$rs_prefixdir/bin/cpucount -x1`
fi

# Main compiler
for module in ${rs_modules[@]}; do
	# set the prefix directory again in case it was altered
	rs_prefixdir="$installdir"
	rs_msys=false
	skip_prepare=false
	rs_triplets=false
	is_ok="0"

	var=rs_process_$module
	if [ ${!var} = true ]; then
		if [ ! -e "$rs_pkgdir/$module" ] ; then
			rs_redmsg "Unable to find package definition for the module!"
			exit 1
		fi

		# Load the package build directives
		source "$rs_pkgdir/$module"

		# Do not build the module if it was already built and we are running in resume mode

		if [ "$rs_triplets" = true ] ; then
			# Triplet based compilation, we have to iterate trough all the arches and see if all of them were built properly
			for arch in ${rs_archs[@]} ; do
				var=rs_arch_$arch
				if [ ${!var} = true ] ; then
					# set the target triplet and new prefix for checking data
					rs_target=${rs_triplets[$arch]}
					rs_prefixdir="$installdir/$arch"
					rs_check

					is_ok="$?"

					# if the function returns 0, then one arch was not built so we have to start the build process
					if [ "$is_ok" = "0" ] ; then
						break
					fi
				fi
			done
		else
			# Simple, one check, for projects that doesn't need more than one target arch
			rs_check
			is_ok=$?
		fi


		if [ "$is_ok" = "1" ] && [ "$rs_resume" = true ]; then
			continue
		fi

		# Disable msys forward if you are not running under Windows
		## We need this msys division because flex doesn't work under MINGW64 due to missing POSIX compatibilty
		if [ ! "$MSYSTEM" ] ; then
			rs_msys=false
		fi

		# Check if we should preparing the sources again or just skip that part
		rs_prepare_check
		status=$?

		if [ "$rs_resume" = false ] ; then
			rm -rf "$rs_workdir/$module"
		elif [ "$status" = "1" ] ; then
			skip_prepare=true
		fi

		if [ "$skip_prepare" = false ] ; then
			rs_boldmsg "Preparing source for $module..."

			# Download and check the downloaded files
			for file in ${!rs_sources[@]} ; do
				rs_download_module "$rs_sourcedir" "${rs_sources[$file]}" "$file"
				rs_sha256_compare "$rs_sourcedir/$file" "${rs_sha256sums[$file]}"
				status=$?
				if [ "$status" = "1" ] ; then
					rs_redmsg "Invalid checksum for file $file, please check your internet connection and try again"
					hash=`eval sha256sum -- "$rs_sourcedir/$file" | cut -d " " -f 1`
					echo "Downloaded file checksum: $hash"
					rm "$rs_sourcedir/$file"
					exit 1
				fi
			done

			mkdir -p "$rs_workdir/$module"
			cd "$rs_workdir/$module"

			# Prepare the source code (extract it and apply any patch)
			rs_prepare
		fi

		if [ "$rs_triplets" = true ] ; then
			# Triplet based compilation, we have to iterate trough all the arches and build the specifics
			for arch in ${rs_archs[@]} ; do
				var=rs_arch_$arch
				if [ ${!var} = true ] ; then
					# set the target triplet and new prefix
					rs_target=${rs_triplets[$arch]}
					rs_prefixdir="$installdir/$arch"

					# Check again to skip target-specific
					rs_check
					if [ "$?" = "1" ] && [ "$rs_resume" = true ]; then
						continue
					fi

					rs_boldmsg "Building $module for $arch..."

					# move to the arch-specific target directory
					mkdir -p "$rs_workdir/$module/build-$arch" 2>/dev/null
					cd "$rs_workdir/$module/build-$arch"

					# Start the build for this triplet
					rs_build
				fi
			done
		else
			# Do a normal build
			rs_boldmsg "Building $module..."
			mkdir -p "$rs_workdir/$module/build" 2>/dev/null
			cd "$rs_workdir/$module/build"
			rs_build
		fi

		# Cleanup any build directory
		rs_clean_module "$module"
	fi
done

# Final actions
echo
rs_boldmsg "Final actions"

echo "Removing unneeded files..."
rs_prefixdir="$installdir"
cd "$rs_prefixdir"
rm -rf "bin/yacc"
rm -rf "doc" "$man" "$share/doc" "$share/info" "$share/man"

for arch in ${rs_archs[@]}; do
	var=rs_arch_$arch
	if [ ${!var} = true ]; then
		rs_archprefixdir="$installdir/$arch"
		rs_target=${rs_triplets[$arch]}
		cd "$rs_archprefixdir/"
		rm -rf "$rs_target/doc" "$rs_target/share" "info" "man" "mingw" "share" "include"
		rm -f lib/* >& /dev/null
	fi
done


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

	if [ "$MSYSTEM" = "MINGW64" ] ; then
		mingw_prefix="mingw64"
	else
		mingw_prefix="mingw32"
	fi

	cp /$mingw_prefix/bin/libgcc_s_dw2-1.dll . 2>/dev/null # compatibiliy with older mingw
	cp /$mingw_prefix/bin/libgcc_s_seh-1.dll . 2>/dev/null
	cp /$mingw_prefix/bin/libstdc++-6.dll .
	cp /$mingw_prefix/bin/libwinpthread-1.dll .
else
	echo "Copying scripts..."
	cp -R "$rs_scriptdir/bash"* "$installdir"

	echo "Writing version..."
	echo "$ROSBE_VERSION" > "$installdir/RosBE-Version"
	echo
fi

# Finish
rs_boldmsg "Finished successfully!"

if [ ! "$MSYSTEM" ]; then
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
