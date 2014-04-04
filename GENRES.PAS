program GenRes;

(* Information
   ßßßßßßßßßßß

   Program Title : Resource Generator
   External name : GENRES.EXE
   Version       : 1.6
   Start date    : 15/11/1995
   Last update   : 08/06/1999
   Author        : Rob Anderton
   Description   : Program to generate resource file containing strings
                   used by the hint line.

*)


uses CRT, OBJECTS, ICONST;

{*** Stream Error Handler ***}

procedure Error(var s : TStream); far;

var w : word;

begin
     writeln('Stream failure.  Status = ',s.Status,'.  Info = ',s.ErrorInfo,'.');
     s.Reset;
     halt(1);
end;

{*** Hints - string list ***}

function Hints : PStrListMaker;

var S : PStrListMaker;

begin
     S:= New(PStrListMaker, Init(16384, 256));

     {*** Menus ***}
     S^.Put(hcFileLo, 'File management commands (Open, Save, etc.)');
     S^.Put(hcEditLo, 'Cut-and-paste editing commands');
     S^.Put(hcSearchLo, 'Search and replace text commands');
     S^.Put(hcAssembleLo, 'Assemble and run code');
     S^.Put(hcOptionsLo, 'Set defualts for assembler, editor, etc.');
     S^.Put(hcWindowLo, 'Open and arrange windows');
     S^.Put(hcHelpLo, 'Get online help');

     {*** File Menu ***}
     S^.Put(hcFileNew, 'Create a new file');
     S^.Put(hcFileNewBlank, 'Create a blank file in a new edit window');
     S^.Put(hcFileNewAssist, 'Use ASM Assistant to create a file in a new edit window');
     S^.Put(hcFileOpen, 'Locate and open a file in an edit window');
     S^.Put(hcFileSave, 'Save the file in the active edit window');
     S^.Put(hcFileSaveAs, 'Save the current file under a different name');
     S^.Put(hcFileSaveAll, 'Save all modified files');
     S^.Put(hcFileChangeDir, 'Choose a new default directory');
     S^.Put(hcFilePrint, 'Print the contents of the active edit window');
     S^.Put(hcFileDosShell, 'Temporarily exit to DOS');
     S^.Put(hcFileExit, 'Exit NASM-IDE');
     S^.Put(hcFileReOpen, 'Open indicated file in a new editor window');

     {*** Edit Menu ***}
     S^.Put(hcEditUndo, 'Undo the previous editor operation');
     S^.Put(hcEditCut, 'Remove the selected text and put it in the clipboard');
     S^.Put(hcEditCopy, 'Copy the selected text into the clipboard');
     S^.Put(hcEditPaste, 'Insert text from the clipboard at the cursor position');
     S^.Put(hcEditClear, 'Delete the selected text');
     S^.Put(hcEditShowClipboard, 'Open the clipboard window');

     {*** Search Menu ***}
     S^.Put(hcSearchFind, 'Search for text');
     S^.Put(hcSearchReplace, 'Search for text and replace it with new text');
     S^.Put(hcSearchRepeat, 'Repeat the last Find or Replace command');
     S^.Put(hcSearchJump, 'Move the cursor to a specified line number');

     {*** Assemble Menu ***}
     S^.Put(hcAssembleAssemble, 'Assemble the active source file');
     S^.Put(hcAssembleBuild, 'Assemble the primary source file');
     S^.Put(hcAssembleRun, 'Run the current program');
     S^.Put(hcAssemblePrimary, 'Define the file that is the focus of Build and Run');
     S^.Put(hcAssembleClear, 'Clear the file previously set with Primary file');
     S^.Put(hcAssembleParam, 'Set command line parameters to be passed to the program');

     {*** Options Menu ***}
     S^.Put(hcOptionsAssembler, 'Set assembler options');
     S^.Put(hcOptionsDirectories, 'Specify paths for include files and generated files');
     S^.Put(hcOptionsEnvironment, 'Specify environment options');

     {*** Window Menu ***}
     S^.Put(hcWindowTile, 'Arrange windows on the desktop by tiling');
     S^.Put(hcWindowCascade, 'Arrange windows on the desktop by cascading');
     S^.Put(hcWindowCloseAll, 'Close all windows on the desktop');
     S^.Put(hcWindowReSize, 'Change the size or position of the active window');
     S^.Put(hcWindowZoom, 'Enlarge or restore the size of the active window');
     S^.Put(hcWindowNext, 'Make the next window active');
     S^.Put(hcWindowPrev, 'Make the previous window active');
     S^.Put(hcWindowClose, 'Close the active window');
     S^.Put(hcWindowErrorInfo, 'Display error information for last assemble');

     {*** Help Menu ***}
     S^.Put(hcHelpContents, 'Show table of contents for online help');
     S^.Put(hcHelpUsing, 'How to use online help');
     S^.Put(hcHelp80x86Opcodes, 'Display the 80x86 integer opcode reference');
     S^.Put(hcHelp80x87Opcodes, 'Display the 80x87 floating point opcode reference');
     S^.Put(hcHelpAbout, 'Show version and copyright information');

     {*** Dialogs ***}

     {*** Generic buttons ***}
     S^.Put(hcCancel, 'Close the dialog box without making any changes');
     S^.Put(hcNo, 'Do not perform the action');
     S^.Put(hcOk, 'Accept the settings in this dialog box');
     S^.Put(hcYes, 'Perform the action');
     S^.Put(hcNext, 'Accept the settings in this dialog box');
     S^.Put(hcFinish, 'Perform the action');
     S^.Put(hcHelp, 'View a help screen about this dialog box');
     S^.Put(hcOpenBtn, 'Open the specified file into a new editor window');

     {*** File dialogs ***}
{     S^.Put(hcFileOpenDialog, '');
     S^.Put(hcFileSaveDialog, '');
     S^.Put(hcFileChangeDirDialog, '');}

     {*** File dialog components ***}
     S^.Put(hcFileName, 'Enter the directory path and file mask');
     S^.Put(hcFileList, 'Type for incremental search');

     {*** Change directory components ***}
     S^.Put(hcFileDirName, 'Type drive and/or directory path');
     S^.Put(hcFileDirTree, 'Use cursor keys to navigate through directory tree');
     S^.Put(hcFileChDir, 'Change to the specified directory');
     S^.Put(hcFileRevert, 'Return to the original directory');

     {*** ASM new file assistant ***}
     S^.Put(hcFileNewAssistant1, 'ASM Assistant - 1/4');
     S^.Put(hcFileNewAssistant2, 'ASM Assistant - 2/4');
     S^.Put(hcFileNewAssistant3, 'ASM Assistant - 3/4');
     S^.Put(hcFileNewAssistant4, 'ASM Assistant - 4/4');

     {*** Search dialogs ***}
{     S^.Put(hcSearchFindDialog, '');
     S^.Put(hcSearchReplaceDialog, '');
     S^.Put(hcSearchJumpDialog, '');}

     {*** Search/replace components ***}
     S^.Put(hcSearchFindText, 'Enter text to search for');
     S^.Put(hcSearchReplaceText, 'Enter text to replace matching text with');

     {*** Check boxes ***}
     S^.Put(hcCaseSensitive, 'Case of letters is significant during search');
     S^.Put(hcWholeWords, 'Consider only whole words during search');
     S^.Put(hcPromptReplace, 'Prompt before replacing text after every match');
     S^.Put(hcReplaceAll, 'Replace all occurrences of the search text');

     {*** Goto line dialog components ***}
     S^.Put(hcJumpLineNumber, 'Move cursor to specified line number in file');

     {*** Assemble dialogs ***}
{     S^.Put(hcAssemblePrimaryDialog, '');
     S^.Put(hcAssembleParamDialog, '');}

     {*** Assemble components ***}
     S^.Put(hcAssembleParamList, 'Enter command line parameters to be passed to your program');

     {*** Options dialogs and checkboxes ***}
{     S^.Put(hcOptionsAssemblerDialog, '');}
     S^.Put(hcAssemblerTarget, 'Select assembler target');
     S^.Put(hcAssemblerNewTarget, 'Define a new assembler target');
     S^.Put(hcAssemblerEditTarget, 'Edit assembler target properties');
     S^.Put(hcAssemblerDelTarget, 'Delete an existing target');
     S^.Put(hcAssemblerWarningsMacro, 'Enable macro parameter warnings');
     S^.Put(hcAssemblerWarningsColon, 'Enable label warnings');
     S^.Put(hcAssemblerWarningsOverflow, 'Enable numeric overflow warnings');
     S^.Put(hcAssemblerWarningsCyclic, 'Enable cyclic macro references warnings');
     S^.Put(hcAssemblerCustomParams, 'Enter additional NASM command line parameters');
     S^.Put(hcAssemblerNASMLocation, 'Enter the full path and file name of the NASM executable');
{     S^.Put(hcOptionsDirectoriesDialog, '');}
     S^.Put(hcDirectoriesInclude, 'The directories that contain your include files');
     S^.Put(hcDirectoriesOutput, 'The directory that stores your .COM, .SYS and .OBJ files');
{     S^.Put(hcOptionsEnvironmentDialog, '');}
     S^.Put(hcScreenSize80x25, 'Use a display of 80 columns and 25 lines');
     S^.Put(hcScreenSize80x50, 'Use a display of 43 lines (EGA) or 50 lines (VGA)');
     S^.Put(hcEditorBackup, 'Create a backup (.BAK) file every time you save');
     S^.Put(hcEditorAutoSave, 'Automatically save files when you assemble');
     S^.Put(hcEditorSyntaxHighlight, 'Enable or disable syntax highlighting of source code');
     S^.Put(hcDesktopAutosave, '');
     S^.Put(hcStartupLogo, 'Display the NASM IDE logo on startup');

     {*** Tab Stop Dialog ***}
{     S^.Put(hcTabStops, '');}

     Hints:= S;
end;

{*** Main program ***}

var Res : TResourceFile;
    S   : PBufStream;

begin
     StreamError:= @Error;
     ClrScr;
     writeln('Hint line resource generator v1.5 - NASM IDE.');
     writeln;

     RegisterType(RStrListMaker);
     S:= New(PBufStream, Init('NASMIDE.RES', stCreate, 2048));
     Res.Init(S);
     write('Creating hint list...');
     Res.Put(Hints, 'HINTS');
     writeln('done.');
     Res.Done;
end.