#!/usr/bin/env bash
#
# Detects the CPU cores in your system and builds ReactOS with this number of threads
# Part of RosBE for Unix-based Operating Systems
# Copyright 2007-2011 Colin Finck <colin@reactos.org>
#
# Released under GNU GPL v2 or any later version.

source "$_ROSBE_ROSSCRIPTDIR/rosbelibrary.sh"

CPUCOUNT=`cpucount -x1`
execute_hooks pre-build $*
buildtime make -j $CPUCOUNT $*
execute_hooks post-build $*
