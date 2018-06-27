#!/usr/bin/env bash
#
# Script for creating shortcuts
# Part of RosBE for Unix-based Operating Systems
# Copyright 2007-2009 Colin Finck <mail@colinfinck.de>
#
# Released under GNU GPL v2 or any later version.

# Constants
DEFAULT_SHORTCUT_DIR=$(xdg-user-dir DESKTOP 2>/dev/null)
if [ "x$DEFAULT_SHORTCUT_DIR" == "x" ]; then
	DEFAULT_SHORTCUT_DIR="$HOME/Desktop"
fi

# Get the absolute path to the script directory
cd `dirname $0`
SCRIPTDIR="$PWD"

source "$SCRIPTDIR/setuplibrary.sh"


# Read the RosBE version
# The file "RosBE-Version" has been created by the RosBE-Builder.sh script
ROSBE_VERSION=`cat "$SCRIPTDIR/RosBE-Version"`

# Select the source directory
rs_boldmsg "ReactOS Source Directory"

echo "Enter the directory where the ReactOS sources are located."
echo "This directory will become the current directory, when you start the Build Environment."

sourcedir=""
while [ "$sourcedir" = "" ]; do
	read -p "Directory: " sourcedir

	# Make sure we have the absolute path to the source directory
	sourcedir=`eval echo $sourcedir`

	if ! [ -d "$sourcedir" ]; then
		echo "The entered path is no directory. Please enter the right path to the ReactOS sources."
		sourcedir=""
	fi

	echo
done

# Select the shortcut directory
rs_boldmsg "Shortcut Directory"

echo "In which directory do you want to create the shortcut?"
echo "Enter the path to the directory here or simply press ENTER to install it into the Desktop directory of the current user."

shortcutdir=""
while [ "$shortcutdir" = "" ]; do
	read -p "[$DEFAULT_SHORTCUT_DIR] " shortcutdir

	if [ "$shortcutdir" = "" ]; then
		shortcutdir="$DEFAULT_SHORTCUT_DIR"
	elif ! [ -d "$shortcutdir" ]; then
		echo "The entered path is no directory. Please enter a valid path."
		shortcutdir=""
	fi

	echo
done

# Create the shortcut
rs_boldmsg "Create Shortcut"

echo -n "Creating shortcut... "
shortcut="$shortcutdir/ReactOS Build Environment.desktop"

echo "[Desktop Entry]" > "$shortcut"
echo "Type=Application" >> "$shortcut"
echo "Categories=Development" >> "$shortcut"
echo "Version=$ROSBE_VERSION" >> "$shortcut"
echo "Name=ReactOS Build Environment" >> "$shortcut"
echo "Icon=$SCRIPTDIR/RosBE.png" >> "$shortcut"
echo "Exec=bash \"$SCRIPTDIR/RosBE.sh\" \"$sourcedir\"" >> "$shortcut"
echo "Terminal=true" >> "$shortcut"

rs_greenmsg "OK"
