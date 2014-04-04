unit ICONST;

(* Information
   ßßßßßßßßßßß

   Program Title : Program Constants Unit
   External name : ICONST.TPU
   Version       : 1.7
   Start date    : 30/03/1997
   Last update   : 18/05/2002
   Author        : Rob Anderton
   Description   : Unit containing constants used by application e.g. command
                   constants (cmXXXX), etc.

*)

interface

{******}

uses APP, VIEWS, IEDIT;

{******}

const
      {*** NASM-IDE Version Number ***}
      IDEVersion = '1.7';

      {*** Commands (cmXXXX) ***}

      {*** File Menu (1000 - 1099) ***}
      cmFileNew           = cmNew;
      cmFileNewBlank      = 1010;
      cmFileNewAssist     = 1020;
      cmFileOpenUp        = cmOpen;
      cmFileSave          = cmSave;
      cmFileSaveAs        = cmSaveAs;
      cmFileSaveAll       = cmSaveAll;
      cmFileChangeDir     = cmChangeDir;
      cmFilePrint         = 100;         {Can be disabled}
      cmFileDosShell      = cmDosShell;
      cmFileExit          = cmQuit;
      cmFile1             = 1030;
      cmFile2             = 1031;
      cmFile3             = 1032;
      cmFile4             = 1033;
      cmFile5             = 1034;

      {*** Edit Menu (1100 - 1199) ***}
      cmEditUndo           = cmUndo;
      cmEditCut            = cmCut;
      cmEditCopy           = cmCopy;
      cmEditPaste          = cmPaste;
      cmEditClear          = cmClear;
      cmEditShowClipboard  = 101;

      {*** Search menu (82 - 84) ***}
      cmSearchFind         = cmFind;
      cmSearchReplace      = cmReplace;
      cmSearchRepeat       = cmSearchAgain;

      {*** Assemble menu (1300 - 1399) ***}
      cmAssembleAssemble   = 102;
      cmAssembleBuild      = 103;
      cmAssembleRun        = 104;
      cmAssemblePrimary    = 1310;
      cmAssembleClear      = 1320;
      cmAssembleParam      = 1330;

      {*** Options menu (1400 - 1499) ***}
      cmOptionsAssembler   = 1410;
      cmOptionsNewFormat   = 1411;
      cmOptionsEditFormat  = 1412;
      cmOptionsDelFormat   = 1413;
      cmOptionsNASMLocation= 1414;
      cmOptionsDirectories = 1420;
      cmOptionsEnvironment = 1430;

      {*** Window menu (1500 - 1599) ***}
      cmWindowTile         = cmTile;
      cmWindowCascade      = cmCascade;
      cmWindowResize       = cmResize;
      cmWindowZoom         = cmZoom;
      cmWindowNext         = cmNext;
      cmWindowPrev         = cmPrev;
      cmWindowClose        = cmClose;
      cmWindowCloseAll     = cmCloseAll;
      cmWindowErrorInfo    = 1510;

      {*** Help menu (1600 - 1699) ***}
      cmHelpContents       = 1610;
      cmHelpWindowClose    = 1620;
      cmHelpUsing          = 1630;
      cmHelp80x86Opcodes   = 1640;
      cmHelp80x87Opcodes   = 1650;
      cmHelpAbout          = 1660;
      cmHelpLinks          = 1670;

      {*** Broadcast commands (2000 - 2100) ***}
      cmHighlightError     = 2000;
      cmCloseErrorInfo     = 2010;
      cmSwitchToHelpTopic  = 2020;
      cmScreenDump         = 2030;
      cmRefresh            = 2040;

      {*** Help contexts (hcXXXX) ***}

      {*** File menu (1000 - 1099) ***}
      hcFileLo             = 1000;
      hcFileNew            = 1005;
      hcFileNewBlank       = 1010;
      hcFileNewAssist      = 1015;
      hcFileOpen           = 1020;
      hcFileSave           = 1025;
      hcFileSaveAs         = 1030;
      hcFileSaveAll        = 1035;
      hcFileChangeDir      = 1040;
      hcFilePrint          = 1045;
      hcFileDosShell       = 1050;
      hcFileExit           = 1055;
      hcFileReopen         = 1060;
      hcFileHi             = 1099;

      {*** Edit menu (1100 - 1199) ***}
      hcEditLo             = 1100;
      hcEditUndo           = 1105;
      hcEditCut            = 1110;
      hcEditCopy           = 1115;
      hcEditPaste          = 1120;
      hcEditClear          = 1125;
      hcEditShowClipboard  = 1130;
      hcEditHi             = 1199;

      {*** Search menu (1200 - 1299) ***}
      hcSearchLo           = 1200;
      hcSearchFind         = 1210;
      hcSearchReplace      = 1220;
      hcSearchRepeat       = 1230;
      hcSearchJump         = 1240;
      hcSearchHi           = 1299;

      {*** Assemble menu (1300 - 1399) ***}
      hcAssembleLo         = 1300;
      hcAssembleAssemble   = 1310;
      hcAssembleBuild      = 1320;
      hcAssembleRun        = 1330;
      hcAssemblePrimary    = 1340;
      hcAssembleClear      = 1350;
      hcAssembleParam      = 1360;
      hcAssembleHi         = 1399;

      {*** Options menu (1400 - 1499) ***}
      hcOptionsLo          = 1400;
      hcOptionsAssembler   = 1410;
      hcOptionsDirectories = 1420;
      hcOptionsEnvironment = 1430;
      hcOptionsHi          = 1499;

      {*** Window menu (1500 - 1599) ***}
      hcWindowLo           = 1500;
      hcWindowTile         = 1505;
      hcWindowCascade      = 1510;
      hcWindowResize       = 1515;
      hcWindowZoom         = 1520;
      hcWindowNext         = 1525;
      hcWindowPrev         = 1530;
      hcWindowClose        = 1535;
      hcWindowCloseAll     = 1540;
      hcWindowErrorInfo    = 1545;
      hcWindowHi           = 1599;

      {*** Help Menu (1600 - 1699) ***}
      hcHelpLo             = 1600;
      hcHelpContents       = 1610;
      hcHelpUsing          = 1630;
      hcHelp80x86Opcodes   = 1640;
      hcHelp80x87Opcodes   = 1650;
      hcHelpAbout          = 1660;
      hcHelpHi             = 1699;

      {*** Status line contexts ***}
      hcHelpWindow         = 2000;

      {*** Dialog box contexts (3000 - 3999) ***}

      {*** Generic buttons ***}
      hcCancel                   = 3000;
      hcNo                       = 3010;
      hcOk                       = 3020;
      hcYes                      = 3030;
      hcNext                     = 3040;
      hcFinish                   = 3050;
      hcHelp                     = 3060;
      hcOpenBtn                  = 3070;

      {*** File dialogs ***}
      hcFileOpenDialog           = 3100;
      hcFileSaveDialog           = 3110;
      hcFileChangeDirDialog      = 3120;

      {*** File dialog components ***}
      hcFileName                 = 3130;
      hcFileList                 = 3140;

      {*** Change directory components ***}
      hcFileDirName              = 3150;
      hcFileDirTree              = 3160;
      hcFileChDir                = 3170;
      hcFileRevert               = 3180;

      {*** ASM new file assistant ***}
      hcFileNewAssistant1        = 3200;
      hcFileNewAssistant2        = 3210;
      hcFileNewAssistant3        = 3220;
      hcFileNewAssistant4        = 3230;

      {*** Search dialogs ***}
      hcSearchFindDialog         = 3300;
      hcSearchReplaceDialog      = 3310;
      hcSearchJumpDialog         = 3320;

      {*** Search/replace components ***}
      hcSearchFindText           = 3330;
      hcSearchReplaceText        = 3340;

      {*** Check boxes ***}
      hcCaseSensitive            = 3350;
      hcWholeWords               = 3351;
      hcPromptReplace            = 3352;
      hcReplaceAll               = 3353;

      {*** Goto line dialog components ***}
      hcJumpLineNumber           = 3360;

      {*** Assemble dialogs ***}
      hcAssemblePrimaryDialog    = 3400;
      hcAssembleParamDialog      = 3410;

      {*** Assemble components ***}
      hcAssembleParamList        = 3420;

      {*** Options dialogs and checkboxes ***}
      hcOptionsAssemblerDialog   = 3500;

      hcAssemblerTarget          = 3510;
      hcAssemblerNewTarget       = 3511;
      hcAssemblerEditTarget      = 3512;
      hcAssemblerDelTarget       = 3513;

      hcAssemblerWarningsMacro    = 3520;
      hcAssemblerWarningsColon    = 3521;
      hcAssemblerWarningsOverflow = 3522;
      hcAssemblerWarningsCyclic   = 3523;

      hcAssemblerCustomParams     = 3525;
      hcAssemblerNASMLocation     = 3526;
      hcAssemblerNASMLocationDlg  = 3527;

      hcOptionsDirectoriesDialog = 3530;

      hcDirectoriesInclude       = 3540;
      hcDirectoriesOutput        = 3550;

      hcOptionsEnvironmentDialog = 3560;

      hcScreenSize80x25          = 3570;
      hcScreenSize80x50          = 3571;

      hcEditorBackup             = 3580;
      hcEditorAutoSave           = 3581;
      hcEditorSyntaxHighlight    = 3582;

      hcDesktopAutoSave          = 3585;

      hcStartupLogo              = 3590;

      {*** Tab Stop Dialog ***}
      hcTabStops                 = 3600;

      {*** ASM Editor ***}
      hcEditWindow               = 3700;

      {*** Stream registration IDs (idXXXX) ***}
      idHintLine       = 20000;
      idHelpTopic      = 20001;
      idHelpIndex      = 20002;
      idEditor         = 20003;
      idEditWindow     = 20004;
      idErrorViewer    = 20005;

      {*** ICONTROL unit ***}
      idColouredText             = 1000;

      {*** History IDs ***}
      hiFileOpen      = 1;
      hiFileSave      = 2;
      hiFileDir       = 3;
      hiRunParam      = 4;
      hiJumpLine      = 5;
      hiOutputDir     = 6;
      hiIncludeDir    = 7;
      hiPrimaryFile   = 8;
      hiNASMLocation  = 9;

      {*** Command sets (for Enable/DisableCommands ***}

      CurrentView     : byte = 0; {Used to index command set array}
      NumberOfWindows : byte = 0; {Number of windows on the desktop}
      NumberOfEditors : byte = 0; {Number of editors on the desktop}

      EditorWindow           = 1; {Used to index command set array}
      TotalSets              = 1; {Holds value of highest index}

      csClipboard   = [cmEditCut, cmEditCopy, cmEditPaste, cmEditClear,
                       cmEditShowClipboard];

      csPrimaryFile = [cmAssembleBuild, cmAssembleRun];

      csWindow      = [cmWindowTile, cmWindowCascade, cmCloseAll];

      csEditor      = [cmFileSaveAll];

      CommandSet : array[1..TotalSets] of TCommandSet =
                   ([cmFileSave, cmFileSaveAs, cmFileSaveAll,
                     cmFilePrint, cmEditUndo, cmEditCut, cmEditCopy,
                     cmEditPaste, cmEditClear, cmSearchFind, cmSearchReplace,
                     cmSearchRepeat, cmJumpLine]);

{******}

implementation
end.