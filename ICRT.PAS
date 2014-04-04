unit ICRT;

(* Information
   ßßßßßßßßßßß

   Program Title : NASM-IDE.
   External name : ICRT.TPU
   Version       : 1.3
   Start date    : 03/02/1998
   Last update   : 08/06/1999
   Author        : Rob Anderton
   Description   : KeyPressed and ReadKey functions replacing standard CRT
                   functions and removing need for CRT unit.
*)

interface

{******}

function KeyPressed : boolean;
function ReadKey : char;

{******}

implementation

{******}

function KeyPressed : boolean; assembler;

asm
   mov  ah, $0B
   int  $21
end;

{******}

function ReadKey : char; assembler;

asm
   mov  ah, $07
   int  $21
end;

{******}

end.