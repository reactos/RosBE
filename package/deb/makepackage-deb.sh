#!/usr/bin/env bash
#
# ReactOS Build Environment for Unix-based Operating Systems - Packaging tool for DEB source packages
# Copyright 2020 Colin Finck <colin@reactos.org>
#
# Released under GNU GPL v2 or any later version.

cd `dirname $0`

#
# Prerequisites
#
# Check the parameters
if [[ "$3" = "" ]]; then
	echo "makepackage-deb - Package a RosBE-Unix version as DEB source package (for Launchpad)"
	echo "Syntax: ./makepackage-deb.sh <package> <version> <distro>"
	echo
	echo " package - Package name (i.e. \"Base-i386\")"
	echo " version - Version number of the Build Environment to package (i.e. \"1.4\")"
	echo " distro  - Debian/Ubuntu distribution name to create a package for (i.e. \"bionic\")"
	exit 1
fi

package_name="$1"
package_version="$2"
distro_name="$3"

# Set the full package name
full_package_name="RosBE-Unix"

case "$package_name" in
	"Base-i386")
		# Add no suffix
		;;
	*)
		# Add the package name as the suffix
		full_package_name+="-$package_name"
		;;
esac

debian_package_name=`echo $full_package_name | tr '[:upper:]' '[:lower:]'`
debian_orig_file="${debian_package_name}_${package_version}.orig.tar.bz2"

full_package_name+="-$package_version"
full_package_file="$full_package_name.tar.bz2"

# Let's hope we will never need more than one try for each distro :)
debian_package_name+="_$package_version-1ppa1~$distro_name"

if [[ ! -d "$full_package_name" || ! -f "$full_package_file" ]]; then
	echo "Directory \"$full_package_name\" or file \"$full_package_file\" does not exist!"
	echo "Make sure that you run ./makepackage.sh beforehand."
	exit 1
fi

debian_directory="${package_name}_debian"
if [[ ! -d "$debian_directory" ]]; then
	echo "Debian package directory \"$debian_directory\" does not exist!"
	exit 1
fi

distro_directory="${debian_directory}_${distro_name}"
if [[ ! -d "$distro_directory" ]]; then
	echo "Distro-specific Debian package directory \"$distro_directory\" does not exist!"
	exit 1
fi

# Create the Debian package structure
rm -rf $debian_package_name
rm -f $debian_package_name*

cp $full_package_file $debian_orig_file
cp -R $full_package_name $debian_package_name
cp -R $debian_directory $debian_package_name/debian
cp $distro_directory/* $debian_package_name/debian

# Create the DEB source package for Launchpad
cd $debian_package_name
debuild -S
