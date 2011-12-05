#!/bin/bash
#
# Detects the CPU cores in your system and builds ReactOS with this number of threads
# Part of RosBE for Unix-based Operating Systems
# Copyright 2007-2011 Colin Finck <colin@reactos.org>
#
# Released under GNU GPL v2 or any later version.

CPUCOUNT=`cpucount -x1`
buildtime make -j $CPUCOUNT $*
