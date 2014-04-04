unit IASSIST;

(* Information
   ßßßßßßßßßßß

   Program Title : NASM-IDE ASM Assistant
   External name : IASSIST.TPU
   Version       : 1.5
   Start date    : 11/04/1997
   Last update   : 01/01/2002
   Author        : Rob Anderton
   Description   : Unit containing ASM Assistant dialogs.

*)

interface

{******}

uses DRIVERS, OBJECTS, VIEWS, DIALOGS, ICONTROL, IHELP;

{*** Record containing ASM Assistant options ***}

type PASMOptionRec = ^TASMOptionRec;
     TASMOptionRec = record
                           Bits : word;
                           Org  : word;
                           Text : boolean;
                           Data : boolean;
                           BSS  : boolean;
                     end;

{*** TASMAss1Dialog ***}

type PASMAss1Dialog = ^TASMAss1Dialog;
     TASMAss1Dialog = object(THelpDialog)
                            constructor Init;
                      end;

type TListBoxRec = record
                        List : PCollection;
                        Selection : Word;
                   end;

     TAss2DataRec = record
                         Bits : Word;
                         Org  : TListBoxRec;
                    end;
     PAss2DataRec = ^TAss2DataRec;

{*** TASMAss2Dialog ***}

     PASMAss2Dialog = ^TASMAss2Dialog;
     TASMAss2Dialog = object(THelpDialog)
                            ListBox : PListBox;
                            constructor Init;
                            procedure HandleEvent(var Event: TEvent); virtual;
                      end;

{*** TASMAss3Dialog ***}

     PASMAss3Dialog = ^TASMAss3Dialog;
     TASMAss3Dialog = object(THelpDialog)
                            CheckBox : PCheckBoxes;
                            constructor Init;
                            procedure HandleEvent(var Event: TEvent); virtual;
                      end;

{*** TASMAss4Dialog ***}

     PASMAss4Dialog = ^TASMAss4Dialog;
     TASMAss4Dialog = object(THelpDialog)
                            constructor Init;
                      end;

{******}

implementation

uses IConst;

{*** TASMAss1Dialog ***}

constructor TASMAss1Dialog.Init;

var R       : TRect;
    Control : PView;

begin
     R.Assign(19, 7, 61, 16);
     inherited Init(R, 'ASM Assistant 1/4');
     Options:= Options or ofCenterX or ofCenterY;
     HelpCtx:= hcFileNewAssistant1;

     R.Assign(7, 2, 35, 5);
     Control:= New(PStaticText, Init(R, 'ASM Assistant helps you to create a '+
                                        'simple '^M+
                                        'assembly source file'));
     Insert(Control);

     R.Assign(2, 2, 3, 3);
     Control:= New(PColouredText, Init(R, 'A', $74));
     Insert(Control);

     R.Assign(3, 3, 4, 4);
     Control:= New(PColouredText, Init(R, 'S', $79));
     Insert(Control);

     R.Assign(4, 4, 5, 5);
     Control:= New(PColouredText, Init(R, 'M', $7E));
     Insert(Control);

     R.Assign(39, 2, 40, 3);
     Control:= New(PColouredText, Init(R, 'A', $74));
     Insert(Control);

     R.Assign(38, 3, 39, 4);
     Control:= New(PColouredText, Init(R, 'S', $79));
     Insert(Control);

     R.Assign(37, 4, 38, 5);
     Control:= New(PColouredText, Init(R, 'M', $7E));
     Insert(Control);

     R.Assign(25, 6, 35, 8);
     Control:= New(PButton, Init(R, '~N~ext >>', cmOK, bfDefault));
     Control^.HelpCtx:= hcNext;
     Insert(Control);

     R.Assign(6, 6, 16, 8);
     Control:= New(PButton, Init(R, '~C~ancel', cmCancel, bfNormal));
     Control^.HelpCtx:= hcCancel;
     Insert(Control);

     SelectNext(False);
end;

{*** TASMAss2Dialog ***}

constructor TASMAss2Dialog.Init;

var R          : TRect;
    Control    : PView;
    ListItems  : PStringCollection;

begin
     R.Assign(13, 2, 66, 21);
     inherited Init(R, 'ASM Assistant 2/4');
     Options:= Options or ofCentered;
     HelpCtx:= hcFileNewAssistant2;

     R.Assign(7, 2, 46, 5);
     Control:= New(PStaticText, Init(R, 'Select the options which you wish to'+
                                        ' include in your assembler project'));
     Insert(Control);

     R.Assign(2, 2, 3, 3);
     Control:= New(PColouredText, Init(R, 'A', $74));
     Insert(Control);

     R.Assign(3, 3, 4, 4);
     Control:= New(PColouredText, Init(R, 'S', $79));
     Insert(Control);

     R.Assign(4, 4, 5, 5);
     Control:= New(PColouredText, Init(R, 'M', $7E));
     Insert(Control);

     R.Assign(50, 2, 51, 3);
     Control:= New(PColouredText, Init(R, 'A', $74));
     Insert(Control);

     R.Assign(49, 3, 50, 4);
     Control:= New(PColouredText, Init(R, 'S', $79));
     Insert(Control);

     R.Assign(48, 4, 49, 5);
     Control:= New(PColouredText, Init(R, 'M', $7E));
     Insert(Control);

     R.Assign(36, 15, 46, 17);
     Control:= New(PButton, Init(R, '~N~ext >>', cmOK, bfDefault));
     Control^.HelpCtx:= hcNext;
     Insert(Control);

     R.Assign(6, 15, 16, 17);
     Control:= New(PButton, Init(R, '~C~ancel', cmCancel, bfNormal));
     Control^.HelpCtx:= hcCancel;
     Insert(Control);

     R.Assign(21, 15, 31, 17);
     Control:= New(PButton, Init(R, '~H~elp', cmHelp, bfNormal));
     Control^.HelpCtx:= hcFileNewAssistant2;
     Insert(Control);

     R.Assign(8, 7, 46, 9);
     Control:= New(PRadioButtons, Init(R, NewSItem('~1~6 bit',
                                          NewSItem('~3~2 bit', Nil))));
     Control^.Options:= Control^.Options or ofFramed;
     Insert(Control);

     R.Assign(8, 6, 25, 7);
     Insert(New(PLabel, Init(R, 'Code ~G~eneration', Control)));

     R.Assign(8, 11, 46, 13);
     ListBox:= New(PListBox, Init(R, 1, Nil));
     ListBox^.Options:= Control^.Options or ofFramed;
     ListItems:= New(PStringCollection, Init(2, 0));
     ListItems^.Insert(NewStr('0000h (DOS .SYS file)'));
     ListItems^.Insert(NewStr('0100h (DOS .COM file)'));
     ListBox^.NewList(ListItems);
     Insert(ListBox);

     R.Assign(8, 10, 22, 11);
     Insert(New(PLabel, Init(R, '~S~tart Address', Control)));

     SelectNext(False);
end;

{******}

procedure TASMAss2Dialog.HandleEvent(var Event: TEvent);

begin
     (*---
          if Event.What and evMessage <> 0 then
            case Event.Command of
            end;    --*)

    inherited HandleEvent(Event);

    (*---
         if Event.What and evMessage <> 0 then
           case Event.Command of
           end;    --*)

end;

{*** TASMAss3Dialog ***}

constructor TASMAss3Dialog.Init;

var R       : TRect;
    Control : PView;

begin
     R.Assign(13, 3, 66, 19);
     inherited Init(R, 'ASM Assistant 3/4');
     Options:= Options or ofCenterX or ofCenterY;
     HelpCtx:= hcFileNewAssistant3;

     R.Assign(7, 2, 46, 5);
     Control:= New(PStaticText, Init(R, 'Select which segments you would like'+
                                        ' ASM Assistant to automatically insert'+
                                        ' into your assembler project'));
     Insert(Control);

     R.Assign(2, 2, 3, 3);
     Control:= New(PColouredText, Init(R, 'A', $74));
     Insert(Control);

     R.Assign(3, 3, 4, 4);
     Control:= New(PColouredText, Init(R, 'S', $79));
     Insert(Control);

     R.Assign(4, 4, 5, 5);
     Control:= New(PColouredText, Init(R, 'M', $7E));
     Insert(Control);

     R.Assign(50, 2, 51, 3);
     Control:= New(PColouredText, Init(R, 'A', $74));
     Insert(Control);

     R.Assign(49, 3, 50, 4);
     Control:= New(PColouredText, Init(R, 'S', $79));
     Insert(Control);

     R.Assign(48, 4, 49, 5);
     Control:= New(PColouredText, Init(R, 'M', $7E));
     Insert(Control);

     R.Assign(36, 12, 46, 14);
     Control:= New(PButton, Init(R, '~N~ext >>', cmOK, bfDefault));
     Control^.HelpCtx:= hcNext;
     Insert(Control);

     R.Assign(6, 12, 16, 14);
     Control:= New(PButton, Init(R, '~C~ancel', cmCancel, bfNormal));
     Control^.HelpCtx:= hcCancel;
     Insert(Control);

     R.Assign(21, 12, 31, 14);
     Control:= New(PButton, Init(R, '~H~elp', cmHelp, bfNormal));
     Control^.HelpCtx:= hcFileNewAssistant3;
     Insert(Control);

     R.Assign(8, 7, 46, 10);
     CheckBox:= New(PCheckboxes, Init(R, NewSItem('.~t~ext (main code segment)',
                                         NewSItem('.~d~ata (initialised data)',
                                         NewSItem('.~b~ss  (uninitialised data)',
                                         Nil)))));
     CheckBox^.Options:= CheckBox^.Options or ofFramed;
     Insert(CheckBox);

     R.Assign(8, 6, 17, 7);
     Insert(New(PLabel, Init(R, '~S~egments', Control)));

     SelectNext(False);
end;

{******}

procedure TASMAss3Dialog.HandleEvent(var Event: TEvent);

begin

     (*---
          if Event.What and evMessage <> 0 then
            case Event.Command of
            end;    --*)

     inherited HandleEvent(Event);

     (*---
          if Event.What and evMessage <> 0 then
            case Event.Command of
            end;    --*)

end;

{*** TASMAss4Dialog ***}

constructor TASMAss4Dialog.Init;

var R       : TRect;
    Control : PView;

begin
     R.Assign(20, 6, 60, 15);
     inherited Init(R, 'ASM Assistant 4/4');
     Options:= Options or ofCenterX or ofCenterY;
     HelpCtx:= hcFileNewAssistant4;

     R.Assign(7, 2, 33, 5);
     Control:= New(PStaticText, Init(R, 'ASM Assistant will now create your '+
                                        'assembler project'));
     Insert(Control);

     R.Assign(2, 2, 3, 3);
     Control:= New(PColouredText, Init(R, 'A', $74));
     Insert(Control);

     R.Assign(3, 3, 4, 4);
     Control:= New(PColouredText, Init(R, 'S', $79));
     Insert(Control);

     R.Assign(4, 4, 5, 5);
     Control:= New(PColouredText, Init(R, 'M', $7E));
     Insert(Control);

     R.Assign(37, 2, 38, 3);
     Control:= New(PColouredText, Init(R, 'A', $74));
     Insert(Control);

     R.Assign(36, 3, 37, 4);
     Control:= New(PColouredText, Init(R, 'S', $79));
     Insert(Control);

     R.Assign(35, 4, 36, 5);
     Control:= New(PColouredText, Init(R, 'M', $7E));
     Insert(Control);

     R.Assign(23, 6, 33, 8);
     Control:= New(PButton, Init(R, '~F~inish', cmOK, bfDefault));
     Control^.HelpCtx:= hcFinish;
     Insert(Control);

     R.Assign(6, 6, 16, 8);
     Control:= New(PButton, Init(R, '~C~ancel', cmCancel, bfNormal));
     Control^.HelpCtx:= hcCancel;
     Insert(Control);

     SelectNext(False);
end;

{******}

end.