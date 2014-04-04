unit ISPAWN;

(* Information
   ßßßßßßßßßßß

   Program Title : NASM-IDE.
   External name : IDESPAWN.TPU
   Version       : 1.1 (SPAWNO 4.13)
   Start date    : 06/11/1997 (SPAWNO 12/12/92)
   Last update   : 20/07/1999
   Author        : Rob Anderton
   Description   : Originally SPAWNO.TPU, this is simply a renamed version
                   of Ralph Brown's SPAWNO unit. No other changes have
                   been made.

                   The original copyright message is below.
*)

{============================================================================}
{ (c) Copyright 1991 Ralf Brown    All Rights Reserved			     }
{ This file is part of the SPAWNO package and may be redistributed as a part }
{ of, and under the same terms as, that package.			     }
{============================================================================}

interface

{******}

const
      {*** symbolic constants for specifying permissible swap locations
           add/or together the desired destinations ***}

      Swap_Disk = 0;
      Swap_XMS  = 1;
      Swap_EMS  = 2;
      Swap_EXT  = 4;
      Swap_All  = $FF; {swap to any available destination}

      {*** Error codes ***}
      eNotFound   = 2;
      eNoPath     = 3;
      eAccess     = 5;
      eNoMem      = 8;
      eTooBig     = 20;
      eWriteFault = 29;

{******}

var Spawno_Error : integer ; {error code when SPAWN returns -1}

{******}

procedure Init_Spawno(Swap_Dirs  : string;
                      Swap_Types : integer;
		      Min_Res    : integer;
                      Res_Stack  : integer);

function Spawn(ProgName  : string;
               Arguments : string;
               EnvSeg    : integer) : integer;

{******}

implementation

{******}

{$L ISPAWN.OBJ}

{******}

(* min_res   = minimum number of paragraphs to keep resident
   res_stack = minimum paragraphs of stack to keep resident (0 = no change)
*)

procedure Init_Spawno(Swap_Dirs  : string;
                      Swap_Types : integer;
		      Min_Res    : integer;
                      Res_Stack  : integer); external;


function Spawn(ProgName  : string;
               Arguments : string;
               EnvSeg    : integer) : integer; external;

{******}

end.

