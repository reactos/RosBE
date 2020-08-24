/*
 * PROJECT:     RosBE - ReactOS Build Environment for Windows.
 * LICENSE:     GNU General Public License v2. (see LICENSE.txt)
 * PURPOSE:     Converts a value to hex and displays it
 * COPYRIGHT:   Copyright 2020 Christoph von Wittich <Christoph_vW@reactos.org>
 *
 */

#include <stdio.h>
#include <stdlib.h>

int main(int argc, char** argv)
{
    if (argc == 2)
        printf("%x", atoi(argv[1]));

    return 0;
}
