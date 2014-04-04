program NASMIDE;

(* Information
   ßßßßßßßßßßß

   Program Title : NASM-IDE
   External name : NASMIDE.EXE
   Version       : 1.6
   Start date    : 31/03/1997
   Last update   : 13/01/2002
   Author        : Rob Anderton
   Description   : Main EXE file for the NetWide Assembler IDE.

*)

{$F+,A+,G-,R-,S+,I+,Q-,V-,B-,X+,P+}
{$M 16384, 0, 200000}

{******}

uses IMAIN, IEXIT, ICONST;

begin
    if (ParamCount = 1) and (ParamStr(1) = '/?') then
    begin
         writeln;
         writeln('NASM-IDE version ' + IDEVersion + ' (c) 1997-2002 Rob Anderton');
         writeln('The NetWide Assembler Integrated Development Environment');
         writeln;
         writeln('Usage: NASMIDE [filenames...]');
         writeln('       where filenames are source code files that you wish to open');
         writeln;
         Halt(0);
    end;

    {*** Main program ***}
    Main.Init;
    Main.Run;
    Main.Done;
end.