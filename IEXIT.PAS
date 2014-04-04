unit IEXIT;

(* Information
   ßßßßßßßßßßß

   Program Title : NASM-IDE exit procedure.
   External name : IEXIT.TPU
   Version       : 1.7
   Start date    : 31/03/1997
   Last update   : 18/05/2002
   Author        : Rob Anderton.
   Description   : Exit procedure (in case of runtime error).

*)

interface

{******}

var OldExit : pointer;

{******}

procedure ExitIDE; far;

{******}

implementation

{******}

uses APP, ICONST, ICRT;

{******}

procedure ExitIDE;

begin
     ExitProc:= OldExit;

     if (ExitCode <> 0) and (ErrorAddr <> nil) then
     begin
          if (Application <> nil) then Application^.Done;
          writeln;
          writeln('NASM-IDE version ' + IDEVersion + '.');
          write(#4' Critical error code ');
          writeln(ExitCode);
          writeln(#4' If the error occurs frequently please email rob@inglenook.co.uk');
          writeln(#4' Please quote the critical error code.');
          writeln;
          writeln('Press any key to exit...');
          ICRT.ReadKey;
          ExitCode:= 0;
          ErrorAddr:= nil;
     end;
end;

{******}

begin
     OldExit:= ExitProc;
     ExitProc:= @ExitIDE;
end.