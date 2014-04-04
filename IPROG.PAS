unit IPROG;

(* Information
   ßßßßßßßßßßß

   Program Title : Progress boxes.
   External name : IPROG.TPU
   Version       : 1.3
   Start date    : 14/12/1995
   Last update   : 08/06/1999
   Author        : Rob Anderton
   Description   : Various progress boxes used in NASM-IDE.

*)

{$O+,F+}

interface

uses Dialogs, App, Objects, Views, Drivers, IHELP;

const pbOk   = 0;
      pbDone = 1;

type
    PPrintFileBox = ^TPrintFileBox;

    TPrintFileBox = object(THelpDialog)
                        Progress    : longint;
                        Total       : longint;
                        Pctg        : longInt;
                        Status      : word;
                        Blocks      : string;

                        constructor Init(ATitle : string; T : Longint);
                        function    UpDate(P : LongInt) : word;
                        procedure   HitAnyKey;
                        procedure   Draw; virtual;
                   end;

implementation

constructor TPrintFileBox.Init;

var R    : TRect;
    P    : PStaticText;
    Temp : string;

begin
     R.Assign(20, 3, 62, 10);
     inherited Init(R, ATitle);
     Options:= Options or ofCentered;
     Flags:= Flags and not wfClose;

     R.A.X:= 11;
     R.A.Y:= 2;
     R.B.X:= 31;
     R.B.Y:= 3;

     Temp:= '0   % Complete   100';
     P:= New(PStaticText, Init(R, Temp));
     Insert(P);

     Total:= T;
     Update(0);

     Desktop^.Insert(@Self);
     inherited Draw;
end;

{******}

function TPrintFileBox.Update(P : LongInt) : word;

var Event: TEvent;
    Ch   : char;
    L    : byte;

begin
     Progress:= P;
     PCtg:= (Progress * 100) div Total;

     case Pctg of

          0..5  : Blocks:= #254;
          6..10 : for L:= 1 to 2 do Blocks[L]:= #254;
         11..15 : for L:= 1 to 3 do Blocks[L]:= #254;
         16..20 : for L:= 1 to 4 do Blocks[L]:= #254;
         21..25 : for L:= 1 to 5 do Blocks[L]:= #254;
         26..30 : for L:= 1 to 6 do Blocks[L]:= #254;
         31..35 : for L:= 1 to 7 do Blocks[L]:= #254;
         36..40 : for L:= 1 to 8 do Blocks[L]:= #254;
         41..45 : for L:= 1 to 9 do Blocks[L]:= #254;
         46..50 : for L:= 1 to 10 do Blocks[L]:= #254;
         51..55 : for L:= 1 to 11 do Blocks[L]:= #254;
         56..60 : for L:= 1 to 12 do Blocks[L]:= #254;
         61..65 : for L:= 1 to 13 do Blocks[L]:= #254;
         66..70 : for L:= 1 to 14 do Blocks[L]:= #254;
         71..75 : for L:= 1 to 15 do Blocks[L]:= #254;
         76..80 : for L:= 1 to 16 do Blocks[L]:= #254;
         81..85 : for L:= 1 to 17 do Blocks[L]:= #254;
         86..90 : for L:= 1 to 18 do Blocks[L]:= #254;
         91..95 : for L:= 1 to 19 do Blocks[L]:= #254;
         96..100: for L:= 1 to 20 do Blocks[L]:= #254;
     else Blocks:= '';
     end;

     Blocks[0]:= chr(L);

     if Progress = Total then Status:= pbDone
                         else Status:= pbOk;
     DrawView;

     If Status = pbDone then HitAnyKey;
     Update:= Status;
end;

{******}

procedure TPrintFileBox.HitAnyKey;

var Event : TEvent;

begin
   If (Status=pbDone) then
      repeat
            Application^.GetEvent(Event)
      until (Event.What <> evNothing);
end;

{******}

procedure TPrintFileBox.Draw;

var Buf      : TDrawBuffer;
    R        : TRect;
    BlockBuf : TDrawBuffer;

begin
     GetExtent(R);
     R.Grow(-1,-1);
     R.A.Y:= R.B.Y - 1;
     Dec(R.B.X);

     If Status = pbDone
       then MoveCStr(Buf, '  Printing completed  : ~Press Any Key~     ', $9F1F)
       else MoveStr (Buf, '            Please wait....                 ', $1F);

     WriteLine(R.A.X, R.A.Y, R.B.X, 1, Buf);

     MoveStr(BlockBuf, Blocks, $71);
     WriteLine(11, 3, Length(Blocks), 1, BlockBuf);
end;

{******}

end.
