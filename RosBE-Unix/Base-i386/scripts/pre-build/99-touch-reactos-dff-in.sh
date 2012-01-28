#!/bin/bash
#
# Pre-build hook script to force CMake rehandle
# reactos.dff (in then, handle optional components)
# Part of RosBE for Unix-based Operating Systems
# Copyright 2012-2012 Pierre Schweitzer <pierre@reactos.org>
#
# Released under GNU GPL v2 or any later version.

# Just touch the file
touch boot/bootdata/packages/reactos.dff.in
