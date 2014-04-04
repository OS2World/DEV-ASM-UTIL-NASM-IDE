unit IEDIT;

(* Information
   ßßßßßßßßßßß

   Program Title : TEditor unit
   External name : IEDIT.TPU
   Version       : 1.7
   Start date    : 13/04/1997
   Last update   : 18/05/2002
   Author        : Rob Anderton
   Description   : Unit containing the TFileEditor descendant TASMEditor which
                   handles the cmAssembleXXXX commands and syntax highlighting.
                   Based on NEWEDIT.PAS by Al Andersen(amongst others!).
*)

{$F+,I-,O+,S-,V-,X+,D-}

interface

{******}

uses DRIVERS, OBJECTS, VIEWS, DIALOGS, IUTILS, SINI, IHELP, IOPT;

{*** Constants ***}

const
     {*** Command constants for saving files and finding text ***}
     cmFind        = 82;
     cmReplace     = 83;
     cmSearchAgain = 84;

     {*** New editor commands that user may want to put into a menu ***}
     cmEndPage     = 201;
     cmHomePage    = 202;
     cmIndentMode  = 203;
     cmJumpLine    = 204;
     cmScrollDown  = 205;
     cmScrollUp    = 206;
     cmSelectWord  = 207;
     cmSetTabs     = 208;
     cmTabKey      = 209;

     {*** Command constants for cursor movement and modifying text ***}
     cmCharLeft      = 500;
     cmCharRight     = 501;
     cmWordLeft      = 502;
     cmWordRight     = 503;
     cmLineStart     = 504;
     cmLineEnd       = 505;
     cmLineUp        = 506;
     cmLineDown      = 507;
     cmPageUp        = 508;
     cmPageDown      = 509;
     cmTextStart     = 510;
     cmTextEnd       = 511;
     cmNewLine       = 512;
     cmBackSpace     = 513;
     cmDelChar       = 514;
     cmDelWord       = 515;
     cmDelStart      = 516;
     cmDelEnd        = 517;
     cmDelLine       = 518;
     cmInsMode       = 519;
     cmStartSelect   = 520;
     cmHideSelect    = 521;
     cmUpdateTitle   = 523;
     cmBludgeonStats = 524;

     {*** Editor constants for dialog boxes ***}
     edOutOfMemory         = 0;
     edReadError           = 1;
     edWriteError          = 2;
     edCreateError         = 3;
     edSaveModify          = 4;
     edSaveUntitled        = 5;
     edSaveAs              = 6;
     edFind                = 7;
     edSearchFailed        = 8;
     edReplace             = 9;
     edReplacePrompt       = 10;
     edJumpToLine          = 11;
     edSetTabStops         = 12;
     edPrintError          = 13;
     edLineTooLong         = 14;

     {*** Editor flag constants for dialog options ***}
     efCaseSensitive   = $0001;
     efWholewordsOnly  = $0002;
     efPromptOnReplace = $0004;
     efReplaceAll      = $0008;
     efDoReplace       = $0010;
     efBackupFiles     = $0100;
     efSyntaxHighlight = $1000;

     {*** Constants for object palettes ***}
     CIndicator    = #2#3;
     CEditor       = #6#7;
     CMemo         = #26#27;
     CASMEditor    = CEditor + #1#2#3;
     {*** Normal, selected, comment, keyword, register, directive ***}

     {*** Length constants ***}
     MaxLineLength   = 256;
     TabStopLength   = 74;

{*** Data types ***}

type
     {*** Editor dialog function ***}
     TEditorDialog = function(Dialog : integer; Info : pointer) : word;

     {*** Edit buffer (for storing text) ***}
     PEditBuffer = ^TEditBuffer;
     TEditBuffer = array[0..65519] of char;

     {*** Memo data (for accessing text in a memo control) ***}
     TMemoData = record
                       Length : word;
                       Buffer : TEditBuffer;
     end;

     {*** Find dialog data ***}
     TFindDialogRec = record
                            Find    : string[80];
                            Options : word;
                      end;

     {*** Replace dialog data ***}
     TReplaceDialogRec = record
                               Find    : String[80];
                               Replace : String[80];
                               Options : word;
                         end;

     {*** Tab stop information ***}
     TTabStopRec = record
                         TabString : string [TabStopLength];
                   end;

{*** Object types ***}

type
     {*** TIndicator - line and column counter used in editor windows ***}
     PIndicator = ^TIndicator;
     TIndicator = object(TView)
                         Location   : TPoint;   {Where the cursor is}
                         Modified   : boolean;  {True if the file has been
                                                 modified}
                         AutoIndent : boolean;  {True if auto-indent mode is
                                                 active}

                         constructor Init(var Bounds : TRect);

                         procedure   Draw; virtual;

                         function    GetPalette : PPalette; virtual;

                         procedure   HandleEvent(var Event : TEvent); virtual;

                         procedure   SetState(AState : word;
                                              Enable : boolean); virtual;

                         procedure   SetValue(ALocation    : TPoint;
                                              IsAutoIndent : boolean;
                                              IsModified   : boolean);

                  end;


     {*** TEditor - the enhanced text editor ***}
     PEditor = ^TEditor;
     TEditor = object(TView)
                      HScrollBar         : PScrollBar;
                      VScrollBar         : PScrollBar;
                      Indicator          : PIndicator;
                      Buffer             : PEditBuffer;
                      BufSize            : word;
                      BufLen             : word;
                      GapLen             : word;
                      SelStart           : word;
                      SelEnd             : word;
                      CurPtr             : word;
                      CurPos             : TPoint;
                      Delta              : TPoint;
                      Limit              : TPoint;
                      DrawLine           : integer;
                      DrawPtr            : word;
                      DelCount           : word;
                      InsCount           : word;
                      IsValid            : boolean;
                      CanUndo            : boolean;
                      Modified           : boolean;
                      Selecting          : boolean;
                      Overwrite          : boolean;
                      AutoIndent         : boolean;
                      LineNumber         : string[4];
                      TabSettings        : string[TabStopLength];

                      constructor Init(var Bounds       : TRect;
                                           AHScrollBar,
                                           AVScrollBar  : PScrollBar;
                                           AIndicator   : PIndicator;
                                           ABufSize     : word);

                      constructor Load(var S : TStream);

                      destructor  Done; virtual;

                      function    Bufchar(P : word) : char;

                      function    BufPtr(P : word) : word;

                      procedure   ChangeBounds(var Bounds : TRect); virtual;

                      procedure   ConvertEvent(var Event : TEvent); virtual;

                      function    CursorVisible : boolean;

                      procedure   DeleteSelect;

                      procedure   DoneBuffer; virtual;

                      procedure   Draw; virtual;

                      function    GetCurrentWord : string; virtual;

                      function    GetPalette : PPalette; virtual;

                      procedure   HandleEvent(var Event : TEvent); virtual;

                      procedure   InitBuffer; virtual;

                      function    InsertBuffer(var P          : PEditBuffer;
                                                   Offset,
                                                   Length     : word;
                                                   AllowUndo,
                                                   SelectText : boolean) : boolean;

                      function    InsertFrom(Editor : PEditor) : boolean; virtual;

                      function    InsertText(Text       : Pointer;
                                             Length     : word;
                                             SelectText : boolean) : boolean;

                      procedure   ScrollTo(X, Y : integer);

                      function    Search(const FindStr : string;
                                               Opts    : word) : boolean;

                      function    SetBufSize(NewSize : word) : boolean; virtual;

                      procedure   SetCmdState(Command : word;
                                              Enable  : boolean);

                      procedure   SetSelect(NewStart, NewEnd : word;
                                            CurStart         : boolean);

                      procedure   SetState(AState : word;
                                           Enable : boolean); virtual;

                      procedure   Store(var S : TStream);

                      procedure   TrackCursor(Center : boolean);

                      procedure   Undo;

                      procedure   UpdateCommands(Enable : boolean); virtual;

                      function    Valid(Command : word) : boolean; virtual;

               private

                      KeyState       : integer;
                      LockCount      : byte;
                      UpdateFlags    : byte;

                      function   CharPos(P, Target : word) : integer;

                      function   CharPtr(P : word; Target : integer) : word;

                      function   ClipCopy : boolean;

                      procedure  ClipCut;

                      procedure  ClipPaste;

                      procedure  DeleteRange(StartPtr, EndPtr : word;
                                             DelSelect        : boolean);

                      procedure  DoSearchReplace;

                      procedure  DoUpdate; virtual;

                      procedure  DrawLines(Y, Count : integer;
                                           LinePtr  : word); virtual;

                      procedure  FormatLine(var DrawBuf;
                                                LinePtr : word;
                                                Width   : integer;
                                                Colors  : word); virtual;

                      procedure  Find;

                      function   GetMousePtr(Mouse : TPoint) : word;

                      function   HasSelection : boolean;

                      procedure  HideSelect;

                      function   IsClipboard : boolean;

                      procedure  JumpToLine(SelectMode : byte);

                      function   LineEnd(P : word) : word;

                      function   LineMove(P : word; Count : integer) : word;

                      function   LineStart(P : word) : word;

                      procedure  Lock;

                      function   NewLine(SelectMode : byte) : boolean;

                      function   NextChar(P : word) : word;

                      function   NextLine(P : word) : word;

                      function   NextWord(P : word) : word;

                      function   PrevChar(P : word) : word;

                      function   PrevLine(P : word) : word;

                      function   PrevWord(P : word) : word;

                      procedure  Remove_EOL_Spaces(SelectMode : byte);

                      procedure  Replace;

                      procedure  ScrollDown;

                      procedure  ScrollUp;

                      procedure  SelectWord;

                      procedure  SetBufLen(Length : word);

                      procedure  SetCurPtr(P : word; SelectMode : byte);

                      procedure  SetTabs;

                      procedure  StartSelect;

                      procedure  TabKey(SelectMode : byte);

                      procedure  ToggleInsMode;

                      procedure  Unlock;

                      procedure  Update(AFlags : byte); virtual;

               end;

     {*** TMemo - memo control allowing text editing with dialog boxes ***}
     PMemo = ^TMemo;
     TMemo = object(TEditor)
                    constructor Load(var S : TStream);

                    function    DataSize : word; virtual;

                    procedure   GetData(var Rec); virtual;

                    function    GetPalette : PPalette; virtual;

                    procedure   HandleEvent(var Event : TEvent); virtual;

                    procedure   SetData(var Rec); virtual;

                    procedure   Store(var S : TStream);
             end;


     {*** TFileEditor - descendant of TEditor for editing disk files ***}
     PFileEditor = ^TFileEditor;
     TFileEditor = object(TEditor)
                          FileName : FNameStr;

                          constructor Init(var Bounds           : TRect;
                                               AHScrollBar,
                                               AVScrollBar      : PScrollBar;
                                               AIndicator       : PIndicator;
                                               AFileName        : FNameStr);

                          constructor Load(var S : TStream);

                          procedure   DoneBuffer; virtual;

                          procedure   HandleEvent(var Event : TEvent); virtual;

                          procedure   InitBuffer; virtual;

                          function    LoadFile : boolean;

                          function    Save : boolean;

                          function    SaveAs : boolean;

                          function    SaveFile : boolean;

                          function    SetBufSize(NewSize : word) : boolean; virtual;

                          procedure   Store(var S : TStream);

                          procedure   UpdateCommands(Enable : boolean); virtual;

                          function    Valid(Command : word) : boolean; virtual;
                   end;

     {*** TEditWindow - a TWindow descendant to hold a file editor ***}
     PEditWindow = ^TEditWindow;
     TEditWindow = object(TWindow)
                          Editor : PFileEditor;

                          constructor Init(var Bounds   : TRect;
                                               FileName : FNameStr;
                                               ANumber  : integer);

                          constructor Load(var S : TStream);

                          procedure   Close; virtual;

                          function    GetTitle(MaxSize : integer) : TTitleStr; virtual;

                          procedure   HandleEvent(var Event : TEvent); virtual;

                          procedure   SizeLimits(var Min, Max: TPoint); virtual;

                          procedure   Store(var S : TStream);

                   end;

{*** NASM Specific Editor OBJECTS ***}

type
     {*** NASM editor window ***}
     PASMEditWindow = ^TASMEditWindow;
     TASMEditWindow = object(TEditWindow)
                            constructor Init(var Bounds   : TRect;
                                                 FileName : FNameStr;
                                                 ANumber  : integer);

                            destructor  Done; virtual;

                            constructor Load(var S : TStream);

                            procedure   Close; virtual;

                            function    GetPalette : PPalette; virtual;

                            function    GetTitle(MaxSize : integer) : TTitleStr; virtual;

                            procedure   HandleEvent(var Event : TEvent); virtual;

                            procedure   SizeLimits(var Min, Max: TPoint); virtual;
                      end;

     {*** NASM syntax highlighting file editor ***}
     PASMEditor = ^TASMEditor;
     TASMEditor = object(TFileEditor)
                        procedure HandleEvent(var Event : TEvent); virtual;

                        procedure Assemble(Warning : string; Run : boolean); virtual;

                        procedure AssembleRun; virtual;

                        procedure DirectJump(Line : word); virtual;

                        procedure Draw; virtual;

                        procedure DrawLines(Y, Count : integer;
                                            LinePtr  : word); virtual;

                        procedure FormatLine(var DrawBuf;
                                                 LinePtr : word;
                                                 Width   : integer;
                                                 Colors  : word); virtual;

                        function  GetPalette : PPalette; virtual;

                        procedure SyntaxHighlight(var DrawBuf); virtual;

                        function  Print : boolean; virtual;

                        procedure UpdateCommands(Enable : boolean); virtual;
                  end;

{*** Functions / procedures ***}

function DefEditorDialog(Dialog : integer; Info : Pointer) : word;

function CreateFindDialog : PHelpDialog;

function CreateReplaceDialog : PHelpDialog;

function CreateJumpLineDialog : PHelpDialog;

function CreateTabStopDialog : PHelpDialog;

function StdEditorDialog(Dialog: integer; Info: Pointer): word;

function ASMEditorDlg(Dialog: integer; Info: Pointer): word;

procedure RegisterEditors;

{*** Additional constants ***}

const
      {*** Editor character set ***}
      WordChars : set of char = ['!'..#255];

      {*** Standard editor dialog ***}
      EditorDialog   : TEditorDialog = DefEditorDialog;
      EditorFlags    : word = efBackupFiles + efPromptOnReplace;

      FindStr        : String[80] = '';
      ReplaceStr     : String[80] = '';
      Clipboard      : PEditor = nil;

      {*** NASM dialog ***}
      ASMEditorDialog : TEditorDialog = ASMEditorDlg;

{******}

implementation

{******}

uses APP, MEMORY,  MSGBOX, DOS, PRINTER, ICONST,
     IOPS, IMAIN, IPROG, ISTD, IASM;

{*** Constants ***}

{*** Registration records ***}

const REditor   : TStreamRec = (ObjType : 70;
                                VMTLink : Ofs(TypeOf(TEditor)^);
                                Load    : @TEditor.Load;
                                Store   : @TEditor.Store);

      RMemo     : TStreamRec = (ObjType : 71;
                                VMTLink : Ofs(TypeOf(TMemo)^);
                                Load    : @TMemo.Load;
                                Store   : @TMemo.Store);

      RFileEditor : TStreamRec = (ObjType : 72;
                                  VMTLink : Ofs(TypeOf(TFileEditor)^);
                                  Load    : @TFileEditor.Load;
                                  Store   : @TFileEditor.Store);

      RIndicator : TStreamRec = (ObjType : 73;
                                 VMTLink : Ofs(TypeOf(TIndicator)^);
                                 Load    : @TIndicator.Load;
                                 Store   : @TIndicator.Store);

      REditWindow : TStreamRec = (ObjType : 74;
                                  VMTLink : Ofs(TypeOf(TEditWindow)^);
                                  Load    : @TEditWindow.Load;
                                  Store   : @TEditWindow.Store);


      RASMEditor     : TStreamRec = (ObjType : idEditor;
                                     VMTLink : Ofs(TypeOf(TASMEditor)^);
                                     Load    : @TFileEditor.Load;
                                     Store   : @TFileEditor.Store);

      RASMEditWindow : TStreamRec = (ObjType : idEditWindow;
                                     VMTLink : Ofs(TypeOf(TASMEditWindow)^);
                                     Load    : @TASMEditWindow.Load;
                                     Store   : @TEditWindow.Store);

const
      {*** Update flag constants ***}
      ufUpdate = $01;
      ufLine   = $02;
      ufView   = $04;
      ufStats  = $05;

      {*** SelectMode constants ***}
      smExtend = $01;
      smDouble = $02;

      {*** Search results ***}
      sfSearchFailed = $FFFF;

      {*** Arrays that hold all the command keys and options ***}

      FirstKeys : array[0..44 * 2] of word = (44, Ord(^A),     cmWordLeft,
                                                  Ord(^C),     cmPageDown,
                                                  Ord(^D),     cmCharRight,
                                                  Ord(^E),     cmLineUp,
                                                  Ord(^F),     cmWordRight,
                                                  Ord(^G),     cmDelchar,
                                                  Ord(^H),     cmBackSpace,
                                                  Ord(^I),     cmTabKey,
                                                  Ord(^J),     $FF04,
                                                  Ord(^K),     $FF02,
                                                  Ord(^L),     cmSearchAgain,
                                                  Ord(^M),     cmNewLine,
                                                  Ord(^O),     $FF03,
                                                  Ord(^Q),     $FF01,
                                                  Ord(^R),     cmPageUp,
                                                  Ord(^S),     cmCharLeft,
                                                  Ord(^T),     cmDelword,
                                                  Ord(^U),     cmUndo,
                                                  Ord(^V),     cmInsMode,
                                                  Ord(^W),     cmScrollUp,
                                                  Ord(^X),     cmLineDown,
                                                  Ord(^Y),     cmDelLine,
                                                  Ord(^Z),     cmScrollDown,
                                                  kbLeft,      cmcharLeft,
                                                  kbRight,     cmcharRight,
                                                  kbCtrlLeft,  cmwordLeft,
                                                  kbCtrlRight, cmwordRight,
                                                  kbHome,      cmLineStart,
                                                  kbEnd,       cmLineEnd,
                                                  kbCtrlHome,  cmHomePage,
                                                  kbCtrlEnd,   cmEndPage,
                                                  kbUp,        cmLineUp,
                                                  kbDown,      cmLineDown,
                                                  kbPgUp,      cmPageUp,
                                                  kbPgDn,      cmPageDown,
                                                  kbCtrlPgUp,  cmTextStart,
                                                  kbCtrlPgDn,  cmTextEnd,
                                                  kbIns,       cmInsMode,
                                                  kbDel,       cmDelchar,
                                                  kbCtrlBack,  cmDelStart,
                                                  kbShiftIns,  cmPaste,
                                                  kbShiftDel,  cmCut,
                                                  kbCtrlIns,   cmCopy,
                                                  kbCtrlDel,   cmClear);

      QuickKeys : array[0..10 * 2] of word = (10,  Ord('A'), cmReplace,
                                                   Ord('C'), cmTextEnd,
                                                   Ord('D'), cmLineEnd,
                                                   Ord('F'), cmFind,
                                                   Ord('H'), cmDelStart,
                                                   Ord('I'), cmIndentMode,
                                                   Ord('L'), cmUndo,
                                                   Ord('R'), cmTextStart,
                                                   Ord('S'), cmLineStart,
                                                   Ord('Y'), cmDelEnd);

      BlockKeys : array[0..9 * 2] of word = (9,  Ord('B'), cmStartSelect,
                                                 Ord('C'), cmPaste,
                                                 Ord('D'), cmSave,
                                                 Ord('F'), cmSaveAs,
                                                 Ord('H'), cmHideSelect,
                                                 Ord('K'), cmCopy,
                                                 Ord('S'), cmSave,
                                                 Ord('T'), cmSelectWord,
                                                 Ord('Y'), cmCut);

      FormatKeys : array[0..1 * 2] of word = (1, Ord('I'), cmSetTabs);

      JumpKeys   : array[0..1 * 2] of word = (1, Ord('L'), cmJumpLine);

      KeyMap     : array[0..4] of pointer =(@FirstKeys,
                                            @QuickKeys,
                                            @BlockKeys,
                                            @FormatKeys,
                                            @JumpKeys);

{*** Functions/procedures ***}

(* DefEditorDialog - this is the default value assigned to the EditorDialog
                     variable. DefEditorDialog shows no dialog boxes at all,
                     and simply returns the value cmCancel, as if any dialog
                     it was called to show had been canceled.

                     Dialog - a code indicating the dialog to display.
                     Info   - additional information for the dialog.

                     Returns cmCancel.
*)

function DefEditorDialog(Dialog : integer; Info : pointer) : word;

begin
     DefEditorDialog:= VIEWS.cmCancel;
end;

(* CreateFindDialog - constructs and returns a pointer to the standard text
                      search dialog box used by StdEditorDialog.

                      Returns pointer to dialog box.
*)

function CreateFindDialog : PHelpDialog;

var D       : PHelpDialog; {Pointer to dialog box}
    Control : PView;       {Pointer to various controls inserted into dialog}
    R       : TRect;       {Used to define regions for controls}

begin
     {*** Create new dialog box ***}
     R.Assign(0, 0, 38, 12);
     D:= New(PHelpDialog, Init(R, 'Find'));

     with D^ do
     begin
          {*** Centre dialog on screen ***}
          Options:= Options or ofCentered;
          HelpCtx:= hcSearchFindDialog;

          {*** Add input line and label ***}
          R.Assign(3, 3, 32, 4);
          Control:= New(PInputLine, Init(R, 80));
          Control^.HelpCtx:= hcSearchFindText;
          Insert(Control);
          R.Assign(2, 2, 15, 3);
          Insert(New(PLabel, Init(R, '~T~ext to find', Control)));
          R.Assign(32, 3, 35, 4);
          Insert(New(PHistory, Init(R, PInputLine(Control), 10)));

          {*** Add search option check boxes ***}
          R.Assign(3, 5, 35, 7);
          Control:= New(PCheckBoxes, Init(R, NewSItem('~C~ase sensitive',
                                             NewSItem('~W~hole words only',
                                             nil))));

          Control^.HelpCtx:= hcCaseSensitive;
          Insert(Control);

          {*** Add buttons ***}
          R.Assign(14, 9, 24, 11);
          Control:= New(PButton, Init(R, 'O~K~', cmOk, bfDefault));
          Control^.HelpCtx:= hcOk;
          Insert(Control);

          Inc(R.A.X, 12);
          Inc(R.B.X, 12);
          Control:= New(PButton, Init(R, '~C~ancel', cmCancel, bfNormal));
          Control^.HelpCtx:= hcCancel;
          Insert(Control);

          SelectNext(False);
     end;

     {*** Return pointer to dialog ***}
     CreateFindDialog:= D;
end;

(* CreateReplaceDialog - constructs and returns a pointer to the standard
                         text replace dialog box used by StdEditorDialog.

                         Returns pointer to dialog box.
*)

function CreateReplaceDialog : PHelpDialog;

var D       : PHelpDialog; {Pointer to dialog box}
    Control : PView;       {Pointer to various controls inserted into dialog}
    R       : TRect;       {Used to define regions for controls}

begin
     {*** Create new dialog box ***}
     R.Assign(0, 0, 40, 16);
     D:= New(PHelpDialog, Init(R, 'Replace'));

     with D^ do
     begin
          {*** Centre dialog on screen ***}
          Options:= Options or ofCentered;
          HelpCtx:= hcSearchReplaceDialog;

          {*** Add input lines and labels ***}
          R.Assign(3, 3, 34, 4);
          Control:= New(PInputLine, Init(R, 80));
          Control^.HelpCtx:= hcSearchFindText;
          Insert(Control);

          R.Assign(2, 2, 15, 3);
          Insert(New(PLabel, Init(R, '~T~ext to find', Control)));
          R.Assign(34, 3, 37, 4);
          Insert(New(PHistory, Init(R, PInputLine(Control), 10)));

          R.Assign(3, 6, 34, 7);
          Control:= New(PInputLine, Init(R, 80));
          Control^.HelpCtx:= hcSearchReplaceText;
          Insert(Control);
          R.Assign(2, 5, 12, 6);
          Insert(New(PLabel, Init(R, '~N~ew text', Control)));
          R.Assign(34, 6, 37, 7);
          Insert(New(PHistory, Init(R, PInputLine(Control), 11)));

          {*** Insert replace options check boxes ***}
          R.Assign(3, 8, 37, 12);
          Control:= New(DIALOGS.PCheckBoxes, Init(R, NewSItem('~C~ase sensitive',
                                                     NewSItem('~W~hole words only',
                                                     NewSItem('~P~rompt on replace',
                                                     NewSItem('~R~eplace all',
                                                     nil))))));
          Control^.HelpCtx:= hcCaseSensitive;
          Insert(Control);

          {*** Add buttons ***}
          R.Assign(8, 13, 18, 15);
          Control:= New(PButton, Init(R, 'O~K~', cmOk, bfDefault));
          Control^.HelpCtx:= hcOk;
          Insert(Control);

          R.Assign(22, 13, 32, 15);
          Control:= New(PButton, Init(R, '~C~ancel', cmCancel, bfNormal));
          Control^.HelpCtx:= hcCancel;
          Insert(Control);

          SelectNext(False);
     end;

     {*** Return pointer to dialog ***}
     CreateReplaceDialog:= D;
end;

(* CreateJumpLineDialog - constructs and returns a pointer to the standard
                          jump to line dialog box used by StdEditorDialog.

                          Returns pointer to dialog box.
*)

function CreateJumpLineDialog : PHelpDialog;

var D       : PHelpDialog; {Pointer to dialog box}
    Control : PView;       {Pointer to various controls inserted into dialog}
    R       : TRect;       {Used to define regions for controls}

begin
     {*** Create new dialog box ***}
     R.Assign(0, 0, 26, 8);
     D:= New(PHelpDialog, Init(R, 'Jump To'));
     with D^ do
     begin
          Options:= Options or ofCentered;
          HelpCtx:= hcSearchJumpDialog;

          {*** Insert input line and label ***}
          R.Assign(3, 2, 15, 3);
          Control:= New(PStaticText, Init(R, 'Line Number:'));
          Insert(Control);

          R.Assign(15, 2, 21, 3);
          Control:= New(PInputLine, Init(R, 4));
          Control^.HelpCtx:= hcJumpLineNumber;
          Insert(Control);

          R.Assign(21, 2, 24, 3);
          Insert(New(PHistory, Init(R, PInputLine(Control), 12)));
          R.Assign(2, 5, 12, 7);

          {*** Insert buttons ***}
          Control:= New(PButton, Init(R, '~O~K', cmOK, bfDefault));
          Control^.HelpCtx:= hcOk;
          Insert(Control);

          R.Assign(14, 5, 24, 7);
          Control:= New(PButton, Init(R, '~C~ancel', cmCancel, bfNormal));
          Control^.HelpCtx:= hcCancel;
          Insert(Control);
          SelectNext(False);
     end;

     {*** Return pointer to dialog ***}
     CreateJumpLineDialog:= D;
end;

(* CreateTabStopDialog - constructs and returns a pointer to the standard
                         tab stops dialog box used by StdEditorDialog.

                         Returns pointer to dialog box.
*)

function CreateTabStopDialog : PHelpDialog;

var D        : PHelpDialog;   {Pointer to dialog box}
    Control  : PView;         {Pointer to various controls inserted into dialog}
    R        : TRect;         {Used to define regions for controls}
    Index    : integer;   {Loop control variable}
    Tab_Stop : string[2]; {Local string to print tab column number}

begin
     {*** Create dialog box ***}
     R.Assign(0, 0, 80, 8);
     D:= New(PHelpDialog, Init(R, 'Tab Settings'));

     with D^ do
     begin
          Options:= Options or ofCentered;

          {*** Add tab stop display ***}
          R.Assign(2, 2, 77, 3);
          Control:= New(PStaticText, Init(R, ' ....|....|....|....|....|' +
                                             '....|....|....|....|....|' +
                                             '....|....|....|....|....'));
          Insert(Control);

          {*** Display tab stops ***}
          for Index:= 1 to 7 do
          begin
               R.Assign(Index * 10 + 1, 1, Index * 10 + 3, 2);
               Str(Index * 10, Tab_Stop);
               Control:= New(PStaticText, Init(R, Tab_Stop));
               Insert(Control);
          end;

          {*** Insert input line ***}
          R.Assign(2, 3, 78, 4);
          Control:= New(PInputLine, Init(R, 74));
          Control^.HelpCtx:= hcTabStops;
          Insert(Control);

          R.Assign(38, 5, 41, 6);
          Insert(New(PHistory, Init(R, PInputLine(Control), 14)));

          {*** Insert buttons ***}
          R.Assign(27, 5, 37, 7);
          Control:= New(PButton, Init(R, '~O~K', cmOK, bfDefault));
          Control^.HelpCtx:= hcOk;
          Insert(Control);

          R.Assign(42, 5, 52, 7);
          Control:= New(PButton, Init(R, '~C~ancel', cmCancel, bfNormal));
          Control^.HelpCtx:= hcCancel;
          Insert(Control);

          SelectNext(False);
     end;

     {*** Return pointer to dialog ***}
     CreateTabStopDialog:= D;
end;

(* StdEditorDialog - displays a dialog box based on the value of
                     Dialog and the information passed in Info.

                     Dialog - value indicating dialog to display.
                     Info   - additional information for dialog.

                     Returns command code from dialog.
*)

function StdEditorDialog(Dialog : integer; Info : pointer) : word;

var R : TRect;  {Region for dialog to occupy}
    T : TPoint; {Used for positioning dialog}

begin
   case Dialog of
        edOutOfMemory : StdEditorDialog:= MessageBox('Not enough memory' +
                                                     ' for this operation.',
                                                     nil, mfError + mfOkButton);

          edReadError : StdEditorDialog:= MessageBox('Error reading file %s.',
                                                     @Info,
                                                     mfError + mfOkButton);

         edWriteError : StdEditorDialog:= MessageBox('Error writing file %s.',
                                                     @Info,
                                                     mfError + mfOkButton);

        edCreateError : StdEditorDialog:= MessageBox('Error creating file %s.',
                                                     @Info,
                                                     mfError + mfOkButton);

         edSaveModify : StdEditorDialog:= MessageBox('%s has been modified. Save?',
                                                     @Info,
                                                     mfInformation + mfYesNoCancel);

       edSaveUntitled : StdEditorDialog:= MessageBox('Save untitled file?',
                                                     nil,
                                                     mfInformation + mfYesNoCancel);

             edSaveAs : StdEditorDialog:= Application^.ExecuteDialog(
                                          New(PFileDialog, Init('*.*',
                                          'Save file as', '~N~ame',
                                          fdOkButton, 101)), Info);

               edFind : StdEditorDialog:= Application^.ExecuteDialog(CreateFindDialog, Info);

       edSearchFailed : StdEditorDialog:= MessageBox('Search string not found.',
                                                     nil, mfError + mfOkButton);

            edReplace : StdEditorDialog:= Application^.ExecuteDialog(CreateReplaceDialog, Info);

      edReplacePrompt : begin
                             {*** Avoid placing the dialog on the same
                                  line as the cursor ***}
                             R.Assign(0, 1, 40, 8);
                             R.Move((Desktop^.Size.X - R.B.X) div 2, 0);
                             Desktop^.MakeGlobal(R.B, T);
                             Inc(T.Y);
                             if TPoint(Info).Y <= T.Y then
                                R.Move(0, Desktop^.Size.Y - R.B.Y - 2);

                             {*** Display dialog ***}
                             StdEditorDialog:= MessageBoxRect(R, 'Replace this occurence?',
                                                              nil, mfYesNoCancel + mfInformation);
                        end;

         edJumpToLine : StdEditorDialog:= Application^.ExecuteDialog(CreateJumpLineDialog, Info);

        edSetTabStops : StdEditorDialog:= Application^.ExecuteDialog(CreateTabStopDialog, Info);


                 else   StdEditorDialog:= MessageBox(^C'Unknown dialog requested!',
                                                     nil, mfError + mfOkButton);
   end;
end;

{*** Internal procedures and functions ***}

(* CountLines - returns the number of lines in a given buffer.

                Buf   - the buffer to process.
                Count - the size of the buffer.

                Returns the number of lines (using carriage returns).
*)

function CountLines(var Buf; Count : word) : integer; near; assembler;

asm
   les     di, Buf      {ES:DI points to buffer}
   mov     cx, Count    {CX = size of buffer}
   xor     dx, dx       {DX = 0}
   mov     al, $0D      {AL = 13 (carriage return)}
   cld

@@1:

   jcxz    @@2          {Scan for carriage returns}
   repne   scasb
   jne     @@2
   inc     dx
   jmp     @@1

@@2:

   mov     ax, dx       {Return number of lines}

end;



(* ScanKeyMap - scans for a given keycode in the keymap.

                KeyMap  - the keymap to search through.

                KeyCode - the key code to search for.

                Returns the associated command for the key if found.
*)

function ScanKeyMap(KeyMap : pointer; KeyCode : word) : word; near; assembler;

asm
   push    ds           {Save data segment}
   lds     si, KeyMap   {DS:SI points to keymap}
   mov     dx, KeyCode  {DX = required keycode}
   cld
   lodsw                {AX = first word from keymap (number of entries)}
   mov     cx, ax

@@1:

   lodsw                {Get keymap entry data}
   mov     bx, ax
   lodsw
   cmp     bl, dl
   jne     @@3
   or      bh, bh
   je      @@4
   cmp     bh, dh
   je      @@4

@@3:

   loop    @@1          {Try next keymap entry}
   xor     ax, ax

@@4:

   pop     ds           {Restore data segment}

end;


(* Scan - searches for a specified string in a given buffer (case sensitive).

          Block - buffer to search.
          Size  - size of buffer.
          Str   - string to search for.

          Returns success/fail code.
*)

function Scan(var Block; Size : word; Str : string) : word; near; assembler;

asm
   push    ds
   les     di, Block
   lds     si, Str
   mov     cx, Size
   jcxz    @@3
   cld
   lodsb
   cmp     al, 1
   jb      @@5
   ja      @@1
   lodsb
   repne   scasb
   jne     @@3
   jmp     @@5

@@1:

   xor     ah, ah
   mov     bx, ax
   dec     bx
   mov     dx, cx
   sub     dx, ax
   jb      @@3
   lodsb
   inc     dx
   inc     dx

@@2:

   dec     dx
   mov     cx, dx
   repne   scasb
   jne     @@3
   mov     dx, cx
   mov     cx, bx
   rep     cmpsb
   je      @@4
   sub     cx, bx
   add     si, cx
   add     di, cx
   inc     di
   or      dx, dx
   jne     @@2

@@3:

    xor     ax, ax
    jmp     @@6

@@4:

    sub     di, bx

@@5:

    mov     ax, di
    sub     ax, word ptr Block

@@6:

    dec     ax
    pop     ds

end;

(* IScan - searches for a specified string in a given buffer (not case
           sensitive).

           Block - buffer to search.
           Size  - size of buffer.
           Str   - string to search for.

           Returns success/fail code.
*)

function IScan(var Block; Size : word; Str : string) : word; near; assembler;

var S : string; {Temporary string}

asm
   push    ds
   mov     ax, ss
   mov     es, ax
   lea     di, S
   lds     si, Str
   xor     ah, ah
   lodsb
   stosb
   mov     cx, ax
   mov     bx, ax
   jcxz    @@9

@@1:

   lodsb
   cmp     al, 'a'
   jb      @@2
   cmp     al, 'z'
   ja      @@2
   sub     al, $20

@@2:

   stosb
   loop    @@1
   sub     di, bx
   lds     si, Block
   mov     cx, Size
   jcxz    @@8
   cld
   sub     cx,bx
   jb      @@8
   inc     cx

@@4:

   mov     ah, es:[di]
   and     ah, $DF

@@5:

   lodsb
   and     al, $DF
   cmp     al,ah
   loopne  @@5
   jne     @@8
   dec     si
   mov     dx, cx
   mov     cx, bx

@@6:

   repe    cmpsb
   je      @@10
   mov     al, ds:[si - 1]
   cmp     al, 'a'
   jb      @@7
   cmp     al, 'z'
   ja      @@7
   sub     al, $20

@@7:

   cmp     al, es:[di - 1]
   je      @@6
   sub     cx, bx
   add     si, cx
   add     di, cx
   inc     si
   mov     cx, dx
   or      cx, cx
   jne     @@4

@@8:

   xor     ax, ax
   jmp     @@11

@@9:

   mov     ax, 1
   jmp     @@11

@@10:

    sub     si, bx
    mov     ax, si
    sub     ax, word ptr Block
    inc     ax

@@11:

    dec     ax
    pop     ds

end;

{*** TIndicator object ***}

(* TIndicator.Init - initialises the TIndicator object.

                     Bounds - the region for the indicator to occupy.

*)

constructor TIndicator.Init(var Bounds : TRect);

begin
     inherited Init(Bounds);
     GrowMode:= gfGrowLoY + gfGrowHiY;
end;


(* TIndicator.Draw - displays the indicator on the screen. *)

procedure TIndicator.Draw;

var Color : byte;                    {Holds the colour attributes to use}
    Frame : char;                    {Holds the frame character to use
                                      for padding}
    L     : array[0..1] of longint;  {Holds the X and Y cursor position}
    S     : string[15];              {Holds formatted position string}
    B     : TDrawBuffer;             {Output buffer}

begin
     {*** Determine if the container window is being dragged ***}
     if State and sfDragging = 0 then
     begin
          Color:= GetColor(1);
          Frame:= #205;
     end
     else
     begin
          Color:= GetColor(2);
          Frame:= #196;
     end;

     {*** Create a draw display ***}
     MoveChar(B, Frame, Color, Size.X);

     {*** if the text has been modified, put an 'M' in the
          TIndicator display ***}
     if Modified then WORDREC(B[1]).Lo:= 77;

     {*** if AutoIndent is active put an 'I' in TIndicator display.
          Otherwise, just use the current frame character. ***}
     if AutoIndent then WORDREC(B[0]).Lo:= 73
                   else WORDREC(B[0]).Lo:= BYTE(Frame);

     {*** Get cursor position ***}
     L[0]:= Location.Y + 1;
     L[1]:= Location.X + 1;
     FormatStr(S, ' %d:%d ', L);
     MoveStr(B[9 - Pos(':', S)], S, Color);       { Changed original 8 to 9. }

     {*** Display on screen ***}
     WriteBuf(0, 0, Size.X, 1, B);
end;


(* TIndicator.GetPalette - returns the indicator's palette entries. *)

function TIndicator.GetPalette : PPalette;

const P : string[Length(CIndicator)] = CIndicator;

begin
     {*** Return a pointer to the palette ***}
     GetPalette:= @P;
end;

(* TIndicator.HandleEvent - handles a double click on the indicator.

                            Event - the event record to process.
*)


procedure TIndicator.HandleEvent(var Event : TEvent);

begin
     if (Event.What = evMouseDown) then
        if (Event.Double) then
           Message(Application, evCommand, cmJumpLine, nil);

     inherited HandleEvent(Event);
end;

(* TIndicator.SetState - redraws the view if the view is being dragged.

                         AState - the current state.
                         Enable - if true sets the relevant state bit.

*)

procedure TIndicator.SetState(AState : word; Enable : boolean);

begin
     {*** Call TView.SetState ***}
     inherited SetState(AState, Enable);

     {*** If being dragged then redraw view ***}
     if AState = sfDragging then DrawView;
end;


(* TIndicator.SetValue - updates the indicator view with a new cursor location
                         and the state of the auto-indent and modification
                         flags.

                         ALocation    - cursor location.
                         IsAutoIndent - true if auto-indent mode is on.
                         IsModified   - true if buffer has been modified.

*)

procedure TIndicator.SetValue(ALocation    : TPoint;
                              IsAutoIndent : boolean;
                              IsModified   : boolean);

begin
     {*** Determine if update is necessary ***}
     if (LONGINT(Location) <> LONGINT(ALocation)) or
        (AutoIndent <> IsAutoIndent) or
        (Modified <> IsModified) then
     begin
          {*** Update variables ***}
          Location:= ALocation;
          AutoIndent:= IsAutoIndent;
          Modified:= IsModified;

          {*** Update view ***}
          DrawView;
     end;
end;

{*** TEditor object (full comments in TP7 on-line help) ***}

constructor TEditor.Init(var Bounds       : TRect;
                             AHScrollBar,
                             AVScrollBar  : PScrollBar;
                             AIndicator   : PIndicator;
                             ABufSize     : word);

var Element : byte;

begin
     inherited Init(Bounds);
     GrowMode:= gfGrowHiX + gfGrowHiY;
     Options:= Options or ofSelectable;
     EventMask:= evMouseDown + evKeyDown + evCommand + evBroadcast;
     ShowCursor;

     HScrollBar:= AHScrollBar;
     VScrollBar:= AVScrollBar;

     Indicator:= AIndicator;
     BufSize:= ABufSize;
     CanUndo:= True;
     InitBuffer;

     if Assigned(Buffer) then IsValid:= true
                         else
                         begin
                              EditorDialog(edOutOfMemory, nil);
                              BufSize:= 0;
                         end;

     SetBufLen(0);
     Element:= 1;

     while Element <= 70 do
     begin
          if Element mod 5 = 0 then Insert('x', TabSettings, Element)
                               else Insert(#32, TabSettings, Element);
          Inc(Element);
     end;
end;

{******}

constructor TEditor.Load(var S : TStream);

begin
     inherited Load(S);
     GetPeerViewPtr(S, HScrollBar);
     GetPeerViewPtr(S, VScrollBar);
     GetPeerViewPtr(S, Indicator);
     S.Read(BufSize, SizeOf(WORD));
     S.Read(CanUndo, SizeOf(BOOLEAN));
     S.Read(AutoIndent, SizeOf(AutoIndent));
     S.Read(LineNumber, SizeOf(LineNumber));
     S.Read(TabSettings, SizeOf(TabSettings));

     InitBuffer;

     if Assigned(Buffer) then IsValid:= True
                         else
                         begin
                              EditorDialog(edOutOfMemory, nil);
                              BufSize:= 0;
                         end;

     Lock;
     SetBufLen(0);
end;

{******}

destructor TEditor.Done;

begin
     DoneBuffer;
     inherited Done;
end;

{******}

function TEditor.Bufchar(P : word) : char; assembler;

asm
   les     di, Self
   mov     bx, p
   cmp     bx, es:[di].TEditor.CurPtr
   jb      @@1
   add     bx, es:[di].TEditor.GapLen

@@1:

   les     di, es:[di].TEditor.Buffer
   mov     al, es:[di + bx]
end;

{******}

function TEditor.BufPtr(P : word) : word; assembler;

asm
   les     di, Self
   mov     ax, p
   cmp     ax, es:[di].TEditor.CurPtr
   jb      @@1
   add     ax,es:[di].TEditor.GapLen

@@1:

end;

{******}

procedure TEditor.ChangeBounds(var Bounds : TRect);

begin
     SetBounds(Bounds);
     Delta.X:= Max(0, Min(Delta.X, Limit.X - Size.X));
     Delta.Y:= Max(0, Min(Delta.Y, Limit.Y - Size.Y));
     Update(ufView);
end;

{******}

function TEditor.CharPos(P, Target : word) : integer;

var Pos : integer;

begin
     Pos:= 0;

     while P < Target do
     begin
          if Bufchar(P) = #9 then Pos:= Pos or 7;
          Inc(Pos);
          Inc(P);
     end;

     CharPos:= Pos;
end;

{******}

function TEditor.CharPtr(P : word; Target : integer) : word;

var Pos : integer;

begin
     Pos:= 0;

     while (Pos < Target) and (P < BufLen) and (Bufchar(P) <> #13) do
     begin
          if Bufchar(P) = #9 then Pos:= Pos or 7;
          Inc(Pos);
          Inc(P);
     end;

     if Pos > Target then Dec(P);

     CharPtr:= P;
end;

{******}

function TEditor.ClipCopy : boolean;

begin
     ClipCopy:= false;

     if Assigned(Clipboard) and (Clipboard <> @Self) then
     begin
          ClipCopy:= Clipboard^.InsertFrom(@Self);
          Selecting:= false;
          Update(ufUpdate);
     end;
end;

{******}

procedure TEditor.ClipCut;

begin
     if ClipCopy then DeleteSelect;
end;

{******}

procedure TEditor.ClipPaste;

begin
     if Assigned(Clipboard) and (Clipboard <> @Self) then InsertFrom(Clipboard);
end;

{******}

procedure TEditor.ConvertEvent(var Event : TEvent);

var ShiftState : byte absolute $40:$17;
    Key        : word;

begin
     if Event.What = evKeyDown then
     begin
          if (ShiftState and $03 <> 0) and
             (Event.ScanCode >= $47) and
             (Event.ScanCode <= $51) then Event.charCode:= #0;

          Key:= Event.KeyCode;

          if KeyState <> 0 then
          begin
               if (Lo(Key) >= $01) and (Lo(Key) <= $1A) then Inc(Key, $40);
               if (Lo(Key) >= $61) and (Lo(Key) <= $7A) then Dec(Key, $20);
          end;

          Key:= ScanKeyMap(KeyMap[KeyState], Key);
          KeyState:= 0;

          if Key <> 0 then
             if Hi(Key) = $FF then
             begin
                  KeyState:= Lo(Key);
                  ClearEvent(Event);
             end
             else
             begin
                  Event.What:= evCommand;
                  Event.Command:= Key;
             end;
     end;
end;

{******}

function TEditor.CursorVisible : boolean;

begin
     CursorVisible:= (CurPos.Y >= Delta.Y) and (CurPos.Y < Delta.Y + Size.Y);
end;

{******}

procedure TEditor.DeleteRange(StartPtr, EndPtr : word; DelSelect : boolean);

begin
     if HasSelection and DelSelect then DeleteSelect
                                   else
                                   begin
                                        SetSelect(CurPtr, EndPtr, True);
                                        DeleteSelect;
                                        SetSelect(StartPtr, CurPtr, False);
                                        DeleteSelect;
                                   end;
end;

{******}

procedure TEditor.DeleteSelect;

begin
     InsertText(nil, 0, False);
end;

{******}

procedure TEditor.DoneBuffer;

begin
     if Assigned(Buffer) then
     begin
          FreeMem(Buffer, BufSize);
          Buffer:= nil;
     end;
end;

{******}

procedure TEditor.DoSearchReplace;

var I : word;
    C : TPoint;

begin
     repeat
           I:= cmCancel;

           if not Search(FindStr, EditorFlags) then
           begin
                if EditorFlags and (efReplaceAll + efDoReplace) <>
                   (efReplaceAll + efDoReplace) then EditorDialog(edSearchFailed, nil)
           end
           else
               if EditorFlags and efDoReplace <> 0 then
               begin
                    I:= cmYes;
                    if EditorFlags and efPromptOnReplace <> 0 then
                    begin
                         MakeGlobal(Cursor, C);
                         I:= EditorDialog(edReplacePrompt, POINTER(C));
                    end;

                    if I = cmYes then
                    begin
                         Lock;
                         InsertText(@ReplaceStr[1], Length(ReplaceStr), False);
                         TrackCursor(False);
                         Unlock;
                    end;
               end;

     until(I = cmCancel) or (EditorFlags and efReplaceAll = 0);
end;

{******}

procedure TEditor.DoUpdate;

begin
     if UpdateFlags <> 0 then
     begin
          SetCursor(CurPos.X - Delta.X, CurPos.Y - Delta.Y);

          if UpdateFlags and ufView <> 0 then
              DrawView
          else
              if UpdateFlags and ufLine <> 0 then
                 DrawLines(CurPos.Y - Delta.Y, 1, LineStart(CurPtr));

          if Assigned(HScrollBar) then
             HScrollBar^.SetParams(Delta.X, 0, Limit.X - Size.X, Size.X div 2, 1);

          if Assigned(VScrollBar) then
             VScrollBar^.SetParams(Delta.Y, 0, Limit.Y - Size.Y, Size.Y - 1, 1);

          if Assigned(Indicator) then
             Indicator^.SetValue(CurPos, AutoIndent, Modified);

          if ((State and sfActive) <> 0) then
             UpdateCommands(True);

          UpdateFlags:= 0;
     end;
end;

{******}

procedure TEditor.Draw;

begin
     if DrawLine <> Delta.Y then
     begin
          DrawPtr:= LineMove(DrawPtr, Delta.Y - DrawLine);
          DrawLine:= Delta.Y;
     end;
     DrawLines(0, Size.Y, DrawPtr);
end;

{******}

procedure TEditor.DrawLines(Y, Count : integer; LinePtr : word);

var Color : word;
    B     : array[0..MaxLineLength - 1] of word;

begin
     Color:= GetColor($0201);

     while Count > 0 do
     begin
          FormatLine(B, LinePtr, Delta.X + Size.X, Color);
          WriteBuf(0, Y, Size.X, 1, B[Delta.X]);
          LinePtr:= NextLine(LinePtr);
          Inc(Y);
          Dec(Count);
     end;
end;

{******}

procedure TEditor.Find;

var FindRec : TFindDialogRec;

begin
     with FindRec do
     begin
          Find:= FindStr;
          Options:= EditorFlags;

          if EditorDialog(edFind, @FindRec) <> cmCancel then
          begin
               FindStr:= Find;
               EditorFlags:= Options and not efDoReplace;
               DoSearchReplace;
          end;
     end;
end;

{******}

procedure TEditor.FormatLine(var DrawBuf;
                                 LinePtr : word;
                                 Width   : integer;
                                 Colors  : word); assembler;

asm
   push    ds
   lds     bx, Self
   les     di, DrawBuf
   mov     si, LinePtr
   xor     dx, dx
   cld
   mov     ah, Colors.BYTE[0]
   mov     cx, ds:[bx].TEditor.SelStart
   call    @@10
   mov     ah, Colors.BYTE[1]
   mov     cx, ds:[bx].TEditor.CurPtr
   call    @@10
   add     si, ds:[bx].TEditor.GapLen
   mov     cx, ds:[bx].TEditor.SelEnd
   add     cx, ds:[bx].TEditor.GapLen
   call    @@10
   mov     ah, Colors.BYTE[0]
   mov     cx, ds:[bx].TEditor.BufSize
   call    @@10
   jmp     @@31

@@10:

   sub     cx, si
   ja      @@11
   retn

@@11:

   lds     bx, ds:[bx].TEditor.Buffer
   add     si, bx
   mov     bx, Width

@@12:

   lodsb
   cmp     al, ' '
   jb      @@20

@@13:

   stosw
   inc     dx

@@14:

   cmp     dx, bx
   jae     @@30
   loop    @@12
   lds     bx, Self
   sub     si, ds:[bx].TEditor.Buffer.WORD[0]
   retn

@@20:

   cmp     al, $0D
   je      @@30
   cmp     al, $09
   jne     @@13
   mov     al, ' '

@@21:

   stosw
   inc     dx
   test    dl, 7
   jne     @@21
   jmp     @@14

@@30:

   pop     cx

@@31:

   mov     al, ' '
   mov     cx, Width
   sub     cx, dx
   jbe     @@32
   rep     stosw

@@32:

   pop     ds

end;

{******}

function TEditor.GetMousePtr(Mouse : TPoint) : word;

begin
     MakeLocal(Mouse, Mouse);
     Mouse.X:= Max(0, Min(Mouse.X, Size.X - 1));
     Mouse.Y:= Max(0, Min(Mouse.Y, Size.Y - 1));

     GetMousePtr:= CharPtr(LineMove(DrawPtr, Mouse.Y + Delta.Y - DrawLine),
                           Mouse.X + Delta.X);
end;

{******}

function TEditor.GetCurrentWord : string;

var S, E        : word; {End of the current line}
    Temp        : string;
    WS          : word;

begin
     S:= LineStart(CurPtr);
     E:= LineEnd(CurPtr);
     Temp:= '';
     WS:= CurPtr;

     if (Bufchar(CurPtr) = #32) or (CurPtr = E) then
     begin
          GetCurrentWord:= '';
          Exit;
     end;

     while (BufChar(PrevChar(CurPtr)) > #32) and (CurPtr > S) do
            SetCurPtr(PrevChar(CurPtr), 0);

     while (Bufchar(Nextchar(CurPtr)) > #32) and (CurPtr < E) do
     begin
           Temp:= Temp + BufChar(CurPtr);
           SetCurPtr(Nextchar(CurPtr), 0);
     end;
     Temp:= Temp + BufChar(CurPtr);
     SetCurPtr(WS, 0);
     GetCurrentWord:= Temp;
end;

{******}

function TEditor.GetPalette : PPalette;

const P : string[Length(CEditor)] = CEditor;

begin
     GetPalette:= @P;
end;

{******}

procedure TEditor.HandleEvent(var Event : TEvent);

var ShiftState   : byte absolute $40:$17;
    CenterCursor : boolean;
    SelectMode   : byte;
    I            : integer;
    NewPtr       : word;
    D            : TPoint;
    Mouse        : TPoint;

 {******}

 function CheckScrollBar(P : PScrollBar; var D : integer) : boolean;

 begin
      CheckScrollBar:= false;

      if (Event.InfoPtr = P) and (P^.Value <> D) then
      begin
           D:= P^.Value;
           Update(ufView);
           CheckScrollBar:= true;
      end;
  end;

  {******}

begin
   inherited HandleEvent(Event);
   ConvertEvent(Event);
   CenterCursor:= not CursorVisible;
   SelectMode:= 0;

   if Selecting or (ShiftState and $03 <> 0) then SelectMode:= smExtend;

   case Event.What of

      evMouseDown : begin
                      if Event.Double then SelectMode:= SelectMode or smDouble;

                      repeat
                         Lock;
                         if Event.What = evMouseAuto then
                         begin
                            MakeLocal(Event.Where, Mouse);
                            D:= Delta;
                            if Mouse.X < 0 then Dec(D.X);
                            if Mouse.X >= Size.X then Inc(D.X);
                            if Mouse.Y < 0 then Dec(D.Y);
                            if Mouse.Y >= Size.Y then Inc(D.Y);
                            ScrollTo(D.X, D.Y);
                         end;

                         SetCurPtr(GetMousePtr(Event.Where), SelectMode);
                         SelectMode:= SelectMode or smExtend;
                         Unlock;
                      until not MouseEvent(Event, evMouseMove + evMouseAuto);
                    end;

        evKeyDown : case Event.charCode of

                       #32..#255 : begin
                                     if Abs(LineEnd(CurPtr) -
                                            LineStart(CurPtr)) > MaxLineLength - 4 then
                                        EditorDialog(edLineTooLong, nil)
                                     else
                                     begin
                                       Lock;
                                       if Overwrite and not HasSelection then
                                          if CurPtr <> LineEnd(CurPtr) then
                                             SelEnd:= NextChar(CurPtr);

                                       InsertText(@Event.CharCode, 1, False);
                                       TrackCursor(CenterCursor);
                                       Unlock;
                                     end;
                                   end;

                             else  Exit;
                    end;

        evCommand : case Event.Command of

                      cmFind        : begin
                                           FindStr:= GetCurrentWord;
                                           Find;
                                      end;
                      cmReplace     : begin
                                           FindStr:= GetCurrentWord;
                                           Replace;
                                      end;
                      cmSearchAgain : DoSearchReplace;
                               else   begin
                                         Lock;
                                         case Event.Command of

                                            cmCut         : ClipCut;
                                            cmCopy        : ClipCopy;
                                            cmPaste       : ClipPaste;
                                            cmUndo        : Undo;
                                            cmClear       : DeleteSelect;
                                            cmCharLeft    : SetCurPtr(PrevChar(CurPtr), SelectMode);
                                            cmCharRight   : SetCurPtr(NextChar(CurPtr), SelectMode);
                                            cmWordLeft    : SetCurPtr(PrevWord(CurPtr), SelectMode);
                                            cmWordRight   : SetCurPtr(NextWord(CurPtr), SelectMode);
                                            cmLineStart   : SetCurPtr(LineStart(CurPtr), SelectMode);
                                            cmLineEnd     : SetCurPtr(LineEnd(CurPtr), SelectMode);
                                            cmLineUp      : SetCurPtr(LineMove(CurPtr, -1), SelectMode);
                                            cmLineDown    : SetCurPtr(LineMove(CurPtr, 1),  SelectMode);
                                            cmPageUp      : SetCurPtr(LineMove(CurPtr, -(Size.Y - 1)), SelectMode);
                                            cmPageDown    : SetCurPtr(LineMove(CurPtr, Size.Y - 1), SelectMode);
                                            cmTextStart   : SetCurPtr(0, SelectMode);
                                            cmTextEnd     : SetCurPtr(BufLen, SelectMode);
                                            cmNewLine     : NewLine(SelectMode);
                                            cmBackSpace   : DeleteRange(PrevChar(CurPtr), CurPtr, True);
                                            cmDelChar     : DeleteRange(CurPtr, NextChar(CurPtr), True);
                                            cmDelWord     : DeleteRange(CurPtr, NextWord(CurPtr), False);
                                            cmDelStart    : DeleteRange(LineStart(CurPtr), CurPtr, False);
                                            cmDelEnd      : DeleteRange(CurPtr, LineEnd(CurPtr), False);
                                            cmDelLine     : DeleteRange(LineStart(CurPtr), NextLine(CurPtr), False);
                                            cmInsMode     : ToggleInsMode;
                                            cmStartSelect : StartSelect;
                                            cmHideSelect  : HideSelect;
                                            cmIndentMode  : begin
                                                              AutoIndent:= not AutoIndent;
                                                              Update(ufStats);
                                                            end;
                                            cmEndPage     : SetCurPtr(LineMove (CurPtr, Delta.Y - CurPos.Y + Size.Y - 1),
                                                                      SelectMode);
                                            cmHomePage    : SetCurPtr(LineMove (CurPtr, -(CurPos.Y - Delta.Y)), SelectMode);
                                            cmJumpLine    : JumpToLine(SelectMode);
                                            cmScrollDown  : ScrollDown;
                                            cmScrollUp    : ScrollUp;
                                            cmSelectWord  : SelectWord;
                                            cmSetTabs     : SetTabs;
                                            cmTabKey      : TabKey(SelectMode);

                                                    else    Unlock;
                                                            Exit;
                                         end;

                                         TrackCursor(CenterCursor);
                                         if (Event.Command <> cmNewLine) and
                                            (Event.Command <> cmBackSpace) and
                                            (Event.Command <> cmTabKey) and
                                             Modified then Remove_EOL_Spaces(SelectMode);

                                         Unlock;
                                      end;
                    end;

      evBroadcast : case Event.Command of
                      cmScrollBarChanged : if (Event.InfoPtr = HScrollBar) or
                                              (Event.InfoPtr = VScrollBar) then
                                           begin
                                              CheckScrollBar(HScrollBar, Delta.X);
                                              CheckScrollBar(VScrollBar, Delta.Y);
                                           end
                                           else Exit;
                                    else   Exit;
                    end;
   end;

   ClearEvent(Event);
end;

{******}

function TEditor.HasSelection : boolean;

begin
     HasSelection:= SelStart <> SelEnd;
end;

{******}

procedure TEditor.HideSelect;

begin
     Selecting:= False;
     SetSelect(CurPtr, CurPtr, False);
end;

{******}

procedure TEditor.InitBuffer;

begin
     Buffer:= MemAlloc(BufSize);
end;

{******}

function TEditor.InsertBuffer(var P          : PEditBuffer;
                                  Offset,
                                  Length     : word;
                                  AllowUndo,
                                  SelectText : boolean) : boolean;

var SelLen   : word;
    DelLen   : word;
    SelLines : word;
    Lines    : word;
    NewSize  : longint;

begin
     InsertBuffer:= True;
     Selecting:= False;
     SelLen:= SelEnd - SelStart;

     if (SelLen = 0) and (Length = 0) then Exit;

     DelLen:= 0;

     if AllowUndo then
        if CurPtr = SelStart then DelLen:= SelLen
                             else if SelLen > InsCount then DelLen:= SelLen - InsCount;

     NewSize:= LONGINT(BufLen + DelCount - SelLen + DelLen) + Length;

     if NewSize > BufLen + DelCount then
        if(NewSize > $FFF0) or not SetBufSize(NewSize) then
        begin
             EditorDialog(edOutOfMemory, nil);
             InsertBuffer:= False;
             SelEnd:= SelStart;
             Exit;
        end;

     SelLines:= CountLines(Buffer^[BufPtr(SelStart)], SelLen);

     if CurPtr = SelEnd then
     begin
          if AllowUndo then
          begin
               if DelLen > 0 then
                  Move(Buffer^[SelStart], Buffer^[CurPtr + GapLen - DelCount - DelLen], DelLen);

               Dec(InsCount, SelLen - DelLen);
          end;

          CurPtr:= SelStart;
          Dec(CurPos.Y, SelLines);
     end;

     if Delta.Y > CurPos.Y then
     begin
          Dec(Delta.Y, SelLines);
          if Delta.Y < CurPos.Y then Delta.Y:= CurPos.Y;
     end;

     if Length > 0 then Move(P^[Offset], Buffer^[CurPtr], Length);

     Lines:= CountLines(Buffer^[CurPtr], Length);
     Inc(CurPtr, Length);
     Inc(CurPos.Y, Lines);

     DrawLine:= CurPos.Y;
     DrawPtr:= LineStart(CurPtr);
     CurPos.X:= CharPos(DrawPtr, CurPtr);

     if not SelectText then SelStart:= CurPtr;

     SelEnd:= CurPtr;
     Inc(BufLen, Length - SelLen);
     Dec(GapLen, Length - SelLen);

     if AllowUndo then
     begin
          Inc(DelCount, DelLen);
          Inc(InsCount, Length);
     end;

     Inc(Limit.Y, Lines - SelLines);
     Delta.Y:= Max(0, Min(Delta.Y, Limit.Y - Size.Y));

     if not IsClipboard then Modified:= True;

     SetBufSize(BufLen + DelCount);

     if (SelLines = 0) and (Lines = 0) then Update(ufLine)
                                       else Update(ufView);
end;

{******}

function TEditor.InsertFrom(Editor : PEditor) : boolean;

begin
     InsertFrom:= InsertBuffer(Editor^.Buffer,
                               Editor^.BufPtr(Editor^.SelStart),
                               Editor^.SelEnd - Editor^.SelStart,
                               CanUndo, IsClipboard);
end;

{******}

function TEditor.InsertText(Text       : pointer;
                            Length     : word;
                            SelectText : boolean) : boolean;

begin
     InsertText:= InsertBuffer(PEditBuffer(Text), 0, Length, CanUndo, SelectText);
end;

{******}

function TEditor.IsClipboard : boolean;

begin
     IsClipboard:= Clipboard = @Self;
end;

{******}

procedure TEditor.JumpToLine(SelectMode : byte);

var Code       : integer;   {Used for Val conversion}
    Temp_Value : integer;   {Holds converted dialog value}

begin
     if EditorDialog(edJumpToLine, @LineNumber) <> cmCancel then
     begin
          Val(LineNumber, Temp_Value, Code);
          if (Temp_Value < 1) or (Temp_Value > 9999) then Exit;

          if Temp_Value = CurPos.Y + 1 then Exit;

          SetCurPtr(0, SelectMode);
          SetCurPtr(LineMove(CurPtr, Temp_Value - 1), SelectMode);
     end;
end;

{******}

function TEditor.LineEnd(P : word) : word; assembler;

asm
   push    ds
   lds     si, Self
   les     bx, ds:[si].TEditor.Buffer
   mov     di, p
   mov     al, $0D
   cld
   mov     cx, ds:[si].TEditor.CurPtr
   sub     cx, di
   jbe     @@1
   add     di, bx
   repne   scasb
   je      @@2
   mov     di, ds:[si].TEditor.CurPtr

@@1:

   mov     cx, ds:[si].TEditor.BufLen
   sub     cx, di
   jcxz    @@4
   add     bx, ds:[si].TEditor.GapLen
   add     di, bx
   repne   scasb
   jne     @@3

@@2:

    dec     di

@@3:

    sub     di, bx

@@4:

    mov     ax, di
    pop     ds

end;

{******}

function TEditor.LineMove(P : word; Count : integer) : word;

var Pos : integer;
    I   : word;

begin
     I:= P;
     P:= LineStart(P);
     Pos:= CharPos(P, I);

     while Count <> 0 do
     begin
          I:= P;
          if Count < 0 then
          begin
               P:= PrevLine(P);
               Inc(Count);
          end
          else
          begin
               P:= NextLine(P);
               Dec(Count);
          end;
     end;

     if P <> I then P:= CharPtr(P, Pos);

     LineMove:= P;
end;

{******}

function TEditor.LineStart(P : word) : word; assembler;

asm
   push    ds
   lds     si,self
   les     bx,ds:[si].TEditor.Buffer
   mov     di,p
   mov     al,0dh
   std
   mov     cx,di
   sub     cx,ds:[si].TEditor.Curptr
   jbe     @@1
   add     bx,ds:[si].TEditor.Gaplen
   add     di,bx
   dec     di
   repne   scasb
   je      @@2
   sub     bx,ds:[si].TEditor.Gaplen
   mov     di,ds:[si].TEditor.Curptr

@@1:

   mov     cx,di
   jcxz    @@4
   add     di,bx
   dec     di
   repne   scasb
   jne     @@3

@@2:

   inc     di
   inc     di
   sub     di,bx
   cmp     di,ds:[si].TEditor.CurPtr
   je      @@4
   cmp     di,ds:[si].TEditor.BufLen
   je      @@4
   cmp     es:[bx + di].BYTE, $0A
   jne     @@4
   inc     di
   jmp     @@4

@@3:

   xor     di,di

@@4:

   mov     ax,di
   pop     ds

end;

{******}

procedure TEditor.Lock;

begin
     Inc(LockCount);
end;

{******}

function TEditor.NewLine(SelectMode : byte) : boolean;

const CRLF : array[1..2] of char = #13#10;

var I : word;  {Used to track spaces for AutoIndent}
    P : word;  {Position of Cursor when we arrive and after Newline}

begin
     P:= LineStart(CurPtr);
     I:= P;

     Remove_EOL_Spaces(SelectMode);

     while (I < CurPtr) and ((Buffer^[I] = ' ') or (Buffer^[I] = #9)) do Inc(I);

     if InsertText(@CRLF, 2, False) = FALSE then exit;

     if AutoIndent then InsertText(@Buffer^[P], I - P, False);

     I:= BufLen;
     P:= CurPtr;

     SetCurPtr(LineMove(CurPtr, -1), SelectMode);
     Remove_EOL_Spaces(SelectMode);

     if I - BufLen <> 0 then SetCurPtr(P -(I - BufLen), SelectMode)
                        else SetCurPtr(P, SelectMode);
end;

{******}

function TEditor.NextChar(P : word) : word; assembler;

asm
   push    ds
   lds     si, Self
   mov     di, P
   cmp     di, ds:[si].TEditor.BufLen
   je      @@2
   inc     di
   cmp     di, ds:[si].TEditor.BufLen
   je      @@2
   les     bx, ds:[si].TEditor.Buffer
   cmp     di, ds:[si].TEditor.CurPtr
   jb      @@1
   add     bx, ds:[si].TEditor.GapLen

@@1:

   cmp     es:[bx + di - 1].WORD, $0A0D
   jne     @@2
   inc     di

@@2:

   mov     ax, di
   pop     ds

end;

{******}

function TEditor.NextLine(P : word) : word;

begin
     NextLine:= NextChar(LineEnd(P));
end;

{******}

function TEditor.NextWord(P : word) : word;

begin
     while (P < BufLen) and (Bufchar(P) in WordChars) do P:= Nextchar(P);

     while (P < BufLen) and not(Bufchar(P) in WordChars) do P:= Nextchar(P);

     NextWord:= P;
end;

{******}

function TEditor.PrevChar(P : word) : word; assembler;

asm
   push    ds
   lds     si, Self
   mov     di, P
   or      di, di
   je      @@2
   dec     di
   je      @@2
   les     bx, ds:[si].TEditor.Buffer
   cmp     di, ds:[si].TEditor.CurPtr
   jb      @@1
   add     bx, ds:[si].TEditor.GapLen

@@1:

   cmp     es:[bx + di - 1].WORD, $0A0D
   jne     @@2
   dec     di

@@2:

   mov     ax, di
   pop     ds

end;

{******}

function TEditor.PrevLine(P : word) : word;

begin
     PrevLine:= LineStart(PrevChar(P));
end;

{******}

function TEditor.PrevWord(P : word) : word;

begin
   while (P > 0) and not(Bufchar(PrevChar(P)) in WordChars) do P:= PrevChar(P);
   while (P > 0) and (Bufchar(Prevchar(P)) in WordChars) do P:= Prevchar(P);

   PrevWord:= P;
end;

{******}

procedure TEditor.Remove_EOL_Spaces(SelectMode : byte);

var C : word;  {Current pointer when we come into procedure}
    E : word;  {End of line}
    P : word;  {Position of pointer at any given moment}
    S : word;  {Start of a line}

begin
     C:= CurPtr;
     E:= LineEnd(CurPtr);
     P:= E;
     S:= LineStart(CurPtr);

     while (P > S) and (BufChar(PrevChar(P)) = #32) do P:= PrevChar(P);

     if P < E then
     begin
          SetSelect(P, E, True);
          DeleteSelect;
     end;

     if C < CurPtr then SetCurPtr(C, SelectMode)
                   else SetCurPtr(CurPtr, SelectMode);
end;

{******}

procedure TEditor.Replace;

var ReplaceRec : TReplaceDialogRec;

begin
     with ReplaceRec do
     begin
          Find:= FindStr;
          Replace:= ReplaceStr;
          Options:= EditorFlags;

          if EditorDialog(edReplace, @ReplaceRec) <> cmCancel then
          begin
               FindStr:= Find;
               ReplaceStr:= Replace;
               EditorFlags:= Options or efDoReplace;
               DoSearchReplace;
          end;
     end;
end;

{******}

procedure TEditor.ScrollDown;

var C : word;   {Position of CurPtr when we enter procedure.}
    P : word;   {Position of CurPtr at any given time.}
    W : TPoint; {CurPos.Y of CurPtr and P('.X and '.Y)}

begin
     C:= CurPtr;
     W.X:= CurPos.Y;
     P:= LineMove(CurPtr, Delta.Y - CurPos.Y + Size.Y);
     SetCurPtr(P, 0);
     TrackCursor(False);
     W.Y:= CurPos.Y;

     if W.Y - W.X > Size.Y - 1 then SetCurPtr(LineMove(C, 1), 0)
                               else SetCurPtr(C, 0);
end;

{******}

procedure TEditor.ScrollUp;

var C : word;   {Position of CurPtr when we enter procedure}
    P : word;   {Position of CurPtr at any given time}
    W : TPoint; {CurPos.Y of CurPtr and P('.X and '.Y)}

begin
     C:= CurPtr;
     W.Y:= CurPos.Y;
     P:= LineMove(CurPtr, -(CurPos.Y - Delta.Y + 1));
     SetCurPtr(P, 0);
     TrackCursor(False);
     W.X:= CurPos.Y;

     if W.Y - W.X > Size.Y - 1 then SetCurPtr(LineMove(C, -1), 0)
                               else SetCurPtr(C, 0);
end;

{******}

procedure TEditor.ScrollTo(X, Y : integer);

begin
     X:= Max(0, Min(X, Limit.X - Size.X));
     Y:= Max(0, Min(Y, Limit.Y - Size.Y));

     if (X <> Delta.X) or (Y <> Delta.Y) then
     begin
          Delta.X:= X;
          Delta.Y:= Y;
          Update(ufView);
     end;
end;

{******}

function TEditor.Search(const FindStr : string; Opts : word) : boolean;

var I   : word;
    Pos : word;

begin
     Search:= False;
     Pos:= CurPtr;

     repeat
           if Opts and efCaseSensitive <> 0 then
               I:= Scan(Buffer^[BufPtr(Pos)], BufLen - Pos, FindStr)
           else
               I:= IScan(Buffer^[BufPtr(Pos)], BufLen - Pos, FindStr);

           if (I <> sfSearchFailed) then
           begin
                Inc(I, Pos);

                if (Opts and efWholewordsOnly = 0) or
                   not(((I <> 0) and (Bufchar(I - 1) in WordChars)) or
                   ((I + Length(FindStr) <> BufLen) and
                    (Bufchar(I + Length(FindStr)) in wordchars))) then
                begin
                     Lock;
                     SetSelect(I, I + Length(FindStr), False);
                     TrackCursor(not CursorVisible);
                     Unlock;
                     Search:= True;
                     Exit;
                end
                else Pos:= I + 1;
           end;
     until I = sfSearchFailed;
end;

{******}

procedure TEditor.SelectWord;

var E           : word; {End of the current line}
    Select_Mode : byte; {Allows us to turn select mode on inside procedure}

begin
     E:= LineEnd(CurPtr);

     if (Bufchar(CurPtr) = #32) or (CurPtr = E) then Exit;

     Select_Mode:= smExtend;
     StartSelect;

     while (Bufchar(Nextchar(CurPtr)) > #32) and (CurPtr < E) do
           SetCurPtr(Nextchar(CurPtr), Select_Mode);

     SetCurPtr(Nextchar(CurPtr), Select_Mode);
     ClipCopy;
end;

{******}

procedure TEditor.SetBufLen(Length : word);

begin
     BufLen:= Length;
     GapLen:= BufSize - Length;
     SelStart:= 0;
     SelEnd:= 0;
     CurPtr:= 0;
     LONGINT(CurPos):= 0;
     LONGINT(Delta):= 0;
     Limit.X:= MaxLineLength;
     Limit.Y:= CountLines(Buffer^[GapLen], BufLen) + 1;
     DrawLine:= 0;
     DrawPtr:= 0;
     DelCount:= 0;
     InsCount:= 0;
     Modified:= False;
     Update(ufView);
end;

{******}

function TEditor.SetBufSize(NewSize : word) : boolean;

begin
     SetBufSize:= NewSize <= BufSize;
end;

{******}

procedure TEditor.SetCmdState(Command : word; Enable : boolean);

var S : TCommandSet;

begin
     S:= [Command];

     if Enable and (State and sfActive <> 0) then EnableCommands(S)
                                             else DisableCommands(S);
end;

{******}

procedure TEditor.SetCurPtr(P : word; SelectMode : byte);

var Anchor : word;

begin
     if SelectMode and smExtend = 0 then Anchor:= P
                                    else if CurPtr = SelStart then
                                             Anchor:= SelEnd
                                         else
                                             Anchor:= SelStart;

     if P < Anchor then
     begin
          if SelectMode and smDouble <> 0 then
          begin
               P:= PrevLine(NextLine(P));
               Anchor:= NextLine(PrevLine(Anchor));
          end;
          SetSelect(P, Anchor, True);
     end
     else
     begin
          if SelectMode and smDouble <> 0 then
          begin
               P:= NextLine(P);
               Anchor:= PrevLine(NextLine(Anchor));
          end;
          SetSelect(Anchor, P, False);
     end;
end;

{******}

procedure TEditor.SetSelect(NewStart, NewEnd : word; CurStart : boolean);

var Flags : byte;
    P     : word;
    L     : word;

begin
     if CurStart then P:= NewStart
                 else P:= NewEnd;

     Flags:= ufUpdate;

     if (NewStart <> SelStart) or (NewEnd <> SelEnd) then
        if (NewStart <> NewEnd) or (SelStart <> SelEnd) then
           Flags:= ufView;

     if P <> CurPtr then
     begin
          if P > CurPtr then
          begin
               L:= P - CurPtr;
               Move(Buffer^[CurPtr + GapLen], Buffer^[CurPtr], L);
               Inc(CurPos.Y, CountLines(Buffer^[CurPtr], L));
               CurPtr:= P;
          end
          else
          begin
               L:= CurPtr - P;
               CurPtr:= P;
               Dec(CurPos.Y, CountLines(Buffer^[CurPtr], L));
               Move(Buffer^[CurPtr], Buffer^[CurPtr + GapLen], L);
          end;
          DrawLine:= CurPos.Y;
          DrawPtr:= LineStart(P);
          CurPos.X:= charPos(DrawPtr, P);
          DelCount:= 0;
          InsCount:= 0;
          SetBufSize(BufLen);
     end;
     SelStart:= NewStart;
     SelEnd:= NewEnd;
     Update(Flags);
end;

{******}

procedure TEditor.SetState(AState : word; Enable : boolean);

begin
     inherited SetState(AState, Enable);

     case AState of

          sfActive :  begin
                         if Assigned(HScrollBar) then
                            HScrollBar^.SetState(sfVisible, Enable);

                         if Assigned(VScrollBar) then
                            VScrollBar^.SetState(sfVisible, Enable);

                         if Assigned(Indicator) then
                            Indicator^.SetState(sfVisible, Enable);

                         UpdateCommands(Enable);
                      end;

          sfExposed : if Enable then Unlock;
     end;
end;

{******}

procedure TEditor.SetTabs;

var Index    : integer;      {Index into string array}
    TabData  : TTabStopRec;  {Holds dialog results}

begin
     with TabData do
     begin
          TabString:= Copy(TabSettings, 1, TabStopLength);

          if EditorDialog(edSetTabStops, @TabString) <> cmCancel then
          begin
               if Length(TabString) = 0 then
               begin
                    Fillchar(TabSettings, SizeOf(TabSettings), #0);
                    TabSettings[0]:= #0;
                    Exit;
               end
               else
               begin
                    Index:= Length(TabString);
                    while TabString[Index] <= #32 do Dec(Index);
                    TabSettings:= Copy(TabString, 1, Index);
               end;
          end;
     end;
end;

{******}

procedure TEditor.StartSelect;

begin
     HideSelect;
     Selecting:= True;
end;

{******}

procedure TEditor.Store(var S : TStream);

begin
     inherited Store(S);
     PutPeerViewPtr(S, HScrollBar);
     PutPeerViewPtr(S, VScrollBar);
     PutPeerViewPtr(S, Indicator);
     S.Write(BufSize, SizeOf(WORD));
     S.Write(CanUndo, SizeOf(BOOLEAN));
     S.Write(AutoIndent, SizeOf(AutoIndent));
     S.Write(LineNumber, SizeOf(LineNumber));
     S.Write(TabSettings, SizeOf(TabSettings));
end;

{******}

procedure TEditor.TabKey(SelectMode : byte);

var E        : word;                   {End of current line}
    Index    : integer;                {Loop counter}
    Position : integer;                {CurPos.X position}
    S        : word;                   {Start of current line}
    Spaces   : array [1..80] of char;  {Array to hold spaces for insertion}

begin
     E:= LineEnd(CurPtr);
     S:= LineStart(CurPtr);
     Position:= CurPos.X + 1;

     repeat
           Inc(Position);
     until (TabSettings[Position] <> #32) or (Position >= Ord(TabSettings[0]));

     E:= CurPos.X;
     Index:= 1;

     while Index < Position - E do
     begin
          if Overwrite then
          begin
               if (Position > LineEnd(CurPtr) - LineStart(CurPtr)) or
                  (Position > Ord(TabSettings[0])) then
               begin
                    SetCurPtr(LineStart(LineMove(CurPtr, 1)), SelectMode);
                    Exit;
               end
               else if CurPtr < BufLen then SetCurPtr(Nextchar(CurPtr), SelectMode);
          end
          else
          begin
               if (Position > 255) or (Position > Ord(TabSettings[0])) then
               begin
                    SetCurPtr(LineStart(LineMove(CurPtr, 1)), SelectMode);
                    Exit;
               end
               else Spaces[Index]:= #32;
          end;

          Inc(Index);
     end;

     if not OverWrite then InsertText(@Spaces, Index - 1, False);
end;

{******}

procedure TEditor.ToggleInsMode;

begin
     Overwrite:= not Overwrite;
     SetState(sfCursorIns, not GetState(sfCursorIns));
end;

{******}

procedure TEditor.TrackCursor(Center : boolean);

begin
     if Center then
         ScrollTo(CurPos.X - Size.X + 1, CurPos.Y - Size.Y div 2)
     else
         ScrollTo(Max(CurPos.X - Size.X + 1, Min(Delta.X, CurPos.X)),
                  Max(CurPos.Y - Size.Y + 1, Min(Delta.Y, CurPos.Y)));
end;

{******}

procedure TEditor.Undo;

var Length : word;

begin
     if (DelCount <> 0) or (InsCount <> 0) then
     begin
          SelStart:= CurPtr - InsCount;
          SelEnd:= CurPtr;
          Length:= DelCount;
          DelCount:= 0;
          InsCount:= 0;
          InsertBuffer(Buffer, CurPtr + GapLen - Length, Length, False, True);
     end;
end;

{******}

procedure TEditor.Unlock;

begin
     if LockCount > 0 then
     begin
          Dec(LockCount);
          if LockCount = 0 then DoUpdate;
     end;
end;

{******}

procedure TEditor.Update(AFlags : byte);

begin
     UpdateFlags:= UpdateFlags or AFlags;

     if LockCount = 0 then DoUpdate;
end;

{******}

procedure TEditor.UpdateCommands(Enable : boolean);

begin
     if (Enable = True) then
     begin
          SetCmdState(cmUndo, (DelCount <> 0) or (InsCount <> 0));

          if not IsClipboard then
          begin
               SetCmdState(cmUndo, True);
               SetCmdState(cmCut, HasSelection);
               SetCmdState(cmCopy, HasSelection);
               SetCmdState(cmPaste, Assigned(Clipboard) and (Clipboard^.HasSelection));
          end;

          SetCmdState(cmFilePrint, True);
          SetCmdState(cmClear, HasSelection);
          SetCmdState(cmFind, True);
          SetCmdState(cmReplace, True);
          SetCmdState(cmSearchAgain, True);
          SetCmdState(cmJumpLine, True);
     end
     else
     begin
          SetCmdState(cmFilePrint, False);
          SetCmdState(cmUndo, False);
          SetCmdState(cmCut, False);
          SetCmdState(cmCopy, False);
          SetCmdState(cmPaste, False);
          SetCmdState(cmClear, False);
          SetCmdState(cmFind, False);
          SetCmdState(cmReplace, False);
          SetCmdState(cmSearchAgain, False);
          SetCmdState(cmJumpLine, False);
     end;
end;

{******}

function TEditor.Valid(Command : word) : boolean;

begin
     Valid:= IsValid;
end;


{*** TMemo object (see TP7 online help for more information) ***}

constructor TMemo.Load(var S : TStream);

var Length : word;

begin
     inherited Load(S);
     S.Read(Length, SizeOf(WORD));

     if IsValid then
     begin
          S.Read(Buffer^[BufSize - Length], Length);
          SetBufLen(Length);
     end
     else S.Seek(S.GetPos + Length);
end;

{******}

function TMemo.DataSize : word;

begin
     DataSize:= BufSize + SizeOf(WORD);
end;

{******}

procedure TMemo.GetData(var Rec);

var Data : TMemoData absolute Rec;

begin
     Data.Length:= BufLen;
     Move(Buffer^, Data.Buffer, CurPtr);
     Move(Buffer^[CurPtr + GapLen], Data.Buffer[CurPtr], BufLen - CurPtr);
     Fillchar(Data.Buffer[BufLen], BufSize - BufLen, 0);
end;

{******}

function TMemo.GetPalette : PPalette;

const P : string[Length(CMemo)] = CMemo;

begin
     GetPalette:= @P;
end;

{******}

procedure TMemo.HandleEvent(var Event : TEvent);

begin
     if (Event.What <> evKeyDown) or (Event.KeyCode <> kbTab) then
        inherited HandleEvent(Event);
end;

{******}

procedure TMemo.SetData(var Rec);

var Data : TMemoData absolute Rec;

begin
     Move(Data.Buffer, Buffer^[BufSize - Data.Length], Data.Length);
     SetBufLen(Data.Length);
end;

{******}

procedure TMemo.Store(var S : TStream);

begin
     inherited Store(S);
     S.Write(BufLen, SizeOf(WORD));
     S.Write(Buffer^, CurPtr);
     S.Write(Buffer^[CurPtr + GapLen], BufLen - CurPtr);
end;


{*** TFileEditor object (see TP7 online help for more information) ***}

constructor TFileEditor.Init(var Bounds       : TRect;
                                 AHScrollBar,
                                 AVScrollBar  : PScrollBar;
                                 AIndicator   : PIndicator;
                                 AFileName    : FNameStr);

begin
     inherited Init(Bounds, AHScrollBar, AVScrollBar, AIndicator, 0);

     if AFileName <> '' then
     begin
          FileName:= FExpand(AFileName);

          if IsValid then IsValid:= LoadFile;
     end;
end;

{******}

constructor TFileEditor.Load(var S : TStream);

var SStart : word;
    SEnd   : word;
    Curs   : word;

begin
     inherited Load(S);
     BufSize:= 0;

     S.Read(FileName[0], SizeOf(CHAR));
     S.Read(Filename[1], Length(FileName));

     if IsValid then IsValid:= LoadFile;

     S.Read(SStart, SizeOf(WORD));
     S.Read(SEnd, SizeOf(WORD));
     S.Read(Curs, SizeOf(WORD));

     if IsValid and(SEnd <= BufLen) then
     begin
          SetSelect(SStart, SEnd, Curs = SStart);
          TrackCursor(True);
     end;
end;

{******}

procedure TFileEditor.DoneBuffer;

begin
     if Assigned(Buffer) then DisposeBuffer(Buffer);
end;

{******}

procedure TFileEditor.HandleEvent(var Event : TEvent);

begin
     inherited HandleEvent(Event);

     case Event.What of
          evCommand : case Event.Command of

                           cmSave   : Save;
                           cmSaveAs : SaveAs;
                               else   Exit;
                      end;

               else   Exit;
     end;

     ClearEvent(Event);
end;

{******}

procedure TFileEditor.InitBuffer;

begin
     NewBuffer(POINTER(Buffer), $1000);
end;

{******}

function TFileEditor.LoadFile: boolean;

var Length : word;
    FSize  : longint;
    F      : file;
    IOR    : word;

begin
     {$I-}
     LoadFile:= False;
     Length:= 0;
     FileMode:= 0; {read-only}
     Assign(F, FileName);
     Reset(F, 1);
     FileMode:= 2; {read/write}
     {$I+}

     IOR:= IOResult;
     if IOR <> 0 then
     begin
          EditorDialog(edReadError, @FileName);
     end
     else
     begin
          FSize:= FileSize(F);
          if (FSize > $FFF0) or not SetBufSize(WORD(FSize)) then
               EditorDialog(edOutOfMemory, nil)
          else
          begin
               {$I-}
               BlockRead(F, Buffer^[BufSize - WORD(FSize)], FSize);
               {$I+}
               IOR:= IOResult;
               if IOR <> 0 then
               begin
                    EditorDialog(edReadError, @FileName)
               end
               else
               begin
                    LoadFile:= True;
                    Length:= FSize;
               end;
          end;
          Close(F);
     end;
     SetBufLen(Length);
end;

{******}

function TFileEditor.Save : boolean;

var F    : file;
    A    : word;
    Dir  : string;
    Name : string;
    Ext  : string;


begin
     {*** Check the source file has a name ***}
     if (FileName = '') then
     begin
          Save:= SaveAs
     end
     else
     begin
         {*** Check the source file is not read-only ***}
         Assign(F, FileName);
         GetFAttr(F, A);

         if (A and ReadOnly <> 0) then
         begin
              FSplit(FileName, Dir, Name, Ext);
              MessageBox(#3 + Name + Ext + ' is read-only.'#13#10#3'You must save to a new file.', nil, mfError + mfOKButton);
              Save:= SaveAs;
         end
         else
         begin
              Save:= SaveFile;
         end
     end;
end;

{******}

function TFileEditor.SaveAs : boolean;

var bLoop  : boolean;
    F      : file;
    A      : word;
    Dir    : string;
    Name   : string;
    Ext    : string;
    OldName: string;

begin
     SaveAs:= False;
     bLoop:= True;
     OldName:= FileName;

     while (bLoop = True) do
     begin
          if EditorDialog(edSaveAs, @FileName) <> cmCancel then
          begin
               FileName:= FExpand(FileName);

               {*** Check the source file is not read-only ***}
               Assign(F, FileName);
               GetFAttr(F, A);

               if (A and ReadOnly <> 0) then
               begin
                    FSplit(FileName, Dir, Name, Ext);
                    MessageBox(#3 + Name + Ext + ' is read-only.'#13#10#3'You must save to a new file.',
                               nil, mfError + mfOKButton);
                    FileName:= OldName;
                    bLoop:= True;
               end
               else
               begin
                    Message(Owner, evBroadcast, cmUpdateTitle, nil);
                    SaveAs:= SaveFile;

                    if IsClipboard then FileName:= '';
                    bLoop:= false;
               end
          end
          else
          begin
               FileName:= OldName;
               bLoop:= False;
          end;
     end;
end;

{******}

function TFileEditor.SaveFile : boolean;

var F          : file;
    BackupName : FNameStr;
    D          : DirStr;
    N          : NameStr;
    E          : ExtStr;

begin
     SaveFile:= False;

     if (EditorFlags and efBackupFiles <> 0)  then
     begin
          FSplit(FileName, D, N, E);
          BackupName:= D + N + '.BAK';

          if (FileExists(BackupName)) then
          begin
              Assign(F, BackupName);
              Erase(F);
          end;

          if (FileExists(FileName)) then
          begin
              Assign(F, FileName);
              Rename(F, BackupName);
          end;
          InOutRes:= 0;
     end;

     {$I-}
     Assign(F, FileName);
     Rewrite(F, 1);
     {$I+}

     if IOResult <> 0 then
          EditorDialog(edCreateError, @FileName)
     else
     begin
          {$I-}
          BlockWrite(F, Buffer^, CurPtr);
          BlockWrite(F, Buffer^[CurPtr + GapLen], BufLen - CurPtr);
          {$I+}
          if IOResult <> 0 then
               EditorDialog(edWriteError, @FileName)
          else
          begin
               Modified:= False;
               Update(ufUpdate);
               SaveFile:= True;
          end;
          Close(F);
     end;
end;

{******}

function TFileEditor.SetBufSize(NewSize : word) : boolean;

var N : word;

begin
     SetBufSize:= False;
     if NewSize = 0 then
         NewSize:= $1000
     else
         if NewSize > $F000 then
             NewSize:= $FFF0
         else
             NewSize:=(NewSize + $0FFF) and $F000;

     if NewSize <> BufSize then
     begin
          if NewSize > BufSize then
             if not SetBufferSize(Buffer, NewSize) then Exit;

          N:= BufLen - CurPtr + DelCount;
          Move(Buffer^[BufSize - N], Buffer^[NewSize - N], N);
          if NewSize < BufSize then SetBufferSize(Buffer, NewSize);
          BufSize:= NewSize;
          GapLen:= BufSize - BufLen;
     end;
     SetBufSize:= True;
end;

{******}

procedure TFileEditor.Store(var S : TStream);

begin
     inherited Store(S);
     S.Write(FileName, Length(FileName) + 1);
     S.Write(SelStart, SizeOf(WORD) * 3);
end;

{******}

procedure TFileEditor.UpdateCommands(Enable : boolean);

begin
     inherited UpdateCommands(Enable);

     SetCmdState(cmSave, Enable);
     SetCmdState(cmSaveAs, Enable);

     { SetCmdState(cmEndPage, True);     }
     { SetCmdState(cmHomePage, True);    }
     { SetCmdState(cmIndentMode, True);  }
     { SetCmdState(cmJumpLine, True);    }
     { SetCmdState(cmScrollDown, True);  }
     { SetCmdState(cmScrollUp, True);    }
     { SetCmdState(cmSelectword, True);  }
     { SetCmdState(cmSetTabs, True);     }
     { SetCmdState(cmTabKey, True);      }
end;

{******}

function TFileEditor.Valid(Command : word) : boolean;

var D : integer;

begin
     if Command = cmValid then
          Valid:= IsValid
     else
     begin
          Valid:= True;

          if Modified then
          begin
               if FileName = '' then D:= edSaveUntitled
                                else D:= edSaveModify;

               case EditorDialog(D, @FileName) of

                    cmYes    : Valid:= Save;
                    cmNo     : Modified:= False;
                    cmCancel : Valid:= False;

               end;
          end;
     end;
end;

{*** TEditWindow object (see TP7 online help for more information) ***}

constructor TEditWindow.Init(var Bounds   : TRect;
                                 FileName : FNameStr;
                                 ANumber  : integer);

var HScrollBar : PScrollBar;
    VScrollBar : PScrollBar;
    Indicator  : PIndicator;
    R          : TRect;

begin
     inherited Init(Bounds, '', ANumber);
     Options:= Options or ofTileable;

     R.Assign(18, Size.Y - 1, Size.X - 2, Size.Y);
     HScrollBar:= New(PScrollBar, Init(R));
     HScrollBar^.Hide;
     Insert(HScrollBar);

     R.Assign(Size.X - 1, 1, Size.X, Size.Y - 1);
     VScrollBar:= New(VIEWS.PScrollBar, Init(R));
     VScrollBar^.Hide;
     Insert(VScrollBar);

     R.Assign(2, Size.Y - 1, 16, Size.Y);
     Indicator:= New(PIndicator, Init(R));
     Indicator^.Hide;
     Insert(Indicator);

     GetExtent(R);
     R.Grow(-1, -1);
     Editor:= New(PFileEditor, Init(R, HScrollBar, VScrollBar, Indicator, FileName));
     Insert(Editor);
end;

{******}

constructor TEditWindow.Load(var S : TStream);

begin
     inherited Load(S);
     GetSubViewPtr(S, Editor);
end;

{******}

procedure TEditWindow.Close;

begin
     if Editor^.IsClipboard then Hide
                            else inherited Close;
end;

{******}

function TEditWindow.GetTitle(MaxSize : integer) : TTitleStr;

begin
     if Editor^.IsClipboard then GetTitle:= 'Clipboard'
                            else if Editor^.FileName = '' then
                                     GetTitle:= 'Untitled'
                                 else
                                     GetTitle:= Editor^.FileName;
end;

{******}

procedure TEditWindow.HandleEvent(var Event : TEvent);

begin
     inherited HandleEvent(Event);

     if (Event.What = evBroadcast) then
        case Event.Command of

             cmUpdateTitle   : begin
                                    Frame^.DrawView;
                                    ClearEvent(Event);
                               end;

             cmBludgeonStats : begin
                                    Editor^.Update(ufStats);
                                    ClearEvent(Event);
                               end;
        end;
end;

{******}

procedure TEditWindow.SizeLimits(var Min, Max: TPoint);

begin
     inherited SizeLimits(Min, Max);
     Min.X:= 23;
end;

{******}

procedure TEditWindow.Store(var S : TStream);

begin
     inherited Store(S);
     PutSubViewPtr(S, Editor);
end;

{******}

(* RegisterEditors - registers all editor related registration records. *)

procedure RegisterEditors;

begin
     RegisterType(REditor);
     RegisterType(RMemo);
     RegisterType(RFileEditor);
     RegisterType(RIndicator);
     RegisterType(REditWindow);
     RegisterType(RASMEditor);
     RegisterType(RASMEditwindow);
end;


{*** NASM Specific Editor OBJECTS ***}

{*** TASMEditWindow object ***}

constructor TASMEditWindow.Init(var Bounds   : TRect;
                                    FileName : FNameStr;
                                    ANumber  : integer);

var H, V : PScrollBar;
    R    : TRect;
    I    : PIndicator;

begin
     TWindow.Init(Bounds, '', ANumber);
     HelpCtx:= hcEditWindow;

     R.Assign(18, Size.Y - 1, Size.X - 2, Size.Y);
     H:= New(PScrollBar, Init(R));
     Insert(H);

     V:= StandardScrollBar(sbVertical);

     R.Assign(2, Size.Y - 1, 16, Size.Y);
     I:= New(PIndicator, Init(R));
     Insert(I);

     GetExtent(R);
     R.Grow(-1, -1);
     Editor:= New(PASMEditor, Init(R, H, V, I, FileName));
     Insert(Editor);

     Inc(NumberOfEditors);
     Inc(NumberOfWindows);
end;

{******}

destructor TASMEditWindow.Done;

begin
     inherited Done;
     Dec(NumberOfEditors);
     Dec(NumberOfWindows);
end;

{******}

procedure TASMEditWindow.Close;

begin
     if (not Editor^.IsClipboard) and (Editor^.FileName <> '') then
        Main.AddRecentFile(Editor^.FileName);

     if (Editor^.IsClipboard) then Dec(NumberOfWindows);
     inherited Close;
end;

{******}

function TASMEditWindow.GetPalette : PPalette;

const C = CBlueWindow;
      P : TPalette = C;

begin
     GetPalette:= @P;
end;

{******}

function TASMEditWindow.GetTitle(MaxSize : integer) : TTitleStr;

var Dir      : DirStr;
    Name     : NameStr;
    Ext      : ExtStr;
    Loop     : word;
    CurDir   : string;
    ShortName: string;
    TitleStr : string;

begin
     if Editor^.IsClipboard then
          TitleStr:= 'Clipboard'
     else if Editor^.FileName = '' then
               TitleStr:= 'Untitled'
          else
          begin
               FSplit(Editor^.FileName, Dir, Name, Ext);
               ShortName:= Name + Ext;

               GetDir(0, CurDir);

               if CurDir[Length(CurDir)] <> '\' then
                  CurDir:= CurDir + '\';

               if CurDir = Dir then
                    TitleStr:= ShortName
               else
               begin
                    if Length(Editor^.FileName) <= MaxSize then
                         TitleStr:= Editor^.FileName
                    else
                    begin
                       if (MaxSize <= 19) then
                          TitleStr:= Copy(ShortName, 1, Min(MaxSize,
                                                              Length(ShortName)))
                       else
                       begin
                          Loop:= Length(Editor^.FileName) - MaxSize + 6;
                          while Editor^.FileName[Loop] <> '\' do Inc(Loop);
                          TitleStr:= Copy(Dir, 1, 3) + '...' +
                                     Copy(Editor^.FileName, Loop,
                                          Length(Editor^.FileName) - Loop + 1);
                       end;
                    end;
               end;
          end;

     GetTitle:= TitleStr;
end;

{******}

procedure TASMEditWindow.HandleEvent(var Event : TEvent);

begin
     inherited HandleEvent(Event);

     if (State and sfFocused) <> 0 then CurrentView:= EditorWindow;

     if (Event.What = evBroadcast) then
        case (Event.Command) of

             cmCloseAll : Close;

         cmFileSaveAll  : if not Editor^.IsClipboard then Editor^.Save;

       cmHighlightError : if (StrUpper(PString(Event.InfoPtr)^) =
                              StrUpper(Editor^.Filename)) then
                                   ClearEvent(Event);

              cmRefresh : Redraw;
        end;
end;

{******}

constructor TASMEditWindow.Load(var S : TStream);

begin
     inherited Load(S);

     Inc(NumberOfEditors);
     Inc(NumberOfWindows);

end;

{******}

procedure TASMEditWindow.SizeLimits(var Min, Max: TPoint);

begin
     inherited SizeLimits(Min, Max);
     Min.X:= 30;
     Min.Y:= 6;
end;

{*** TASMEditor object ***}

procedure TASMEditor.HandleEvent(var Event : TEvent);

var PrimaryName : string;
    ININame     : string;

begin
     ININame:= Main.NASMDirectory + 'NASMIDE.INI';
     inherited HandleEvent(Event);
     if (Event.What and evCommand) <> 0 then
     begin
          case Event.Command of

               cmFilePrint : begin
                                  Print;
                                  ClearEvent(Event);
                             end;

        cmAssembleAssemble : begin
                                Assemble('You must save your file before assembling!', false);
                                ClearEvent(Event);
                             end;

            cmAssembleBuild: begin
                                INI_GetProfileString(ININame, 'ASSEMBLER', 'PRIMARY_FILE', PrimaryName, '');
                                if PrimaryName = '' then
                                begin
                                     Assemble('You must save your file before assembling!', false);
                                     ClearEvent(Event);
                                end;
                             end;

              cmAssembleRun: begin
                                INI_GetProfileString(ININame, 'ASSEMBLER', 'PRIMARY_FILE', PrimaryName, '');
                                if PrimaryName = '' then
                                begin
                                     AssembleRun;
                                     ClearEvent(Event);
                                end;
                             end;
          end;
     end;
end;

{******}

procedure TASMEditor.Assemble(Warning : string; Run : boolean);

var ININame            : string;     {NASM-IDE INI file name}
    SrcUntitled        : boolean;    {True if the source has not been saved}
    SrcSave            : boolean;    {Result of auto-save}
    EditorOptions      : integer;

begin
     {*** Check file has been saved ***}
     SrcUntitled:= false;
     if (FileName = '') then
        if MessageBox(#3 + Warning, nil, mfOKCancel + mfInformation) = cmCancel
        then Exit
        else SrcUntitled:= true;

     {*** Get name of INI file ***}
     ININame:= Main.NASMDirectory + 'NASMIDE.INI';

     {*** Determine if auto-save is active ***}
     INI_GetProfileInt(ININame, 'ENVIRONMENT', 'EDITOR_OPTIONS',
                       INTEGER(EditorOptions), 3);
     if EditorOptions > 3 then EditorOptions:= 3;

     if ((EditorOptions and 2) = 2) or (SrcUntitled) then
     begin
          SrcSave:= Save;
          if not SrcSave then Exit;
     end;

     if Run = false then
        NASM.Assemble(FileName)
     else
        NASM.AssembleRun(FileName);
end;

{******}

procedure TASMEditor.AssembleRun;

begin
     {*** Determine if file needs saving ***}
     Assemble('You must save your file before running!', true);
end;

{******}

procedure TASMEditor.DirectJump(Line : word);

begin
     if Line = CurPos.Y + 1 then Exit;
     SetCurPtr(0, 0);
     SetCurPtr(LineMove(CurPtr, Line - 1), 0);
     TrackCursor(false);
end;

{******}

procedure TASMEditor.Draw;

begin
     if EditorFlags and efSyntaxHighlight <> 0 then
     begin
          if DrawLine <> Delta.Y then
          begin
               DrawPtr:= LineMove(DrawPtr, Delta.Y - DrawLine);
               DrawLine:= Delta.Y;
          end;
          DrawLines(0, Size.Y, DrawPtr);
     end
     else inherited Draw;
end;

{******}

procedure TASMEditor.DrawLines(Y, Count : Integer; LinePtr : Word);

var Color : word;
    B     : array[0..MaxLineLength - 1] of word;

begin
     if EditorFlags and efSyntaxHighlight <> 0 then
     begin
          Color:= GetColor($0201);
          while Count > 0 do
          begin
               FormatLine(B, LinePtr, Delta.X + Size.X, Color);
               SyntaxHighlight(B);
               WriteBuf(0, Y, Size.X, 1, B[Delta.X]);
               LinePtr:= NextLine(LinePtr);
               Inc(Y);
               Dec(Count);
          end;
     end
     else inherited DrawLines(Y, Count, LinePtr);
end;

{******}

procedure TASMEditor.FormatLine (var DrawBuf; LinePtr : Word;
                                     Width  : Integer;
                                     Colors : Word); assembler;

asm
   push    ds
   lds     bx, Self
   les     di, DrawBuf
   mov     si, LinePtr
   xor     dx, dx
   cld
   mov     ah, Colors.BYTE[0]
   mov     cx, ds:[bx].TEditor.SelStart
   call    @@10
   mov     ah, Colors.BYTE[1]
   mov     cx, ds:[bx].TEditor.CurPtr
   call    @@10
   add     si, ds:[bx].TEditor.GapLen
   mov     cx, ds:[bx].TEditor.SelEnd
   add     cx, ds:[bx].TEditor.GapLen
   call    @@10
   mov     ah, Colors.BYTE[0]
   mov     cx, ds:[bx].TEditor.BufSize
   call    @@10
   jmp     @@31

@@10:

   sub     cx, si
   ja      @@11
   retn

@@11:

   lds     bx, ds:[bx].TEditor.Buffer
   add     si, bx
   mov     bx, Width

@@12:

   lodsb
   cmp     al, ' '
   jb      @@20

@@13:

   stosw
   inc     dx

@@14:

   cmp     dx, bx
   jae     @@30
   loop    @@12
   lds     bx, Self
   sub     si, ds:[bx].TEditor.Buffer.WORD[0]
   retn

@@20:

   cmp     al, $0D
   je      @@30
   cmp     al, $09
   jne     @@13
   mov     al, ' '

@@21:

   stosw
   inc     dx
   test    dl, 7
   jne     @@21
   jmp     @@14

@@30:

   pop     cx

@@31:

   mov     al, ' '
   mov     cx, Width
   sub     cx, dx
   jbe     @@32
   rep     stosw

@@32:

   pop     ds
end;

{******}

function TASMEditor.GetPalette : PPalette;

const P : string[Length(CASMEditor)] = CASMEditor;

begin
     GetPalette := @P;
end;

{******}

procedure TASMEditor.SyntaxHighlight(var DrawBuf);

type TLineData = array[0..MaxLineLength - 1] of word;

const CDirective = $1B;

{******}

 function BufToStr(B      : TLineData;
                   wStart : word;
                   wEnd   : word) : string;

 var Str    : string;
     StrIdx : word;
     BufIdx : word;

 begin
      BufIdx:= wStart + 1;
      StrIdx:= 1;

      while (Chr(WORDREC(B[BufIdx]).Lo) <> ' ') and (BufIdx < wEnd) do
      begin
           Str[0]:= Chr(StrIdx);
           Str[StrIdx]:= Chr(WORDREC(B[BufIdx]).Lo);
           Inc(StrIdx);
           Inc(BufIdx);
      end;

      BufToStr:= Str;
 end;

{******}

 function FindSelect(    B      : TLineData;
                     var wStart : word;
                     var wEnd   : word) : boolean;

 var Loop   : word;
     Found1 : boolean;
     Found2 : boolean;

 begin
      wStart:= 0;
      wEnd:= 0;
      Loop:= 0;
      Found1:= false;
      Found2:= false;

      repeat
            if WORDREC(B[Loop]).Hi = $71 then
            begin
                 wStart:= Loop;
                 Found1:= true;
            end;
            Inc(Loop);
      until (Found1) or (Loop > High(B));

      if Found1 then
      begin
           repeat
                 if WORDREC(B[Loop]).Hi = $1E then
                 begin
                      wEnd:= Loop - 1;
                      Found2:= true;
                 end;
                 Inc(Loop);
           until (Found2) or (Loop > High(B));

           if not Found2 then wEnd:= MaxLineLength - 1;
           FindSelect:= true;
      end
      else FindSelect:= false;
 end;

{******}

 function FindComment(var B           : TLineData;
                      var wCommentPos : word) : boolean;

 var Loop  : word;
     Found : boolean;

 begin
      wCommentPos:= MaxLineLength - 1;
      Loop:= 0;
      Found:= false;
      repeat
            if Chr(WORDREC(B[Loop]).Lo) = ';' then
            begin
                 wCommentPos:= Loop;
                 Found:= true;
            end;
            Inc(Loop);
      until (Found) or (Loop > High(B));
      FindComment:= Found;
 end;

{******}

 function FindDirective(    B             : TLineData;
                            wSearchStart  : word;
                            wCommentStart : word;
                        var wStart        : word;
                        var wEnd          : word) : boolean;

 var Loop   : word;
     Found1 : boolean;
     Found2 : boolean;

 begin
      wStart:= MaxLineLength + 1;
      wEnd:= MaxLineLength + 1;
      Loop:= wSearchStart;
      Found1:= false;
      Found2:= false;

      repeat
            if Chr(WORDREC(B[Loop]).Lo) = '[' then
            begin
                 wStart:= Loop;
                 Found1:= true;
            end;
            Inc(Loop);
      until (Found1) or (Loop > wCommentStart);

      if Found1 then
      begin
           repeat
                 if Chr(WORDREC(B[Loop]).Lo) = ']' then
                 begin
                      wEnd:= Loop;
                      Found2:= true;
                 end;
                 Inc(Loop);
           until (Found2) or (Loop > High(B));

           if not Found2 then wEnd:= wCommentStart;
           FindDirective:= CheckDirective(BufToStr(B, wStart, wEnd));
      end
      else FindDirective:= false;
 end;

{******}

 function FindMacro(    B             : TLineData;
                        wSearchStart  : word;
                        wCommentStart : word;
                    var wStart        : word;
                    var wEnd          : word) : boolean;

 var Loop   : word;
     Found1 : boolean;
     Found2 : boolean;

 begin
      wStart:= MaxLineLength + 1;
      wEnd:= MaxLineLength + 1;
      Loop:= wSearchStart;
      Found1:= false;
      Found2:= false;

      repeat
            if Chr(WORDREC(B[Loop]).Lo) = '%' then
            begin
                 wStart:= Loop;
                 Found1:= true;
            end;
            Inc(Loop);
      until (Found1) or (Loop > wCommentStart);

      if Found1 then
      begin
           repeat
                 if Chr(WORDREC(B[Loop]).Lo) = ' ' then
                 begin
                      wEnd:= Loop;
                      Found2:= true;
                 end;
                 Inc(Loop);
           until (Found2) or (Loop > High(B));

           if not Found2 then wEnd:= wCommentStart;
           FindMacro:= CheckPreProcDirective(BufToStr(B, wStart, wEnd));
      end
      else FindMacro:= false;
 end;

{******}

 function FindOpCode(    B              : TLineData;
                         wSearchStart   : word;
                         wCommentStart  : word;
                     var wStart         : word;
                     var wEnd           : word) : boolean;

 var Loop   : word;
     Found1 : boolean;
     Found2 : boolean;

 begin
      wStart:= MaxLineLength + 1;
      wEnd:= MaxLineLength + 1;
      Loop:= wSearchStart;
      Found1:= false;
      Found2:= false;

      repeat
            if Chr(WORDREC(B[Loop]).Lo) <> ' ' then
            begin
                 wStart:= Loop;
                 Found1:= true;
            end;
            Inc(Loop);
      until (Found1) or (Loop > wCommentStart);

      if Found1 then
      begin
           repeat
                 if Chr(WORDREC(B[Loop]).Lo) = ' ' then
                 begin
                      wEnd:= Loop;
                      Found2:= true;
                 end;
                 Inc(Loop);
           until (Found2) or (Loop > High(B));

           if not Found2 then wEnd:= wCommentStart;
           FindOpCode:= CheckOpCode(BufToStr(B, wStart - 1, wEnd))
      end
      else FindOpCode:= false;
 end;

{******}

 function FindConditional(    B             : TLineData;
                              wSearchStart  : word;
                              wCommentStart : word;
                          var wStart        : word;
                          var wEnd          : word) : boolean;

 var Loop   : word;
     Found1 : boolean;
     Found2 : boolean;

 begin
      wStart:= MaxLineLength + 1;
      wEnd:= MaxLineLength + 1;
      Loop:= wSearchStart;
      Found1:= false;
      Found2:= false;

      repeat
            if Chr(WORDREC(B[Loop]).Lo) <> ' ' then
            begin
                 wStart:= Loop;
                 Found1:= true;
            end;
            Inc(Loop);
      until (Found1) or (Loop > wCommentStart);

      if Found1 then
      begin
           repeat
                 if Chr(WORDREC(B[Loop]).Lo) = ' ' then
                 begin
                      wEnd:= Loop;
                      Found2:= true;
                 end;
                 Inc(Loop);
           until (Found2) or (Loop > High(B));

           if not Found2 then wEnd:= wCommentStart;
           FindConditional:= CheckConditional(BufToStr(B, wStart - 1, wEnd))
      end
      else FindConditional:= false;
 end;

{******}

 function FindRegister(    B             : TLineData;
                           wSearchStart  : word;
                           wCommentStart : word;
                       var wStart        : word;
                       var wMid          : word;
                       var wEnd          : word) : boolean;

 var Loop   : word;
     Found1 : boolean;
     Found2 : boolean;

 begin
      wStart:= MaxLineLength + 1;
      wEnd:= MaxLineLength + 1;
      Loop:= wSearchStart;
      Found1:= false;
      Found2:= false;

      repeat
            if (Chr(WORDREC(B[Loop]).Lo) in ['A'..'Z', 'a'..'z']) then
            begin
                 if (Loop > 0) then
                 begin
                      if not(Chr(WORDREC(B[Loop - 1]).Lo) in ['A'..'Z', 'a'..'z', '0'..'9']) then
                      begin
                           wStart:= Loop;
                           Found1:= true;
                      end
                 end
                 else
                 begin
                      wStart:= Loop;
                      Found1:= true;
                 end;
            end;

            Inc(Loop);
      until (Found1) or (Loop > wCommentStart);

      if Found1 then
      begin
           repeat
                 if not(Chr(WORDREC(B[Loop]).Lo) in ['A'..'Z', 'a'..'z',
                                                     '0'..'9']) then
                 begin
                      wEnd:= Loop;
                      if Chr(WORDREC(B[Loop]).Lo) <> ' ' then wMid:= Loop - 1
                                                         else wMid:= Loop;
                      Found2:= true;
                 end;
                 Inc(Loop);
           until (Found2) or (Loop > High(B));

           if not Found2 then wEnd:= wCommentStart;
           FindRegister:= CheckRegName(BufToStr(B, wStart - 1, wEnd))
      end
      else FindRegister:= false;
 end;

{******}

 function FindString(    B             : TLineData;
                         wSearchStart  : word;
                         wCommentStart : word;
                     var wStart        : word;
                     var wEnd          : word) : boolean;

 var Loop   : word;
     Found1 : boolean;
     Found2 : boolean;

 begin
      wStart:= MaxLineLength + 1;
      wEnd:= MaxLineLength + 1;
      Loop:= wSearchStart;
      Found1:= false;
      Found2:= false;

      repeat
            if Chr(WORDREC(B[Loop]).Lo) = #39 then
            begin
                 wStart:= Loop;
                 Found1:= true;
            end;
            Inc(Loop);
      until (Found1) or (Loop > wCommentStart);

      if Found1 then
      begin
           repeat
                 if Chr(WORDREC(B[Loop]).Lo) = #39 then
                 begin
                      wEnd:= Loop;
                      Found2:= true;
                 end;
                 Inc(Loop);
           until (Found2) or (Loop > High(B));

           if not Found2 then wEnd:= wCommentStart;
           FindString:= true;
      end
      else FindString:= false;
 end;

 {******}

 function FindUserDirective(    B              : TLineData;
                                wSearchStart   : word;
                                wCommentStart  : word;
                            var wStart         : word;
                            var wEnd           : word) : boolean;

 var Loop   : word;
     Found1 : boolean;
     Found2 : boolean;

 begin
      wStart:= MaxLineLength + 1;
      wEnd:= MaxLineLength + 1;
      Loop:= wSearchStart;
      Found1:= false;
      Found2:= false;

      repeat
            if (Chr(WORDREC(B[Loop]).Lo) <> ' ') then
            begin
                 wStart:= Loop;
                 Found1:= true;
            end;
            Inc(Loop);
      until (Found1) or (Loop > wCommentStart);

      if Found1 then
      begin
           repeat
                 if ((Chr(WORDREC(B[Loop]).Lo) = ' ') or (Chr(WORDREC(B[Loop]).Lo) = ']')) then
                 begin
                      wEnd:= Loop;
                      Found2:= true;
                 end;
                 Inc(Loop);
           until (Found2) or (Loop > High(B));

           if not Found2 then wEnd:= wCommentStart;
           FindUserDirective:= CheckDirective(BufToStr(B, wStart - 1, wEnd))
      end
      else FindUserDirective:= false;
 end;

{******}

 procedure FillBuf(wStart, wEnd : word; bColour : byte; var B : TLineData);

 var Loop : word;

 begin
      for Loop:= wStart to wEnd do WORDREC(B[Loop]).Hi:= bColour;
 end;

{******}

var B            : TLineData;

    Comments     : boolean;
    Selection    : boolean;

    SearchStart  : word;

    wStart       : word;
    wMid         : word;
    wEnd         : word;

    CommentPos   : word;
    SStart       : word;
    SEnd         : word;

begin
     B:= TLineData(DrawBuf);
     Selection:= FindSelect(B, SStart, SEnd);
     Comments:= FindComment(B, CommentPos);

     SearchStart:= 0;
     repeat
           if FindDirective(B, SearchStart, CommentPos, wStart, wEnd) then
              FillBuf(wStart, wEnd, CDirective, B);

           SearchStart:= wEnd;
     until SearchStart >= CommentPos;

     SearchStart:= 0;
     repeat
           if FindUserDirective(B, SearchStart, CommentPos, wStart, wEnd) then
              FillBuf(wStart, wEnd, CDirective, B);
           SearchStart:= wEnd;
     until SearchStart >= CommentPos;

     SearchStart:= 0;
     repeat
           if FindOpCode(B, SearchStart, CommentPos, wStart, wEnd) then
              FillBuf(wStart, wEnd, GetColor(4), B);

           SearchStart:= wEnd;
     until SearchStart >= CommentPos;

     SearchStart:= 0;
     repeat
           if FindConditional(B, SearchStart, CommentPos, wStart, wEnd) then
              FillBuf(wStart, wEnd, $1C, B);

           SearchStart:= wEnd;
     until SearchStart >= CommentPos;

     SearchStart:= 0;
     repeat
           if FindRegister(B, SearchStart, CommentPos, wStart, wMid, wEnd) then
              FillBuf(wStart, wMid, GetColor(5), B);

           SearchStart:= wEnd;
     until SearchStart >= CommentPos;

     SearchStart:= 0;
     repeat
           if FindString(B, SearchStart, CommentPos, wStart, wEnd) then
              FillBuf(wStart, wEnd, $1D, B);

           SearchStart:= wEnd + 1;
     until SearchStart >= CommentPos;

     SearchStart:= 0;
     repeat
           if FindMacro(B, SearchStart, CommentPos, wStart, wEnd) then
              FillBuf(wStart, wEnd, $13, B);

           SearchStart:= wEnd;
     until SearchStart >= CommentPos;

     if Comments then FillBuf(CommentPos, MaxLineLength - 1, GetColor(3), B);

     if Selection then FillBuf(SStart, SEnd, GetColor(2), B);

     TLineData(DrawBuf):= B;
end;

{******}

function TASMEditor.Print : boolean;

var i : word;
    P : PPrintFileBox;
    b : word;

begin
     P:= New(PPrintFileBox, Init('Printing file', BufLen + 1));
     b:= 1;
     if CurPtr <> 0 then
     begin
          i:= 0;
          while i <= CurPtr do
          begin
               write(lst, Buffer^[i]);
               Inc(i);
               Inc(b);
               P^.Update(b);
          end;
     end;
     i:= CurPtr + GapLen;
     while i < GapLen + BufLen do
     begin
          write(lst, Buffer^[i]);
          Inc(i);
          Inc(b);
          P^.Update(b);
     end;
     Dispose(P, Done);
     if IOResult <> 0 then EditorDialog(edPrintError, @FileName)
                      else Print:= true;
end;

{******}

procedure TASMEditor.UpdateCommands(Enable : boolean);

begin
     inherited UpdateCommands(Enable);

     if (IsClipboard = False) then
     begin

        SetCmdState(cmAssembleAssemble, Enable);
        SetCmdState(cmAssembleBuild, Enable);
        SetCmdState(cmAssembleRun, Enable);

     end
     else
     begin

        SetCmdState(cmAssembleAssemble, False);
        SetCmdState(cmAssembleBuild, False);
        SetCmdState(cmAssembleRun, False);

     end;

end;

{******}

function ASMJumpLineDlg : PHelpDialog;

var  D      : PHelpDialog;
     R      : TRect;
     Control: PView;

begin
     R.Assign(0, 0, 39, 7);
     D:= New(PHelpDialog, Init(R, 'Go to line number'));

     with D^ do
     begin
          Options:= Options or ofCentered;
          HelpCtx:= hcSearchJumpDialog;

          R.Assign(26, 2, 32, 3);
          Control:= New(PInputLine, Init(R, 4));
          Control^.HelpCtx:= hcJumpLineNumber;
          Insert(Control);

          R.Assign(3, 2, 26, 3);
          Insert(New(PLabel, Init(R, '~E~nter new line number', Control)));

          R.Assign(32, 2, 35, 3);
          Insert(New(PHistory, Init(R, PInputLine(Control), hiJumpLine)));

          R.Assign(2, 4, 12, 6);
          Control:= New(PButton, Init(R, '~O~K', cmOK, bfDefault));
          Control^.HelpCtx:= hcOk;
          Insert(Control);

          R.Assign(14, 4, 24, 6);
          Control:= New(PButton, Init(R, '~C~ancel', cmCancel, bfNormal));
          Control^.HelpCtx:= hcCancel;
          Insert(Control);

          R.Assign(26, 4, 36, 6);
	  Control:= New(PButton, Init(R, '~H~elp', cmHelp, bfNormal));
          Control^.HelpCtx:= hcSearchJumpDialog;
          Insert(Control);

          SelectNext(False);
     end;
     ASMJumpLineDlg:= D;
end;

{******}

function ASMEditorDlg(Dialog: integer; Info: Pointer): word;

var R: TRect;
    T: TPoint;

begin
     case Dialog of

    edSaveAs : ASMEditorDlg:= Application^.ExecuteDialog(New(PFileDialog,
                             Init('*.ASM', 'Save file as', '~N~ame',
                             fdOkButton + fdHelpButton, hiFileSave)), Info);

edJumpToLine : ASMEditorDlg:= Application^.ExecuteDialog(ASMJumpLineDlg, Info);

edPrintError : ASMEditorDlg:= MessageBox(#3'Error printing file %s.',
                                        @Info, mfError + mfOkButton);

edLineTooLong: ASMEditorDlg:= MessageBox(#3'Line too long.', nil,
                                         mfError + mfOKButton);

         else ASMEditorDlg:= StdEditorDialog(Dialog, Info);
    end;
end;

{******}

end.
