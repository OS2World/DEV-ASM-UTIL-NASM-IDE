unit IMAIN;

(* Information
   ßßßßßßßßßßß

   Program Title : NASM-IDE.
   External name : IMAIN.TPU
   Version       : 1.6
   Start date    : 31/03/1997
   Last update   : 13/01/2002
   Author        : Rob Anderton
   Description   : Unit containing all declarations for type TMain - the main
                   application object.

*)

interface

{******}

uses APP, DRIVERS, OBJECTS, MENUS, VIEWS, MEMORY, DOS, MSGBOX,
     DIALOGS, ICONST, IRES, IASSIST, IEDIT, ILOG, IOPT,
     IHELP, ISPAWN, ISTD, SINI, ICONTROL, IUTILS;

{******}

type TMain = object(TApplication)

                   ClipboardWindow    : PASMEditWindow;
                   Clock              : PClockViewer;
                   ErrorViewer        : PErrorViewer;
                   ErrorViewerVisible : boolean;
                   FileHistory        : array[1..5] of PMenuItem;
                   Heap               : PHeapViewer;
                   HelpFileName       : string;
                   HelpInUse          : boolean;
                   HelpWindow         : PHelpWindow;
                   NASMDirectory      : DirStr;
                   PrimaryItem        : PMenuItem;
                   RecentMenu         : PMenu;

                   constructor Init;

                   destructor  Done; virtual;

                   procedure   AddRecentFile(sFileName : string);

                   procedure   ASMAssistant;

                   procedure   Assemble;

                   procedure   AssembleRun;

                   procedure   DosExecError(DosErrorCode    : integer;
                                            SpawnoErrorCode : integer;
                                            ProgramName     : string);

                   procedure   GetEvent(var Event: TEvent); virtual;

                   function    GetIDEDirectory : string;

                   function    GetPalette: PPalette; virtual;

                   procedure   GetRunParameters;

                   procedure   HandleEvent(var Event : TEvent); virtual;

                   procedure   Idle; virtual;

                   procedure   InitStatusLine; virtual;

                   procedure   InitMenuBar; virtual;

                   procedure   LoadDesktop; virtual;

                   function    NewEditWindow : pointer;

                   function    NextMenuItem(Text, Param            : string;
                                            KeyCode, Command, Help : word;
                                            CurrentItem            : PMenuItem) : PMenuItem;

                   function    OpenEditWindow(FileName : string) : pointer;

                   procedure   OpenLogViewer;

                   procedure   OptionsAssembler;

                   procedure   OptionsDirectories;

                   procedure   OptionsEnvironment;

                   function    RunProgram(ProgramName : string;
                                          Params      : string;
                                          Pause       : boolean;
                                          PauseMsg    : string) : integer; virtual;

                   procedure   SaveDesktop; virtual;

                   procedure   SetEditorOptions(wOptions : word);

                   procedure   SetPrimaryFile(PrimaryName : string);

                   procedure   SetVideoMode(wMode : word);

                   procedure   ShowClipBoard;

                   procedure   ShowHelp(sHelpName : string; aHelpCtx : word);

                   function    TruncateFileName(sFileName : string) : string;

                   procedure   WriteShellMsg; virtual;
             end;

{******}

  { Desktop file signature information }
const SignatureLen = 22;
      DSKSignature : string[SignatureLen] = 'NASM-IDE Desktop File'#26;

{******}

var Main : TMain;

{******}

implementation

uses IABOUT, ICRT, STRINGS, HISTLIST, IASM;

{******}

procedure SaveScreen;

var F            : text;
    Loop1, Loop2 : word;
    Data         : word;

begin
     Assign(F, Main.NASMDirectory + 'SCREEN.TXT');
     Rewrite(F);
     Loop1:= 0;
     Loop2:= 0;

     repeat
           Data:= MemW[$B800:Loop1];
           Inc(Loop1, 2);
           Inc(Loop2);
           write(f, Chr(WordRec(Data).Lo));
           if Loop2 > 79 then
           begin
                writeln(f);
                Loop2:= 0;
           end;
     until (Loop1 = 4000);
     Close(F);
end;

{******}

constructor TMain.Init;

var R              : TRect;
    D              : PathStr;
    DisplayLogo    : wordbool;
    LogoOK         : boolean;
    LogoTime       : longint;
    ININame        : string;
    PrimaryFile    : string;
    ScreenSize     : word;
    EditorOpt      : word;
    DesktopOptions : word;
    Loop           : word;
    INIAttributes  : word;
    INIFile        : file;

begin
     MaxHeapSize:= 8192;
     EditorDialog:= ASMEditorDialog;

     D:= GetIDEDirectory;
     ININame:= D + 'NASMIDE.INI';

     {*** Check INI file exists and its size - not nice code! ***}
     if (FileExists(ININame)) then
     begin
          Assign(INIFile, ININame);

          {*** Check the INI file is not read-only ***}
          GetFAttr(INIFile, INIAttributes);

          if (INIAttributes and ReadOnly <> 0) then
          begin
             writeln;
             writeln('NASM-IDE version ' + IDEVersion + '.');
             writeln(#4' Critical error : Your NASMIDE.INI file is read-only.');
             write(#4' To correct the error, turn off the read-only attribute for your NASMIDE files.');
             writeln;
             Halt(0);
          end;

          Reset(INIFile, 1);

          if (FileSize(INIFile) = 0) then
          begin
             writeln;
             writeln('NASM-IDE version ' + IDEVersion + '.');
             writeln(#4' Critical error : Your NASMIDE.INI file is corrupted.');
             write(#4' To correct the error, overwrite your NASMIDE.INI');
             writeln('  file with the original from the NASM-IDE archive.');
             writeln;
             Halt(0);
          end;
     end
     else
     begin
        writeln;
        writeln('NASM-IDE version ' + IDEVersion + '.');
        writeln(#4' Critical error : Your NASMIDE.INI file is missing.');
        write(#4' To correct the error, extract NASMIDE.INI');
        writeln('  from the NASM-IDE archive.');
        writeln;
        Halt(0);
     end;

     INI_GetProfileInt(ININame, 'ENVIRONMENT', 'STARTUP_LOGO', INTEGER(DisplayLogo), 1);

     writeln;
     writeln('NASM-IDE version ' + IDEVersion + ' (c) 1997 - 2002 Rob Anderton');
     writeln('The NetWide Assembler Integrated Development Environment');
     writeln;

     ResRegister;
     RegisterHelpFile;
     Init_Spawno(D, Swap_All, 20, 0);

     inherited Init;
     NASMDirectory:= D;
     HelpFileName:= NASMDirectory + 'NASMIDE.HLP';
     HelpInUse:= false;
     HelpWindow:= nil;

     INI_GetProfileInt(ININame, 'ENVIRONMENT', 'SCREEN_MODE', INTEGER(ScreenSize), 0);
     if ScreenSize > 1 then ScreenSize:= 0;
     INI_GetProfileInt(ININame, 'ENVIRONMENT', 'EDITOR_OPTIONS', INTEGER(EditorOpt), 3);
     if EditorOpt > 7 then EditorOpt:= 7;

     SetVideoMode(ScreenSize);
     SetEditorOptions(EditorOpt);

     INI_GetProfileString(ININame, 'ASSEMBLER', 'PRIMARY_FILE', PrimaryFile, '');
     SetPrimaryFile(PrimaryFile);

     Desktop^.GetExtent(R);
     ClipboardWindow:= New(PASMEditWindow, Init(R, '', wnNoNumber));
     if ValidView(ClipboardWindow) <> nil then
     begin
          ClipboardWindow^.Hide;
          ClipboardWindow^.Options:= ClipboardWindow^.Options or ofTileable;
          InsertWindow(ClipboardWindow);
          Clipboard:= ClipboardWindow^.Editor;
          Clipboard^.CanUndo:= false;
     end;

     ErrorViewer:= nil;
     ErrorViewerVisible:= false;

     GetExtent(R);
     R.A.X:= R.B.X - 10;
     R.B.Y:= R.A.Y + 1;
     Clock:= New(PClockViewer, Init(R, false));
     Insert(Clock);

     GetExtent(R);
     R.A.X:= R.B.X - 9;
     R.A.Y:= R.B.Y - 1;
     Heap:= New(PHeapViewer, Init(R));
     Insert(Heap);

     INI_GetProfileInt(ININame, 'ENVIRONMENT', 'DESKTOP_AUTOSAVE', INTEGER(DesktopOptions), 1);
     if DesktopOptions > 1 then DesktopOptions:= 1;
     if DesktopOptions and 1 = 1 then LoadDesktop;

     for Loop:= 1 to ParamCount do
         OpenEditWindow(ParamStr(ParamCount));
end;

{******}

destructor TMain.Done;

var Loop           : byte;
    ININame        : string;
    DesktopOptions : word;

begin
     ININame:= NASMDirectory + 'NASMIDE.INI';

     INI_GetProfileInt(ININame, 'ENVIRONMENT', 'DESKTOP_AUTOSAVE', INTEGER(DesktopOptions), 1);
     if DesktopOptions > 1 then DesktopOptions:= 1;
     if DesktopOptions and 1 = 1 then SaveDesktop;
     inherited Done;
     ResFile.Done;
end;

{******}

procedure TMain.AddRecentFile(sFileName : string);

var ININame      : string;
    Loop         : byte;
    TotalFiles   : byte;
    ExistingPos  : byte;
    ExistingFile : boolean;
    FirstItem    : PMenuItem;
    MenuItems    : PMenuItem;
    FileList     : array[1..5] of string;

begin
     ININame:= Main.NASMDirectory + 'NASMIDE.INI';

     TotalFiles:= 0;
     ExistingPos:= 0;
     ExistingFile:= false;

     for Loop:= 1 to 5 do
     begin
          INI_GetProfileString(ININame, 'FILE_HISTORY',
                               'FILE_' + IntToStr(Loop),
                               FileList[Loop], '');

          if FileList[Loop] <> '' then Inc(TotalFiles);

          if FileList[Loop] = sFileName then
          begin
               ExistingFile:= true;
               ExistingPos:= Loop;
          end;
     end;

     {*** If file already exists then exit ***}
     if (ExistingFile) then
     begin
          if (ExistingPos <> 1) then
          begin
               FileList[ExistingPos]:= FileList[1];
               FileList[1]:= sFileName;
          end
          else Exit;
     end
     else
     begin
          if TotalFiles = 5 then Dec(TotalFiles);

          for Loop:= TotalFiles downto 1 do
               FileList[Loop + 1]:= FileList[Loop];

          FileList[1]:= sFileName;
          Inc(TotalFiles);
     end;

     for Loop:= 1 to 5 do
         INI_WriteProfileString(ININame, 'FILE_HISTORY',
                                'FILE_' + IntToStr(Loop),
                                FileList[Loop]);

     if RecentMenu <> nil then
     begin
          FirstItem:= RecentMenu^.Items;
          while FirstItem <> nil do
          begin
               MenuItems:= FirstItem^.Next;
               Dispose(FirstItem);
               FirstItem:= MenuItems;
          end;
     end;

     MenuItems:= nil;
     for Loop:= 1 to TotalFiles do
     begin
          MenuItems:= NextMenuItem('~' + IntToStr(Loop) + '~. ' +
                                   TruncateFileName(FileList[Loop]),
                                   '', kbNoKey, cmFile1 + Loop - 1,
                                   hcFileReopen, MenuItems);

          if Loop = 1 then FirstItem:= MenuItems;
     end;

     RecentMenu^.Items:= FirstItem;
end;

{******}

procedure TMain.ASMAssistant;

{******}

 function StrFn(Num : longint) : string;

 var S : string;

 begin
      Str(Num, S);
      StrFn:= S;
 end;

{******}

 procedure AddEditString(Edit : PEditWindow; S : string);

 var EditNString : PChar;

 begin
      GetMem(EditNString, Length(S));
      StrPCopy(EditNString, S);
      Edit^.Editor^.InsertText(EditNString, StrLen(EditNString), false);
      FreeMem(EditNString, Length(S));
 end;

{******}

var PDlg         : PDialog;
    Edit         : PASMEditWindow;
    R            : TRect;
    W            : word;
    ASMOptions   : TASMOptionRec;
    Ass2Data     : TAss2DataRec;
    Ass3Temp     : integer;
    EditPString  : string;

begin
     {ASM Assistant 1/4}
     PDlg:= New(PASMAss1Dialog, Init);
     W:= ExecView(PDlg);
     Dispose(PDlg, Done);
     if W = cmCancel then Exit;

     {ASM Assistant 2/4}
     PDlg:= New(PASMAss2Dialog, Init);
     if PDlg <> nil then PDlg^.HelpCtx:= hcFileNewAssistant2;
     W:= ExecView(PDlg);
     PDlg^.GetData(Ass2Data);

     if Ass2Data.Bits = 0 then ASMOptions.Bits:= 16
                          else ASMOptions.Bits:= 32;

     if Ass2Data.Org.Selection = 0 then ASMOptions.Org:= $0
                                   else ASMOptions.Org:= $0100;

     PASMAss2Dialog(PDlg)^.ListBox^.NewList(nil);
     Dispose(PDlg, Done);
     if W = cmCancel then Exit;

     {ASM Assistant 3/4}
     PDlg:= New(PASMAss3Dialog, Init);
     if PDlg <> nil then PDlg^.HelpCtx:= hcFileNewAssistant3;
     W:= ExecView(PDlg);
     PDlg^.GetData(Ass3Temp);

     with ASMOptions do
     begin
          Text:= (Ass3Temp and 1) = 1;
          Data:= (Ass3Temp and 2) = 2;
          BSS:= (Ass3Temp and 4) = 4;
     end;
     Dispose(PDlg, Done);
     if W = cmCancel then Exit;

     {ASM Assistant 4/4}
     PDlg:= New(PASMAss4Dialog, Init);
     W:= ExecView(PDlg);
     Dispose(PDlg, Done);
     if W = cmCancel then Exit;

     Desktop^.GetExtent(R);
     R.Grow(-1, -1);
     Edit:= New(PASMEditWindow, Init(R, '', wnNoNumber));
     Edit^.Editor^.CanUndo:= true;
     Edit^.Editor^.AutoIndent:= true;
     Edit^.Options:= Edit^.Options or ofTileable;
     InsertWindow(Edit);

     with ASMOptions do
     begin
          AddEditString(Edit, #9#9#9';NASM-IDE ASM Assistant Assembler Project'+
                              ' File'#13#10);

          EditPString:= 'BITS ' + StrFn(Bits) + #9#9#9';Set code generation'+
                        ' to '+ StrFn(Bits) + ' bit mode'#13#10;
          AddEditString(Edit, EditPString);

          EditPString:= 'ORG 0x' + WordToHex(Org, true) + #9#9';Set code start'+
                        ' address to ' + WordToHex(Org, true) + 'h'#13#10;
          AddEditString(Edit, EditPString);

          if Text = true then
          begin
               EditPString:= #13#10#13#10'SEGMENT .text'#9#9 +
                             ';Main code segment'#13#10;
               AddEditString(Edit, EditPString);
          end;

          if Data = true then
          begin
               EditPString:= #13#10#13#10'SEGMENT .data'#9#9 +
                             ';Initialised data segment'#13#10;
               AddEditString(Edit, EditPString);
          end;

          if BSS = true then
          begin
               EditPString:= #13#10#13#10'SEGMENT .bss'#9#9 +
                             ';Uninitialised data segment'#13#10;
               AddEditString(Edit, EditPString);
          end;
     end;
end;

{******}

procedure TMain.Assemble;

var ININame            : string;     {NASM-IDE INI file name}
    FileName           : string;     {Primary file name}

begin
     {*** Get name of INI file ***}
     ININame:= Main.NASMDirectory + 'NASMIDE.INI';

     {*** Get primary file name ***}
     INI_GetProfileString(ININame, 'ASSEMBLER', 'PRIMARY_FILE', FileName, '');

     {*** Call the assembler ***}
     NASM.Assemble(FileName);
end;

{******}

procedure TMain.AssembleRun;

var ININame          : string;
    FileName         : string;

begin
     {*** Get INI file name ***}
     ININame:= NASMDirectory + 'NASMIDE.INI';

     {*** Get the primary file name ***}
     INI_GetProfileString(ININame, 'ASSEMBLER', 'PRIMARY_FILE', FileName, '');

     {*** Assemble the primary file ***}
     NASM.AssembleRun(FileName);
end;

{******}

procedure TMain.DosExecError(DosErrorCode    : integer;
                             SpawnoErrorCode : integer;
                             ProgramName     : string);

var ErrorMsg : string;
    w        : word;

begin
     {*** Check for a SPAWNO error code ***}
     if (DosErrorCode = 0) then
     begin

        {*** Replace the DOS error code with the SPAWNO code}
        DosErrorCode:= SpawnoErrorCode;

     end;

     case DosErrorCode of
                    2 : ErrorMsg:= 'File not found';
                    3 : ErrorMsg:= 'Path not found';
                    5 : ErrorMsg:= 'Access denied';
                    6 : ErrorMsg:= 'Invalid handle';
                    8 : ErrorMsg:= 'Insufficient memory';
                   10 : ErrorMsg:= 'Invalid environment';
                   11 : ErrorMsg:= 'Invalid format';
                   18 : ErrorMsg:= 'Insufficient file handles';
                   20 : ErrorMsg:= 'Program too big to fit in memory';
                   29 : ErrorMsg:= 'Write fault';
                 else   ErrorMsg:= '';
     end;

     if ErrorMsg <> '' then
     begin
          if StatusLine = nil then
          begin
               ClearScreen;
               writeln(ErrorMsg);
               halt(1);
          end;
          w:= MessageBox(ErrorMsg + ' error executing ' + ProgramName, nil, mfError+mfOKButton);
     end;
end;

{******}

procedure TMain.GetEvent(var Event : TEvent);

var W        : PWindow;
    R        : TRect;

begin
     inherited GetEvent(Event);
     if (Event.What = evCommand) then
     begin
          case Event.Command of

         cmScreenDump : begin
                          SaveScreen;
                          ClearEvent(Event);
                        end;
          end;
     end;
end;

{******}

function TMain.GetIDEDirectory : string;

var Temp : string;
    D    : DirStr;
    N    : NameStr;
    E    : ExtStr;

begin
     Temp:= ParamStr(0);
     Temp:= FExpand(Temp);
     FSplit(Temp, D, N, E);
     GetIDEDirectory:= D;
end;

{******}

function TMain.GetPalette: PPalette;

const CNewColour     = CAppColor + CHelpColor;
      CNewBlackWhite = CAppBlackWhite + CHelpBlackWhite;
      CNewMonochrome = CAppMonochrome + CHelpMonochrome;

      P : array[apColor..apMonochrome] of string[Length(CNewColour)] =
                                 (CNewColour, CNewBlackWhite, CNewMonochrome);
begin
     GetPalette := @P[AppPalette];
end;

{******}

procedure TMain.GetRunParameters;

var PDlg   : PParametersDlg;
    W      : word;
    ININame: string;
    Params : string;

begin
     ININame:= NASMDirectory + 'NASMIDE.INI';
     INI_GetProfileString(ININame, 'ASSEMBLER', 'RUN_PARAMS', Params, '');
     PDlg:= New(PParametersDlg, Init(ININame));
     PDlg^.SetData(Params);
     PDlg^.Options:= PDlg^.Options or ofCentered;
     W:= ExecView(PDlg);
     if W <> cmCancel then PDlg^.GetData(Params);
     Dispose(PDlg, Done);
     INI_WriteProfileString(ININame, 'ASSEMBLER', 'RUN_PARAMS', Params);
end;

{******}

procedure TMain.HandleEvent;

{******}

 function GetFName(FileSpec, Title, IPLineTitle : string; Opts : word;
                   HistID : byte) : string;

 var PDlg   : PFileDialog;
     W      : word;
     S      : PathStr;

 begin
      GetFName:= '';
      PDlg:= New(PFileDialog, Init(FileSpec, Title, IPLineTitle, Opts, HistID));
      if PDlg <> nil then PDlg^.HelpCtx:= hcFileOpenDialog;
      W:= ExecView(PDlg);
      if W <> cmCancel then
      begin
           PDlg^.GetFileName(S);
           GetFName:= S;
      end;
      Dispose(PDlg, Done);
 end;

{******}

var FName   : string;
    PDlg    : PDialog;
    V       : PView;
    ININame : string;

begin
     ININame:= NASMDirectory + 'NASMIDE.INI';

     inherited HandleEvent(Event);

     if (Event.What and evCommand) <> 0 then
     begin
          case Event.Command of
             cmFileNewBlank: begin
                                NewEditWindow;
                                ClearEvent(Event);
                             end;

             cmFileNewAssist:begin
                                ASMAssistant;
                                ClearEvent(Event);
                             end;

               cmFileOpenUp: begin
                                FName:= IUTILS.StrUpper(GetFName('*.ASM', 'Open file', '~N~ame',
                                fdOpenButton + fdHelpButton, hiFileOpen));
                                if (FName <> '') and FileExists(FName) then
                                   OpenEditWindow(FName);
                                ClearEvent(Event);
                             end;

          cmFile1..cmFile5 : begin
                               INI_GetProfileString(ININame, 'FILE_HISTORY',
                               'FILE_' + IntToStr(Event.Command + 1 - cmFile1),
                               FName, '');

                               if FName <> '' then
                                  OpenEditWindow(FName)
                               else
                                  MessageBox('Unable to reopen file.', nil,
                                             mfError + mfOKButton);

                               ClearEvent(Event);
                             end;

             cmFileSaveAll : begin
                                Message(Desktop, evBroadcast, cmFileSaveAll, nil);
                                ClearEvent(Event);
                             end;

           cmFileChangeDir : begin
                                  ExecView(New(PChDirDialog, Init(cdHelpButton, hiFileDir)));

                                  V:= Desktop^.Last;
                                  V:= V^.Next;

                                  with Desktop^ do
                                       while(V <> Desktop^.Last) do
                                       begin
                                            Message(V^.Owner,
                                                    evBroadcast,
                                                    cmUpdateTitle, nil);
                                            PWindow(V)^.Frame^.DrawView;
                                            V:= V^.Next;
                                       end;

                                  ClearEvent(Event);
                             end;

      cmEditShowClipboard: begin
                                ShowClipBoard;
                                ClearEvent(Event);
                           end;

         cmAssembleBuild : begin
                                INI_GetProfileString(ININame, 'ASSEMBLER', 'PRIMARY_FILE', FName, '');
                                if FName <> '' then Assemble;
                                ClearEvent(Event);
                           end;

           cmAssembleRun : begin
                                INI_GetProfileString(ININame, 'ASSEMBLER', 'PRIMARY_FILE', FName, '');
                                if FName <> '' then AssembleRun;
                                ClearEvent(Event);
                           end;

       cmAssemblePrimary : begin
                                FName:= IUTILS.StrUpper(GetFName('*.ASM', 'Primary file', '~N~ame',
                                        fdOkButton + fdHelpButton, hiFileOpen));
                                if (FName <> '') and FileExists(FName) then
                                begin
                                     SetPrimaryFile(FName);
                                     INI_WriteProfileString(ININame, 'ASSEMBLER', 'PRIMARY_FILE', FName);
                                end;
                                ClearEvent(Event);
                           end;

         cmAssembleClear : begin
                                SetPrimaryFile('');
                                INI_WriteProfileString(ININame, 'ASSEMBLER', 'PRIMARY_FILE', '');
                                ClearEvent(Event);
                           end;

         cmAssembleParam : begin
                                GetRunParameters;
                                ClearEvent(Event);
                           end;

       cmOptionsAssembler: begin
                                OptionsAssembler;
                                ClearEvent(Event);
                           end;

     cmOptionsDirectories: begin
                                OptionsDirectories;
                                ClearEvent(Event);
                           end;

     cmOptionsEnvironment: begin
                                OptionsEnvironment;
                                ClearEvent(Event);
                           end;


              cmCloseAll : begin
                                Message(Desktop, evBroadcast, cmCloseAll, nil);
                                ClearEvent(Event);
                           end;

        cmWindowErrorInfo: begin
                                OpenLogViewer;
                                ClearEvent(Event);
                           end;

                  cmHelp : begin
                                ShowHelp(NASMDirectory + 'NASMIDE.HLP', GetHelpCtx);
                                ClearEvent(Event);
                           end;

          cmHelpContents : begin
                                ShowHelp(NASMDirectory + 'NASMIDE.HLP', hcHelpContents);
                                ClearEvent(Event);
                           end;

             cmHelpUsing : begin
                                ShowHelp(NASMDirectory + 'NASMIDE.HLP', hcHelpUsing);
                                ClearEvent(Event);
                           end;

      cmHelp80x86Opcodes : begin
                               ShowHelp(NASMDirectory + '8086HELP.HLP', hcHelp80x86Opcodes);
                               ClearEvent(Event);
                           end;

      cmHelp80x87Opcodes : begin
                               ShowHelp(NASMDirectory + '8087HELP.HLP', hcHelp80x87Opcodes);
                               ClearEvent(Event);
                           end;

             cmHelpAbout : begin
                                PDlg:= New(PAboutDialog, Init);
                                ExecuteDialog(PDlg, nil);
                                ClearEvent(Event);
                           end;
          end;
     end;

     if (Event.What and evBroadcast) <> 0 then
     begin
          case Event.Command of

               cmCloseErrorInfo : begin
                                       ErrorViewerVisible:= false;
                                       ClearEvent(Event);
                                  end;

              cmHelpWindowClose : begin
                                       HelpInUse:= false;
                                       ClearEvent(Event);
                                  end;
          end;
     end;
end;

{******}

procedure TMain.Idle;

var i : byte;

begin
     inherited Idle;
     Clock^.Update;
     Heap^.Update;

     if Desktop^.Current = nil then CurrentView:= 0;

     if ClipBoard = nil then DisableCommands(csClipboard);

     if (PrimaryItem^.Param <> nil) then EnableCommands(csPrimaryFile)
                                    else if (NumberOfEditors <= 1) then DisableCommands(csPrimaryFile);

     if (NumberOfWindows >= 1) then
     begin
          if NumberOfWindows > 1 then EnableCommands(csWindow)
                                 else EnableCommands([cmWindowCloseAll]);
     end
     else
     begin
          DisableCommands(csWindow);
          DisableCommands([cmFilePrint, cmAssembleAssemble]);
     end;

     if NumberOfEditors > 1 then EnableCommands(csEditor)
                            else DisableCommands(csEditor);

     if (Desktop^.Current = PView(ClipboardWindow)) then
     begin
        DisableCommands([cmFileSave, cmFileSaveAs, cmFilePrint, cmEditShowClipboard,
                         cmAssembleAssemble]);

        if (PrimaryItem^.Param = nil) then DisableCommands(csPrimaryFile);
     end;

end;

{******}

procedure TMain.InitStatusLine;

var R : TRect;

begin
     GetExtent(R);
     R.A.Y:= R.B.Y - 1;
     StatusLine:= New(PHintLine, Init(R,
                      StdStatusHelp(
                      NewStatusDef(0, 999,
                          NewStatusKey('~F1~ Help', kbF1, cmHelp,
                          NewStatusKey('~F2~ Save', kbF2, cmFileSave,
                          NewStatusKey('~F3~ Open', kbF3, cmFileOpenUp,
                          NewStatusKey('~Alt+F9~ Assemble', kbAltF9, cmAssembleAssemble,
                          NewStatusKey('~F9~ Build', kbF9, cmAssembleBuild,
                          NewStatusKey('~Ctrl+F9~ Run', kbCtrlF9, cmAssembleRun,
                          NewStatusKey('', kbAltF10, cmScreenDump,
                          StdStatusKeys(nil)))))))),
                      NewStatusDef(1000, $FFFF,
                          NewStatusKey('~F1~ Help', kbF1, cmHelp,
                          NewStatusKey('', kbF3, cmFileOpenUp,
                          NewStatusKey('', kbAltF10, cmScreenDump,
                          StdStatusKeys(nil)))),
                  nil)))));

     PHintLine(StatusLine)^.SetHints(PStringList(ResFile.Get('HINTS')));
end;

{******}

procedure TMain.InitMenuBar;

{******}

 function MakeRecentMenu : PMenu;

 var ININame    : string;
     Loop       : byte;
     TotalFiles : byte;
     FirstItem  : PMenuItem;
     MenuItems  : PMenuItem;
     FileList   : array[1..5] of string;

 begin
      ININame:= Main.NASMDirectory + 'NASMIDE.INI';

      TotalFiles:= 0;

      for Loop:= 1 to 5 do
      begin
           INI_GetProfileString(ININame, 'FILE_HISTORY',
                                'FILE_' + IntToStr(Loop),
                                FileList[Loop], '');

           if FileList[Loop] <> '' then Inc(TotalFiles);
      end;

      if TotalFiles <> 0 then
      begin
           MenuItems:= nil;
           for Loop:= 1 to TotalFiles do
           begin
                MenuItems:= NextMenuItem('~' + IntToStr(Loop) + '~. ' +
                                         TruncateFileName(FileList[Loop]),
                                         '', kbNoKey, cmFile1 + Loop - 1,
                                         hcFileReopen, MenuItems);

                if Loop = 1 then FirstItem:= MenuItems;
           end;

           RecentMenu:= NewMenu(FirstItem);
      end
      else RecentMenu:= NewMenu(nil);

      MakeRecentMenu:= RecentMenu;
 end;

{******}

var R          : TRect;
    C          : PCollection;
    D          : boolean;
    P          : PMenuItem;

begin
     {*** Create menu bar ***}
     GetExtent(R);
     R.B.Y:= R.A.Y + 1;
     MenuBar:= New(PMenuBar,
                   Init(R, NewMenu(
                            NewSubMenu('~F~ile', hcFileLo,
                             NewMenu(
                              NewSubMenu('~N~ew            ', hcFileNew,
                               NewMenu(
                                NewItem('~B~lank file', '', kbNoKey, cmFileNewBlank, hcFileNewBlank,
                                NewItem('~A~SM assistant... ', '', kbNoKey, cmFileNewAssist, hcFileNewAssist,
                              nil))),
                              NewItem('~O~pen...', 'F3', kbF3, cmFileOpenUp, hcFileOpen,
                              NewSubMenu('~R~eopen', hcFileReopen,
                               MakeRecentMenu,
                              NewItem('~S~ave', 'F2', kbF2, cmFileSave, hcFileSave,
                              NewItem('Save ~a~s...', '', kbNoKey, cmFileSaveAs, hcFileSaveAs,
                              NewItem('Save a~l~l', '', kbNoKey, cmFileSaveAll, hcFileSaveAll,
                              NewLine(
                               NewItem('~C~hange dir...', '', kbNoKey, cmFileChangeDir, hcFileChangeDir,
                               NewItem('~P~rint', '', kbNoKey, cmFilePrint, hcFilePrint,
                               NewItem('~D~OS shell', '', kbNoKey, cmFileDosShell, hcFileDosShell,
                               NewLine(
                                NewItem('E~x~it', 'Alt X', kbAltX, cmFileExit, hcFileExit,
                             nil))))))))))))),
                            NewSubMenu('~E~dit', hcEditLo,
                             NewMenu(
                                NewItem('~U~ndo', 'Alt+BkSp', kbAltBack, cmEditUndo, hcEditUndo,
                                NewLine(
                                 NewItem('Cu~t~', 'Shift+Del', kbShiftDel, cmEditCut, hcEditCut,
                                 NewItem('~C~opy', 'Ctrl+Ins', kbCtrlIns, cmEditCopy, hcEditCopy,
                                 NewItem('~P~aste', 'Shift+Ins', kbShiftIns, cmEditPaste, hcEditPaste,
                                 NewItem('C~l~ear', 'Ctrl+Del', kbCtrlDel, cmEditClear, hcEditClear,
                                 NewLine(
                                  NewItem('~S~how clipboard', '', kbNoKey, cmEditShowClipboard, hcEditShowClipboard,
                             nil))))))))),
                            NewSubMenu('~S~earch', hcSearchLo,
                             NewMenu(
                              NewItem('~F~ind...          ', '', kbNoKey, cmSearchFind, hcSearchFind,
                              NewItem('~R~eplace...', '', kbNoKey, cmSearchReplace, hcSearchReplace,
                              NewItem('~S~earch again', '', kbNoKey, cmSearchRepeat, hcSearchRepeat,
                              NewLine(
                               NewItem('~G~o to line number...', '', kbNoKey, cmJumpLine, hcSearchJump,
                             nil)))))),
                            NewSubMenu('~A~ssemble', hcAssembleLo,
                             NewMenu(
                              NewItem('~A~ssemble', 'Alt+F9', kbAltF9, cmAssembleAssemble, hcAssembleAssemble,
                              NewItem('~B~uild          ', 'F9', kbF9, cmAssembleBuild, hcAssembleBuild,
                              NewItem('~R~un', 'Ctrl+F9', kbCtrlF9, cmAssembleRun, hcAssembleRun,
                              NewLine(
                               NewItem('~P~rimary file...', '', kbNoKey, cmAssemblePrimary, hcAssemblePrimary,
                               NewItem('C~l~ear primary file', '', kbNoKey, cmAssembleClear, hcAssembleClear,
                              NewLine(
                               NewItem('Parameter~s~...', '', kbNoKey, cmAssembleParam, hcAssembleParam,
                             nil))))))))),
                            NewSubMenu('~O~ptions', hcOptionsLo,
                             NewMenu(
                              NewItem('~A~ssembler...     ', '', kbNoKey, cmOptionsAssembler, hcOptionsAssembler,
                              NewItem('~D~irectories...', '', kbNoKey, cmOptionsDirectories, hcOptionsDirectories,
                              NewItem('~E~nvironment...', '', kbNoKey, cmOptionsEnvironment, hcOptionsEnvironment,
                             nil)))),
                            NewSubMenu('~W~indow', hcWindowLo,
                             NewMenu(
                              NewItem('~T~ile', '', kbNoKey, cmWindowTile, hcWindowTile,
                              NewItem('C~a~scade', '', kbNoKey, cmWindowCascade, hcWindowCascade,
                              NewItem('Cl~o~se all', '', kbNoKey, cmWindowCloseAll, hcWindowCloseAll,
                              NewLine(
                               NewItem('~S~ize/Move', 'Ctrl+F5', kbCtrlF5, cmWindowResize, hcWindowResize,
                               NewItem('~Z~oom', 'F5', kbF5, cmWindowZoom, hcWindowZoom,
                               NewItem('~N~ext', 'F6', kbF6, cmWindowNext, hcWindowNext,
                               NewItem('~P~revious', 'Shift+F6', kbShiftF6, cmWindowPrev, hcWindowPrev,
                               NewItem('~C~lose', 'Alt+F3', kbAltF3, cmWindowClose, hcWindowClose,
                               NewLine(
                                NewItem('~E~rror information', '', kbNoKey, cmWindowErrorInfo, hcWindowErrorInfo,
                             nil)))))))))))),
                            NewSubMenu('~H~elp', hcHelpLo,
                             NewMenu(
                              NewItem('~H~elp contents     ', 'F1', kbF1, cmHelpContents, hcHelpContents,
                              NewItem('~U~sing Help', '', kbNoKey, cmHelpUsing, hcHelpUsing,
                              NewLine(
                               NewItem('~I~nteger opcodes', '', kbNoKey, cmHelp80x86Opcodes, hcHelp80x86Opcodes,
                               NewItem('~F~loating point opcodes', '', kbNoKey, cmHelp80x87Opcodes, hcHelp80x87Opcodes,
                               NewLine(
                                NewItem('~A~bout...', '', kbNoKey, cmHelpAbout, hcHelpAbout,
                             nil)))))))),
                            nil))))))
                   ))));

     {*** Get a pointer to the primary file item ***}
     C:= New(PCollection, Init(10,10));
     PrimaryItem:= nil;
     P:= MenuBar^.Menu^.Items;
     D:= false;
     while not D do
     begin
          if P = nil then
          begin
               P:= PMenuItem(C^.At(C^.Count - 1))^.Next;
               C^.AtDelete(C^.Count - 1);
          end
          else if (P^.Name <> nil) and (P^.Command=0) then
          begin
               C^.Insert(P);
               P:= P^.SubMenu^.Items;
          end
          else P:= P^.Next;

          if (P <> nil) and (P^.Name <> nil) and
             (P^.Command = cmAssemblePrimary) then D:= true;

          if (P = nil) and (C^.Count = 0) then D:= true;
     end;

     if P <> nil then PrimaryItem:= P;
     C^.DeleteAll;
     Dispose(C, Done);
end;

{******}

procedure TMain.LoadDesktop;

{******}

 procedure CloseView(P: PView); far;

 begin
      Message(P, evCommand, cmClose, nil);
 end;

{******}

var DesktopFile : TBufStream;
    Signature   : string[SignatureLen];
    P           : PView;

begin
     if (fSearch('NASMIDE.DSK', NASMDirectory) = '') then
       {MessageBox(#3'Desktop file not found', nil, mfOKButton + mfError)}
     else
     begin
       DesktopFile.Init(NASMDirectory + 'NASMIDE.DSK', stOpenRead, 1024);

       if LowMemory then OutOfMemory
       else
         if DesktopFile.Status <> stOK then
            MessageBox(#3'Unable to open desktop file.', nil, mfOKButton + mfError)
         else
         begin
              Signature[0]:= Char(SignatureLen);
              DesktopFile.Read(Signature[1], SignatureLen);
              if Signature = DSKSignature then
              begin
                   if Desktop^.Valid(cmClose) then
                   begin
                        Desktop^.ForEach(@CloseView);
                        repeat
                              P:= PView(DesktopFile.Get);
                              Desktop^.InsertBefore(ValidView(P), Desktop^.Last);
                        until P = nil;
                   end;

                   LoadHistory(DesktopFile);
                   if DesktopFile.Status <> stOK then
                      MessageBox(#3'Error reading desktop file.', nil, mfOKButton + mfError);
              end
              else
                  MessageBox(#3'Invalid desktop file.', nil, mfOKButton + mfError);
         end;
     end;
end;

{******}

function TMain.NewEditWindow : pointer;

begin
     NewEditWindow:= OpenEditWindow('');
end;

{******}

function TMain.NextMenuItem(Text, Param            : string;
                            KeyCode, Command, Help : word;
                            CurrentItem            : PMenuItem) : PMenuItem;

var P : PMenuItem;

begin
     P:= NewItem(Text, Param, KeyCode, Command, Help, nil);

     if CurrentItem <> nil then CurrentItem^.Next:= P;
     NextMenuItem:= P;
end;

{******}

function TMain.OpenEditWindow(FileName : string) : pointer;

var R : TRect;
    W : PASMEditWindow;

begin
     Desktop^.GetExtent(R);
     R.Grow(-1, -1);
     W:= New(PASMEditWindow, Init(R, FileName, wnNoNumber));
     W^.Editor^.CanUndo:= true;
     W^.Editor^.AutoIndent:= true;
     W^.Options:= W^.Options or ofTileable;
     InsertWindow(W);
     OpenEditWindow:= W;
end;

{******}

procedure TMain.OpenLogViewer;

var R : TRect;

begin
     if ErrorViewerVisible then
     begin
          {*** Store the error view location ***}
          ErrorViewer^.GetBounds(R);
          Dispose(ErrorViewer, Done);
          ErrorViewer:= nil;
          ErrorViewerVisible:= false;
     end
     else
     begin
          {*** Use default location ***}
          Desktop^.GetExtent(R);
          R.A.Y:= R.B.Y - 10;
     end;

     ErrorViewer:= New(PErrorViewer, Init(R, NASMDirectory + 'NASM.LOG'));
     if ValidView(ErrorViewer) <> nil then
     begin
          InsertWindow(ErrorViewer);
          ErrorViewer^.MakeFirst;
          ErrorViewerVisible:= true;
          Inc(NumberOfWindows);
     end
end;

{******}

procedure TMain.OptionsAssembler;

var PDlg       : PASMOptionsDlg;
    W          : word;
    ASMOptions : TASMOptionsRec;
    ININame    : string;

begin
     {*** Read INI file settings ***}
     ININame:= NASMDirectory + 'NASMIDE.INI';
     INI_GetProfileInt(ININame, 'ASSEMBLER', 'OUTPUT_FORMAT', INTEGER(ASMOptions.Target.Selection), 0);
     Dec(ASMOptions.Target.Selection);
     INI_GetProfileInt(ININame, 'ASSEMBLER', 'NASM_WARNING', INTEGER(ASMOptions.Warnings), 15);
     if ASMOptions.Warnings > 15 then ASMOptions.Warnings:= 15;
     INI_GetProfileString(ININame, 'ASSEMBLER', 'CUSTOM_PARAMS', ASMOptions.CustomParams, '');
     INI_GetProfileString(ININame, 'ASSEMBLER', 'NASM_LOCATION', ASMOptions.NASMLocation, '');

     PDlg:= New(PASMOptionsDlg, Init(ININame));
     ASMOptions.Target.List:= nil;
     PDlg^.SetData(ASMOptions);
     PDlg^.UpdateListBox(ASMOptions.Target.Selection);
     W:= ExecView(PDlg);
     if W <> cmCancel then
     begin
	  PDlg^.GetData(ASMOptions);

          {*** Write INI file settings ***}
          ININame:= NASMDirectory + 'NASMIDE.INI';
          Inc(ASMOptions.Target.Selection);
          INI_WriteProfileInt(ININame, 'ASSEMBLER', 'OUTPUT_FORMAT', INTEGER(ASMOptions.Target.Selection));
          INI_WriteProfileInt(ININame, 'ASSEMBLER', 'NASM_WARNING', INTEGER(ASMOptions.Warnings));
          INI_WriteProfileString(ININame, 'ASSEMBLER', 'CUSTOM_PARAMS', ASMOptions.CustomParams);
          INI_WriteProfileString(ININame, 'ASSEMBLER', 'NASM_LOCATION', ASMOptions.NASMLocation);
     end;
     PDlg^.TargetList^.NewList(nil);
     Dispose(PDlg, Done);
end;

{******}

procedure TMain.OptionsDirectories;

var PDlg    : PASMDirectoriesDlg;
    W       : word;
    Dir     : TASMDirectoriesRec;
    ININame : string;

begin
     {*** Read INI file settings ***}
     ININame:= NASMDirectory + 'NASMIDE.INI';
     INI_GetProfileString(ININame, 'DIRECTORIES', 'OUTPUT_DIR', Dir.OutputDir, '');
     INI_GetProfileString(ININame, 'DIRECTORIES', 'INCLUDE_DIR', Dir.IncludeDir, '');

     PDlg:= New(PASMDirectoriesDlg, Init(ININame));
     PDlg^.SetData(Dir);
     W:= ExecView(PDlg);
     if W <> cmCancel then
     begin
          PDlg^.GetData(Dir);
          INI_WriteProfileString(ININame, 'DIRECTORIES', 'OUTPUT_DIR', Dir.OutputDir);
          INI_WriteProfileString(ININame, 'DIRECTORIES', 'INCLUDE_DIR', Dir.IncludeDir);
     end;
     Dispose(PDlg, Done);
end;

{******}

procedure TMain.OptionsEnvironment;

var PDlg    : PASMEnvironmentDlg;
    W       : word;
    Env     : TASMEnvironmentRec;
    ININame : string;
    R       : TRect;

begin
     {*** Read INI file settings ***}
     ININame:= NASMDirectory + 'NASMIDE.INI';
     INI_GetProfileInt(ININame, 'ENVIRONMENT', 'SCREEN_MODE', INTEGER(Env.ScreenSize), 0);
     if Env.ScreenSize > 1 then Env.ScreenSize:= 0;
     INI_GetProfileInt(ININame, 'ENVIRONMENT', 'EDITOR_OPTIONS', INTEGER(Env.EditorOptions), 3);
     if Env.EditorOptions > 7 then Env.EditorOptions:= 7;
     INI_GetProfileInt(ININame, 'ENVIRONMENT', 'DESKTOP_AUTOSAVE', INTEGER(Env.DesktopOptions), 1);
     if Env.DesktopOptions > 1 then Env.DesktopOptions:= 1;
     INI_GetProfileInt(ININame, 'ENVIRONMENT', 'STARTUP_LOGO', INTEGER(Env.StartupOptions), 1);
     if Env.StartupOptions > 1 then Env.StartupOptions:= 1;

     PDlg:= New(PASMEnvironmentDlg, Init);
     PDlg^.SetData(Env);
     W:= ExecView(PDlg);
     if W <> cmCancel then
     begin
          PDlg^.GetData(Env);
          INI_WriteProfileInt(ININame, 'ENVIRONMENT', 'SCREEN_MODE', INTEGER(Env.ScreenSize));
          INI_WriteProfileInt(ININame, 'ENVIRONMENT', 'EDITOR_OPTIONS', INTEGER(Env.EditorOptions));
          INI_WriteProfileInt(ININame, 'ENVIRONMENT', 'DESKTOP_AUTOSAVE', INTEGER(Env.DesktopOptions));
          INI_WriteProfileInt(ININame, 'ENVIRONMENT', 'STARTUP_LOGO', INTEGER(Env.StartupOptions));

          SetVideoMode(Env.ScreenSize);
          SetEditorOptions(Env.EditorOptions);
          Message(Application, evBroadcast, cmRefresh, nil);
     end;
     Dispose(PDlg, Done);
end;

{******}

function TMain.RunProgram(ProgramName : string;
                          Params      : string;
                          Pause       : boolean;
                          PauseMsg    : string) : integer;

var DError : integer;
    DExit  : integer;

begin
     DoneSysError;
     DoneEvents;
     DoneVideo;
     DoneDosMem;

     DError:= Spawn(ProgramName, Params, 0);
     DExit:= DosError;

     if Pause then
     begin
          writeln(PauseMsg);
          readkey;
     end;

     InitDosMem;
     InitVideo;
     InitEvents;
     InitSysError;
     Application^.Redraw;
     if ((DError <> 0) or (DExit <> 0)) then DosExecError(DExit, Spawno_Error, ProgramName);
     RunProgram:= DExit;
end;

{******}

procedure TMain.SaveDesktop;

var DesktopFile : TBufStream;
    F           : file;

{******}

 procedure WriteView(P: PView); far;

 begin
      if P <> Desktop^.Last then DesktopFile.Put(P);
 end;

{******}

begin
     DesktopFile.Init(NASMDirectory + 'NASMIDE.DSK', stCreate, 1024);
     if not LowMemory and (DesktopFile.Status = stOK) then
     begin
          Desktop^.Delete(ClipboardWindow);
          if ErrorViewerVisible then Desktop^.Delete(ErrorViewer);
          if HelpInUse then Desktop^.Delete(HelpWindow);
          DesktopFile.Write(DSKSignature[1], SignatureLen);
          Desktop^.ForEach(@WriteView);
          DesktopFile.Put(nil);
          StoreHistory(DesktopFile);
          if DesktopFile.Status <> stOK then
          begin
               MessageBox('Unable to create desktop file.', nil, mfOKButton + mfError);
               {$I-}
               DesktopFile.Done;
               Assign(F, NASMDirectory + 'NASMIDE.DSK');
               Erase(F);
               {$I+}
               Exit;
          end;
          if HelpInUse then InsertWindow(HelpWindow);
          if ErrorViewerVisible then InsertWindow(ErrorViewer);
          InsertWindow(ClipboardWindow);
     end;
     DesktopFile.Done;
end;

{******}

procedure TMain.SetEditorOptions(wOptions : word);

begin
     if (wOptions and 1) = 1 then
          EditorFlags:= EditorFlags or efBackupFiles
     else
          EditorFlags:= EditorFlags and not efBackupFiles;

     if (wOptions and 4) = 4 then
          EditorFlags:= EditorFlags or efSyntaxHighlight
     else
          EditorFlags:= EditorFlags and not efSyntaxHighlight;
end;

{******}

procedure TMain.SetPrimaryFile(PrimaryName : string);

var Dir        : DirStr;
    Name       : NameStr;
    Ext        : ExtStr;

begin
     if (PrimaryItem <> nil) then
     begin
          if (PrimaryItem^.Param <> nil) then DisposeStr(PrimaryItem^.Param);
          if (PrimaryName <> '') then
          begin
               FSplit(PrimaryName, Dir, Name, Ext);
               PrimaryItem^.Param:= NewStr(Name + Ext)
          end
          else PrimaryItem^.Param:= nil;
     end;
end;

{******}

procedure TMain.SetVideoMode(wMode : word);

var CurMode : word;
    NewMode : word;
    R       : TRect;

begin
     if (ScreenMode and smFont8x8) <> 0 then CurMode:= 1
                                        else CurMode:= 0;

     if CurMode <> wMode then
     begin
          if wMode = 1 then
          begin
               ShadowSize.X:= 1;
               NewMode:= ScreenMode or smFont8x8;
          end
          else
          begin
               ShadowSize.X:= 2;
               NewMode:= ScreenMode and not smFont8x8;
          end;

          SetScreenMode(NewMode);

          if Assigned(Clock) then
          begin
               GetExtent(R);
               R.A.X:= R.B.X - 10;
               R.B.Y:= R.A.Y + 1;
               Clock^.MoveTo(R.A.X, R.A.Y);
          end;
     end;
end;

{******}

procedure TMain.ShowClipboard;

begin
     if ClipBoard <> nil then
     begin
          ClipBoardWindow^.Show;
          ClipBoardWindow^.Select;
          Inc(NumberOfWindows);
     end;
end;

{******}

procedure TMain.ShowHelp(sHelpName : string; aHelpCtx : word);

var W            : PHelpWindow;
    Event        : TEvent;
    HelpF        : PHelpFile;
    HelpS        : PDosStream;

begin
     if (HelpInUse) and (sHelpName = HelpFileName) then
     begin
          Event.What:= evCommand;
          Event.Command:= cmSwitchToHelpTopic;
          Event.InfoWord:= aHelpCtx;
          PutEvent(Event);
     end
     else
     begin
          if HelpInUse then
          begin
               HelpFileName:= sHelpName;
               New(HelpS, Init(sHelpName, stOpenRead));
               New(HelpF, Init(HelpS));
               if HelpS^.Status <> stOK then
               begin
                    MessageBox(#3'Could not open help file.', nil, mfError + mfOKButton);
                    Dispose(HelpF, Done);
                    Exit;
               end;
               HelpWindow^.HelpViewer^.SetHelpFile(HelpF, aHelpCtx);
          end
          else
          begin
               HelpInUse:= true;
               HelpFileName:= sHelpName;
               New(HelpS, Init(sHelpName, stOpenRead));
               New(HelpF, Init(HelpS));

               if HelpS^.Status <> stOK then
               begin
                    MessageBox(#3'Could not open help file.', nil, mfError + mfOKButton);
                    Dispose(HelpF, Done);
                    Exit;
               end;

               W:= New(PHelpWindow, Init(HelpF, aHelpCtx));
               if ValidView(W) <> nil then
               begin
                    W^.HelpCtx:= hcHelpWindow;
                    InsertWindow(W);
                    HelpWindow:= W;
               end;
          end;
     end;
end;

{******}

function TMain.TruncateFileName(sFileName : string) : string;

var Dir      : DirStr;
    Name     : NameStr;
    Ext      : ExtStr;
    Loop     : word;
    MenuStr  : string;

begin
     FSplit(sFileName, Dir, Name, Ext);

     if Length(sFileName) <= 15 then
        MenuStr:= sFileName
     else
     begin
          Loop:= Length(sFileName) - 21;
          while sFileName[Loop] <> '\' do Inc(Loop);
                MenuStr:= Copy(Dir, 1, 3) + '..' +
                          Copy(sFileName, Loop,
                          Length(sFileName) - Loop + 1);
     end;

     TruncateFileName:= MenuStr;
end;

{******}

procedure TMain.WriteShellMsg;

begin
     PrintStr('NASM-IDE DOS Shell. Type EXIT to return.'#13#10);
end;

{******}

end.