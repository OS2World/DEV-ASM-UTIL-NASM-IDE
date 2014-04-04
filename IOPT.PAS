unit IOPT;

(* Information
   ßßßßßßßßßßß

   Program Title : Options dialog boxes
   External name : IOPT.TPU
   Version       : 1.5
   Start date    : 16/10/1997
   Last update   : 01/01/2002
   Author        : Rob Anderton
   Description   : Unit containing dialog boxes used to set NASM and NASM-IDE
		   options.
*)

{******}

interface

{******}

uses OBJECTS, DIALOGS, IHELP, DRIVERS, MSGBOX, APP;

{*** Record types ***}

type
     {*** Assembler options dialog record ***}
     TASMOptionsRec = record
                            Target       : record
                                               List      : PCollection;
                                               Selection : word;
                                           end;
                            Warnings     : word;
                            CustomParams : string[127];
                            NASMLocation : string[127];
                      end;
     PASMOptionsRec = ^TASMOptionsRec;

     {*** New target dialog record ***}
     TTargetRec = record
                       Description : string[45];
                       FileExt     : string[3];
                       CmdParam    : string[10];
                  end;
     PTargetRec = ^PTargetRec;

     {*** Directory dialog record ***}
     TASMDirectoriesRec = record
                                IncludeDir : string[127];
                                OutputDir  : string[127];
                          end;
     PASMDirectoriesRec = ^TASMDirectoriesRec;


     {*** Environment options dialog record ***}
     TASMEnvironmentRec = record
                                ScreenSize     : word;
                                EditorOptions  : word;
                                DesktopOptions : word;
                                StartupOptions : word;
                          end;
     PASMEnvironmentRec = ^TASMEnvironmentRec;

{*** Object types ***}

type
     {*** Assembler options dialog box ***}
     PASMOptionsDlg = ^TASMOptionsDlg;
     TASMOptionsDlg = object(THelpDialog)
                             ININame     : string;
                             TargetList  : PListBox;
                             NASMLocation: PInputLine;

			     constructor Init(sININame : string);
                             procedure   AddTarget(TargetInfo : TTargetRec);
			     procedure   HandleEvent(var Event : TEvent); virtual;
                             procedure   UpdateListBox(Selection : word); virtual;
		      end;

     {*** New target dialog box ***}
     PNewTargetDlg = ^TNewTargetDlg;
     TNewTargetDlg = object(THelpDialog)
                            constructor Init;
                            function Valid(Command : word): boolean; virtual;
                     end;

     {*** Edit target dialog box ***}
     PEditTargetDlg = ^TEditTargetDlg;
     TEditTargetDlg = object(THelpDialog)
                            constructor Init;
                            function Valid(Command : word): boolean; virtual;
                      end;

     PDeleteTargetDlg = ^TDeleteTargetDlg;
     TDeleteTargetDlg = object(THelpDialog)
                            constructor Init(TargetInfo : TTargetRec);
                        end;

     {*** Directories dialog box ***}
     PASMDirectoriesDlg = ^TASMDirectoriesDlg;
     TASMDirectoriesDlg = object(THelpDialog)
				 constructor Init(sININame : string);
			  end;

     {*** Environment options dialog box ***}
     PASMEnvironmentDlg = ^TASMEnvironmentDlg;
     TASMEnvironmentDlg = object(THelpDialog)
                                 constructor Init;
                          end;

     {*** Run parameters dialog box ***}
     PParametersDlg = ^TParametersDlg;
     TParametersDlg = object(THelpDialog)
                            constructor Init(sININame : string);
                      end;

{******}

implementation

uses VIEWS, SINI, IUTILS, ICONST, ICONTROL, HISTLIST, ISTD, DOS;

{*** Assembler options dialog ***}

constructor TASMOptionsDlg.Init(sININame : string);

var R       : TRect;
    Control : PView;

begin
     R.Assign(6, 2, 76, 21);
     inherited Init(R, 'Assembler Options');
     Options:= Options or ofCenterX or ofCenterY;
     HelpCtx:= hcOptionsAssemblerDialog;

     R.Assign(51, 3, 52, 8);
     Control:= New(PScrollBar, Init(R));
     Insert(Control);

     R.Assign(3, 3, 51, 8);
     TargetList:= New(PListBox, Init(R, 1, PScrollbar(Control)));
     TargetList^.HelpCtx:= hcAssemblerTarget;
     Insert(TargetList);

     R.Assign(2, 2, 9, 3);
     Insert(New(PLabel, Init(R, '~T~arget', Control)));

     R.Assign(54, 3, 64, 5);
     Control:= New(PButton, Init(R, '~N~ew', cmOptionsNewFormat, bfNormal));
     Control^.HelpCtx:= hcAssemblerNewTarget;
     Insert(Control);

     R.Assign(54, 5, 64, 7);
     Control:= New(PButton, Init(R, '~E~dit', cmOptionsEditFormat, bfNormal));
     Control^.HelpCtx:= hcAssemblerEditTarget;
     Insert(Control);

     R.Assign(54, 7, 64, 9);
     Control:= New(PButton, Init(R, '~D~elete', cmOptionsDelFormat, bfNormal));
     Control^.HelpCtx:= hcAssemblerDelTarget;
     Insert(Control);

     R.Assign(3, 10, 37, 14);
     Control:= New(PCheckboxes, Init(R,
                   NewSItem('Too few macro ~p~arameters',
		   NewSItem('~M~issing colon for label',
		   NewSItem('Numeric ~o~verflow',
                   NewSItem('C~y~clic macro self-references', nil))))));
     Control^.HelpCtx:= hcAssemblerWarningsMacro;
     Insert(Control);

     R.Assign(2, 9, 11, 10);
     Insert(New(PLabel, Init(R, '~W~arnings', Control)));

     R.Assign(38, 10, 66, 11);
     Control:= New(PInputLine, Init(R, 127));
     Control^.HelpCtx:= hcAssemblerCustomParams;
     Insert(Control);

     R.Assign(37, 9, 61, 10);
     Insert(New(PLabel, Init(R, 'C~u~stom NASM Parameters', Control)));

     R.Assign(38, 13, 62, 14);
     NASMLocation:= New(PInputLine, Init(R, 127));
     NASMLocation^.HelpCtx:= hcAssemblerNASMLocation;
     Insert(NASMLocation);

     R.Assign(37, 12, 51, 13);
     Insert(New(PLabel, Init(R, '~N~ASM Location', NASMLocation)));

     R.Assign(62, 13, 67, 15);
     Control:= New(PButton, Init(R, '..', cmOptionsNASMLocation, bfNormal));
     Control^.HelpCtx:= hcAssemblerNASMLocation;
     Insert(Control);

     R.Assign(14, 16, 24, 18);
     Control:= New(PButton, Init(R, 'O~K~', cmOK, bfDefault));
     Control^.HelpCtx:= hcOK;
     Insert(Control);

     R.Assign(28, 16, 38, 18);
     Control:= New(PButton, Init(R, '~C~ancel', cmCancel, bfNormal));
     Control^.HelpCtx:= hcCancel;
     Insert(Control);

     R.Assign(42, 16, 52, 18);
     Control:= New(PButton, Init(R, '~H~elp', cmHelp, bfNormal));
     Control^.HelpCtx:= hcOptionsAssemblerDialog;
     Insert(Control);

     SelectNext(False);

     ININame:= sININame;
end;

{******}

procedure TASMOptionsDlg.AddTarget(TargetInfo : TTargetRec);

var IDX  : word;
    Stop : boolean;
    Desc : string;

begin
     IDX:= 1;
     Stop:= false;

     while not Stop do
     begin
          INI_GetProfileString(ININame, 'OUTPUT_FORMATS', 'OPF_' + IntToStr(IDX), Desc, '');
          if Desc = '' then
               Stop:= true
          else
               Inc(IDX);
     end;
     INI_WriteProfileString(ININame, 'OUTPUT_FORMATS', 'OPF_' + IntToStr(IDX),
                            TargetInfo.Description + ',' + StrUpper(TargetInfo.FileExt) + ',' +
                            StrLower(TargetInfo.CmdParam));
end;

{******}

procedure TASMOptionsDlg.HandleEvent(var Event : TEvent);

{******}

 function GetFName(FileSpec, Title, IPLineTitle : string; Opts : word;
                   HistID : byte) : string;

 var PDlg   : PFileDialog;
     W      : word;
     S      : PathStr;

 begin
      GetFName:= '';
      PDlg:= New(PFileDialog, Init(FileSpec, Title, IPLineTitle, Opts, HistID));
      if PDlg <> nil then PDlg^.HelpCtx:= hcAssemblerNASMLocationDlg;
      W:= Application^.ExecView(PDlg);
      if W <> cmCancel then
      begin
           PDlg^.GetFileName(S);
           GetFName:= S;
      end;
      Dispose(PDlg, Done);
 end;

{******}

var Dlg        : PDialog;
    TargetInfo : TTargetRec;
    TargetNum  : word;
    TargetDesc : string;
    Stop       : boolean;
    FName      : string;

begin
     inherited HandleEvent(Event);

     if (Event.What and evCommand) <> 0 then
     begin
          case Event.Command of
               cmOptionsNewFormat : begin
                                         Application^.Current^.Hide;
                                         Dlg:= New(PNewTargetDlg, Init);
                                         if Application^.ExecView(Dlg) <> cmCancel then
                                         begin
                                              Dlg^.GetData(TargetInfo);
                                              AddTarget(TargetInfo);
                                              UpdateListBox(TargetList^.Focused);
                                         end;
                                         Dispose(Dlg, Done);
                                         Application^.Current^.Show;
                                    end;

              cmOptionsEditFormat : begin
                                      if TargetList^.Range > 0 then
                                      begin
                                         TargetNum:= TargetList^.Focused + 1;
                                         Application^.Current^.Hide;
                                         Dlg:= New(PEditTargetDlg, Init);
                                         INI_GetProfileString(ININame, 'OUTPUT_FORMATS',
                                                              'OPF_' + IntToStr(TargetNum),
                                                              TargetDesc, '');
                                         TargetInfo.Description:= Copy(TargetDesc, 1, Pos(',', TargetDesc) - 1);
                                         SYSTEM.Delete(TargetDesc, 1, Pos(',', TargetDesc));
                                         TargetInfo.FileExt:= Copy(TargetDesc, 1, Pos(',', TargetDesc) - 1);
                                         SYSTEM.Delete(TargetDesc, 1, Pos(',', TargetDesc));
                                         TargetInfo.CmdParam:= TargetDesc;
                                         Dlg^.SetData(TargetInfo);
                                         if Application^.ExecView(Dlg) <> cmCancel then
                                         begin
                                              Dlg^.GetData(TargetInfo);
                                              INI_WriteProfileString(ININame, 'OUTPUT_FORMATS', 'OPF_' + IntToStr(TargetNum),
                                              TargetInfo.Description + ',' + StrUpper(TargetInfo.FileExt) + ',' +
                                              StrLower(TargetInfo.CmdParam));
                                              UpdateListBox(TargetList^.Focused);
                                         end;
                                         Dispose(Dlg, Done);
                                         Application^.Current^.Show;
                                      end
                                      else MessageBox(#3'No targets to edit!', nil, mfError + mfOKButton + mfInsertInApp);
                                    end;

               cmOptionsDelFormat : begin
                                      if TargetList^.Range > 0 then
                                      begin
                                         TargetNum:= TargetList^.Focused + 1;
                                         INI_GetProfileString(ININame, 'OUTPUT_FORMATS',
                                                              'OPF_' + IntToStr(TargetNum),
                                                              TargetDesc, '');
                                         TargetInfo.Description:= Copy(TargetDesc, 1, Pos(',', TargetDesc) - 1);
                                         Application^.Current^.Hide;
                                         Dlg:= New(PDeleteTargetDlg, Init(TargetInfo));
                                         if Application^.ExecView(Dlg) <> cmCancel then
                                         begin
                                              Stop:= false;
                                              while not Stop do
                                              begin
                                                   INI_GetProfileString(ININame, 'OUTPUT_FORMATS',
                                                                        'OPF_' + IntToStr(TargetNum + 1),
                                                                        TargetDesc, '');
                                                   INI_WriteProfileString(ININame, 'OUTPUT_FORMATS',
                                                                          'OPF_' + IntToStr(TargetNum),
                                                                          TargetDesc);
                                                   if TargetDesc = '' then
                                                      Stop:= true
                                                   else
                                                      Inc(TargetNum);
                                              end;
                                              UpdateListBox(TargetList^.Focused);
                                         end;
                                         Dispose(Dlg, Done);
                                         Application^.Current^.Show;
                                      end
                                      else MessageBox(#3'No targets to delete!', nil, mfError + mfOKButton + mfInsertInApp);
                                    end;

            cmOptionsNASMLocation : begin
                                         Application^.Current^.Hide;
                                         FName:= IUTILS.StrUpper(GetFName('*.EXE', 'NASM Location', '~N~ame',
                                                                          fdOKButton + fdHelpButton, hiNASMLocation));

                                         if (FName <> '') and FileExists(FName) then
                                         begin
                                            DisposeStr(NASMLocation^.Data);
                                            NASMLocation^.Data:= NewStr(FName);
                                            NASMLocation^.Draw;
                                         end;
                                         Application^.Current^.Show;
                                         ClearEvent(Event);
                                    end;

          end;
     end;
end;

{******}

procedure TASMOptionsDlg.UpdateListBox(Selection : word);

var List : PSCollection;
    IDX  : word;
    Stop : boolean;
    Desc : string;

begin
     {*** Get list of output file formats ***}
     List:= New(PSCollection, Init(10, 1));
     IDX:= 1;
     Stop:= false;

     while not Stop do
     begin
          INI_GetProfileString(ININame, 'OUTPUT_FORMATS', 'OPF_' + IntToStr(IDX), Desc, '');
          if Desc = '' then
               Stop:= true
          else
          begin
               if Pos(',', Desc) <> 0 then SYSTEM.Delete(Desc, Pos(',', Desc), 255);
               List^.Insert(NewStr(Desc));
               Inc(IDX);
          end;
     end;
     TargetList^.NewList(List);
     TargetList^.FocusItem(Selection);
end;

{*** Validation routines ***}

function ValidExtension(Ext : string) : boolean;

const InvalidChars : array[0..9] of char = (' ', '<', '>', ',', '.',
                                            '?', '*', 'Ý', '/', '\');

var Found : boolean;
    Loop  : byte;

begin
     if Ext <> '' then
     begin
          Ext:= StrUpper(Ext);
          Found:= false;

          for Loop:= 0 to 9 do
              if Pos(InvalidChars[Loop], Ext) <> 0 then Found:= true;

          ValidExtension:= not Found;
     end
     else ValidExtension:= true;
end;

{*** New target dialog ***}

constructor TNewTargetDlg.Init;

var R       : TRect;
    Control : PView;

begin
     R.Assign(9, 3, 71, 19);
     inherited Init(R, 'Target Assistant - Add new target');
     Options:= Options or ofCenterX or ofCenterY;
     HelpCtx:= hcAssemblerNewTarget;

     R.Assign(32, 6, 54, 7);
     Control:= New(PInputLine, Init(R, 45));
     Insert(Control);

     R.Assign(8, 6, 20, 7);
     Insert(New(PLabel, Init(R, '~D~escription', Control)));

     R.Assign(32, 8, 37, 9);
     Control:= New(PInputLine, Init(R, 3));
     Insert(Control);

     R.Assign(8, 8, 30, 9);
     Insert(New(PLabel, Init(R, '~O~utput file extension', Control)));

     R.Assign(32, 10, 44, 11);
     Control:= New(PInputLine, Init(R, 10));
     Insert(Control);

     R.Assign(8, 10, 31, 11);
     Insert(New(PLabel, Init(R, 'Command line ~p~arameter', Control)));

     R.Assign(8, 13, 18, 15);
     Control:= New(PButton, Init(R, 'O~K~', cmOK, bfDefault));
     Control^.HelpCtx:= hcOK;
     Insert(Control);

     R.Assign(26, 13, 36, 15);
     Control:= New(PButton, Init(R, '~C~ancel', cmCancel, bfNormal));
     Control^.HelpCtx:= hcCancel;
     Insert(Control);

     R.Assign(44, 13, 54, 15);
     Control:= New(PButton, Init(R, '~H~elp', cmHelp, bfNormal));
     Insert(Control);

     R.Assign(3, 2, 4, 3);
     Control:= New(PColouredText, Init(R, 'A', $74));
     Insert(Control);

     R.Assign(4, 3, 5, 4);
     Control:= New(PColouredText, Init(R, 'S', $79));
     Insert(Control);

     R.Assign(5, 4, 6, 5);
     Control:= New(PColouredText, Init(R, 'M', $7E));
     Insert(Control);

     R.Assign(8, 2, 54, 4);
     Control:= New(PStaticText, Init(R, 'Complete the input boxes below to'+
                                        'enable support for a new NASM output'+
                                        ' format.'));
     Insert(Control);

     R.Assign(56, 4, 57, 5);
     Control:= New(PColouredText, Init(R, 'M', $7E));
     Insert(Control);

     R.Assign(57, 3, 58, 4);
     Control:= New(PColouredText, Init(R, 'S', $79));
     Insert(Control);

     R.Assign(58, 2, 59, 3);
     Control:= New(PColouredText, Init(R, 'A', $74));
     Insert(Control);

     SelectNext(False);
end;

{******}

function TNewTargetDlg.Valid(Command : word): boolean;

var Result     : boolean;
    TargetInfo : TTargetRec;

begin
     Result:= inherited Valid(Command);
     if (Result = true) and (Command = cmOK) then
     begin
          GetData(TargetInfo);
          Result:= false;
          if TargetInfo.Description <> '' then
           if Pos(',', TargetInfo.Description) = 0 then
            if ValidExtension(TargetInfo.FileExt) then
             if TargetInfo.CmdParam <> '' then
                Result:= true
             else
                MessageBox(#3'You must enter a NASM command line parameter.', nil, mfError + mfOKButton + mfInsertInApp)
            else
               MessageBox(#3'You must enter a valid DOS file extension.', nil, mfError + mfOKButton + mfInsertInApp)
            else
             MessageBox(#3'The target description can contain any characters except for commas.', nil,
                        mfError + mfOKButton + mfInsertInApp)
         else
            MessageBox(#3'You must enter a target description.', nil, mfError + mfOKButton + mfInsertInApp);
     end;
     Valid:= Result;
end;

{*** Edit target dialog ***}

constructor TEditTargetDlg.Init;

var R       : TRect;
    Control : PView;

begin
     R.Assign(9, 3, 71, 19);
     inherited Init(R, 'Target Assistant - Edit target properties');
     Options:= Options or ofCenterX or ofCenterY;
     HelpCtx:= hcAssemblerEditTarget;

     R.Assign(32, 6, 54, 7);
     Control:= New(PInputLine, Init(R, 45));
     Insert(Control);

     R.Assign(8, 6, 20, 7);
     Insert(New(PLabel, Init(R, '~D~escription', Control)));

     R.Assign(32, 8, 37, 9);
     Control:= New(PInputLine, Init(R, 3));
     Insert(Control);

     R.Assign(8, 8, 30, 9);
     Insert(New(PLabel, Init(R, '~O~utput file extension', Control)));

     R.Assign(32, 10, 44, 11);
     Control:= New(PInputLine, Init(R, 10));
     Insert(Control);

     R.Assign(8, 10, 31, 11);
     Insert(New(PLabel, Init(R, 'Command line ~p~arameter', Control)));

     R.Assign(8, 13, 18, 15);
     Control:= New(PButton, Init(R, 'O~K~', cmOK, bfDefault));
     Control^.HelpCtx:= hcOK;
     Insert(Control);

     R.Assign(26, 13, 36, 15);
     Control:= New(PButton, Init(R, '~C~ancel', cmCancel, bfNormal));
     Control^.HelpCtx:= hcCancel;
     Insert(Control);

     R.Assign(44, 13, 54, 15);
     Control:= New(PButton, Init(R, '~H~elp', cmHelp, bfNormal));
     Insert(Control);

     R.Assign(3, 2, 4, 3);
     Control:= New(PColouredText, Init(R, 'A', $74));
     Insert(Control);

     R.Assign(4, 3, 5, 4);
     Control:= New(PColouredText, Init(R, 'S', $79));
     Insert(Control);

     R.Assign(5, 4, 6, 5);
     Control:= New(PColouredText, Init(R, 'M', $7E));
     Insert(Control);

     R.Assign(8, 2, 54, 4);
     Control:= New(PStaticText, Init(R, 'Make any necessary changes to the ' +
                                        'properties of an existing target.'));
     Insert(Control);

     R.Assign(56, 4, 57, 5);
     Control:= New(PColouredText, Init(R, 'M', $7E));
     Insert(Control);

     R.Assign(57, 3, 58, 4);
     Control:= New(PColouredText, Init(R, 'S', $79));
     Insert(Control);

     R.Assign(58, 2, 59, 3);
     Control:= New(PColouredText, Init(R, 'A', $74));
     Insert(Control);

     SelectNext(False);
end;

{******}

function TEditTargetDlg.Valid(Command : word): boolean;

var Result     : boolean;
    TargetInfo : TTargetRec;

begin
     Result:= inherited Valid(Command);
     if (Result = true) and (Command = cmOK) then
     begin
          GetData(TargetInfo);
          Result:= false;
          if TargetInfo.Description <> '' then
             if ValidExtension(TargetInfo.FileExt) then
                if TargetInfo.CmdParam <> '' then
                   Result:= true
                else
                   MessageBox(#3'You must enter a NASM command line parameter.', nil, mfError + mfOKButton + mfInsertInApp)
             else
                 MessageBox(#3'You must enter a valid DOS file extension.', nil, mfError + mfOKButton + mfInsertInApp)
          else
              MessageBox(#3'You must enter a target description.', nil, mfError + mfOKButton + mfInsertInApp);
     end;
     Valid:= Result;
end;

{*** Delete target dialog ***}

constructor TDeleteTargetDlg.Init(TargetInfo : TTargetRec);

var R       : TRect;
    Control : PView;

begin
     R.Assign(9, 5, 71, 18);
     inherited Init(R, 'Target Assistant - Delete target');
     Options:= Options or ofCenterX or ofCenterY;
     HelpCtx:= hcAssemblerDelTarget;

     R.Assign(8, 10, 18, 12);
     Control:= New(PButton, Init(R, '~D~elete', cmOK, bfDefault));
     Control^.HelpCtx:= hcOK;
     Insert(Control);

     R.Assign(26, 10, 36, 12);
     Control:= New(PButton, Init(R, '~C~ancel', cmCancel, bfNormal));
     Control^.HelpCtx:= hcCancel;
     Insert(Control);

     R.Assign(44, 10, 54, 12);
     Control:= New(PButton, Init(R, '~H~elp', cmHelp, bfNormal));
     Control^.HelpCtx:= hcAssemblerDelTarget;
     Insert(Control);

     R.Assign(3, 2, 4, 3);
     Control:= New(PColouredText, Init(R, 'A', $74));
     Insert(Control);

     R.Assign(4, 3, 5, 4);
     Control:= New(PColouredText, Init(R, 'S', $79));
     Insert(Control);

     R.Assign(5, 4, 6, 5);
     Control:= New(PColouredText, Init(R, 'M', $7E));
     Insert(Control);

     R.Assign(8, 2, 54, 4);
     Control:= New(PStaticText, Init(R, 'Take care when using this option, ' +
                                        'once a target has been deleted it ' +
                                        'cannot be restored.'));
     Insert(Control);

     R.Assign(56, 4, 57, 5);
     Control:= New(PColouredText, Init(R, 'M', $7E));
     Insert(Control);

     R.Assign(57, 3, 58, 4);
     Control:= New(PColouredText, Init(R, 'S', $79));
     Insert(Control);

     R.Assign(58, 2, 59, 3);
     Control:= New(PColouredText, Init(R, 'A', $74));
     Insert(Control);

     R.Assign(8, 6, 54, 9);
     Control:= New(PColouredText, Init(R, 'Please confirm deletion of ''' + TargetInfo.Description + ''' target.', $74));
     Insert(Control);

     SelectNext(False);
end;

{*** Directories dialog ***}

constructor TASMDirectoriesDlg.Init(sININame : string);

var R        : TRect;
    Control  : PView;
    Loop     : word;
    History  : string;

begin
     R.Assign(15, 7, 65, 16);
     inherited Init(R, 'Directories');
     Options:= Options or ofCenterX or ofCenterY;
     HelpCtx:= hcOptionsDirectoriesDialog;

     R.Assign(21, 2, 44, 3);
     Control:= New(PInputLine, Init(R, 127));
     Control^.HelpCtx:= hcDirectoriesInclude;
     Insert(Control);

     R.Assign(44, 2, 47, 3);
     Insert(New(PHistory, Init(R, PInputline(Control), hiIncludeDir)));

     R.Assign(2, 2, 20, 3);
     Insert(New(PLabel, Init(R, '~I~nclude directory', Control)));

     R.Assign(21, 4, 44, 5);
     Control:= New(PInputLine, Init(R, 127));
     Control^.HelpCtx:= hcDirectoriesOutput;
     Insert(Control);

     R.Assign(44, 4, 47, 5);
     Insert(New(PHistory, Init(R, PInputline(Control), hiOutputDir)));

     R.Assign(2, 4, 19, 5);
     Insert(New(PLabel, Init(R, '~O~utput directory', Control)));

     R.Assign(13, 6, 23, 8);
     Control:= New(PButton, Init(R, 'O~K~', cmOK, bfDefault));
     Control^.HelpCtx:= hcOK;
     Insert(Control);

     R.Assign(25, 6, 35, 8);
     Control:= New(PButton, Init(R, '~C~ancel', cmCancel, bfNormal));
     Control^.HelpCtx:= hcCancel;
     Insert(Control);

     R.Assign(37, 6, 47, 8);
     Control:= New(PButton, Init(R, '~H~elp', cmHelp, bfNormal));
     Control^.HelpCtx:= hcOptionsDirectoriesDialog;
     Insert(Control);

     SelectNext(False);
end;

{*** Environment options dialog ***}

constructor TASMEnvironmentDlg.Init;

var R       : TRect;
    Control : PView;

begin
     R.Assign(20, 1, 59, 20);
     inherited Init(R, 'Environment Options');
     Options:= Options or ofCenterX or ofCenterY;
     HelpCtx:= hcOptionsEnvironmentDialog;

     R.Assign(3, 3, 36, 5);
     Control:= New(PRadioButtons, Init(R, NewSItem('~2~5 lines',
                                          NewSItem('~4~3/50 lines', nil))));
     Control^.HelpCtx:= hcScreenSize80x25;
     Insert(Control);

     R.Assign(2, 2, 14, 3);
     Insert(New(PLabel, Init(R, 'Screen size', Control)));

     R.Assign(3, 7, 36, 10);
     Control:= New(PCheckboxes, Init(R, NewSItem('~C~reate backup files',
                                        NewSItem('~A~utosave on assemble',
                                        NewSItem('~S~yntax highlighting', nil)))));
     Control^.HelpCtx:= hcEditorBackup;
     Insert(Control);

     R.Assign(2, 6, 9, 7);
     Insert(New(PLabel, Init(R, 'Editor', Control)));

     R.Assign(3, 12, 36, 13);
     Control:= New(PCheckboxes, Init(R, NewSItem('Autosave on e~x~it', nil)));
     Control^.HelpCtx:= hcDesktopAutosave;
     Insert(Control);

     R.Assign(2, 11, 10, 12);
     Insert(New(PLabel, Init(R, 'Desktop', Control)));

     R.Assign(2, 15, 12, 17);
     Control:= New(PButton, Init(R, 'O~K~', cmOK, bfDefault));
     Control^.HelpCtx:= hcOK;
     Insert(Control);

     R.Assign(14, 15, 24, 17);
     Control:= New(PButton, Init(R, '~C~ancel', cmCancel, bfNormal));
     Control^.HelpCtx:= hcCancel;
     Insert(Control);

     R.Assign(26, 15, 36, 17);
     Control:= New(PButton, Init(R, '~H~elp', cmHelp, bfNormal));
     Control^.HelpCtx:= hcOptionsEnvironmentDialog;
     Insert(Control);

     SelectNext(False);
end;

{*** Run parameters dialog box ***}

constructor TParametersDlg.Init(sININame : string);

var R        : TRect;
    Control  : PView;
    History  : string;
    Loop     : byte;

begin
     R.Assign(10, 2, 60, 9);
     inherited Init(R, 'Program parameters');
     Options:= Options or ofCenterX or ofCenterY;
     HelpCtx:= hcAssembleParamDialog;

     R.Assign(14, 2, 44, 3);
     Control:= New(PInputLine, Init(R, 255));
     Control^.HelpCtx:= hcAssembleParamList;
     Insert(Control);

     R.Assign(44, 2, 47, 3);
     Insert(New(PHistory, Init(R, PInputline(Control), hiRunParam)));

     R.Assign(2, 2, 13, 3);
     Insert(New(PLabel, Init(R, '~P~arameters', Control)));

     R.Assign(13, 4, 23, 6);
     Control:= New(PButton, Init(R, 'O~K~', cmOK, bfDefault));
     Control^.HelpCtx:= hcOK;
     Insert(Control);

     R.Assign(25, 4, 35, 6);
     Control:= New(PButton, Init(R, '~C~ancel', cmCancel, bfNormal));
     Control^.HelpCtx:= hcCancel;
     Insert(Control);

     R.Assign(37, 4, 47, 6);
     Control:= New(PButton, Init(R, '~H~elp', cmHelp, bfNormal));
     Control^.HelpCtx:= hcAssembleParamDialog;
     Insert(Control);

     SelectNext(False);
end;

{******}

end.