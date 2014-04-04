unit IASM;

(* Information
   ßßßßßßßßßßß

   Program Title : NASM interface unit.
   External name : IASM.TPU
   Version       : 1.7
   Start date    : 08/06/1999
   Last update   : 18/05/2002
   Author        : Rob Anderton
   Description   : Unit containing Assembler object that can be
                   used to assemble code.
*)

interface

{******}

uses OBJECTS;

{******}

type TAssembler = object(TObject)
                     procedure Assemble(FileName : string);
                     procedure AssembleRun(FileName : string);
                     procedure ExpandCustomParams(var CustomParams : string; ParamTag : string; Replacement : string);
                  end;

{******}

var NASM : TAssembler;

{******}

implementation

uses IUTILS, IMAIN, IOPT, DOS, SINI, MSGBOX, VIEWS, APP, DRIVERS, ICONST;

{*** Custom parameter tags ***}

const cpSourceName = '%SRCNAME%';
      cpSourceExt  = '%SRCEXT%';
      cpSourceDir  = '%SRCDIR%';
      cpOutputName = '%OUTNAME%';
      cpOutputExt  = '%OUTEXT%';
      cpOutputDir  = '%OUTDIR%';

{******}

procedure TAssembler.Assemble(FileName : string);

var TargetInfo         : TTargetRec; {Holds target information from INI file}
    TargetDesc         : string;     {Target description string from INI file}
    ListingParameter   : string;     {-l parameter}
    OutputParameter    : string;     {-o parameter}
    OutputPath         : string;     {String from INI file}
    FormatParameter    : string;     {-f parameter}
    WarningParameter   : string;     {-w parameter}
    IncludeParameter   : string;     {-i parameter}
    IncludePath        : string;     {String from INI file}
    IncludePos         : word;       {Position in include string}
    WarningOptions     : word;
    ListingOptions     : word;
    OutputFormat       : word;
    DosCode            : integer;    {DOS return code}
    ININame            : string;     {NASM-IDE INI file name}
    SrcUntitled        : boolean;    {True if the source has not been saved}
    SrcSave            : boolean;    {Result of auto-save}
    SrcDirectory       : DirStr;     {Split name of source file}
    SrcName            : NameStr;
    SrcExtension       : ExtStr;
    ResponseFile       : text;       {The response file used to run NASM}
    LogFile            : file;       {The log file containing NASM status}
    NASMLocation       : string;     {The path and directory to NASM.EXE}
    CustomParams       : string;     {The custom parameter string}

begin
     {*** Create batch file ***}
     Assign(ResponseFile, Main.NASMDirectory + 'NASM.RSP');
     Rewrite(ResponseFile);

     {*** Get name of INI file ***}
     ININame:= Main.NASMDirectory + 'NASMIDE.INI';

     {*** Get name of assembler ***}
     INI_GetProfileString(ININame, 'ASSEMBLER', 'NASM_LOCATION', NASMLocation, '');
     if NASMLocation = '' then
     begin
          MessageBox('You need to enter the location of NASM in the assembler options.', nil, mfError + mfOKButton);
          Exit;
     end;


     {*** Determine current output format ***}
     INI_GetProfileInt(ININame, 'ASSEMBLER', 'OUTPUT_FORMAT',
                       INTEGER(OutputFormat), 0);

     INI_GetProfileString(ININame, 'OUTPUT_FORMATS', 'OPF_' + IntToStr(OutputFormat),
                          TargetDesc, '');

     if TargetDesc = '' then
     begin
          MessageBox('Unknown output format selected.', nil, mfError + mfOKButton);
          Exit;
     end;

     TargetInfo.Description:= Copy(TargetDesc, 1, Pos(',', TargetDesc) - 1);
     SYSTEM.Delete(TargetDesc, 1, Pos(',', TargetDesc));
     TargetInfo.FileExt:= Copy(TargetDesc, 1, Pos(',', TargetDesc) - 1);
     SYSTEM.Delete(TargetDesc, 1, Pos(',', TargetDesc));
     TargetInfo.CmdParam:= TargetDesc;
     FormatParameter:= '-f ' + TargetInfo.CmdParam;

     {*** Write the format parameter ***}
     writeln(ResponseFile, FormatParameter);

     {*** Get the individual components of the source file name ***}
     FSplit(FileName, SrcDirectory, SrcName, SrcExtension);

     {*** Get output path ***}
     INI_GetProfileString(ININame, 'DIRECTORIES', 'OUTPUT_DIR', OutputPath,
                          '');

     {*** Construct output filename parameter ***}
     if Length(OutputPath) > 0 then
     begin
          if OutputPath[Length(OutputPath)] <> '\' then
             OutputPath:= OutputPath + '\';

          OutputParameter:= '-o ' + OutputPath + SrcName + '.' + TargetInfo.FileExt;
     end
     else
     begin
         OutputParameter:= '-o ' + SrcDirectory + SrcName + '.' + TargetInfo.FileExt;
         OutputPath:= SrcDirectory;
     end;

     {*** Store in response file ***}
     writeln(ResponseFile, OutputParameter);

     {*** Determine warning options required ***}
     INI_GetProfileInt(ININame, 'ASSEMBLER', 'NASM_WARNING',
                       INTEGER(WarningOptions), 15);
     if WarningOptions > 15 then WarningOptions:= 15;

     {*** Construct warnings parameter ***}
     if WarningOptions and 1 = 1 then WarningParameter:= '-w+macro-params'
                                 else WarningParameter:= '-w-macro-params';
     writeln(ResponseFile, WarningParameter);

     if WarningOptions and 2 = 2 then WarningParameter:= '-w+orphan-labels'
                                 else WarningParameter:= '-w-orphan-labels';
     writeln(ResponseFile, WarningParameter);

     if WarningOptions and 4 = 4 then WarningParameter:= '-w+number-overflow'
                                 else WarningParameter:= '-w-number-overflow';
     writeln(ResponseFile, WarningParameter);

     if WarningOptions and 8 = 8 then WarningParameter:= '-w+macro-selfref'
                                 else WarningParameter:= '-w-macro-selfref';
     writeln(ResponseFile, WarningParameter);

     {*** Write include paths ***}
     INI_GetProfileString(ININame, 'DIRECTORIES', 'INCLUDE_DIR', IncludePath, '');
     while Length(IncludePath) > 0 do
     begin
          IncludePos:= Pos(';', IncludePath);
          if IncludePos > 0 then
          begin
               IncludeParameter:= Copy(IncludePath, 1, IncludePos - 1);
               if IncludeParameter[Length(IncludeParameter)] <> '\' then
                  IncludeParameter:= IncludeParameter + '\';
               writeln(ResponseFile, '-i', IncludeParameter);
               SYSTEM.Delete(IncludePath, 1, IncludePos);
          end
          else
          begin
               if (IncludePath[Length(IncludePath)] <> '\') and
                  (Length(IncludePath) > 0) then
                     IncludePath:= IncludePath + '\';
               writeln(ResponseFile, '-i', IncludePath);
               IncludePath:= '';
          end;
     end;

     {*** Write error log parameter ***}
     writeln(ResponseFile, '-E ', Main.NASMDirectory, 'NASM.LOG');
     Close(ResponseFile);

     {*** Truncate the log file ***}
     Assign(LogFile, Main.NASMDirectory + 'NASM.LOG');
     Rewrite(LogFile, 1);
     Close(LogFile);

     {*** Get Custom Parameters ***}
     INI_GetProfileString(ININame, 'ASSEMBLER', 'CUSTOM_PARAMS', CustomParams, '');

     {*** Process any special tags in the custom parameters ***}
     ExpandCustomParams(CustomParams, cpSourceName, SrcName);
     ExpandCustomParams(CustomParams, cpSourceExt, SrcExtension);
     ExpandCustomParams(CustomParams, cpSourceDir, SrcDirectory);
     ExpandCustomParams(CustomParams, cpOutputName, SrcName);
     ExpandCustomParams(CustomParams, cpOutputExt, '.' + TargetInfo.FileExt);
     ExpandCustomParams(CustomParams, cpOutputDir, OutputPath);

     {*** Call COMMAND.COM ***}
     DosCode:= Main.RunProgram(NASMLocation, '-@ ' + Main.NASMDirectory +
                               'NASM.RSP ' + CustomParams + ' ' + FileName, false, 'Assembling...');

     {*** Send message to open log viewer window ***}
     Message(Application, evCommand, cmWindowErrorInfo, nil);
end;

{******}

procedure TAssembler.AssembleRun(FileName : string);

var ProgName, Params : string;
    D                : DirStr;
    N                : NameStr;
    E                : ExtStr;
    OutputFormat     : word;
    OutputPath       : string;
    ININame          : string;
    LogFile          : file;
    LogSize          : longint;

begin
     {*** Get INI file name ***}
     ININame:= Main.NASMDirectory + 'NASMIDE.INI';

     {*** Assemble the file ***}
     Assemble(FileName);

     {*** Get output path ***}
     INI_GetProfileString(ININame, 'DIRECTORIES', 'OUTPUT_DIR', OutputPath,
                          '');

     {*** Construct program name ***}
     FSplit(FileName, D, N, E);

     if Length(OutputPath) > 0 then
     begin
          if OutputPath[Length(OutputPath)] <> '\' then
             OutputPath:= OutputPath + '\';

          Progname:= OutputPath + N + '.COM';
     end
     else
         ProgName:= D + N + '.COM';

     {*** Get parameters ***}
     INI_GetProfileString(ININame, 'ASSEMBLER', 'RUN_PARAMS', Params, '');

     {*** Check for errors ***}
     if (IUTILS.FileExists(Main.NASMDirectory + 'NASM.LOG') = true) then
     begin

        Assign(LogFile, Main.NASMDirectory + 'NASM.LOG');
        Reset(LogFile, 1);
        LogSize:= FileSize(LogFile);
        Close(LogFile);

     end
     else
     begin

        LogSize:= 0;

     end;

     {*** Run the program ***}
     if (FileExists(ProgName)) then
     begin

        {*** Check the log file size ***}
        if (LogSize <> 0) then
        begin

           if (MessageBox('The error log is not empty - are you sure you wish to run the assembled code?',
                           nil, mfWarning + mfYesButton + mfNoButton) = mfYesButton) then
           begin

              Main.RunProgram(ProgName, Params, true, 'Press any key to continue...');

           end;

        end
        else
        begin

             Main.RunProgram(ProgName, Params, true, 'Press any key to continue...');

        end

     end
     else
     begin

          MessageBox('Unable to run the assembled code - file does not exist.', nil, mfError + mfOKButton);

     end;

end;

{******}

procedure TAssembler.ExpandCustomParams(var CustomParams : string; ParamTag : string; Replacement : string);

var bTagPosition : byte;

begin
     repeat

          {*** Check for the required tag and replace with the given string ***}
          bTagPosition:= Pos(ParamTag, StrUpper(CustomParams));

          if (bTagPosition <> 0) then
          begin
               Delete(CustomParams, bTagPosition, Length(ParamTag));
               Insert(Replacement, CustomParams, bTagPosition);
          end;

     until (bTagPosition = 0)

end;

{******}

end.