unit ICONTROL;

(* Information
   ßßßßßßßßßßß

   Program Title : NASM-IDE miscellaneous Turbo Vision Objects.
   External name : ICONTROL.TPU
   Version       : 1.0
   Start date    : 25/09/1997
   Last update   : 20/12/1998
   Author        : Rob Anderton.
   Description   : Useful objects for use in Turbo Vision 2.0.
                   Originally STVISION.PAS part of the S-Library.

*)

interface

{******}

uses APP, DIALOGS, DOS, DRIVERS, MEMORY, MENUS, OBJECTS, VIEWS,
     ICONST, IUTILS;

{*** New object types ***}

{*** TColouredText (see documentation for copyright info) ***}
type PColouredText = ^TColouredText;
     TColouredText =
        object(TStaticText)
          private
            Attr : byte;

          public
            constructor Init(var Bounds : TRect; const AText : string;
                             Attribute : byte);
            constructor Load(var S : TStream);

            function  GetTheColour : byte; virtual;
            procedure Draw; virtual;
            procedure Store(var S : TStream);
        end;

{*** TCustomDesktop - desktop that can use any character ***}

type PCustomDesktop = ^TCustomDesktop;
     TCustomDesktop =
        object(TDesktop)

          public
            constructor Init(var Bounds : TRect; APattern : char;
                             Attribute : byte);

            procedure InitBackground; virtual;
        end;

{*** TCustomBackground - used by TCustomDesktop to draw using any
                         character. ***}

type PCustomBackground = ^TCustomBackground;
     TCustomBackground =
        object(TBackground)
          private
            Attr : byte; {Holds the colour attributes to use for the
                          background}

          public
            constructor Init(var Bounds : TRect; APattern : char;
                             Attribute : byte);

            function  GetTheColour : byte; virtual;
            procedure Draw; virtual;
        end;

{*** THintLine - uses a string list in a resource file to display hints on
                 the hint line based on the hcXXXX constant. ***}

type PHintLine = ^THintLine;
     THintLine =
        object(TStatusLine)
          private
            Hints : PStringList; {Holds hint strings, indexed by a help
                                  constant}

          public
            procedure SetHints(pHints : PStringList);
            function  Hint(AHelpCtx : word) : string; virtual;
        end;

{*** THeapViewer - enhanced heap viewer displays memory available,
                   percentage of memory available and percentage of
                   memory used. ***}

type PHeapViewer = ^THeapViewer;
     THeapViewer =
        object(TView)

          private
            Display : byte;       {Indicates current display mode}
            OldMem  : longint;    {Used to determine if display needs
                                   updating}
            MemStr  : string[10]; {Used for writing display on to the screen}

          public
            constructor Init(var Bounds : TRect);

            procedure Draw; virtual;
            procedure Update;
            procedure HandleEvent(var Event : TEvent); virtual;
        end;

{*** TClockViewer - based on TClickClock by Jake Mathews, a 12/24 hour clock
                    viewer ***}

type PClockViewer = ^TClockViewer;
     TClockViewer =
        object(TView)

          private
            TimeStr    : string[12]; {Used to display time on the screen}
            LastTime   : DateTime;   {Used to determine if display needs updating}
            TwelveHour : boolean;    {True if 12 hour mode, false if 24 hour mode}
            Refresh    : byte;       {Determines the minimum number of seconds to
                                      elapse before updating}

          public
            constructor Init(var Bounds : TRect; TwelveHr : boolean);

            procedure Draw; virtual;
            function  FormatTimeStr(H, M, S : word) : string; virtual;
            procedure Update; virtual;
            procedure HandleEvent(var Event : TEvent); virtual;
        end;

{*** TSCollection - an unordered collection for storing PStrings ***}

type PSCollection = ^TSCollection;
     TSCollection =
        object(TCollection)
          public
            procedure FreeItem(Item : pointer); virtual;
            function  GetItem(var S : TStream) : pointer; virtual;
            procedure PutItem(var S : TStream; Item : pointer); virtual;
        end;

{*** Procedures ***}

procedure RegisterControls;


{*** Registration records ***}

const

      RColouredText : TStreamRec = (ObjType : idColouredText;
                                    VMTLink : Ofs(TypeOf(TColouredText)^);
                                    Load    : @TColouredText.Load;
                                    Store   : @TColouredText.Store);

      RHintLine : TStreamRec = (ObjType : idHintLine;
                                VMTLink : Ofs(TypeOf(THintLine)^);
                                Load    : @THintLine.Load;
                                Store   : @THintLine.Store);

{*** Constants ***}

const HINTLINE_DEFAULT : string = ''; {Default hint returned by THintLine}

{******}

implementation

{******}

{*** TColouredText object ***}

(* TColouredText.Init - initialises a coloured static text object.

                        Bounds     - the area the object is to occupy on
                                     screen.

                        AText      - the text string to display.

                        Attributes - the colour attributes to use.

*)

constructor TColouredText.Init(var   Bounds    : TRect;
                               const AText     : string;
                                     Attribute : byte);

begin
     {*** Initialise ancestor ***}
     TStaticText.Init(Bounds, AText);

     {*** Store specified colour attributes ***}
     Attr:= Attribute;
end;


(* TColouredText.Load - creates a static text object by loading it from a
                        stream.

                        S - the stream to load the object from.

*)

constructor TColouredText.Load(var S: TStream);

begin
     {*** Load the standard TStaticText object ***}
     TStaticText.Load(S);

     {*** Read the colour attributes ***}
     S.Read(Attr, Sizeof(Attr));
end;


(* TColouredText.Store - writes a coloured static text object to the
                         specified stream.

                         S - the stream to write to.

*)

procedure TColouredText.Store(var S: TStream);

begin
     {*** Store the base TStaticText object ***}
     TStaticText.Store(S);

     {*** Store the colour attribute ***}
     S.Write(Attr, Sizeof(Attr));
end;


(* TColouredText.GetTheColour - ensures the application is running in colour
                                mode and returns the Attr field of the text
                                object. If the application is not in colour
                                mode then returns the normal text attribute.

                                Returns appropriate colour code.
*)

function TColouredText.GetTheColour : byte;

begin
     {*** Check colour mode ***}
     if (AppPalette = apColor) then
         GetTheColour:= Attr
     else
         GetTheColour:= GetColor(1);
end;


(* TColouredText.Draw - draws the text onto the screen.

                        Largely taken from Borland's TStaticText.Draw.
*)

procedure TColouredText.Draw;

var Colour : byte;          {Holds the colour attribute used to display text}
    Center : boolean;       {True if the text is to be centred}
    I      : integer;       {Variables used to draw text}
    J      : integer;
    L      : integer;
    P      : integer;
    Y      : Integer;
    B      : TDrawBuffer;   {The buffer holding the formatted output text}
    S      : string;        {Holds the text to be displayed}

begin
     {*** Get colour attributes ***}
     Colour:= GetTheColour;

     {*** Get the string to be displayed ***}
     GetText(S);

     {*** Initialise variables ***}
     L:= Length(S);
     P:= 1;
     Y:= 0;
     Center:= false;

     {*** Height loop - repeat for each line of text ***}
     while Y < Size.Y do
     begin
          {*** Blank out line ***}
          MoveChar(B, ' ', Colour, Size.X);

          {*** Process each character ***}
          if P <= L then
          begin
               {*** Check for centred text code ***}
               if S[P] = #3 then
               begin
                    Center:= True;
                    Inc(P);
               end;

               I:= P;
               repeat
                     J:= P;

                     {*** Skip spaces ***}
                     while (P <= L) and (S[P] = ' ') do Inc(P);
                     while (P <= L) and (S[P] <> ' ') and (S[P] <> #13) do Inc(P);
               until (P > L) or (P >= I + Size.X) or (S[P] = #13);


               {*** Calculate text position ***}
               if P > I + Size.X then

                  if J > I then P:= J
                           else P:= I + Size.X;

               if Center then J:= (Size.X - P + I) div 2
                         else J:= 0;

               {*** Create formatted text buffer ***}
               MoveBuf(B[J], S[I], Colour, P - I);

               while (P <= L) and (S[P] = ' ') do Inc(P);

               {*** Process new line ***}
               if (P <= L) and (S[P] = #13) then
               begin
                    Center:= False;
                    Inc(P);
                    if (P <= L) and (S[P] = #10) then Inc(P);
               end;
          end;

          {*** Output formatted text ***}
          WriteLine(0, Y, Size.X, 1, B);
          Inc(Y);
     end;
end;


{*** TCustomDesktop object ***}


(* TCustomDesktop.Init - initialises a desktop object and inserts a
                         TCustomBackground object.

                         Bounds    - the bounding rectangle the desktop is to
                                     occupy.

                         APattern  - the pattern to use for the background.

                         Attribute - the colour attribute to use for the
                                     background.

*)

constructor TCustomDesktop.Init(var Bounds    : TRect;
                                    APattern  : char;
                                    Attribute : byte);

begin
     {*** Call TDesktop.Init ***}
     inherited Init(Bounds);

     {*** Create background object ***}
     Background:= New(PCustomBackground, Init(Bounds, APattern, Attribute));

     {*** If creation successful then insert ***}
     if Assigned(Background) then Insert(Background);
end;


(* TCustomDesktop.InitBackground - this procedure is called by TDesktop.Init.
                                   Nil is always returned so that the new
                                   TCustomBackground can be initialised and
                                   inserted by the new Init procedure.
*)

procedure TCustomDesktop.InitBackground;

begin
     {*** Set background to nil so TDesktop.Init does not draw it ***}
     Background:= nil;
end;


{*** TCustomBackground object ***}


(* TCustomBackground.Init - call inherited Init to set bounds and pattern.
                            Then sets colour attribute specified.

                            Bounds    - the bounding rectangle occupied by
                                        the background.

                            APattern  - the ASCII character to use to draw
                                        the background.

                            Attribute - the colour attribute to use to draw
                                        the background.

*)

constructor TCustomBackground.Init(var Bounds    : TRect;
                                       APattern  : char;
                                       Attribute : byte);

begin
     {*** Call ancestor's Init ***}
     inherited Init(Bounds, APattern);

     {*** Set required colour attribute ***}
     Attr:= Attribute;
end;


(* TCustomBackground.GetTheColour - ensures the application is running in
                                    colour mode and returns the Attr field
                                    of the text object. If the application
                                    is not in colour mode then returns the
                                    normal background attribute.

                                    Returns appropriate colour code.
*)

function TCustomBackground.GetTheColour : byte;

begin
     {*** Check colour mode ***}
     if (AppPalette = apColor) then
         GetTheColour:= Attr
     else
         GetTheColour:= GetColor(1);
end;


(* TCustomBackground.Draw - fills the background view rectangle with the
                            current Pattern in current colour.
*)

procedure TCustomBackground.Draw;

var I    : integer;     {Loop control variable}
    Buf  : TDrawBuffer; {Holds text to draw}
    Col  : byte;        {Holds colour attribute}

begin
     {*** Get the colour attribute ***}
     Col:= GetTheColour;

     {*** Draw pattern ***}
     for I:= 0 to Size.Y - 1 do
     begin
          MoveChar(Buf, Pattern, Attr, Size.X);
          WriteBuf(0, I, Size.X, 1, Buf);
     end;
end;

{*** THintLine object ***}

(* THintLine.SetHints - assigns the Hints field to the string list passed to
                        the procedure.

                        pHints - pointer to string list of hints.

                        NOTE: any lists previously assigned to Hints are NOT
                              deallocated by this method.

*)

procedure THintLine.SetHints(pHints : PStringList);

begin
     Hints:= pHints;
end;

(* THintLine.Hint - access the hints string list using the given hcXXXX
                    constant and returns a help string.

                    AHelpCtx - the hcXXXX constant to index the hints list

                    Returns hint string, or default string if no entry for
                    the given hcXXXX constant exists.
*)

function THintLine.Hint(AHelpCtx : word) : string;

var S : string; {Holds hint string}

begin
     {*** Get string from hints list ***}
     S:= Hints^.Get(AHelpCtx);
     {*** If empty then return default hint ***}
     If S = '' then S:= HINTLINE_DEFAULT;
     {*** Return hint string ***}
     Hint:= S;
end;


{*** THeapViewer object ***}

(* THeapView.Init - initialises the enhanced heap view.

                    Bounds - the region on the screen to be occupied by the
                             view.

*)

constructor THeapViewer.Init(var Bounds: TRect);

begin
     {*** Call TView.Init ***}
     inherited Init(Bounds);

     {*** Initialise fields ***}
     OldMem:= 0;
     Display:= 0;
     MemStr:= '';
     GrowMode:= gfGrowAll;
end;

(* THeapViewer.Draw - formats the display and outputs to the screen. *)

procedure THeapViewer.Draw;

var B : TDrawBuffer; {Holds the formatted display data}
    C : byte;        {Holds the colour attribute for the display}

begin
     {*** If the available memory is low then
          display in a different colour ***}
     if not LowMemory then C:= GetColor(3)
                      else C:= GetColor(4);

     {*** Set output to blanks ***}
     MoveChar(B, ' ', C, Size.X);
     {*** Move display string ***}
     MoveStr(B, MemStr, C);
     {*** Output to screen ***}
     WriteLine(0, 0, Size.X, 1, B);
end;

(* THeapViewer.Update - if the available memory has changed since the last
                        call to Update, the display is redrawn to reflect
                        the change.
*)

procedure THeapViewer.Update;

{******}

 (* LeadingSpace - Returns a string containing a number of padding spaces
                   based on the number of digits in a given number.

                   Num - the number to use to determine padding spaces.

                   Returns a padded string.
 *)

 function LeadingSpace(Num : longint) : string;

 var StrTemp : string; {Holds return string}

 begin
      {*** Add appropriate padding ***}
      case Num of
             0..9 : StrTemp:= '  ';
           10..99 : StrTemp:= ' ';
             else   StrTemp:= '';
      end;

      {*** Return string ***}
      LeadingSpace:= StrTemp;
 end;

{******}

var MemTemp : longint; {Used to calculate value to display}

begin
     {*** Check update is required ***}
     if (OldMem <> MemAvail) then
     begin
          {*** Update variables ***}
          OldMem:= MemAvail;

          case Display of
                     0 : Str(OldMem:Size.X, MemStr); {Display memory available}
                     1 : begin
                              {*** Determine % free ***}
                              MemTemp:= Trunc(100 * (OldMem /
                                             (LONGINT(MaxHeapSize) * 16)));
                              {*** Convert to string ***}
                              MemStr:= 'Free:' + LeadingSpace(MemTemp) +
                                       IntToStr(MemTemp) + '%';
                         end;
                     2 : begin
                              {*** Determine % used ***}
                              MemTemp:= 100 - Trunc(100 * (OldMem /
                                              (LONGINT(MaxHeapSize) * 16)));
                              {*** Convert to string ***}
                              MemStr:= 'Used:' + LeadingSpace(MemTemp) +
                                       IntToStr(MemTemp) + '%';
                         end;
          end;

          {*** Update display on screen ***}
          DrawView;
     end;
end;

(* THeapViewer.HandleEvent - process double click to change display mode. *)

procedure THeapViewer.HandleEvent(var Event : TEvent);

begin
     if (Event.What = evMouseDown) then
        if (Event.Double) then
        begin
             {*** Wrap display mode to 0 ***}
             if Display < 2 then Inc(Display)
                            else Display:= 0;
             OldMem:= 0;
             {*** Update display ***}
             Update;
        end;
end;

{*** TClockViewer object ***}

(* TClockViewer.Init - initialises the enhanced clock viewer.

                       Bounds   - the region on screen that the viewer is to
                                  occupy.

                       TwelveHr - determines the initial mode of the clock
                                  True for 12 hour, false for 24 hour.
*)

constructor TClockViewer.Init(var Bounds: TRect; TwelveHr : boolean);

begin
     {*** Call TView.Init ***}
     inherited Init(Bounds);
     {*** Initialise fields ***}
     FillChar(LastTime, SizeOf(LastTime), #$FF);
     TimeStr:= '';
     Refresh:= 1; {1 second minimum refresh}
     TwelveHour:= TwelveHr;
     GrowMode:= gfGrowAll;
end;

(* ClockViewer.Draw - formats the display and outputs to the screen. *)

procedure TClockViewer.Draw;

var B : TDrawBuffer; {Holds the formatted display data}
    C : byte;        {Holds the colour attribute for the display}

begin
     {*** Get colour attribute ***}
     C:= GetColor(1);
     {*** Set output to blanks ***}
     MoveChar(B, ' ', C, Size.X);
     {*** Move display string ***}
     MoveStr(B, TimeStr, C);
     {*** Output to screen ***}
     WriteLine(0, 0, Size.X, 1, B);
end;

(* TClockViewer.Update - redraws the display if the necessary time has
                         elapsed since the last call to update.
*)

procedure TClockViewer.Update;

var h, m, s, hund : word; {Holds current time}

begin
     {*** Get current time ***}
     GetTime(h, m, s, hund);

     {*** Determine if update is necessary ***}
     if Abs(s - LastTime.sec) >= Refresh then
     begin
          {*** Update variable ***}
          with LastTime do
          begin
               Hour:= h;
               Min:= m;
               Sec:= s;
          end;
          {*** Create formatted time string ***}
          TimeStr:= FormatTimeStr(h, m, s);
          {*** Draw the viewer ***}
          DrawView;
     end;
end;

(* TClockViewer.FormatTimeStr - returns a string containing a 12/24 hour
                                formatted time ready for display.

                                H - the time in hours
                                M - the time in minutes
                                S - the time in seconds

                                Returns formatted time string.
*)

function TClockViewer.FormatTimeStr(H, M, S : word): string;

 (* LeadingSpace - Returns a string containing a number of padding spaces
                   based on the number of digits in a given number.

                   Num - the number to use to determine padding spaces.

                   Returns a padded string.
 *)

 function LeadingSpace(Num : longint) : string;

 var StrTemp : string; {Holds return string}

 begin
      {*** Add appropriate padding ***}
      case Num of
             0..9 : StrTemp:= ' ';
             else   StrTemp:= '';
      end;

      {*** Return string ***}
      LeadingSpace:= StrTemp;
 end;

 (* LeadingZero - Converts a given value to a string and adds leading zeros
                  as appropriate.

                  Num - the number to convert.

                  Returns the converted string.
 *)


 function LeadingZero(Num : word): string;

 var StrTemp : string; {Holds return string}

 begin
      {*** Convert to string ***}
      Str(Num:0, StrTemp);
      {*** Add leading zeros ***}
      LeadingZero:= Copy('00', 1, 2 - Length(StrTemp)) + StrTemp;
 end;

{******}

var AmPm : string[2];   {Holds string containing either 'am' or 'pm'}
    Temp : string[12];  {Holds return string}

begin
     {*** Deal with 12 hour display ***}
     if TwelveHour then
     begin
          if h >= 12 then
          begin
               {*** After midday so add 'pm' string ***}
               AmPm:= 'pm';
               {*** Subtract 12 from times except midday itself ***}
               if h <> 12 then Dec(h, 12);
          end
          else
          begin
               {*** If midnight then set hours to 12 ***}
               if h = 0 then h:= 12;
               {*** Add 'am' string ***}
               AmPm:= 'am';
          end;

          {*** Build formatted string ***}
          Temp:= LeadingSpace(h) + IntToStr(h) + ':' +
                 LeadingZero(m) + ':' + LeadingZero(s) + AmPm;
     end
     else Temp:= '  ' + LeadingSpace(h) + IntToStr(h) + ':' +
                 LeadingZero(m) + ':' + LeadingZero(s);

     {*** Return formatted string ***}
     FormatTimeStr:= Temp;
end;

(* TClockViewer.HandleEvent - process double click to change display mode. *)

procedure TClockViewer.HandleEvent(var Event : TEvent);

begin
     if (Event.What = evMouseDown) then
        if (Event.Double) then
        begin
             {*** Toggle 12/24 hour ***}
             TwelveHour:= not TwelveHour;
             {*** Update display ***}
             Update;
        end;
end;

{*** TSCollection object ***}

(* FreeItem - disposes of an item in the collection.

   Item - the item to dispose of.

*)

procedure TSCollection.FreeItem(Item : pointer);

begin
     DisposeStr(PString(Item));
end;

(* GetItem - TSCollection is not streamable, so this is an abstract method. *)

function TSCollection.GetItem(var S : TStream) : pointer;

begin
     Abstract;
end;

(* PutItem - TSCollection is not streamable, so this is an abstract method. *)

procedure TSCollection.PutItem(var S : TStream; Item : pointer);

begin
     Abstract;
end;

{******}

(* RegisterControls - registers the new objects for stream I/O. *)

procedure RegisterControls;

begin
     RegisterType(RColouredText);
     RegisterType(RHintLine);
end;

{******}

end.