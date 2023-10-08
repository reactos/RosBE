/*
 * PROJECT:     RosBE - ReactOS Build Environment for Windows.
 * LICENSE:     GNU General Public License v2. (see LICENSE.txt)
 * FILE:        Tools/getdate.c
 * PURPOSE:     Returns System Date
 * COPYRIGHT:   Copyright 2020 Peter Ward <dralnix@gmail.com>
 *
 */


#include <time.h>
#include <stdio.h>

int main(void)
{
    time_t t = time(NULL);
    struct tm tm = *localtime(&t);
    printf("%02d/%02d/%d", tm.tm_mon + 1, tm.tm_mday, tm.tm_year + 1900);
    return 0;
}
