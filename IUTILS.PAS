unit IUTILS;

(* Information
   ßßßßßßßßßßß

   Program Title : NASM-IDE General System Components
   External name : IUTILS.TPU
   Version       : 1.3
   Start date    : 08/06/1998
   Last update   : 08/06/1999
   Author        : Rob Anderton
   Description   : General system components.

                   Incorporates most of the procedures/functions found in
                   SUTILS.PAS from the S-Library.

*)

interface

uses DOS, OBJECTS;

{*** Data types ***}

{*** TListBoxRec - used to set/get data with dialog boxes containing a
                   TListBox descendant. ***}

type PListBoxRec = ^TListBoxRec;
     TListBoxRec = record
                         pList      : PCollection;
                         wSelection : word;
                   end;

{*** Useful data types (for typecasting etc.) ***}

type PByteArray = ^TByteArray;
     TByteArray = array[0..65534] of byte;

     PCharArray = ^TCharArray;
     TCharArray = array[0..65534] of char;

     PWordArray = ^TWordArray;
     TWordArray = array[0..32766] of word;

     {*** Equivalent to a QWORD or COMP data type ***}
     PQuadRec   = ^TQuadRec;
     TQuadRec   = record
                        Lo : longint;
                        Hi : longint;
                  end;

{*** Procedures ***}

procedure RegisterAll;

function  HexToDec(sHex : string) : longint;

function  ByteToHex(bVal         : byte;
                      bLeadingZero : boolean) : string;

function  WordToHex(wVal         : word;
                    bLeadingZero : boolean) : string;

function  LongToHex(lVal         : longint;
                    bLeadingZero : boolean) : string;

function  IntToStr(lVal : longint): string;

function  StrUpper(sText : string) : string;

function  StrLower(sText : string) : string;

function  LoCase(cUpper : char) : char;

function  GetLinearAddr(pPtr : pointer) : longint;

function  NormalisePtr(pPtr : pointer) : pointer;

function  Min(lValA, lValB : longint) : longint;

function  Max(lValA, lValB : longint) : longint;

procedure Swap(var lValA, lValB : longint);

function  Power(lN, lP : longint) : longint;

function  InpLong(wReg : word) : longint;

procedure OutpLong(wReg : word; lVal : longint);

function GetLongTime : longint;

{*** File management ***}

function FileExists(sFilename : string) : boolean;
function IsDir(const sPath : string) : boolean;
function IsWild(const sPath : string) : boolean;
function GetCurDir : DirStr;
function DriveValid(cDrive : char) : boolean;
function PathValid(var sPath : PathStr) : boolean;
function ValidFileName(var sFileName : PathStr) : boolean;

{******}

implementation

uses APP, DIALOGS, MENUS, VIEWS, ICONTROL;

{******}


(* RegisterAll - registers all existing and new NASM-IDE objects for
                 stream I/O.
*)

procedure RegisterAll;

begin
     {*** Register standard Turbo Vision objects ***}
     RegisterApp;
     RegisterDialogs;
     RegisterMenus;
     RegisterViews;
     RegisterType(RCollection);

     {*** ICONTROL unit ***}
     RegisterControls;
end;

{*** Following functions formerly in SUTILS.PAS ***}

(* HexToDec - converts a string of hexadecimal characters into a decimal
              representation.

   sHex - the hexadecimal string to convert.

   Returns a longint containing the decimal value, conversion
   is stopped when a non-hexadecimal character is detected, and
   the current working value is returned.

*)

function HexToDec(sHex : string) : longint;

var NumChars : integer; {Number of characters processed}
    Value    : longint; {Temporary value of conversion}
    i        : word;    {Loop control variable}

begin
     {*** Initialise variables ***}
     NumChars:= 0;
     Value:= 0;

     {*** Only process non-empty strings ***}
     if sHex <> '' then
     begin
          {*** Skip any leading spaces ***}
          i:= 1;
          while (sHex[i] = ' ') and (i <= Length(sHex)) do Inc(i);

          {*** Process remaining characters ***}
          while i <= Length(sHex) do
          begin
               case UpCase(sHex[i]) of
                    '0'..'9' : begin
                                    {*** Convert value ***}
                                    Value:= Value * $10;
                                    Value:= Value + INTEGER(sHex[i]) -
                                                    INTEGER('0');
                                    NumChars:= Succ(NumChars);
                               end;

                    'A'..'F' : begin
                                    {*** Convert value ***}
                                    Value:= Value * $10;
                                    Value:= Value + INTEGER(UpCase(sHex[i])) -
                                                    INTEGER('A') + 10;
                                    NumChars:= Succ(NumChars);
                               end;

                          else begin
                                    {*** Stop processing when invalid
                                         character detected ***}

                                    if NumChars <> 0 then HexToDec:= Value
                                                     else HexToDec:= 0;
                                    Exit;
                               end;
               end;
               Inc(i);
          end;
          {*** Return converted value ***}
          HexToDec:= Value;
     end
     else HexToDec:= 0; {Return zero if sHex is empty}
end;

(* ByteToHex - converts a byte value into a string of hexadecimal
               characters.

   bVal         - the decimal value to convert
   bLeadingZero - if true the returned string is padded
                  with zeros to always make the string
                  have a length of 2 characters

   Returns the converted string.
*)

function ByteToHex(bVal : byte; bLeadingZero : boolean) : string;

{*** Hexadecimal characters ***}
const HexChars : array [0..$F] of char = '0123456789ABCDEF';

var HexStr : string; {Temporary string}

begin
     {*** Convert to string ***}
     HexStr:= (HexChars[bVal shr 4] + HexChars[bVal and $F]);

     {*** Remove leading zero ***}
     if not bLeadingZero then
        if HexStr[1] = '0' then
        begin
             HexStr[1]:= HexStr[2];
             HexStr[0]:= Chr(1);
        end;

     {*** Return string ***}
     ByteToHex:= HexStr;
end;

(* WordToHex - converts a word value into a string of hexadecimal
               characters.

   wVal         - the decimal value to convert
   bLeadingZero - if true the returned string is padded
                  with zeros to always make the string
                  have a length of 4 characters

   Returns the converted string.
*)

function WordToHex(wVal : word; bLeadingZero : boolean) : string;

{*** Hexadecimal characters ***}
const HexChars : array [0..$F] of char = '0123456789ABCDEF';

var HexStr : string; {Temporary string}
    i, j   : byte;   {Loop control variables}

begin
     {*** Convert to string ***}
     HexStr:= (HexChars[Hi(wVal) shr 4] + HexChars[Hi(wVal) and $F] +
               HexChars[Lo(wVal) shr 4] + HexChars[Lo(wVal) and $F]);

     {*** Remove leading zeros ***}
     if not bLeadingZero then
     begin
          i:= 1;
          {*** Find position of first non-zero character ***}
          while HexStr[i] = '0' do Inc(i);

          {*** Remove zeros if necessary ***}
          if i > 1 then
          begin
               Move(HexStr[i], HexStr[1], 5 - i);
               HexStr[0]:= Chr(5 - i);
          end;
     end;

     {*** Return string ***}
     WordToHex:= HexStr;
end;


(* LongToHex - converts a longint value into a string of hexadecimal
               characters.

   lVal         - the decimal value to convert
   bLeadingZero - if true the returned string is padded
                  with zeros to always make the string
                  have a length of 8 characters

   Returns the converted string.
*)

function LongToHex(lVal : longint; bLeadingZero : boolean) : string;

{*** Hexadecimal characters ***}
const HexChars : array [0..$F] of char = '0123456789ABCDEF';

var HexStr : string; {Temporary string}
    w1, w2 : word;   {Store high and low words of DWORD}
    i      : byte;   {Loop control variable}

begin
     {*** Get high and low words ***}
     w1:= WORD(lVal);
     w2:= WORD(lVal shr 16);

     {*** Convert to string ***}
     HexStr:= (HexChars[Hi(w2) shr 4] + HexChars[Hi(w2) and $F] +
               HexChars[Lo(w2) shr 4] + HexChars[Lo(w2) and $F]) +
              (HexChars[Hi(w1) shr 4] + HexChars[Hi(w1) and $F] +
               HexChars[Lo(w1) shr 4] + HexChars[Lo(w1) and $F]);

     {*** Remove leading zeros ***}
     if not bLeadingZero then
     begin
          i:= 1;
          {*** Find position of first non-zero character ***}
          while HexStr[i] = '0' do Inc(i);

          {*** Remove zeros if necessary ***}
          if i > 1 then
          begin
               Move(HexStr[i], HexStr[1], 9 - i);
               HexStr[0]:= Chr(9 - i);
          end;
     end;

     {*** Return string ***}
     LongToHex:= HexStr;
end;


(* IntToStr - converts a decimal value into a string. This is a functional
              wrapper for the STR procecedure.

   lVal - the number to convert to a string.

   Returns a string containing the converted value.
*)

function IntToStr(lVal : longint): string;

var S : string[11]; {Temporary string for conversion}

begin
     {*** Call standard STR procedure ***}
     Str(lVal, S);
     {*** Return string ***}
     IntToStr:= S;
end;


(* StrUpper - converts an entire string to upper case.

   sText - the string to convert.

   Returns the upper case string.
*)

function StrUpper(sText : string) : string;

var Loop : byte;    {Used to process characters in a string}
    Temp : string;  {Holds converted string}

begin
     {*** Set length ***}
     Temp[0]:= sText[0];

     {*** Convert individual characters to upper case ***}
     for Loop:= 1 to Length(sText) do Temp[Loop]:= Upcase(sText[Loop]);

     {*** Return the converted string ***}
     StrUpper:= Temp;
end;


(* StrLower - converts an entire string to lower case.

   sText - the string to be converted.

   Returns the converted string.
*)

function StrLower(sText : string) : string;

var Loop : byte;   {Used to process individual characters}
    Temp : string; {Holds the converted string}

begin
     {*** Set string length ***}
     Temp[0]:= sText[0];

     {*** Convert individual characters to lower case ***}
     for Loop:= 1 to Length(sText) do Temp[Loop]:= LoCase(sText[Loop]);

     {*** Return the converted string ***}
     StrLower:= Temp;
end;


(* LoCase - converts an alphabetical character to lower case. Does not
            alter lower case, numeric or other characters.

   cUpper - the character to process.

   Returns the converted character.
*)

function LoCase(cUpper : char) : char;

begin
     {*** If cUpper is an upper case letter then convert ***}
     if cUpper in ['A'..'Z'] then LoCase:= Chr(Ord(cUpper) + 32)
                             else LoCase:= cUpper; {Otherwise do nothing}
end;

(* GetLinearAddr - converts a segment:offset pointer into a 32 bit linear
                   address.

   pPtr - the pointer to convert.

   Returns the 32 bit linear address.

*)

function GetLinearAddr(pPtr : pointer) : longint;

begin
     {*** Convert pointer and return ***}
     GetLinearAddr:= LONGINT(Seg(pPtr^)) shl 4 + LONGINT(Ofs(pPtr^));
end;


(* NormalisePtr - normalises a pointer so that the offset address is always
                  between 0 and 15.

   pPtr - the pointer to normalise.

   Returns the normalised pointer.

*)

function NormalisePtr(pPtr : pointer) : pointer;

var LinearAddr : longint;  {Holds the 32 bit linear address of pPtr}

begin
     {*** Convert pointer to a linear address ***}
     LinearAddr:= GetLinearAddr(pPtr);

     {*** Normalise and return the pointer ***}
     NormalisePtr:= Ptr(LinearAddr div 16, LinearAddr mod 16);
end;


(* Min - compares two values and returns the lowest.
         If lValA and lValB are equal then lValB is returned.

   lValA, lValB - the two numbers to be compared.

   Returns the minimum value of the two.

*)

function Min(lValA, lValB : longint) : longint;

begin
     if lValA < lValB then Min:= lValA
                      else Min:= lValB;
end;


(* Max - compares two values and returns the highest.
         If lValA and lValB are equal then lValB is returned.

   lValA, lValB - the two numbers to be compared.

   Returns the maximum value of the two.

*)

function Max(lValA, lValB : longint) : longint;

begin
     if lValA > lValB then Max:= lValA
                      else Max:= lValB;
end;


(* Swap - swaps the values of two numbers, so that lValA becomes the value
          of lValB and lValB takes on the value of lValA.

   lValA, lValB - the two numbers to be swapped.

*)

procedure Swap(var lValA, lValB : longint);

var t : longint; {Temporary store for lValA}

begin
     t:= lValA;         {Store lValA}
     lValA:= lValB;     {Set lValA to lValB}
     lValB:= t;         {Set lValB to the original value of lValA}
end;


(* Power - raises lN to the power lP.
           For example: lN = 2, lP = 3, returns 2^3 = 8.

   lN - the number to be raised to the power.
   lP - the power.

   Returns lN ^ lP.
*)

function Power(lN, lP : longint) : longint;

begin
     {*** if lP = 0 then lN ^ lP is always 1 ***}
     if lP = 0 then Power:= 1
               {*** if lN is 0 then lN ^ lP is always 0 ***}
               else if lN = 0 then Power:= 0
                              {*** Otherwise recursively call Power ***}
                              else Power:= lN * Power(lN, (lP - 1))
end;


(* InpLong - inputs a 32 bit value from the specified register. This is
             equivalent to a single IN EAX, DX instruction and requires
             a 386 or better processor.

   wReg - the register to read from.

   Returns the value read from wReg.

   This function is taken from the VGADOC 4.0 package.

*)

function InpLong(wReg : word) : longint;

var l : longint; {Temporary register value}

begin
     inline($8B/$56/<wReg/$66/$ED/$66/$89/$46/<l);
     InpLong:= l;
end;

{******}

(* OutpLong - outputs a 32 bit value to the specified register. This is
              equivalent to a single OUT EAX, DX instruction and requires
              a 386 or better processor.

   wReg - the register to write to.
   lVal - the value to write.

   This procedure is taken from the VGADOC 4.0 package.

*)

procedure OutpLong(wReg : word; lVal : longint);

begin
     (* mov dx,  [BP + wReg]
        mov eax, [BP + lVal]
        out dx,  eax
     *)
     inline($8B/$56/<wReg/$66/$8B/$46/<lVal/$66/$EF);
end;


(* FileExists - checks a given file name, returning true if the file exists
                and false if it does not.

   sFilename - the name of the file to check.

   Returns result of check.

*)

function FileExists(sFilename : string) : boolean;

var SearchInfo : SearchRec;

begin
   {*** Find matching file if one exists ***}
   FindFirst(FExpand(sFileName), AnyFile, SearchInfo);
   FileExists:= (DosError = 0);
end;

(* IsDir - returns true if the given path is a directory, false if not.

   sPath - path to check.

*)

function IsDir(const sPath : string) : boolean;

var SearchData : SearchRec;

begin
   FindFirst(sPath, Directory, SearchData);
   if DosError = 0 then
      IsDir:= SearchData.Attr and Directory <> 0
   else
      IsDir:= false;
end;

(* IsWild - returns true if the given string contains any wild card
            characters ('*' or '?').

   sPath - string to check.

*)

function IsWild(const sPath : string) : boolean;

begin
   IsWild:= (Pos('?', sPath) > 0) or (Pos('*', sPath) > 0);
end;

(* GetCurDir - returns the current directory including trailing '\' *)

function GetCurDir : DirStr;

var CurDir : DirStr;

begin
   GetDir(0, CurDir);
   if Length(CurDir) > 3 then
   begin
      Inc(CurDir[0]);
      CurDir[Length(CurDir)]:= '\';
   end;
   GetCurDir:= CurDir;
end;

(* DriveValid - returns true if the given drive letter is valid.

   cDrive - drive letter to check.

*)

function DriveValid(cDrive : char) : boolean; assembler;

asm
   mov	 ah, $19        {Save the current drive in BL}
   int	 $21
   mov	 bl, al
   mov	 dl, cDrive	{Select the given drive}
   sub	 dl, 'A'
   mov	 ah, $0E
   int	 $21
   mov	 ah, $19	{Retrieve what DOS thinks is current}
   int	 $21
   mov	 cx, 0		{Assume false}
   cmp	 al, dl		{Is the current drive the given drive?}
   jne	 @@1
   mov	 cx, 1		{It is, so the drive is valid}
   mov	 dl, bl		{Restore the old drive}
   mov	 ah, $0E
   int	 $21

@@1:

   xchg	 ax, cx	        {Put the return value into AX}

end;

(* PathValid - returns true if the given path is valid.

   sPath - path to check.

*)

function PathValid(var sPath : PathStr) : boolean;

var ExpPath    : PathStr;
    SearchData : SearchRec;

begin
   {*** Expand to fully qualified path ***}
   ExpPath:= FExpand(sPath);
   if Length(ExpPath) <= 3 then
      {*** Validate disk drive ***}
      PathValid:= DriveValid(ExpPath[1])
   else
   begin
      {*** Validate full path ***}
      if ExpPath[Length(ExpPath)] = '\' then Dec(ExpPath[0]);
      FindFirst(ExpPath, Directory, SearchData);
      PathValid:= (DosError = 0) and (SearchData.Attr and Directory <> 0);
   end;
end;

(* ValidFileName - returns true if the given filename contains no illegal
                   characters.

   sFileName - the filename to validate.

*)

function ValidFileName(var sFileName : PathStr) : boolean;

const IllegalChars = ';,=+<>|"[] \';

var Dir  : DirStr;
    Name : NameStr;
    Ext  : ExtStr;

 {*** Contains - returns true if S1 contains any characters in S2 ***}

 function Contains(S1, S2 : string) : boolean; near; assembler;

 asm
    push  ds
    cld
    lds	  si, S1
    les	  di, S2
    mov	  dx, di
    xor	  ah, ah
    lodsb
    mov   bx, ax
    or    bx, bx
    jz    @@2
    mov	  al, es:[di]
    xchg  ax, cx

@@1:

    push  cx
    mov	  di, dx
    lodsb
    repne scasb
    pop	  cx
    je	  @@3
    dec	  bx
    jnz	  @@1

@@2:

    xor   al, al
    jmp	  @@4

@@3:

    mov   al, 1

@@4:

    pop   ds

 end;

 {******}

begin
   ValidFileName:= true;
   {*** Extract filename ***}
   FSplit(sFileName, Dir, Name, Ext);
   {*** Check for illegal characters ***}
   if not ((Dir = '') or PathValid(Dir)) or
      Contains(Name, IllegalChars) or
      Contains(Dir, IllegalChars) then ValidFileName:= false;
end;

{******}

function GetLongTime : longint;

var Hour, Min, Sec, Sec100 : word;

begin
     GetTime(Hour, Min, Sec, Sec100);
     GetLongTime:= (LONGINT(Hour) * 3600) + (LONGINT(Min) * 60) + LONGINT(Sec);
end;

{******}

end.