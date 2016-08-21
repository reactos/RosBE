Unicode true
!define PRODUCT_NAME "ReactOS Build Environment Amine Edition"
!define PRODUCT_VERSION "2.1.4"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\RosBE.cmd"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKCU"
!define PRODUCT_STARTMENU_REGVAL "NSIS:StartMenuDir"

;;
;; Basic installer options
;;
Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "RosBE-${PRODUCT_VERSION}.exe"
InstallDirRegKey HKCU "${PRODUCT_DIR_REGKEY}" ""
ShowInstDetails show
ShowUnInstDetails show

;;
;; Add version/product information metadata to the installation file.
;;
VIAddVersionKey /LANG=1033 "FileVersion" "2.1.4.0"
VIAddVersionKey /LANG=1033 "ProductVersion" "${PRODUCT_VERSION}"
VIAddVersionKey /LANG=1033 "ProductName" "${PRODUCT_NAME}"
VIAddVersionKey /LANG=1033 "Comments" "This installer was written by Peter Ward and Daniel Reimer using Nullsoft Scriptable Install System"
VIAddVersionKey /LANG=1033 "CompanyName" "ReactOS Foundation"
VIAddVersionKey /LANG=1033 "LegalTrademarks" "Copyright © 2015 ReactOS Foundation"
VIAddVersionKey /LANG=1033 "LegalCopyright" "Copyright © 2015 ReactOS Foundation"
VIAddVersionKey /LANG=1033 "FileDescription" "${PRODUCT_NAME} Setup"
VIProductVersion "2.1.4.0"

CRCCheck force
SetDatablockOptimize on
XPStyle on
SetCompressor /FINAL /SOLID lzma

!include "MUI2.nsh"
!include "InstallOptions.nsh"
!include "RosSourceDir.nsh"
!include "LogicLib.nsh"
!include "EnvVarUpdate.nsh"
!include "AddCertificateToStore.nsh"

;;
;; Read our custom page ini, remove previous version and make sure only
;; one instance of the installer is running.
;;
Function .onInit
    ReadRegStr $R3 HKLM \
    "SOFTWARE\Microsoft\Windows NT\CurrentVersion" CurrentVersion
    StrCpy $R4 $R3 3
    System::Call 'kernel32::CreateMutexA(i 0, i 0, t "RosBE-v${PRODUCT_VERSION}-Installer") i .r1 ?e'
    Pop $R0
    StrCmp $R0 0 +3
        MessageBox MB_OK|MB_ICONEXCLAMATION "The ${PRODUCT_NAME} v${PRODUCT_VERSION} installer is already running."
        Abort
    StrCpy $INSTDIR "C:\RosBE"
    Call UninstallPrevious
    !insertmacro INSTALLOPTIONS_EXTRACT "RosSourceDir.ini"
FunctionEnd

;;
;; MUI Settings
;;
!define MUI_ABORTWARNING
!define MUI_ICON "Icons\rosbe.ico"
!define MUI_UNICON "Icons\uninstall.ico"
!define MUI_COMPONENTSPAGE_NODESC

!define MUI_WELCOMEPAGE_TITLE_3LINES
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "Root\License.txt"
!insertmacro MUI_PAGE_DIRECTORY

;;
;; ReactOS Source Directory Pages
;;
var REACTOS_SOURCE_DIRECTORY
!insertmacro CUSTOM_PAGE_ROSDIRECTORY

;;
;; Start menu page
;;
var ICONS_GROUP
!define MUI_STARTMENUPAGE_NODISABLE
!define MUI_STARTMENUPAGE_DEFAULTFOLDER "ReactOS Build Environment"
!define MUI_STARTMENUPAGE_REGISTRY_ROOT "${PRODUCT_UNINST_ROOT_KEY}"
!define MUI_STARTMENUPAGE_REGISTRY_KEY "${PRODUCT_UNINST_KEY}"
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "${PRODUCT_STARTMENU_REGVAL}"
!insertmacro MUI_PAGE_STARTMENU Application $ICONS_GROUP

!insertmacro MUI_PAGE_COMPONENTS

!insertmacro MUI_PAGE_INSTFILES

!define MUI_FINISHPAGE_TITLE_3LINES
!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\README.pdf"
!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
!insertmacro MUI_PAGE_FINISH

;;
;; Uninstaller pages
;;
!insertmacro MUI_UNPAGE_INSTFILES

;;
;;  Language and reserve files
;;
ReserveFile /plugin InstallOptions.dll
!insertmacro MUI_LANGUAGE "English"

Section -BaseFiles SEC01
    SetShellVarContext current
    SetOutPath "$INSTDIR"
    SetOverwrite try
    File /r Icons\rosbe.ico
    File /r Root\Basedir.cmd
    File /r Root\Build-Shared.cmd
    File /r Root\changelog.txt
    File /r Root\charch.cmd
    File /r Root\chdefdir.cmd
    File /r Root\chdefgcc.cmd
    File /r Root\Clean.cmd
    File /r Root\Help.cmd
    File /r Root\kdbg.cmd
    File /r Root\LICENSE.txt
    File /r Root\Make.cmd
    File /r Root\Makex.cmd
    File /r Root\options.cmd
    File /r Root\raddr2line.cmd
    File /r Root\raddr2lineNW.cmd
    File /r Root\README.pdf
    File /r Root\Remake.cmd
    File /r Root\Remakex.cmd
    File /r Root\Renv.cmd
    File /r Root\RosBE.cmd
    File /r Root\rosbe-gcc-env.cmd
    File /r Root\scut.cmd
    File /r Root\sSVN.cmd
    File /r Root\TimeDate.cmd
    File /r Root\update.cmd
    File /r Root\version.cmd
    SetOutPath "$INSTDIR\share"
    SetOverwrite try
    File /r Root\share\*.*
    SetOutPath "$INSTDIR\Bin"
    SetOverwrite try
    File /r Components\Bin\7z.dll
    File /r Components\Bin\7z.exe
    File /r Components\Bin\apr_ldap-1.dll
    File /r Components\Bin\bison.exe
    File /r Components\Bin\buildtime.exe
    File /r Components\Bin\ccache.exe
    File /r Components\Bin\chknewer.exe
    File /r Components\Bin\chkslash.exe
    File /r Components\Bin\cmake.exe
    File /r Components\Bin\cmcldeps.exe
    File /r Components\Bin\cmp.exe
    File /r Components\Bin\cmw9xcom.exe
    File /r Components\Bin\cpack.exe
    File /r Components\Bin\cpucount.exe
    File /r Components\Bin\ctest.exe
    File /r Components\Bin\diff.exe
    File /r Components\Bin\diff3.exe
    File /r Components\Bin\diff4.exe
    File /r Components\Bin\echoh.exe
    File /r Components\Bin\elevate.exe
    File /r Components\Bin\flash.exe
    File /r Components\Bin\flex.exe
    File /r Components\Bin\gdb.exe
    File /r Components\Bin\gdbserver.exe
    File /r Components\Bin\getdate.exe
    File /r Components\Bin\libapr-1.dll
    File /r Components\Bin\libapriconv-1.dll
    File /r Components\Bin\libaprutil-1.dll
    File /r Components\Bin\libeay32.dll
    File /r Components\Bin\libexpat-1.dll
    File /r Components\Bin\libgcc_s_dw2-1.dll
    File /r Components\Bin\libiconv2.dll
    File /r Components\Bin\libiconv-2.dll
    File /r Components\Bin\libintl3.dll
    File /r Components\Bin\libintl-8.dll
    File /r Components\Bin\libsasl.dll
    File /r Components\Bin\libsvn_client-1.dll
    File /r Components\Bin\libsvn_delta-1.dll
    File /r Components\Bin\libsvn_diff-1.dll
    File /r Components\Bin\libsvn_fs-1.dll
    File /r Components\Bin\libsvn_ra-1.dll
    File /r Components\Bin\libsvn_repos-1.dll
    File /r Components\Bin\libsvn_subr-1.dll
    File /r Components\Bin\libsvn_wc-1.dll
    File /r Components\Bin\libsvnjavahl-1.dll
    File /r Components\Bin\log2lines.exe
    File /r Components\Bin\m4.exe
    File /r Components\Bin\Microsoft.VC90.CRT.manifest
    File /r Components\Bin\mingw32-make.exe
    File /r Components\Bin\msys-1.0.dll
    File /r Components\Bin\MSVCM90.dll
    File /r Components\Bin\msvcp60.dll
    File /r Components\Bin\MSVCP90.dll
    File /r Components\Bin\MSVCP100.dll
    File /r Components\Bin\MSVCP120.dll
    File /r Components\Bin\MSVCR90.dll
    File /r Components\Bin\MSVCR100.dll
    File /r Components\Bin\MSVCR120.dll
    File /r Components\Bin\ninja.exe
    File /r Components\Bin\options.exe
    File /r Components\Bin\patch.exe
    File /r Components\Bin\patch.exe.manifest
    File /r Components\Bin\pexports.exe
    File /r Components\Bin\piperead.exe
    File /r Components\Bin\playwav.exe
    File /r Components\Bin\regex2.dll
    File /r Components\Bin\rquote.exe
    File /r Components\Bin\saslANONYMOUS.dll
    File /r Components\Bin\saslCRAMMD5.dll
    File /r Components\Bin\saslDIGESTMD5.dll
    File /r Components\Bin\saslLOGIN.dll
    File /r Components\Bin\saslNTLM.dll
    File /r Components\Bin\saslPLAIN.dll
    File /r Components\Bin\scut.exe
    File /r Components\Bin\sdiff.exe
    File /r Components\Bin\ssleay32.dll
    File /r Components\Bin\svn.exe
    File /r Components\Bin\svnadmin.exe
    File /r Components\Bin\svnauthz.exe
    File /r Components\Bin\svnauthz-validate.exe
    File /r Components\Bin\svndumpfilter.exe
    File /r Components\Bin\svnlook.exe
    File /r Components\Bin\svnmucc.exe
    File /r Components\Bin\svn-populate-node-origins-index.exe
    File /r Components\Bin\svnraisetreeconflict.exe
    File /r Components\Bin\svnrdump.exe
    File /r Components\Bin\svnserve.exe
    File /r Components\Bin\svnsync.exe
    File /r Components\Bin\svnversion.exe
    File /r Components\Bin\tee.exe
    File /r Components\Bin\wget.exe
    File /r Components\Bin\zlib1.dll
    SetOutPath "$INSTDIR\Bin\iconv"
    SetOverwrite try
    File /r Components\Bin\iconv\*.*
    SetOutPath "$INSTDIR\Bin\license"
    SetOverwrite try
    File /r Components\Bin\license\*.*
    SetOutPath "$INSTDIR\Bin\data"
    SetOverwrite try
    File /r Components\Bin\data\*.*
    SetOutPath "$INSTDIR\samples"
    SetOverwrite try
    File /r Components\samples\*.*
SectionEnd

Section -MinGWGCCNASM SEC02
    SetShellVarContext current
    SetOutPath "$INSTDIR\i386"
    SetOverwrite try
    File /r Components\i386\*.*
SectionEnd

Section /o "Add BIN folder to PATH variable (MSVC users)" SEC03
    ${EnvVarUpdate} $0 "PATH" "A" "HKCU" "$INSTDIR\bin"
SectionEnd

Section /o "Update for GlobalSign Certificates (XP users NEED THAT)" SEC04
    SetShellVarContext current
    SetOutPath "$INSTDIR\certs"
    SetOverwrite try
    File /r Components\certs\Root-R1.crt
    File /r Components\certs\Root-R2.crt
    File /r Components\certs\Root-R3.crt
    
    Push "$INSTDIR\certs\Root-R1.crt"
    Call AddCertificateToStore
    Pop $0
    ${If} $0 != success
        MessageBox MB_OK "Import of R1 GlobalSign Root Certificate failed: $0"
    ${EndIf}
    Push "$INSTDIR\certs\Root-R2.crt"
    Call AddCertificateToStore
    Pop $0
    ${If} $0 != success
        MessageBox MB_OK "Import of R1 GlobalSign Root Certificate failed: $0"
    ${EndIf}
    Push "$INSTDIR\certs\Root-R3.crt"
    Call AddCertificateToStore
    Pop $0
    ${If} $0 != success
        MessageBox MB_OK "Import of R1 GlobalSign Root Certificate failed: $0"
    ${EndIf}
SectionEnd

Section /o "PowerShell Version" SEC05
    SetShellVarContext current
    SetOutPath "$INSTDIR"
    SetOverwrite try
    File /r Components\Powershell\Build.ps1
    File /r Components\Powershell\charch.ps1
    File /r Components\Powershell\chdefdir.ps1
    File /r Components\Powershell\chdefgcc.ps1
    File /r Components\Powershell\Clean.ps1
    File /r Components\Powershell\Help.ps1
    File /r Components\Powershell\kdbg.ps1
    File /r Components\Powershell\options.ps1
    File /r Components\Powershell\playwav.ps1
    File /r Components\Powershell\reladdr2line.ps1
    File /r Components\Powershell\reladdr2lineNW.ps1
    File /r Components\Powershell\Remake.ps1
    File /r Components\Powershell\Remakex.ps1
    File /r Components\Powershell\RosBE.ps1
    File /r Components\Powershell\rosbe-gcc-env.ps1
    File /r Components\Powershell\scut.ps1
    File /r Components\Powershell\sSVN.ps1
    File /r Components\Powershell\update.ps1
    File /r Components\Powershell\version.ps1
    SetOutPath "$DESKTOP"
    SetOverwrite try
    File /r "Components\Powershell\RosBE PS - PostInstall.reg"
    MessageBox MB_ICONINFORMATION|MB_OK \
               "A REG-File was generated on your desktop. Please use it with Admin Rights to set Powershell's execution rights correctly if your RosBE Powershell Version fails to run after install. Otherwise, just delete it."
SectionEnd

Section -StartMenuShortcuts SEC06
    SetShellVarContext current

    ;;
    ;; Add our start menu shortcuts.
    ;;
    IfFileExists "$SMPROGRAMS\$ICONS_GROUP\ReactOS Build Environment ${PRODUCT_VERSION}.lnk" +13 0
        !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
            CreateDirectory "$SMPROGRAMS\$ICONS_GROUP"
            SetOutPath $REACTOS_SOURCE_DIRECTORY
            IfFileExists "$INSTDIR\RosBE.cmd" 0 +2
                CreateShortCut "$SMPROGRAMS\$ICONS_GROUP\ReactOS Build Environment ${PRODUCT_VERSION}.lnk" "$SYSDIR\cmd.exe" '/t:0A /k "$INSTDIR\RosBE.cmd"' "$INSTDIR\rosbe.ico"
            IfFileExists "$INSTDIR\RosBE.ps1" 0 +2
                CreateShortCut "$SMPROGRAMS\$ICONS_GROUP\ReactOS Build Environment ${PRODUCT_VERSION} - PS.lnk" "$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" "-noexit &'$INSTDIR\RosBE.ps1'" "$INSTDIR\rosbe.ico"
            SetOutPath $INSTDIR
            CreateShortCut "$SMPROGRAMS\$ICONS_GROUP\Uninstall RosBE.lnk" \
                           "$INSTDIR\Uninstall.exe"
            CreateShortCut "$SMPROGRAMS\$ICONS_GROUP\Readme.lnk" \
                           "$INSTDIR\README.pdf"
            CreateShortCut "$SMPROGRAMS\$ICONS_GROUP\Options.lnk" \
                           "$INSTDIR\Bin\options.exe"
    !insertmacro MUI_STARTMENU_WRITE_END
SectionEnd

Section /o "Desktop Shortcuts" SEC07
    SetShellVarContext all

    ;;
    ;; Add our desktop shortcuts.
    ;;
    IfFileExists "$DESKTOP\ReactOS Build Environment ${PRODUCT_VERSION}.lnk" +6 0
        SetOutPath $REACTOS_SOURCE_DIRECTORY
        IfFileExists "$INSTDIR\RosBE.cmd" 0 +2
            CreateShortCut "$DESKTOP\ReactOS Build Environment ${PRODUCT_VERSION}.lnk" "$SYSDIR\cmd.exe" '/t:0A /k "$INSTDIR\RosBE.cmd"' "$INSTDIR\rosbe.ico"
        IfFileExists "$INSTDIR\RosBE.ps1" 0 +2
            CreateShortCut "$DESKTOP\ReactOS Build Environment ${PRODUCT_VERSION} - PS.lnk" "$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" "-noexit &'$INSTDIR\RosBE.ps1'" "$INSTDIR\rosbe.ico"
SectionEnd

Section /o "Quick Launch Shortcuts" SEC08
    SetShellVarContext current

    ;;
    ;; Add our quick launch shortcuts.
    ;;
    IfFileExists "$QUICKLAUNCH\ReactOS Build Environment ${PRODUCT_VERSION}.lnk" +6 0
        SetOutPath $REACTOS_SOURCE_DIRECTORY
        IfFileExists "$INSTDIR\RosBE.cmd" 0 +2
            CreateShortCut "$QUICKLAUNCH\ReactOS Build Environment ${PRODUCT_VERSION}.lnk" "$SYSDIR\cmd.exe" '/t:0A /k "$INSTDIR\RosBE.cmd"' "$INSTDIR\rosbe.ico"
        IfFileExists "$INSTDIR\RosBE.ps1" 0 +2
            CreateShortCut "$QUICKLAUNCH\ReactOS Build Environment ${PRODUCT_VERSION} - PS.lnk" "$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" "-noexit &'$INSTDIR\RosBE.ps1'" "$INSTDIR\rosbe.ico"
SectionEnd

Section -Post SEC09
    WriteUninstaller "$INSTDIR\Uninstall.exe"
    WriteRegStr HKCU "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\RosBE.cmd"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "$(^Name)"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\Uninstall.exe"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
SectionEnd

Function un.onUninstSuccess
    HideWindow
    MessageBox MB_ICONINFORMATION|MB_OK \
               "ReactOS Build Environment was successfully removed from your computer."
FunctionEnd

Function un.onInit
    MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 \
        "Are you sure you want to remove ReactOS Build Environment and all of its components?" \
        IDYES +2
    Abort
    IfFileExists "$APPDATA\RosBE\." 0 +5
        MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 \
        "Do you want to remove the ReactOS Build Environment configuration file from the Application Data Path?" \
        IDNO +2
        RMDir /r /REBOOTOK "$APPDATA\RosBE"
    MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 \
    "Do you want to remove the Shortcuts? If you just want to Update to a new Version of RosBE, keep them. This keeps your previous settings." \
    IDNO +5
        Delete /REBOOTOK "$DESKTOP\ReactOS Build Environment ${PRODUCT_VERSION}.lnk"
        Delete /REBOOTOK "$QUICKLAUNCH\ReactOS Build Environment ${PRODUCT_VERSION}.lnk"
        Delete /REBOOTOK "$DESKTOP\ReactOS Build Environment ${PRODUCT_VERSION} - PS.lnk"
        Delete /REBOOTOK "$QUICKLAUNCH\ReactOS Build Environment ${PRODUCT_VERSION} - PS.lnk"
FunctionEnd

Section Uninstall
    !insertmacro MUI_STARTMENU_GETFOLDER "Application" $ICONS_GROUP
    SetShellVarContext current

    ;;
    ;; Clean up PATH Variable.
    ;;
    ${un.EnvVarUpdate} $0 "PATH" "R" "HKCU" "$INSTDIR\bin"

    ;;
    ;; Clean up installed files.
    ;;
    RMDir /r /REBOOTOK "$INSTDIR\i386"
    RMDir /r /REBOOTOK "$INSTDIR\Bin"
    RMDir /r /REBOOTOK "$INSTDIR\certs"
    RMDir /r /REBOOTOK "$INSTDIR\samples"
    RMDir /r /REBOOTOK "$INSTDIR\share"
    StrCmp $ICONS_GROUP "" NO_SHORTCUTS
    RMDir /r /REBOOTOK "$SMPROGRAMS\$ICONS_GROUP"
    NO_SHORTCUTS:
    Delete /REBOOTOK "$INSTDIR\Basedir.cmd"
    Delete /REBOOTOK "$INSTDIR\Build.ps1"
    Delete /REBOOTOK "$INSTDIR\Build-Shared.cmd"
    Delete /REBOOTOK "$INSTDIR\ChangeLog.txt"
    Delete /REBOOTOK "$INSTDIR\charch.cmd"
    Delete /REBOOTOK "$INSTDIR\charch.ps1"
    Delete /REBOOTOK "$INSTDIR\chdefdir.cmd"
    Delete /REBOOTOK "$INSTDIR\chdefdir.ps1"
    Delete /REBOOTOK "$INSTDIR\chdefgcc.cmd"
    Delete /REBOOTOK "$INSTDIR\chdefgcc.ps1"
    Delete /REBOOTOK "$INSTDIR\Clean.cmd"
    Delete /REBOOTOK "$INSTDIR\Clean.ps1"
    Delete /REBOOTOK "$INSTDIR\Help.cmd"
    Delete /REBOOTOK "$INSTDIR\Help.ps1"
    Delete /REBOOTOK "$INSTDIR\kdbg.cmd"
    Delete /REBOOTOK "$INSTDIR\kdbg.ps1"
    Delete /REBOOTOK "$INSTDIR\LICENSE.txt"
    Delete /REBOOTOK "$INSTDIR\Make.cmd"
    Delete /REBOOTOK "$INSTDIR\Makex.cmd"
    Delete /REBOOTOK "$INSTDIR\options.cmd"
    Delete /REBOOTOK "$INSTDIR\options.ps1"
    Delete /REBOOTOK "$INSTDIR\playwav.ps1"
    Delete /REBOOTOK "$INSTDIR\raddr2line.cmd"
    Delete /REBOOTOK "$INSTDIR\raddr2lineNW.cmd"
    Delete /REBOOTOK "$INSTDIR\README.pdf"
    Delete /REBOOTOK "$INSTDIR\reladdr2line.ps1"
    Delete /REBOOTOK "$INSTDIR\reladdr2lineNW.ps1"
    Delete /REBOOTOK "$INSTDIR\Remake.cmd"
    Delete /REBOOTOK "$INSTDIR\Remakex.cmd"
    Delete /REBOOTOK "$INSTDIR\Remake.ps1"
    Delete /REBOOTOK "$INSTDIR\Remakex.ps1"
    Delete /REBOOTOK "$INSTDIR\Renv.cmd"
    Delete /REBOOTOK "$INSTDIR\RosBE PS - PostInstall.reg"
    Delete /REBOOTOK "$INSTDIR\RosBE.cmd"
    Delete /REBOOTOK "$INSTDIR\rosbe.ico"
    Delete /REBOOTOK "$INSTDIR\RosBE.ps1"
    Delete /REBOOTOK "$INSTDIR\rosbe-gcc-env.cmd"
    Delete /REBOOTOK "$INSTDIR\rosbe-gcc-env.ps1"
    Delete /REBOOTOK "$INSTDIR\scut.cmd"
    Delete /REBOOTOK "$INSTDIR\scut.ps1"
    Delete /REBOOTOK "$INSTDIR\sSVN.cmd"
    Delete /REBOOTOK "$INSTDIR\sSVN.ps1"
    Delete /REBOOTOK "$INSTDIR\TimeDate.cmd"
    Delete /REBOOTOK "$INSTDIR\uninstall.ico"
    Delete /REBOOTOK "$INSTDIR\update.cmd"
    Delete /REBOOTOK "$INSTDIR\update.ps1"
    Delete /REBOOTOK "$INSTDIR\version.cmd"
    Delete /REBOOTOK "$INSTDIR\version.ps1"
    Delete /REBOOTOK "$INSTDIR\Uninstall.exe"
    ;; Whoever dares to change this back into: RMDir /r /REBOOTOK "$INSTDIR" will be KILLED!!!
    RMDir /REBOOTOK "$INSTDIR"

    ;;
    ;; Clean up the registry.
    ;;
    DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
    DeleteRegKey HKCU "${PRODUCT_DIR_REGKEY}"
    SetAutoClose true
SectionEnd

Function UninstallPrevious
    ReadRegStr $R0 HKCU \
               "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" \
               "UninstallString"
    ReadRegStr $R1 HKCU \
               "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" \
               "DisplayVersion"
    ${If} $R1 == "${PRODUCT_VERSION}"
        messageBox MB_OK|MB_ICONEXCLAMATION \
            "You already have the ${PRODUCT_NAME} v${PRODUCT_VERSION} installed. You should uninstall the ${PRODUCT_NAME} v${PRODUCT_VERSION} if you want to reinstall."
    ${EndIf}
    ${If} $R0 == ""
        ReadRegStr $R0 HKLM \
                   "Software\Microsoft\Windows\CurrentVersion\Uninstall\ReactOS Build Environment" \
                   "UninstallString"
        ReadRegStr $R1 HKLM \
                   "Software\Microsoft\Windows\CurrentVersion\Uninstall\ReactOS Build Environment" \
                   "DisplayVersion"
        ${If} $R0 == ""
            Return
        ${EndIf}
    ${EndIf}
    MessageBox MB_YESNO|MB_ICONQUESTION  \
               "A previous version of the ${PRODUCT_NAME} was found. You should uninstall it before installing this version.$\n$\nDo you want to do that now?" \
               IDNO UninstallPrevious_no \
               IDYES UninstallPrevious_yes
    Abort
    UninstallPrevious_yes:
        Var /global PREVIOUSINSTDIR
        Push $R0
        Call GetParent
        Pop $PREVIOUSINSTDIR
        Pop $R0
        ExecWait '$R0 _?=$PREVIOUSINSTDIR'
    UninstallPrevious_no:
FunctionEnd

Function GetParent
    Exch $R0
    Push $R1
    Push $R2
    Push $R3
    Push $R4

    StrCpy $R1 0
    StrLen $R2 $R0

    loop:
        IntOp $R1 $R1 + 1
        IntCmp $R1 $R2 get 0 get
        StrCpy $R3 $R0 1 -$R1
        StrCmp $R3 "\" get
        Goto loop

    get:
        StrCpy $R0 $R0 -$R1

        Pop $R3
        Pop $R2
        Pop $R1
        Exch $R0
FunctionEnd
