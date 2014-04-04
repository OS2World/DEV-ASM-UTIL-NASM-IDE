unit IABOUT;

(* Information
   ßßßßßßßßßßß

   Program Title : NASM-IDE About Box
   External name : IABOUT.TPU
   Version       : 1.6
   Start date    : 31/03/1997
   Last update   : 21/04/2002
   Author        : Rob Anderton
   Description   : Unit containing About dialog box.
*)

interface

{******}

uses DIALOGS, OBJECTS, VIEWS, ICONTROL;

{*** TAboutDlg ***}

type PAboutDialog = ^TAboutDialog;
     TAboutDialog = object(TDialog)
                          constructor Init;
                    end;

{******}

implementation

uses ICONST;

{******}

constructor TAboutDialog.Init;

var R       : TRect;
    Control : PView;

begin
     R.Assign(0, 0, 52, 14);
     inherited Init(R, 'About');
     Options:= Options or ofCenterX or ofCenterY;

     R.Assign(4, 2, 12, 3);
     Insert(New(PColouredText, Init(R, 'NASM-IDE', $74)));

     R.Assign(4, 3, 17, 4);
     Insert(New(PColouredText, Init(R, 'Version ' + IDEVersion, $7F)));

     R.Assign(4, 5, 39, 6);
     Insert(New(PColouredText, Init(R, 'Copyright 1997-2002 Robert Anderton', $70)));

     R.Assign(4, 6, 23, 7);
     Insert(New(PColouredText, Init(R, 'All rights reserved', $70)));

     R.Assign(4, 8, 9, 9);
     Insert(New(PColouredText, Init(R, 'email', $71)));

     R.Assign(11, 8, 30, 9);
     Insert(New(PColouredText, Init(R, 'rob@inglenook.co.uk', $76)));

     R.Assign(4, 9, 7, 10);
     Insert(New(PColouredText, Init(R, 'www', $71)));

     R.Assign(11, 9, 48, 10);
     Insert(New(PColouredText, Init(R, 'http://uk.geocities.com/rob_anderton/', $76)));

     R.Assign(37, 11, 48, 13);
     Control:= New(PButton, Init(R, '~C~lose', cmOK, bfDefault));
     Insert(Control);

     SelectNext(False);
end;

{******}

end.
