unit SINI;

(* Information
   ßßßßßßßßßßß

   Program Title : INI file routines.
   External name : SINI.TPU
   Version       : 1.0
   Start date    : 12/9/97
   Last update   : 12/9/97
   Author        : Rob Anderton.
   Description   : Routines to handle INI files in a similar way to Windows.

   This unit is a slightly modified version of INIF.PAS. The modifications
   made are mainly visual, allowing the unit to fit in with other S Library
   units. The following text is taken from the original unit. Thanks go
   to the original author for making the code free for use.

   ---------------------------------------------------------------------
    (c) 1994 by Kim Greve.
    This is given to the public domain, so if you want to make changes
    feel free to do it, my only demand/request is that you don't remove
    my name.

    If you have any questions, suggestions or have found any bugs,
    please contact me.

    DISCLAIMER:
    This source is given as is, you can not hold me responsibly for any
    errors in the source (if any <g>).

   +-------------------------------+-----------------------------------+
   + Last changed: December, 27-1994
   +
   +-------------------------------+-----------------------------------+
   + Kim Greve                     + Internet:
   +
   + Krebsens kvt 9F               + 1. kim.greve@dkb.dk
   +
   + 2620 Albertslund.             +
   +
   + Denmark.                      + 2. kimgreve@inet.uni-c.dk
   +
   +-------------------------------+-----------------------------------+

*)

interface

{******}

uses DOS;

{*** Global variables ***}

const INI_LoadComments : boolean = true;  {true if comments are to be loaded}
      INI_FlushOnExit  : boolean = true;  {flush collection when terminating}
      INI_ReadError    : boolean = false; {true if a read error occurred}
      INI_WriteError   : boolean = false; {true if an write error occurred}

{*** Functions and procedures ***}

function  INI_GetProfileString(sAppName    : PathStr;
                               sSection    : string;
                               sEntryName  : string;
                           var sEntryValue : string;
                               sDefault    : string) : integer;

function  INI_GetProfileInt(    sAppName    : PathStr;
                                sSection    : string;
                                sEntryName  : string;
                            var iEntryValue : integer;
                                iDefault    : integer) : integer;

function INI_WriteProfileString(sAppName    : PathStr;
                                sSection    : string;
                                sEntryName  : string;
                                sEntryValue : string) : integer;

function INI_WriteProfileInt(sAppName    : PathStr;
                             sSection    : string;
                             sEntryName  : string;
                             iEntryValue : integer): integer;

procedure INI_DisposeData;

{******}

implementation

{******}

uses OBJECTS, IUTILS;

{*** Unit constants ***}

const CommentChar : char = ';'; {Character leading a comment line}

{*** Unit global variables ***}

var INI_Name        : PathStr;           {Filename for INI file}
    BAK_Name        : PathStr;           {Filename for backup file}
    TMP_Name        : PathStr;           {Filename for temporary file}

    OldExitProc     : pointer;           {Pointer to the original exit
                                          procedure}

    INI_Data        : PStringCollection; {INI file data stored in memory}

    SectionStartIDX : integer;           {Start of section in collection}
    SectionEndIDX   : integer;           {End of section in collection}

{******}

(* INI_ReadLine - reads a line from the specified file.

                  hFile - file to read from

                  Returns a string containing line read from hFile.
*)

function INI_ReadLine(var hFile : Text) : string;

var Ch   : char;   {Character read in from file}
    Line : string; {String of characters from file}

begin
     {*** Initialise variables ***}
     Line:= '';
     Ch:= #13;

     {*** Read in until end of line or end of file ***}
     while (Ch <> #10) and (not Eof(hFile)) do
     begin
          {*** Add next character to string ***}
          if (Ch <> #13) then Line:= Line + Ch;
          {*** Read next character from file ***}
          Read(hFile, Ch);
     end;

     {*** Add Ch to Line if last entry is not folowed by CR/LF ***}
     if (Eof(hFile)) and ((Ch <> #10) and (Ch <> #13)) then Line:= Line + Ch;

     {*** Return string ***}
     INI_ReadLine:= Line;
end;


(* INI_ReadFile - reads the entire INI file into a collection, updates
                  global variables as necessary.
*)

procedure INI_ReadFile;

var hFile : Text;    {INI file pointer}
    Line  : string;  {Temporary store of current line from INI file}

begin
     {*** Ensure memory is released before new read is allowed ***}
     INI_DisposeData;

     {*** Create a new string collection ***}
     INI_Data:= New(PStringCollection, Init(1, 1));
     {*** Exit if creation unsuccessful ***}
     if INI_Data = nil then Exit;

     INI_Data^.Duplicates:= True;  {duplicates allowed in collection}

     {*** Check INI file exists ***}
     if not FileExists(INI_Name) then Exit;
     {$I-}
     Assign(hFile, INI_Name);
     Reset(hFile);

     INI_ReadError:= True = (IOResult <> 0); {check for error}

     if not INI_ReadError then
     begin
          {*** Add lines to collection ***}
          while (not Eof(hFile)) and not INI_ReadError do
          begin
               Line:= INI_ReadLine(hFile);

               {*** Don't add blank lines to save memory ***}
               case INI_LoadComments of

                    True  : if (Line <> '') then
                               INI_Data^.AtInsert(INI_Data^.Count, NewStr(Line));

                    False : if (Line <> '') and (Line[1] <> ';') then
                               INI_Data^.AtInsert(INI_Data^.Count, NewStr(Line));
               end;
          end;
     end;
     {$I+}

     {*** Close INI file ***}
     Close(hFile);
end;

(* INI_SaveFile - writess the entire buffer to the INI file, updates
                  global variables as necessary.
*)

function INI_SaveFile : boolean;

var i        : integer; {Loop control variable}
    INI_File : text;    {original INI file}
    TMP_File : text;    {temporary file}
    IOError  : boolean; {true if I/O error occurs}
    Line     : string;  {holds line of data}

begin
     {$I-}
     {*** Associate files ***}
     Assign(INI_File, INI_Name);
     Assign(TMP_File, TMP_Name);

     {*** Create temporary file ***}
     Rewrite(TMP_File);

     {*** Write buffer to file ***}
     for i:= 0 to INI_Data^.Count - 1 do
     begin
          Line:= PString(INI_Data^.At(i))^;

          {*** if next line is a new section then make a linefeed ***}
          if (Line[1] = '[') and (i > 0) then WriteLn(TMP_File);
          WriteLn(TMP_File, Line);
          INI_WriteError:= true = (IOResult <> 0);
     end;
     {*** Close file ***}
     Close(TMP_File);
     IOError:= (IOResult <> 0);

     {*** Erase the INI file ***}
     if FileExists(INI_Name) and not IOError then
     begin
          Erase(INI_File);
          IOError:= (IOResult <> 0);
     end;

     {*** Rename TMP file to .INI ***}
     if FileExists(TMP_Name) and not IOError then
     begin
          Rename(TMP_File, INI_Name);
          IOError:= (IOResult <> 0);
     end;
     {$I+}

     {*** Return value ***}
     if (INI_WriteError) or (IOError) then INI_SaveFile:= false
                                      else INI_SaveFile:= true;
end;

(* INI_FindSection - searches collection for specified section. Returns
                     true if the section is found. Updates the
                     SectionStartIDX and SectionEndIDX variables as
                     necessary.

                     sSection - section name to search for

*)

function INI_FindSection(sSection : string) : boolean;

var Line        : string;  {Holds current line}
    StartFound  : boolean; {True when start of section found}
    EndFound    : boolean; {True when end of section found}
    RetVal      : boolean; {Holds function return value}

begin
     {*** Initialise variables ***}
     RetVal:= false;
     StartFound:= false;
     EndFound:= false;
     sSection:= StrUpper('[' + sSection + ']');

     {*** Find start of section ***}
     SectionStartIDX:= 0;

     while (not StartFound) and (INI_Data^.Count > 0) and
           (SectionStartIDX < INI_Data^.Count) do
     begin
          {*** Get line from data ***}
          Line:= PString(INI_Data^.At(SectionStartIDX))^;
          {*** Check if it is a section heading ***}
          if Line[1] = '[' then
          begin
               {*** Convert to upper case ***}
               Line:= StrUpper(Line);
               {*** Set length of line (ignoring all after closing bracket) ***}
               Line[0]:= Chr(Pos(']', Line));
               {*** Compare with required section heading ***}
               if Line = sSection then StartFound:= true;
          end;

          {*** Update variables if necessary ***}
          if (not StartFound) and (SectionStartIDX < INI_Data^.Count) then
             Inc(SectionStartIDX);
     end;

     {*** Find end of section if start of section is found ***}
     SectionEndIDX:= SectionStartIDX;

     if StartFound then
     begin
          while (not EndFound) and (SectionEndIDX < INI_Data^.Count - 1) do
          begin
               {*** Update variables ***}
               if SectionEndIDX < INI_Data^.Count - 1 then
                  Inc(SectionEndIDX);

               {*** Get line from collection ***}
               Line:= PString(INI_Data^.At(SectionEndIDX))^;

               {*** Check if it is a section heading ***}
               if Line[1] = '[' then EndFound:= true;
          end;
     end;

     if StartFound then RetVal:= true;

     {*** Return result ***}
     INI_FindSection:= RetVal;
end;

(* INI_SplitEntry - processes an INI file entry returning the value of
                    the entry and the name of the entry.

                    sEntry - the entry string to be processed
                    sValue - the value of the entry

                    Return - the entry name

*)

function INI_SplitEntry(    sEntry : string;
                        var sValue : string) : string;

var EntryName : string; {Stores the name of the entry}

begin
     {*** Don't process comments ***}
     if sEntry[1] <> CommentChar then
     begin
          {*** Get entry name and value ***}
          EntryName:= Copy(sEntry, 1, Pos('=', sEntry) - 1);
          sValue:= Copy(sEntry, Pos('=', sEntry) + 1, Length(sEntry));
     end
     else EntryName:= CommentChar; {Return comment character}

     {*** Return entry name string ***}
     INI_SplitEntry:= EntryName;
end;

(* INI_FindEntry - search the specified section for the specified entry.
                   Return the entry value and it's index in the collection.

                   sSection    - name of the section to search
                   sEntryName  - string containing entry name to search for
                   sEntryValue - returned value of entry

                   Function returns index of entry if found, or -1 if the
                   entry doesn't exist, or -2 if the section doesn't exists.

*)

function INI_FindEntry(    sSection    : string;
                           sEntryName  : string;
                       var sEntryValue : string) : integer;

var Ch             : char;
    S              : string;
    Line           : string;  {Holds line from collection}
    TempLine       : string;  {Temporary variables for processing}
    TempEntryValue : string;
    SectionIndex   : integer; {Index of section start}
    EntryFound     : boolean; {Indicates if entry is found}
    RetVal         : integer; {Holds function return code}

begin
     RetVal:= -1; {assume that the required entry doesn't exist}

     {*** Look for specified section ***}
     if INI_FindSection(sSection) then
     begin
          {*** Update variables ***}
          EntryFound:= false;
          SectionIndex:= SectionStartIDX;
          sEntryName:= StrUpper(sEntryName);

          {*** Search for entry ***}
          while (not EntryFound) and (SectionIndex <= SectionEndIDX) do
          begin
               {*** Get line from collection ***}
               Line:= PString(INI_Data^.At(SectionIndex))^;
               {*** Work on a copy of original line ***}
               TempLine:= StrUpper(Line);

               {*** Check if entry found ***}
               if INI_SplitEntry(TempLine, TempEntryValue) = sEntryName then
               begin
                    {*** Return sEntryValue without conversion to
                         upper case ***}
                    INI_SplitEntry(Line, sEntryValue);
                    EntryFound:= true;
               end;

               {*** Move on to next line ***}
               if not EntryFound then Inc(SectionIndex);
          end;

          {*** if found then update return code ***}
          if EntryFound then RetVal:= SectionIndex;
     end
     else RetVal:= -2;  {Return -2 to tell caller that section doesn't exist}

     {*** Return value ***}
     INI_FindEntry:= RetVal;
end;

(* INI_SetFileName - sets up filename strings for the INI file, the backup
                     file and the temporary file.

                     sFileName - base name of INI file

*)

procedure INI_SetFileName(sFileName : PathStr);

var D : DirStr;  {Holds directory name}
    N : NameStr; {Holds file name}
    E : ExtStr;  {Holds file extension}

begin
     {*** Convert to upper case ***}
     sFileName:= StrUpper(sFileName);

     {*** Split name into seperate parts ***}
     FSplit(sFileName, D, N, E);

     {*** Update variables ***}
     INI_Name:= D + N + '.INI';
     TMP_Name:= D + N + '.TMP';
end;

(* INI_GetProfileString - the following description is taken from the original
                          INIF unit.

   ---------------------------------------------------------------------

   The GetProfileString function retrieves a character string from a
   specified [Section] and a specified entry name in the. INI file
   specified in sAppName.

   parameter   | description
   ------------+---------------------------------------------------------
   sAppName    | The name of the .INI file.
               | You do not need to type .INI after the path:\filename.
               |
   sSection    | The [Section] where you want to search for the entry name
               | (don't put [ ] around the section name).
               |
   sEntryName  | String containing the entry whose associated string is
               | to be retrieved. For more see the following Comment
               | section.
               |
   sEntryValue | The returned string for the actual sEntryName.
               |
   sDefault    | String that specifies the default value (string) for the
               | given entry if the entry cannot be found in the INI file.
   ---------------------------------------------------------------------
   Returns:
           GetProfileString returns the length of retrieved string
           (sEntryValue).

   Comment:
           The function searches the file for an entry that matches
           the name specified by the 'sEntryName' parameter under
           the section heading specified by the 'sSection' parameter.
           If the entry is found, 'sEntryValue' is altered to the string
           in 'sEntryName'. If the entry does not exist, the default value
           specified by the 'sDefault' parameter is used instead.

           A string entry must have the following form:

           [Section]
           EntryName=EntryValue
           .
           .

           The Section, EntryName and EntryValue are not case-dependent.
           With every compare all the strings are in uppercase.

*)

function INI_GetProfileString(sAppName    : PathStr;
                              sSection    : string;
                              sEntryName  : string;
                          var sEntryValue : string;
                              sDefault    : string) : integer;

var D  : DirStr;  {Stores directory}
    N  : NameStr; {Stores name}
    E  : ExtStr;  {Stores extension}
    ON : NameStr; {Stores old INI file name (from last call to the function)}
    NN : NameStr; {Stores new INI file name (from this call to the function)}

begin
     {*** Split the old file name (the file currently in memory) ***}
     FSplit(INI_Name, D, N, E);
     ON:= StrUpper(N);

     {*** Split the new file to be used ***}
     FSplit(sAppName, D, N, E);
     NN:= StrUpper(N);

     {*** Ensure that INI_Data = nil, if OldName <> NewName (i.e. another
          INI file is to be used) ***}

     if ON <> NN then INI_DisposeData;

     {*** Set new file name ***}
     INI_SetFileName(sAppName);

     {*** Set default return value ***}
     sEntryValue:= sDefault;

     {*** If file is not buffered then load it into memory ***}
     if (INI_Data = nil) then INI_ReadFile;

     {*** Find specified entry ***}
     if (INI_Data <> nil) then INI_FindEntry(sSection, sEntryName, sEntryValue);

     {*** Return string length ***}
     INI_GetProfileString:= Length(sEntryValue);
end;

(* INI_GetProfileInt - works in the same way as INI_GetProfileString, except
                       the entry value returned is an integer, not a string. *)

function INI_GetProfileInt(    sAppName    : PathStr;
                               sSection    : string;
                               sEntryName  : string;
                           var iEntryValue : integer;
                               iDefault    : integer) : integer;

var Def : string;  {Holds default value converted to a string}
    S   : string;  {Holds entry value as a string}
    E   : integer; {Holds error code for string to integer conversion}
    R   : integer; {Holds entry value as an integer}
    L   : Integer; {Holds return value of INI_GetProfileString}

begin
     {*** Convert default value ***}
     Str(iDefault, Def);

     {*** Get entry as a string ***}
     L:= INI_GetProfileString(sAppName, sSection, sEntryName, S, Def);

     {*** Convert entry value to integer ***}
     Val(S, R, E);

     {*** Check for errors ***}
     if (E = 0) then iEntryValue:= R
                else iEntryValue:= iDefault;

     {*** Return value ***}
     INI_GetProfileInt:= L;
end;

(* INI_WriteProfileString - the following description is taken from the
                            original INIF unit.

   ---------------------------------------------------------------------

   The INI_WriteProfileString function copies a character string into the
   specified [Section] and a specified entry name in the .INI file
   specified in sAppName.

   parameter   | description
   ------------+---------------------------------------------------------
   sAppName    | The name of the .INI file.
               | You do not need to type .INI after the path:\filename.
   sSection    | The [Section] to witch the string will by copied. If the
               | section does not exist, it is created. The name of the
               | section is not case-dependent; the string may be any
               | combination of uppercase and lowercase letters.
               | (don't put [ ] around the section name.)
   sEntryName  | String containing the entry which is to be associated with
               | the string. If the entry does not exist in the specified
               | section, it is created.
   sEntryValue | The string which is to be associated with EntryName.
   ---------------------------------------------------------------------
   Returns:
           INI_WriteProfileString returns zero if write was successful
           otherwise -1.

   Comment:
           Sections in the .INI file have the following form:

           [Section]
           EntryName=EntryValue
            .
            .

            The Section, EntryName and EntryValue is not case-dependent.
            With every compare all the strings are converted into uppercase.

*)

function INI_WriteProfileString(sAppName    : PathStr;
                                sSection    : string;
                                sEntryName  : string;
                                sEntryValue : string) : integer;

var i        : integer; {Loop control variable}
    EntryIDX : integer; {Used to index buffer}
    Line     : string;  {Current line of data}
    Dummy    : string;  {Used in data processing}
    D        : DirStr;  {Used to hold components of file name}
    N        : NameStr;
    E        : ExtStr;
    ON       : NameStr; {Holds name of file currently buffered}
    NN       : NameStr; {Holds name of file required}
    RetVal   : integer; {Holds function return code}

begin
     {*** Initialise variables ***}
     RetVal:= -1;
     INI_SetFileName(sAppName);

     {*** Process file names ***}
     FSplit(INI_Name, D, N, E);
     ON:= StrUpper(N);
     FSplit(sAppName, D, N, E);
     NN:= StrUpper(N);

     {*** Ensure that INI_Data = nil, if OldName <> NewName (i.e. another
          INI file is to be used) ***}
     if ON <> NN then INI_DisposeData;

     {*** If no file buffered then load in new file ***}
     if (INI_Data = nil) then INI_ReadFile;

     if INI_Data <> nil then
     begin
          {*** Handle special case to flush collection to .INI file ***}
          if (INI_Data <> nil) and
             ((StrUpper(sSection) = 'NIL') and
              (StrUpper(sEntryName) = 'NIL') and
              (StrUpper(sEntryValue) = 'NIL')) then
          begin
               if INI_SaveFile then INI_WriteProfileString:= 0;
               Exit;
          end
          {*** Handle delete section request ***}
          else
              if (StrUpper(sEntryName) = 'NIL') and
                 (StrUpper(sEntryValue) = 'NIL') and
                 (INI_FindSection(sSection)) then
              begin
                   {*** Adjust SectionEndIDX if the section is the last
                        section in the INI file ***}
                   if SectionEndIDX = INI_Data^.Count - 1 then
                      Inc(SectionEndIDX);

                   while (SectionStartIDX < SectionEndIDX) and
                         (SectionEndIDX <= INI_Data^.Count) do
                   begin
                        INI_Data^.AtFree(SectionStartIDX);
                        Dec(SectionEndIDX);
                   end;
              end
              {*** Handle delete entry request ***}
              else
                   if (StrUpper(sEntryValue) = 'NIL') then
                   begin
                        EntryIDX:= INI_FindEntry(sSection, sEntryName, Dummy);
                        {*** Dispose string ***}
                        if EntryIDX > 0 then
                           INI_Data^.AtFree(EntryIDX);
                   end
                   {*** Deal with other requests ***}
                   else
                   begin
                        EntryIDX:= INI_FindEntry(sSection, sEntryName, Dummy);
                        {*** If sEntryName is found, then replace the old
                             string with the new string ***}
                        if EntryIDX > 0 then
                        begin
                             {*** Dispose the old string ***}
                             DisposeStr(INI_Data^.At(EntryIDX));
                             {*** Write the new one ***}
                             INI_Data^.AtPut(EntryIDX,
                                             NewStr(sEntryName + '=' +
                                                    sEntryValue));
                        end
                        {*** If INI_FindEntry returns -1 then the entry
                             does not exist. So insert the new entry at
                             index returned by INI_FindEntry.  ***}
                        else
                            {*** If sEntryValue = NIL, don't do anyting ***}
                            if (StrUpper(sEntryValue) <> 'NIL') and
                               (EntryIDX = -1) then
                            begin
                                 for i:= 0 to INI_Data^.Count - 1 do
                                     Line:= PString(INI_Data^.At(i))^;

                                 if SectionEndIDX < INI_Data^.Count - 1 then
                                    INI_Data^.AtInsert(SectionEndIDX,
                                                       NewStr(sEntryName +
                                                              '=' +
                                                              sEntryValue))
                                 else
                                    INI_Data^.AtInsert(INI_Data^.Count,
                                                       NewStr(sEntryName +
                                                              '=' +
                                                              sEntryValue));

                                 for i:= 0 to INI_Data^.Count - 1 do
                                     Line:= PString(INI_Data^.At(i))^;
                            end
                            {*** If INI_FindEntry returns -2 then the section
                                 does not exist. So insert the new section
                                 and entry at the end ***}
                            else
                                if EntryIDX = -2 then
                                begin
                                     INI_Data^.AtInsert(INI_Data^.Count,
                                                        NewStr('[' +
                                                               sSection +
                                                               ']'));
                                     INI_Data^.AtInsert(INI_Data^.Count,
                                                        NewStr(sEntryName +
                                                               '=' +
                                                               sEntryValue));
                                end;
                   end;
     end;
     INI_WriteProfileString:= RetVal;
end;

(* INI_WriteProfileInt - works in the same way as INI_WriteProfileString,
                         except the entry value an integer, not a string. *)

function INI_WriteProfileInt(sAppName    : PathStr;
                             sSection    : string;
                             sEntryName  : string;
                             iEntryValue : integer): integer;

var S : string;  {Used to convert entry value to a string}
    L : integer; {Stores return code of INI_WriteProfileString}

begin
     Str(iEntryValue, S);
     L:= INI_WriteProfileString(sAppName, sSection, sEntryName, S);
     INI_WriteProfileInt:= L;
end;

(* INI_DisposeData - releases memory used by buffered INI file collection *)

procedure INI_DisposeData;

begin
     {*** Ensure buffer is in use, and release memory ***}
     if INI_Data <> nil then Dispose(INI_Data, Done);

     {*** Set buffer to nil ***}
     INI_Data:= nil;

     {*** Update global variables ***}
     INI_ReadError:= false;
     INI_WriteError:= false;
end;

(* INI_ExitProc - custom exit procedure that ensures buffered data
                  is written to the INI file and that the buffer
                  memory is released.
*)

procedure INI_ExitProc; far;

begin
     {*** Restore old exit procedure ***}
     ExitProc:= OldExitProc;

     {*** Flush the collection ***}
     if INI_FlushOnExit and (INI_Data <> nil) then
        INI_WriteProfileString(INI_Name, 'NIL', 'NIL', 'NIL');

     {*** Release memory ***}
     INI_DisposeData;
end;

(* Unit initialisation - setup collection pointer and exit procedure *)

begin
     INI_Data:= nil;
     OldExitProc:= ExitProc;
     ExitProc:= @INI_ExitProc;
end.