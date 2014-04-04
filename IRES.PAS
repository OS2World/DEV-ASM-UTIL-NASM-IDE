unit IRES;

(* Information
   ßßßßßßßßßßß

   Program Title : Resource Manager
   External name : IRES.TPU
   Version       : 1.3
   Start update  : 31/03/1997
   Last update   : 08/06/1999
   Author        : Rob Anderton
   Description   : Unit to initialise resource stream.
                   Bug fixed April '98
*)

{$O+,F+}

interface

uses Objects, DOS;

var ResFile : TResourceFile;
    Stream  : PBufStream;

procedure ResRegister;

{******}

implementation

uses App, Menus, Views, MsgBox, Dialogs, IEDIT, ICONTROL, Drivers;

{*** Internal function ***}

function StrFn(Num : longint) : string;

var S : string;

begin
     Str(Num, S);
     StrFn:= S;
end;

{*** Stream Error Handler ***}

procedure SError(var S : TStream); far;

var w   : word;
    Msg : string;

begin
     case S.Status of
          stError      : Msg:= 'Error accessing file.';
          stInitError  : Msg:= 'Unable to initialise file.';
          stReadError,
          stGetError   : Msg:= 'Error reading from file.';
          stWriteError,
          stGetError   : Msg:= 'Error writing to file.';
     else                Msg:= 'Unknown file access error';
     end;

     if StatusLine = nil then
     begin
          ClearScreen;
          writeln(Msg);
          halt(1);
     end;

     w:= MessageBox(Chr(3) + Msg, nil, mfError+mfOKButton);
     S.Reset;
end;

{******}

procedure ResRegister;

begin
     RegisterMenus;
     RegisterViews;
     RegisterDialogs;
     RegisterEditors;
     RegisterType(RStringList);
     RegisterType(RHintLine);
end;

{******}

var Temp : string;
    D    : DirStr;
    N    : NameStr;
    E    : ExtStr;

begin
     StreamError:= @SError;
     Temp:= FExpand(ParamStr(0));
     FSplit(Temp, D, N, E);
     Stream:= New(PBufStream, Init(D + 'NASMIDE.RES', stOpenRead, 1024));
     ResFile.Init(Stream);
end.