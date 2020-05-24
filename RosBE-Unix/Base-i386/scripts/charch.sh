#!/usr/bin/env bash
#
# Change the current target build tools to an architecture to build for
# Part of RosBE for Unix-based Operating Systems
# Copyright 2009-2020 Colin Finck <colin@reactos.org>
#
# Released under GPL-2.0-or-later (https://spdx.org/licenses/GPL-2.0-or-later)

if [ "$1" = "" ]; then
	echo "charch: Changes the target architecture for building ReactOS."
	echo "The appropriate build tools for this architecture need to be installed by a"
	echo "RosBE-Unix package."
	echo
	echo "Syntax: charch <architecture>"
	return 0
fi

# Change the architecture
source "$_ROSBE_ROSSCRIPTDIR/rosbelibrary.sh"
change_architecture $1

# Display tool versions
source "$_ROSBE_ROSSCRIPTDIR/$ROS_ARCH/version.sh"
