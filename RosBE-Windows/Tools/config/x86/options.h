/*
 * PROJECT:     RosBE Options Dialog
 * LICENSE:     GNU General Public License v2. (see LICENSE.txt)
 * FILE:        Tools/config/options.h
 * PURPOSE:     Configuring RosBE
 * COPYRIGHT:   Copyright 2018 Maarten Bosma
 *                             Pierre Schweitzer
 *                             Daniel Reimer
 *
 */

#include <windows.h>
#include <stdio.h>
#include <shlobj.h>
#include <wchar.h>
#include "resources.h"

#define MINGWVERSION64 L"\\amd64"
#define MINGWVERSIONARM L"\\arm"
#define MINGWVERSION L"\\i386"

typedef struct _SETTINGS
{
    WCHAR logdir[MAX_PATH];
    WCHAR objdir[MAX_PATH];
    WCHAR outdir[MAX_PATH];
    WCHAR mingwpath[MAX_PATH];
    INT foreground;
    INT background;
    BOOL showtime;
    BOOL useccache;
    WCHAR lstrip[MAX_PATH];
    WCHAR lnostrip[MAX_PATH];
    BOOL strip;
    BOOL nostrip;
    BOOL writelog;
    BOOL objstate;
    BOOL outstate;
    BOOL showversion;
    BOOL syspath;
}
SETTINGS, *PSETTINGS;

wchar_t *wcsset(wchar_t *string, wchar_t c);
BOOL amd64 = FALSE;
BOOL arm = FALSE;
