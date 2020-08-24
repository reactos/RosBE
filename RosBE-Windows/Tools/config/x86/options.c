/*
 * PROJECT:     RosBE Options Dialog
 * LICENSE:     GNU General Public License v2. (see LICENSE.txt)
 * PURPOSE:     Configuring RosBE
 * COPYRIGHT:   Copyright 2020 Maarten Bosma
 *                             Pierre Schweitzer
 *                             Daniel Reimer
 *
 */

#include "options.h"

typedef struct _OPTIONS_DLG
{
    HWND hwndDlg;
    HWND hwndToolTip;
    HICON hIcon;
    HFONT hFont;
    SETTINGS Settings;
} OPTIONS_DLG, *POPTIONS_DLG;

HINSTANCE hInstance;

BOOL CreateDir(HWND hwnd, WCHAR* dir)
{
    WCHAR msgerror[256];

    if (0 > (LONG)GetFileAttributes(dir))
    {
        if (CreateDirectory(dir, NULL) == 0)
        {
            LoadStringW(hInstance, MSG_DIREFAILED, msgerror, 256);
            MessageBoxW(hwnd, msgerror, NULL, MB_ICONERROR);
            return FALSE;
        }
    }
    return TRUE;
}

static
const
WCHAR*
getConfigFileCMD() 
{
    static WCHAR filename[MAX_PATH];
    if (SHGetSpecialFolderPathW(NULL, filename, CSIDL_APPDATA, FALSE))
    {
        if (amd64)
        {
            if ((wcslen(filename) + wcslen(L"\\RosBE\\rosbe-options-amd64.cmd")) < MAX_PATH)
            {
                wcscat(filename, L"\\RosBE\\rosbe-options-amd64.cmd");
            }
        }
        else if (arm)
        {
            if ((wcslen(filename) + wcslen(L"\\RosBE\\rosbe-options-arm.cmd")) < MAX_PATH)
            {
                wcscat(filename, L"\\RosBE\\rosbe-options-arm.cmd");
            }
        }
        else
        {
            if ((wcslen(filename) + wcslen(L"\\RosBE\\rosbe-options-2.2.1.cmd")) < MAX_PATH)
            {
                wcscat(filename, L"\\RosBE\\rosbe-options-2.2.1.cmd");
            }
        }
    }
    else
    {
        if (amd64)
        {
            wcscpy(filename, L"rosbe-options-amd64.cmd");
        }
        else if (arm)
        {
            wcscpy(filename, L"rosbe-options-arm.cmd");
        }
        else
        {
            wcscpy(filename, L"rosbe-options-2.2.1.cmd");
        }
    }
    return filename;
}

static
const
WCHAR*
getConfigFilePS1() 
{
    static WCHAR filename[MAX_PATH];
    if (SHGetSpecialFolderPathW(NULL, filename, CSIDL_APPDATA, FALSE))
    {
        if (amd64)
        {
            if ((wcslen(filename) + wcslen(L"\\RosBE\\rosbe-options-amd64.ps1")) < MAX_PATH)
            {
                wcscat(filename, L"\\RosBE\\rosbe-options-amd64.ps1");
            }
        }
        else if (arm)
        {
            if ((wcslen(filename) + wcslen(L"\\RosBE\\rosbe-options-arm.ps1")) < MAX_PATH)
            {
                wcscat(filename, L"\\RosBE\\rosbe-options-arm.ps1");
            }
        }
        else
        {
            if ((wcslen(filename) + wcslen(L"\\RosBE\\rosbe-options-2.2.1.ps1")) < MAX_PATH)
            {
                wcscat(filename, L"\\RosBE\\rosbe-options-2.2.1.ps1");
            }
        }
    }
    else
    {
        if (amd64)
        {
            wcscpy(filename, L"rosbe-options-amd64.ps1");
        }
        else if (arm)
        {
            wcscpy(filename, L"rosbe-options-arm.ps1");
        }
        else
        {
            wcscpy(filename, L"rosbe-options-2.2.1.ps1");
        }
    }
    return filename;
}

INT
WriteSettings(POPTIONS_DLG infoPtr)
{
    INT foreground, background;
    BOOL showtime, writelog, useccache, strip, nostrip, showversion, syspath;
    WCHAR logdir[MAX_PATH], mingwpath[MAX_PATH], checkmgw[MAX_PATH];
    WCHAR msgerror[256];
    HANDLE hFile;
    FILE *pFilecmd, *pFileps1;

    showtime = (SendDlgItemMessageW(infoPtr->hwndDlg, ID_SHOWBUILDTIME, BM_GETCHECK, 0, 0) == BST_CHECKED);
    writelog = (SendDlgItemMessageW(infoPtr->hwndDlg, ID_SAVELOGS, BM_GETCHECK, 0, 0) == BST_CHECKED);
    useccache = (SendDlgItemMessageW(infoPtr->hwndDlg, ID_USECCACHE, BM_GETCHECK, 0, 0) == BST_CHECKED);
    strip = (SendDlgItemMessageW(infoPtr->hwndDlg, ID_STRIP, BM_GETCHECK, 0, 0) == BST_CHECKED);
    nostrip = (SendDlgItemMessageW(infoPtr->hwndDlg, ID_NOSTRIP, BM_GETCHECK, 0, 0) == BST_CHECKED);
    showversion = (SendDlgItemMessageW(infoPtr->hwndDlg, ID_SHOWVERSION, BM_GETCHECK, 0, 0) == BST_CHECKED);
    syspath = (SendDlgItemMessageW(infoPtr->hwndDlg, ID_SYSPATH, BM_GETCHECK, 0, 0) == BST_CHECKED);
    foreground = (INT) SendDlgItemMessageW(infoPtr->hwndDlg, IDC_FONT, CB_GETCURSEL, 0, 0);
    background = (INT) SendDlgItemMessageW(infoPtr->hwndDlg, IDC_BACK, CB_GETCURSEL, 0, 0);
    GetDlgItemTextW(infoPtr->hwndDlg, ID_LOGDIR, logdir, MAX_PATH);
    GetDlgItemTextW(infoPtr->hwndDlg, ID_MGWDIR, mingwpath, MAX_PATH);
 
    if (writelog && (logdir[0] != 0))
    {
        if (!CreateDir(infoPtr->hwndDlg, logdir))
        {
            return FALSE;
        }
    }

    wcscpy(checkmgw, mingwpath);
    if (amd64)
    {
        if ((wcslen(checkmgw) + wcslen(L"\\bin\\x86_64-w64-mingw32-gcc.exe")) < MAX_PATH)
        {
            wcscat(checkmgw, L"\\bin\\x86_64-w64-mingw32-gcc.exe");
        }
    }
    else if (arm)
    {
        if ((wcslen(checkmgw) + wcslen(L"\\bin\\arm-mingw32ce-gcc.exe")) < MAX_PATH)
        {
            wcscat(checkmgw, L"\\bin\\arm-mingw32ce-gcc.exe");
        }
    }
    else
    {
        if ((wcslen(checkmgw) + wcslen(L"\\bin\\gcc.exe")) < MAX_PATH)
        {
            wcscat(checkmgw, L"\\bin\\gcc.exe");
        }
    }
    hFile = CreateFile(checkmgw, 0, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile == INVALID_HANDLE_VALUE)
    {
        LoadStringW(hInstance, MSG_NOGCCFOUND, msgerror, 256);
        MessageBoxW(infoPtr->hwndDlg, msgerror, NULL, MB_ICONERROR);
        return FALSE;
    }
    CloseHandle(hFile);

    pFilecmd = _wfopen(getConfigFileCMD(), L"w");
    pFileps1 = _wfopen(getConfigFilePS1(), L"w");

    if (pFilecmd)
    {
        fwprintf(pFilecmd, L"::\n");
        fwprintf(pFilecmd, L":: This file has been automatically generated by the ReactOS\n");
        fwprintf(pFilecmd, L":: Build Environment options utility.\n");
        fwprintf(pFilecmd, L"::\n\n");
        fwprintf(pFilecmd, L"color %X%X\n", background, foreground);
        fwprintf(pFilecmd, L"set _ROSBE_SHOWTIME=%d\n", showtime);
        fwprintf(pFilecmd, L"set _ROSBE_USECCACHE=%d\n", useccache);
        fwprintf(pFilecmd, L"set ROS_LEAN_AND_MEAN=%s\n", (strip == 1) ? "yes" : "no");
        fwprintf(pFilecmd, L"set ROS_BUILDNOSTRIP=%s\n", (nostrip == 1) ? "yes" : "no");
        fwprintf(pFilecmd, L"set _ROSBE_WRITELOG=%d\n", writelog);
        fwprintf(pFilecmd, L"set _ROSBE_SHOWVERSION=%d\n", showversion);
        fwprintf(pFilecmd, L"set _ROSBE_SYSPATH=%d\n", syspath);
        if (logdir[0] != 0)
        {
            fwprintf(pFilecmd, L"set _ROSBE_LOGDIR=%s\n", logdir);
        }
        if (amd64 || arm)
        {
            if (mingwpath[0] != 0)
            {
                fwprintf(pFilecmd, L"set _ROSBE_TARGET_MINGWPATH=%s\n", mingwpath);
            }
        }
        else
        {
            if (mingwpath[0] != 0)
            {
                fwprintf(pFilecmd, L"set _ROSBE_HOST_MINGWPATH=%s\n", mingwpath);
                fwprintf(pFilecmd, L"set _ROSBE_TARGET_MINGWPATH=%s\n", mingwpath);
            }
        }
    }

    if (pFileps1)
    {
        fwprintf(pFileps1, L"#\n");
        fwprintf(pFileps1, L"# This file has been automatically generated by the ReactOS\n");
        fwprintf(pFileps1, L"# Build Environment options utility.\n");
        fwprintf(pFileps1, L"#\n\n");
        fwprintf(pFileps1, L"(Get-Host).UI.RawUI.ForegroundColor = 0x%X\n", foreground);
        fwprintf(pFileps1, L"(Get-Host).UI.RawUI.BackgroundColor = 0x%X\n", background);
        fwprintf(pFileps1, L"clear-host\n");
        fwprintf(pFileps1, L"$global:_ROSBE_SHOWTIME = %d\n", showtime);
        fwprintf(pFileps1, L"$global:_ROSBE_USECCACHE = %d\n", useccache);
        fwprintf(pFileps1, L"$ENV:ROS_LEAN_AND_MEAN=\"%s\"\n", (strip == 1) ? "yes" : "no");
        fwprintf(pFileps1, L"$ENV:ROS_BUILDNOSTRIP=\"%s\"\n", (nostrip == 1) ? "yes" : "no");
        fwprintf(pFileps1, L"$global:_ROSBE_WRITELOG = %d\n", writelog);
        fwprintf(pFileps1, L"$global:_ROSBE_SHOWVERSION = %d\n", showversion);
        fwprintf(pFileps1, L"$global:_ROSBE_SYSPATH = %d\n", syspath);
        if (logdir[0] != 0)
        {
            fwprintf(pFileps1, L"$global:_ROSBE_LOGDIR = \"%s\"\n", logdir);
        }
        if (amd64 || arm)
        {
            if (mingwpath[0] != 0)
            {
                fwprintf(pFileps1, L"$global:_ROSBE_TARGET_MINGWPATH = \"%s\"\n", mingwpath);
            }
        }
        else
        {
            if (mingwpath[0] != 0)
            {
                fwprintf(pFileps1, L"$global:_ROSBE_HOST_MINGWPATH = \"%s\"\n", mingwpath);
                fwprintf(pFileps1, L"$global:_ROSBE_TARGET_MINGWPATH = \"%s\"\n", mingwpath);
            }
        }
    }

    if (pFilecmd && pFileps1)
    {
        fclose(pFilecmd);
        fclose(pFileps1);
        return TRUE;
    }

    if (!pFilecmd)
    {
        fclose(pFileps1);
        LoadStringW(hInstance, MSG_CMDFFAILED, msgerror, 256);
        MessageBoxW(infoPtr->hwndDlg, msgerror, NULL, MB_ICONERROR);
    }

    if (!pFileps1)
    {
        fclose(pFilecmd);
        LoadStringW(hInstance, MSG_PS1FFAILED, msgerror, 256);
        MessageBoxW(infoPtr->hwndDlg, msgerror, NULL, MB_ICONERROR);
    }
    return FALSE;
}

VOID LoadSettings(POPTIONS_DLG infoPtr)
{
    FILE *pFile;
    WCHAR *ptr, *ptr2;
    WCHAR WTempLine[25+MAX_PATH];
    WCHAR SBTitle[256];
    PSETTINGS LoadedSettings = &infoPtr->Settings;

    pFile = _wfopen(getConfigFileCMD(), L"r");
    if (pFile)
    {
        while (fgetws(WTempLine, 24+MAX_PATH, pFile))
        {
            ptr = wcstok(WTempLine, L" ");
            if (wcscmp(ptr, L"color") == 0)
            {
                ptr = wcstok(NULL, L" ");
                ptr[2] = ptr[1];
                ptr[1] = 0;
                LoadedSettings->background = wcstol(&ptr[0], NULL, 16);
                LoadedSettings->foreground = wcstol(&ptr[2], NULL, 16);
            }
            else if (wcscmp(ptr, L"set") == 0)
            {
                ptr = wcstok(NULL, L"\0");
                ptr = wcstok(ptr, L"=");
                ptr2 = wcstok(NULL, L"=");
                if (wcscmp(ptr, L"_ROSBE_SHOWTIME") == 0)
                {
                    LoadedSettings->showtime = wcstol(ptr2, NULL, 2);
                }
                else if (wcscmp(ptr, L"_ROSBE_USECCACHE") == 0)
                {
                    LoadedSettings->useccache = wcstol(ptr2, NULL, 2);
                }
                else if (wcscmp(ptr, L"ROS_LEAN_AND_MEAN") == 0)
                {
                    wcsncpy(LoadedSettings->lstrip, ptr2, wcslen(ptr2)-1);
                }
                else if (wcscmp(ptr, L"ROS_BUILDNOSTRIP") == 0)
                {
                    wcsncpy(LoadedSettings->lnostrip, ptr2, wcslen(ptr2)-1);
                }
                else if (wcscmp(ptr, L"_ROSBE_WRITELOG") == 0)
                {
                    LoadedSettings->writelog = wcstol(ptr2, NULL, 2);
                }
                else if (wcscmp(ptr, L"_ROSBE_SHOWVERSION") == 0)
                {
                    LoadedSettings->showversion = wcstol(ptr2, NULL, 2);
                }
                else if (wcscmp(ptr, L"_ROSBE_SYSPATH") == 0)
                {
                    LoadedSettings->syspath = wcstol(ptr2, NULL, 2);
                }
                else if (wcscmp(ptr, L"_ROSBE_LOGDIR") == 0)
                {
                    wcsncpy(LoadedSettings->logdir, ptr2, wcslen(ptr2)-1);
                }
                else if ((amd64 || arm) && (wcscmp(ptr, L"_ROSBE_TARGET_MINGWPATH") == 0))
                {
                    wcsncpy(LoadedSettings->mingwpath, ptr2, wcslen(ptr2)-1);
                }
                else if ((!(amd64 || arm)) && (wcscmp(ptr, L"_ROSBE_HOST_MINGWPATH") == 0))
                {
                    wcsncpy(LoadedSettings->mingwpath, ptr2, wcslen(ptr2)-1);
                }
            }
        }
        fclose(pFile);
        LoadStringW(hInstance, MSG_SETLOADSUC, SBTitle, 256);
        SetDlgItemTextW(infoPtr->hwndDlg, ID_STATUSBAR, SBTitle);
    }
    else
    {
        if (amd64)
        {
            LoadedSettings->foreground = 0xb;
        }
        else if (arm)
        {
            LoadedSettings->foreground = 0xe;
        }
        else
        {
            LoadedSettings->foreground = 0xa;
        }
        LoadedSettings->background = 0;
        LoadedSettings->showtime = 1;
        LoadedSettings->writelog = 1;
        LoadedSettings->showversion = 0;
        LoadedSettings->syspath = 1;
        GetCurrentDirectory(MAX_PATH, LoadedSettings->mingwpath);
        if (amd64)
        {
            if ((wcslen(LoadedSettings->mingwpath) + wcslen(MINGWVERSION64)) < MAX_PATH)
            {
                wcscat(LoadedSettings->mingwpath, MINGWVERSION64);
            }
        }
        else if (arm)
        {
            if ((wcslen(LoadedSettings->mingwpath) + wcslen(MINGWVERSIONARM)) < MAX_PATH)
            {
                wcscat(LoadedSettings->mingwpath, MINGWVERSIONARM);
            }
        }
        else
        {
            if ((wcslen(LoadedSettings->mingwpath) + wcslen(MINGWVERSION)) < MAX_PATH)
            {
                wcscat(LoadedSettings->mingwpath, MINGWVERSION);
            }
        }

        LoadStringW(hInstance, HLP_DEFAULTMSG, SBTitle, 256);
        SetDlgItemTextW(infoPtr->hwndDlg, ID_STATUSBAR, SBTitle);
    }

    if (!wcscmp(LoadedSettings->lstrip, L"yes"))
    {
        LoadedSettings->strip = 1;
    }
    else
    {
        LoadedSettings->strip = 0;
    }
    if (!wcscmp(LoadedSettings->lnostrip, L"yes"))
    {
        LoadedSettings->nostrip = 1;
    }
    else
    {
        LoadedSettings->nostrip = 0;
    }
    SendDlgItemMessageW(infoPtr->hwndDlg, IDC_FONT, CB_SETCURSEL, LoadedSettings->foreground, 0);
    SendDlgItemMessageW(infoPtr->hwndDlg, IDC_BACK, CB_SETCURSEL, LoadedSettings->background, 0);
    SendDlgItemMessageW(infoPtr->hwndDlg, ID_SHOWBUILDTIME, BM_SETCHECK, LoadedSettings->showtime, 0);
    SendDlgItemMessageW(infoPtr->hwndDlg, ID_SHOWVERSION, BM_SETCHECK, LoadedSettings->showversion, 0);
    SendDlgItemMessageW(infoPtr->hwndDlg, ID_SYSPATH, BM_SETCHECK, LoadedSettings->syspath, 0);
    SendDlgItemMessageW(infoPtr->hwndDlg, ID_SAVELOGS, BM_SETCHECK, LoadedSettings->writelog, 0);
    if (LoadedSettings->writelog)
    {
        EnableWindow(GetDlgItem(infoPtr->hwndDlg, ID_BROWSE), TRUE);
        EnableWindow(GetDlgItem(infoPtr->hwndDlg, ID_LOGDIR), TRUE);
    }
    SendDlgItemMessageW(infoPtr->hwndDlg, ID_USECCACHE, BM_SETCHECK, LoadedSettings->useccache, 0);
    SendDlgItemMessageW(infoPtr->hwndDlg, ID_STRIP, BM_SETCHECK, LoadedSettings->strip, 0);
    SendDlgItemMessageW(infoPtr->hwndDlg, ID_NOSTRIP, BM_SETCHECK, LoadedSettings->nostrip, 0);
    SetDlgItemTextW(infoPtr->hwndDlg, ID_MGWDIR, LoadedSettings->mingwpath);
    SetDlgItemTextW(infoPtr->hwndDlg, ID_LOGDIR, LoadedSettings->logdir);
}

VOID SetSaveState(POPTIONS_DLG infoPtr)
{
    INT foreground, background;
    BOOL showtime, writelog, useccache, strip, nostrip, showversion, syspath;
    WCHAR logdir[MAX_PATH], mingwpath[MAX_PATH];
    BOOL StateLog = TRUE, State = TRUE;
    PSETTINGS DefaultSettings = &infoPtr->Settings;

    if (!wcscmp(DefaultSettings->lstrip, L"yes"))
    {
        DefaultSettings->strip = 1;
    }
    else
    {
        DefaultSettings->strip = 0;
    }
    if (!wcscmp(DefaultSettings->lnostrip, L"yes"))
    {
        DefaultSettings->nostrip = 1;
    }
    else
    {
        DefaultSettings->nostrip = 0;
    }

    showtime = (SendDlgItemMessageW(infoPtr->hwndDlg, ID_SHOWBUILDTIME, BM_GETCHECK, 0, 0) == BST_CHECKED);
    writelog = (SendDlgItemMessageW(infoPtr->hwndDlg, ID_SAVELOGS, BM_GETCHECK, 0, 0) == BST_CHECKED);
    useccache = (SendDlgItemMessageW(infoPtr->hwndDlg, ID_USECCACHE, BM_GETCHECK, 0, 0) == BST_CHECKED);
    strip = (SendDlgItemMessageW(infoPtr->hwndDlg, ID_STRIP, BM_GETCHECK, 0, 0) == BST_CHECKED);
    nostrip = (SendDlgItemMessageW(infoPtr->hwndDlg, ID_NOSTRIP, BM_GETCHECK, 0, 0) == BST_CHECKED);
    showversion = (SendDlgItemMessageW(infoPtr->hwndDlg, ID_SHOWVERSION, BM_GETCHECK, 0, 0) == BST_CHECKED);
    syspath = (SendDlgItemMessageW(infoPtr->hwndDlg, ID_SYSPATH, BM_GETCHECK, 0, 0) == BST_CHECKED);
    foreground = (INT) SendDlgItemMessageW(infoPtr->hwndDlg, IDC_FONT, CB_GETCURSEL, 0, 0);
    background = (INT) SendDlgItemMessageW(infoPtr->hwndDlg, IDC_BACK, CB_GETCURSEL, 0, 0);
    GetDlgItemTextW(infoPtr->hwndDlg, ID_LOGDIR, logdir, MAX_PATH);
    GetDlgItemTextW(infoPtr->hwndDlg, ID_MGWDIR, mingwpath, MAX_PATH);

    if (writelog)
    {
        if ((wcscmp(logdir, DefaultSettings->logdir) != 0) && (wcslen(logdir) > 0))
        {
            StateLog = FALSE;
        }
    }

    State ^= ((foreground == DefaultSettings->foreground) && (background == DefaultSettings->background) &&
            (showtime == DefaultSettings->showtime) && (writelog == DefaultSettings->writelog) &&
            (useccache == DefaultSettings->useccache) && (strip == DefaultSettings->strip) &&
            (StateLog) && (wcscmp(mingwpath, DefaultSettings->mingwpath) == 0) &&
            (nostrip == DefaultSettings->nostrip) && (showversion == DefaultSettings->showversion) &&
            (syspath == DefaultSettings->syspath));

    EnableWindow(GetDlgItem(infoPtr->hwndDlg, ID_OK), State);
}

INT CALLBACK
BrowseProc(HWND Dlg, UINT Msg, WPARAM wParam, LPARAM lParam)
{
    HWND hwndParent;
    hwndParent = GetWindow(Dlg, GW_OWNER);
    switch (Msg)
    {
        case BFFM_INITIALIZED:
        {
            WCHAR ActualPath[MAX_PATH];
            GetDlgItemTextW(hwndParent, (INT) lParam, ActualPath, MAX_PATH);
            SendMessage(Dlg, BFFM_SETSELECTION, TRUE, (LPARAM)ActualPath);
            break;
        }
        case BFFM_VALIDATEFAILED:
        {
            if (lParam != ID_MGWDIR)
            {
                WCHAR BoxMsg[256], BoxTitle[128];
                size_t PathLen;
                LoadStringW(hInstance, MSG_WARNINGBOX, BoxTitle, 128);
                LoadStringW(hInstance, MSG_INVALIDDIR, BoxMsg, 256);
                if (MessageBoxW(Dlg, BoxMsg, BoxTitle, MB_ICONWARNING | MB_YESNO) == IDYES)
                {
                    PathLen = wcslen((LPWSTR)wParam);
                    if (wcscmp((LPWSTR)wParam+PathLen, L"\\"))
                    {
                        wcsset((LPWSTR)wParam+(PathLen-1), '\0');
                    }
                    if (CreateDirectory((LPWSTR)wParam, NULL) == 0)
                    {
                        LoadStringW(hInstance, MSG_DIREFAILED, BoxMsg, 256);
                        MessageBoxW(Dlg, BoxMsg, NULL, MB_ICONERROR);
                    }
                    else
                    {
                        SetDlgItemTextW(hwndParent, (INT) lParam, (LPWSTR)wParam);
                    }
                }
            }
            break;
        }
    }
    return FALSE;
}

static VOID
AssociateToolWithControl(POPTIONS_DLG infoPtr, int ControlId, UINT StringId)
{
    HWND hwndControl;
    TOOLINFO ti;

    hwndControl = GetDlgItem(infoPtr->hwndDlg, ControlId);
    if (infoPtr->hwndToolTip && hwndControl)
    {
        ZeroMemory(&ti, sizeof(ti));
        ti.cbSize = sizeof(ti);
        ti.uFlags = TTF_IDISHWND | TTF_SUBCLASS;
        ti.hwnd = infoPtr->hwndDlg;
        ti.uId = (UINT_PTR)hwndControl;
        ti.hinst = hInstance;
        ti.lpszText = MAKEINTRESOURCE(StringId);

        SendMessage(infoPtr->hwndToolTip, TTM_ADDTOOL, 0, (LPARAM)&ti);
    }
}

INT_PTR CALLBACK
DlgProc(HWND Dlg, UINT Msg, WPARAM wParam, LPARAM lParam)
{
    POPTIONS_DLG infoPtr = NULL;

    if (Msg != WM_INITDIALOG)
    {
        infoPtr = (POPTIONS_DLG)GetWindowLongPtr(Dlg, DWLP_USER);
        if (infoPtr == NULL)
        {
            return FALSE;
        }
    }

    switch (Msg)
    {
        case WM_INITDIALOG:
        {
            static const struct {
                int ControlId;
                UINT StringId;
            } ToolTipAssociations[] = {
                {IDC_BACK, HLP_BACKCOLORC},
                {IDC_FONT, HLP_FONTCOLORC},
                {ID_SHOWBUILDTIME, HLP_SBUILDTIME},
                {ID_USECCACHE, HLP_CCACHEUSED},
                {ID_STRIP, HLP_STRIPEDEXE},
                {ID_NOSTRIP, HLP_NOSTRIP},
                {ID_MGWDIR, HLP_FINDMGWDIR},
                {ID_BROWSEMGW, HLP_FINDMGWDIR},
                {ID_LOGDIR, HLP_FINDLOGDIR},
                {ID_BROWSE, HLP_FINDLOGDIR},
                {ID_SAVELOGS, HLP_FINDLOGDIR},
                {ID_SHOWVERSION, HLP_VERSION},
                {ID_SYSPATH, HLP_SYSPATH},
                {ID_OK, HLP_SAVEBUTTON},
                {ID_CANCEL, HLP_QUITBUTTON},
            };
            int i;
            UINT j;
            LOGFONT lf;
            WCHAR TempColor[256];

            infoPtr = (POPTIONS_DLG)lParam;
            infoPtr->hwndDlg = Dlg;

            SetWindowLongPtr(Dlg, DWLP_USER, (LONG_PTR)infoPtr);

            infoPtr->hwndToolTip = CreateWindowEx(0,
                                                  TOOLTIPS_CLASS,
                                                  NULL,
                                                  WS_POPUP | TTS_ALWAYSTIP,
                                                  CW_USEDEFAULT,
                                                  CW_USEDEFAULT,
                                                  CW_USEDEFAULT,
                                                  CW_USEDEFAULT,
                                                  infoPtr->hwndDlg,
                                                  NULL,
                                                  hInstance,
                                                  NULL);

            for (i = 0; i < sizeof(ToolTipAssociations) / sizeof(ToolTipAssociations[0]); i++)
            {
                AssociateToolWithControl(infoPtr, ToolTipAssociations[i].ControlId, ToolTipAssociations[i].StringId);
            }

            infoPtr->hIcon = LoadImage( hInstance,
                                        MAKEINTRESOURCE(ID_OPTICON),
                                        IMAGE_ICON,
                                        GetSystemMetrics(SM_CXSMICON),
                                        GetSystemMetrics(SM_CYSMICON),
                                        0);
            if(infoPtr->hIcon)
            {
                SendMessage(Dlg, WM_SETICON, ICON_SMALL, (LPARAM)infoPtr->hIcon);
            }

            GetObject(GetStockObject(ANSI_FIXED_FONT), sizeof(LOGFONT),  &lf);
            lf.lfWeight = FW_BOLD;
            infoPtr->hFont = CreateFont(lf.lfHeight, lf.lfWidth,  lf.lfEscapement, lf.lfOrientation, lf.lfWeight,
            lf.lfItalic, lf.lfUnderline, lf.lfStrikeOut, lf.lfCharSet,  lf.lfOutPrecision,
            lf.lfClipPrecision, lf.lfQuality,  lf.lfPitchAndFamily, lf.lfFaceName);

            for(j = 0; j < 16; j++)
            {
                LoadStringW(hInstance, j, TempColor, 256);
                SendDlgItemMessageW(Dlg, IDC_BACK, CB_ADDSTRING, 0, (LPARAM) TempColor);
                SendDlgItemMessageW(Dlg, IDC_FONT, CB_ADDSTRING, 0, (LPARAM) TempColor);
            }
            LoadSettings(infoPtr);
            return TRUE;
        }

        case WM_COMMAND:
        {
            if ((HIWORD(wParam) == CBN_SELCHANGE) && ((LOWORD(wParam) == IDC_FONT) || (LOWORD(wParam) == IDC_BACK)))
            {
                InvalidateRect(GetDlgItem(Dlg, ID_EXAMPLE), NULL, FALSE);
            }
            else
            {
                switch (wParam)
                {
                    case ID_OK:
                    {
                       if (!WriteSettings(infoPtr))
                       {
                            break;
                       }
                    }
                    case ID_CANCEL:
                    {
                        WCHAR BoxMsg[256], BoxTitle[128];
                        if ((IsWindowEnabled(GetDlgItem(Dlg, ID_OK))) && (wParam == ID_CANCEL))
                        {
                            LoadStringW(hInstance, MSG_WARNINGBOX, BoxTitle, 128);
                            LoadStringW(hInstance, MSG_EXITCHANGE, BoxMsg, 256);
                            if (MessageBoxW(Dlg, BoxMsg, BoxTitle, MB_ICONWARNING | MB_YESNO) == IDNO)
                            {
                                break;
                            }
                        }
                        PostMessage(Dlg, WM_CLOSE, 0, 0);
                        break;
                    }
                    case ID_BROWSE:
                    case ID_BROWSEMGW:
                    {
                        BROWSEINFO PathInfo;
                        LPITEMIDLIST pidl;
                        LPMALLOC pMalloc;
                        INT Control = ID_LOGDIR;
                        INT IDText = MSG_FINDLOGDIR;
                        WCHAR path[MAX_PATH];
                        WCHAR Text[512];

                        if (SHGetMalloc(&pMalloc) == NOERROR)
                        {
                            ZeroMemory(&PathInfo, sizeof(BROWSEINFO));
                            PathInfo.hwndOwner = Dlg;
                            PathInfo.ulFlags = BIF_EDITBOX | BIF_VALIDATE;
                            PathInfo.lpfn = (BFFCALLBACK)BrowseProc;
                            PathInfo.lParam = ID_LOGDIR;
                            PathInfo.pidlRoot = NULL;
                            if (wParam == ID_BROWSEMGW)
                            {
                                Control = ID_MGWDIR;
                                IDText = MSG_FINDMGWDIR;
                                PathInfo.lParam = Control;
                            }
                            LoadStringW(hInstance, IDText, Text, 512);
                            PathInfo.lpszTitle = Text;
                            if ((pidl = SHBrowseForFolder(&PathInfo)) != NULL)
                            {
                                if (SHGetPathFromIDList(pidl, path))
                                {
                                    SetDlgItemTextW(Dlg, Control, path);
                                }
                                pMalloc->lpVtbl->Free(pMalloc, pidl);
                            }
                            pMalloc->lpVtbl->Release(pMalloc);
                        }
                        break;
                    }
                    case ID_SAVELOGS:
                    {
                        BOOL WriteLogSet;
                        INT Dialog1 = ID_BROWSE;
                        INT Dialog2 = ID_LOGDIR;
                        WriteLogSet = (SendDlgItemMessageW(Dlg, (INT)wParam, BM_GETCHECK, 0, 0) == BST_CHECKED);
                        EnableWindow(GetDlgItem(Dlg, Dialog1), WriteLogSet);
                        EnableWindow(GetDlgItem(Dlg, Dialog2), WriteLogSet);
                        break;
                    }
                }

            }
            SetSaveState(infoPtr);
            return FALSE;
        }

        case WM_CTLCOLORSTATIC:
        {
            HFONT hFontOld;
            // note: do not change the order - it matches to previous order
            static const COLORREF ColorsRGB[] = { 0x00000000, 0x00800000, 0x00008000, 0x00808000, 0x00000080, 0x00800080,
                0x00008080, 0x00c0c0c0, 0x00808080, 0x00ff0000, 0x0000ff00,
                0x00ffff00, 0x000000ff, 0x00ff00ff, 0x0000ffff, 0x00ffffff
            };

            if((HWND)lParam == GetDlgItem(Dlg, ID_EXAMPLE))
            {
                hFontOld = SelectObject((HDC)wParam, infoPtr->hFont);
                SetTextColor((HDC)wParam, ColorsRGB[SendDlgItemMessageW(Dlg, IDC_FONT, CB_GETCURSEL, 0, 0)]);
                SetBkColor((HDC)wParam, ColorsRGB[SendDlgItemMessageW(Dlg, IDC_BACK, CB_GETCURSEL, 0, 0)]);
                return (INT_PTR)CreateSolidBrush(ColorsRGB[SendDlgItemMessageW(Dlg, IDC_BACK, CB_GETCURSEL, 0, 0)]);
            }
            break;
        }

        case WM_DESTROY:
        {
            if (infoPtr->hIcon)
            {
                DestroyIcon(infoPtr->hIcon);
            }
            if (infoPtr->hFont)
            {
                DeleteObject(infoPtr->hFont);
            }
        }

        case WM_CLOSE:
        {
            EndDialog(Dlg, 0);
            return TRUE;
        }
    }
    return FALSE;
}

int WINAPI
WinMain(HINSTANCE hInst, HINSTANCE hPrevInst, LPSTR cmdline, int cmdshow)
{
    POPTIONS_DLG OptionsDlgInfo;
    hInstance = hInst;

    if (strcmp(cmdline,"amd64") == 0)
    {
        amd64 = TRUE;
        arm = FALSE;
    }

    if (strcmp(cmdline,"arm") == 0)
    {
        amd64 = FALSE;
        arm = TRUE;
    }

    OptionsDlgInfo = HeapAlloc(GetProcessHeap(), 0, sizeof(*OptionsDlgInfo));
    if (OptionsDlgInfo != NULL)
    {
        ZeroMemory(OptionsDlgInfo, sizeof(OPTIONS_DLG));
        if (amd64)
        {
            DialogBoxParamW(hInst, MAKEINTRESOURCE(ID_DIALOG64), 0, DlgProc, (LPARAM)OptionsDlgInfo);
        }
        else if (arm)
        {
            DialogBoxParamW(hInst, MAKEINTRESOURCE(ID_DIALOGARM), 0, DlgProc, (LPARAM)OptionsDlgInfo);
        }
        else
        {
            DialogBoxParamW(hInst, MAKEINTRESOURCE(ID_DIALOG), 0, DlgProc, (LPARAM)OptionsDlgInfo);
        }
        HeapFree(GetProcessHeap(), 0, OptionsDlgInfo);
    }
    return 0;
}
