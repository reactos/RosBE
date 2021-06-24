# Show the amd64 tool versions
# Part of RosBE for Unix-based Operating Systems
# Copyright 2021 Colin Finck <colin@reactos.org>
#
# Released under GPL-2.0-or-later (https://spdx.org/licenses/GPL-2.0-or-later)

x86_64-w64-mingw32-gcc -v 2>&1 | grep "gcc version"
x86_64-w64-mingw32-ld -v
