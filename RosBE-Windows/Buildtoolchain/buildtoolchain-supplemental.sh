#!/bin/bash
#
# ReactOS Build Environment for Windows - Script for copying supplemental tools for RosBE-Windows
# Copyright 2020 Colin Finck <colin@reactos.org>
#
# Released under GPL-2.0-or-later (https://spdx.org/licenses/GPL-2.0-or-later)
#

set -eu

# We want exactly one parameter
if [[ $# -ne 1 ]]; then
	echo "Syntax: ./buildtoolchain-supplemental.sh <workdir>"
	echo
	echo " workdir  - Path to the directory used for building. Will contain the final executables and"
	echo "            temporary files."
	echo "            The path must be an absolute one in Unix style, e.g. /d/buildtoolchain"
	exit 1
fi

# Install required tools in MSYS2
pacman -S --quiet --noconfirm --needed unzip

cd $1

# ccache (native, latest version)
mkdir ccache
cd ccache
wget https://github.com/ccache/ccache/releases/download/v3.7.9/ccache-3.7.9-windows-32.zip
unzip ccache-3.7.9-windows-32.zip
cp ccache-3.7.9-windows-32/ccache.exe ../RosBE/bin
cd ..
rm -rf ccache

# diffutils (MSYS2, latest XP-compatible version)
mkdir diffutils
cd diffutils
wget http://repo.msys2.org/msys/i686/diffutils-3.3-3-i686.pkg.tar.xz
tar xf diffutils-3.3-3-i686.pkg.tar.xz
cp usr/bin/cmp.exe ../RosBE/bin
cp usr/bin/diff.exe ../RosBE/bin
cp usr/bin/diff3.exe ../RosBE/bin
cp usr/bin/sdiff.exe ../RosBE/bin
cd ..
rm -rf diffutils

# libiconv (MSYS2, latest XP-compatible version, required for diffutils)
mkdir libiconv
cd libiconv
wget http://repo.msys2.org/msys/i686/libiconv-1.14-2-i686.pkg.tar.xz
tar xf libiconv-1.14-2-i686.pkg.tar.xz
cp usr/bin/msys-iconv-2.dll ../RosBE/bin
cd ..
rm -rf libiconv

# libintl (MSYS2, latest XP-compatible version, required for diffutils)
mkdir libintl
cd libintl
wget http://repo.msys2.org/msys/i686/libintl-0.19.7-3-i686.pkg.tar.xz
tar xf libintl-0.19.7-3-i686.pkg.tar.xz
cp usr/bin/msys-intl-8.dll ../RosBE/bin
cd ..
rm -rf libintl

# patch (MSYS2, latest XP-compatible version)
mkdir patch
cd patch
wget http://repo.msys2.org/msys/i686/patch-2.7.5-1-i686.pkg.tar.xz
tar xf patch-2.7.5-1-i686.pkg.tar.xz
cp usr/bin/patch.exe ../RosBE/bin
cd ..
rm -rf patch

# wget (latest XP-compatible version)
cd RosBE/bin
wget https://eternallybored.org/misc/wget/1.19.4/32/wget.exe
cd ../..

echo "Finished!"
