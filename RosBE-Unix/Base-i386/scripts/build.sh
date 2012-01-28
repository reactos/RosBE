#!/bin/bash
#
# Builds ReactOS with one thread
# Part of RosBE for Unix-based Operating Systems
# Copyright 2007-2011 Colin Finck <colin@reactos.org>
#
# Released under GNU GPL v2 or any later version.

source "$_ROSBE_ROSSCRIPTDIR/rosbelibrary.sh"

execute_hooks pre-build $*
buildtime make $*
execute_hooks post-build $*
