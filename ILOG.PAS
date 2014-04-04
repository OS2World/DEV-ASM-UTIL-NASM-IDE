unit ILOG;

(* Information
   ßßßßßßßßßßß

   Program Title : NASM-IDE
   External name : ILOG.TPU
   Version       : 1.6
   Start date    : 24/04/1997
   Last update   : 13/01/2002
   Author        : Rob Anderton
   Description   : Unit containing TErrorViewer, a TWindow descendant used to
                   view the NASM.LOG after assembly.

*)

interface

uses OBJECTS, VIEWS, DRIVERS, MSGBOX, APP, IUTILS, IEDIT;

{******}

{*** Custom error message scroller object ***}

type PErrorCollection = ^TErrorCollection;
     TErrorCollection = object(TCollection)
                              procedure FreeItem(Item : pointer); virtual;
                              function  GetItem(var S : TStream) : pointer; virtual;
                              procedure PutItem(var S : TStream; Item : pointer); virtual;
                        end;

type PErrorScroller = ^TErrorScroller;
     TErrorScroller = object(TScroller)

                             ErrorList : PErrorCollection;
                             Highlight : longint;

                             constructor Init(var Bounds      : TRect;
                                                  AHScrollBar : PScrollBar;
                                                  AVScrollBar : PScrollBar);

                             destructor  Done; virtual;

                             procedure   Draw; virtual;

                             function    GetAttributes(L : longint) : byte; virtual;

                             procedure   GetBuffer(    L : longint;
                                                   var T : TDrawBuffer); virtual;

                             function    GetText(L : longint) : string; virtual;

                             procedure   GotoSource(L : longint); virtual;

                             procedure   HandleEvent(var Event : TEvent); virtual;

                             procedure   NewList(AList : PErrorCollection); virtual;

                             procedure   SetCmdState(Command : Word; Enable : Boolean);

                             procedure   SetState(AState: Word; Enable: Boolean); virtual;

                      end;

     {*** TWindow descendant used to hold error scroller ***}
     PErrorViewer = ^TErrorViewer;
     TErrorViewer = object(TWindow)
                           Errors : PErrorScroller;

                           constructor Init(var Bounds   : TRect;
                                                FileName : FNameStr);

                           destructor  Done; virtual;

                           procedure   Close; virtual;

                           function    GetPalette : PPalette; virtual;

                           procedure   HandleEvent(var Event : TEvent); virtual;

                           procedure   SizeLimits(var Min, Max: TPoint); virtual;

                    end;

{******}

const MaxNumberOfErrors = 100; {Holds the number of error lines before
                                the error log is trucated}

{******}

implementation

uses ICONST;

{*** Error message scroller ***}

procedure TErrorCollection.FreeItem(Item : pointer);

begin
     DisposeStr(PString(Item));
end;

{******}

function TErrorCollection.GetItem(var S : TStream) : pointer;

begin
     Abstract;
end;

{******}

procedure TErrorCollection.PutItem(var S : TStream; Item : pointer);

begin
     Abstract;
end;

{******}

constructor TErrorScroller.Init(var Bounds      : TRect;
                                    AHScrollBar : PScrollBar;
                                    AVScrollBar : PScrollBar);

begin
     inherited Init(Bounds, AHScrollBar, AVScrollBar);

     if AHScrollBar <> nil then with AHScrollBar^ do
     begin
          Options:= Options and not ofPreProcess;
          Options:= Options or ofPostProcess;
     end;

     if AVScrollBar <> nil then with AVScrollBar^ do
     begin
          Options:= Options and not ofPreProcess;
          Options:= Options or ofPostProcess;
     end;

     Highlight:= -1;
     ErrorList:= nil;
end;

{******}

destructor TErrorScroller.Done;

begin
     NewList(nil);
     inherited Done;
end;

{******}

procedure TErrorScroller.Draw;

var Buffer : TDrawBuffer;
    Y      : integer;

begin
     for Y:= 0 to Size.Y - 1 do
     begin
          GetBuffer(Y + Delta.Y, Buffer);
          WriteBuf(0, Y, Size.X, 1, Buffer);
     end;
end;

{******}

function TErrorScroller.GetAttributes(L : longint) : byte;

begin
     if (L <> Highlight) then GetAttributes:= $30
                         else GetAttributes:= $5F;
end;

{******}

procedure TErrorScroller.GetBuffer(    L : longint;
                                   var T : TDrawBuffer);

var S : string;
    I : word;

begin
     S:= GetText(L);
     System.Delete(S, 1, Delta.X);

     while Length(S) < Size.X do S:= S + ' ';
     while Length(S) > Size.X do Delete(S, Length(S), 1);

     MoveStr(T, S, GetAttributes(L));
end;

{******}

function TErrorScroller.GetText(L : longint) : string;

begin
     if (ErrorList = nil) or (L >= ErrorList^.Count) then
          GetText:= ''
     else
          GetText:= STRING(ErrorList^.At(L)^);
end;

{******}

procedure TErrorScroller.GotoSource(L : longint);

var S       : string;
    SrcName : string;
    LineStr : string;
    LineNum : longint;
    NamePtr : PString;
    Colon   : byte;
    ValCode : integer;
    R       : TRect;
    W       : PASMEditWindow;

begin
     S:= GetText(L);

     SrcName:= Copy(S, 1, 3);
     Delete(S, 1, 3);
     Colon:= Pos(':', S);
     SrcName:= SrcName + Copy(S, 1, Colon - 1);
     Delete(S, 1, Colon);

     Colon:= Pos(':', S);
     LineStr:= Copy(S, 1, Colon - 1);
     Val(LineStr, LineNum, ValCode);

     if ValCode = 0 then
     begin
          NamePtr:= NewStr(SrcName);
          W:= PASMEditWindow(Message(Application, evBroadcast,
                                     cmHighlightError, NamePtr));
          DisposeStr(NamePtr);

          if (W = nil) then
          begin
               Desktop^.GetExtent(R);
               R.Grow(-4, -4);
               W:= New(PASMEditWindow, Init(R, SrcName, wnNoNumber));
               W^.Editor^.CanUndo:= true;
               W^.Editor^.AutoIndent:= true;
               W^.Options:= W^.Options or ofTileable;
               Application^.InsertWindow(W);
          end;

          if W <> nil then
          begin
               W^.Select;
               PASMEditor(W^.Editor)^.DirectJump(LineNum);
          end;
     end;
end;

{******}

procedure TErrorScroller.HandleEvent(var Event : TEvent);

var OH       : longint;
    MouseLoc : TPoint;

begin
     OH:= Highlight;

     if (Event.What and evKeyDown) <> 0 then
     begin
          case Event.KeyCode of

               kbUp       : Dec(Highlight);
               kbDown     : Inc(Highlight);
               kbPgUp     : Dec(Highlight, Size.Y - 1);
               kbPgDn     : Inc(Highlight, Size.Y - 1);
               kbCtrlPgUp : Highlight:= 0;
               kbCtrlPgDn : Highlight:= Limit.Y - 1;
               kbEnter    : GotoSource(Highlight);
          end;

          if Highlight < 0 then Highlight:= 0;
          if Highlight > Limit.Y then Highlight:= Limit.Y - 1;

          if OH <> Highlight then
          begin
               if (Highlight >= Delta.Y) and (Highlight < Delta.Y + Size.Y) then
                   ClearEvent(Event)
               else
               begin
                    if Highlight < Delta.Y then ScrollTo(Delta.X, Highlight)
                                           else ScrollTo(Delta.X, (Highlight - Size.Y) + 1);
                    ClearEvent(Event);
               end;
          end;
     end
     else
       if (Event.What and evMouseDown) <> 0 then
       begin
            if (State and sfSelected) = 0 then Select;
            MakeLocal(Event.Where, MouseLoc);
            Highlight:= MouseLoc.Y + Delta.Y;

            if Event.Double then GotoSource(Highlight);

            ClearEvent(Event);
       end;

     if Event.What = evNothing then DrawView
                               else inherited HandleEvent(Event);

     OH:= Highlight;
     if Highlight < Delta.Y then Highlight:= Delta.Y;
     if Highlight >= Delta.Y + Size.Y then Highlight:= Delta.Y + Size.Y - 1;
     if OH <> Highlight then DrawView;
end;

{******}

procedure TErrorScroller.NewList(AList : PErrorCollection);

begin
     if ErrorList <> nil then ErrorList^.FreeAll;
     ErrorList:= nil;

     if AList <> nil then
     begin
          ErrorList:= AList;
          SetLimit(255, AList^.Count);
          DrawView;
     end;
end;

{******}

constructor TErrorViewer.Init(var Bounds   : TRect;
                                  FileName : FNameStr);

var H, V      : PScrollBar;
    R, S      : TRect;
    TempList  : PErrorCollection;
    ErrorStr  : string;
    InChar    : char;
    LogFile   : TDosStream;
    LogSize   : longint;
    NumErrors : longint;

begin
     inherited Init(Bounds, 'Error information', wnNoNumber);
     Options:= Options or ofTileable;
     HelpCtx:= hcWindowErrorInfo;

     GetExtent(R);
     R.Grow(-1, -1);
     S.Assign(R.A.X, R.B.Y, R.B.X, R.B.Y + 1);
     H:= New(PScrollBar, Init(S));

     S.Assign(R.B.X, R.A.Y, R.B.X + 1, R.B.Y);
     V:= New(PScrollBar, Init(S));

     Errors:= New(PErrorScroller, Init(R, H, V));
     Errors^.GrowMode:= gfGrowHiX or gfGrowHiY;

     TempList:= New(PErrorCollection, Init(1, 1));

     if FileExists(FileName) then
     begin
          LogFile.Init(FileName, stOpenRead);
          LogSize:= LogFile.GetSize;
          NumErrors:= 0;

          if LogSize = 0 then
               TempList^.Insert(NewStr('No errors occurred.'))
          else
              while (LogFile.GetPos < LogSize) and
                    (NumErrors <= MaxNumberOfErrors) do
              begin
                   ErrorStr:= '';
                   LogFile.Read(InChar, SizeOf(InChar));
                   while (InChar <> #13) and (InChar <> #10) do
                   begin
                        ErrorStr:= ErrorStr + InChar;
                        LogFile.Read(InChar, SizeOf(InChar));
                   end;
                   if ErrorStr <> '' then
                   begin
                        TempList^.Insert(NewStr(ErrorStr));
                        Inc(NumErrors);
                   end;
              end;

          LogFile.Done;

          if (NumErrors = MaxNumberOfErrors) then
             MessageBox(#3'Error information trucated after ' +
                        IntToStr(NumErrors) + ' errors.', nil,
                        mfOKButton + mfInformation);
     end;

     Errors^.NewList(TempList);
     Insert(H);
     Insert(V);
     Insert(Errors);
     Errors^.SetLimit(255, 300);
     Inc(NumberOfWindows)
end;

{******}

destructor TErrorViewer.Done;

begin
     if Assigned(Errors) then Dispose(Errors, Done);
     inherited Done;
     Dec(NumberOfWindows)
end;

{******}

procedure TErrorViewer.Close;

begin
     Message(Application, evBroadcast, cmCloseErrorInfo, nil);
     inherited Close;
end;

{******}

function TErrorViewer.GetPalette : PPalette;

const P : string[Length(CCyanWindow)] = CCyanWindow;

begin
     GetPalette:= @P;
end;

{******}

procedure TErrorViewer.HandleEvent(var Event : TEvent);

begin
     inherited HandleEvent(Event);

     if (Event.What = evBroadcast) then
        case (Event.Command) of

             cmCloseAll : Close;

        end;
end;

{******}

procedure TErrorScroller.SetCmdState(Command : word; Enable : boolean);

var S : TCommandSet;

begin

     S:= [Command];

     if Enable and (State and sfActive <> 0) then EnableCommands(S)
                                             else DisableCommands(S);
end;

{******}

procedure TErrorScroller.SetState(AState: Word; Enable: Boolean);

begin

     inherited SetState(AState, Enable);

     SetCmdState(cmEditUndo, False);
     SetCmdState(cmEditCut, False);
     SetCmdState(cmEditCopy, False);
     SetCmdState(cmEditPaste, False);
     SetCmdState(cmJumpLine, False);
     SetCmdState(cmAssembleAssemble, False);
     SetCmdState(cmAssembleRun, False);
     SetCmdState(cmAssembleBuild, False);

end;

{******}

procedure TErrorViewer.SizeLimits(var Min, Max: TPoint);

begin
     inherited SizeLimits(Min, Max);
     Min.X:= 30;
     Min.Y:= 6;
end;

{******}

end.


