#!/usr/bin/env bash
#
# Script for cleaning the ReactOS source directory
# Part of RosBE for Unix-based Operating Systems
# Copyright 2007-2011 Colin Finck <colin@reactos.org>
#
# Released under GNU GPL v2 or any later version.

# We only care about cleaning the default output directory, if any
REACTOS_OUTPUT_PATH="output-MinGW-$ROS_ARCH"

if [ -d "$REACTOS_OUTPUT_PATH" ]; then
	echo "Cleaning ReactOS $ROS_ARCH source directory..."
	rm -rf "$REACTOS_OUTPUT_PATH"
	echo "Done cleaning ReactOS $ROS_ARCH source directory."
else
	echo "ERROR: This directory contains no $ROS_ARCH compiler output to clean."
fi
