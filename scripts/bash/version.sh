#!/usr/bin/env bash
#
# Show the tool versions
# Part of RosBE for Unix-based Operating Systems
# Copyright 2007-2020 Colin Finck <colin@reactos.org>
#
# Released under GPL-2.0-or-later (https://spdx.org/licenses/GPL-2.0-or-later)

source "$_ROSBE_ROSSCRIPTDIR/setuplibrary.sh"

# Display RosBE version
echo "This is the ReactOS Build Environment for Unix-based Operating Systems"
echo "Version $_ROSBE_VERSION"
echo

# Environment Information
rs_boldmsg "Environment Information"
echo "Selected Target Architecture: $ROS_ARCH"
echo

# Display tool versions
rs_boldmsg "Build Tools"
source "$_ROSBE_ROSSCRIPTDIR/$ROS_ARCH/version.sh"
bison --version | grep "GNU Bison"
flex --version
echo "Ninja `ninja --version`"
cmake --version | grep "version"
