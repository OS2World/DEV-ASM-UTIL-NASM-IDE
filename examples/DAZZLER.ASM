; Information
; ßßßßßßßßßßß
;
;  Program Title : NASM-IDE Dazzler Demo
;  External name : DAZZLER.COM
;  Version       : 1.0
;  Start date    : 14/11/1997
;  Last update   : 14/11/1997
;  Author        : Rob Anderton
;  Description   : An example of text mode programming using NASM-IDE 1.1
;                  and NASM 0.95.
;
;  Notes         : Set output mode to 'COM executable file' and then
;                  assemble and run to be dazzled!

[BITS 16]                    ; Set 16 bit code generation
[ORG 0x0100]                 ; Set code start address to 100h (COM file)

[SECTION .text]              ; Code segment

BEGIN:
       mov   ax, $0001       ; Set video mode 1
       int   $10
       mov   ax, $0B800       ; Set ES to start of video page 0
       mov   es, ax         

                             ; Put the pattern into video page 0 and 1

       mov   al, 219         ; Character is a solid block
       mov   dx, 0           ; Initialize row counter

RLOOP:

       mov   di, dx          ; DI = row
       mov   ah, dl          ; colour = row
       mov   cl, 4           ; 2 ^ 4 = 16
       sal   di, cl          ; DI = 16 * row
       mov   cx, di          ; Save in CX
       sal   di, 1           ; DI = 32 * row
       sal   di, 1           ; DI = 64 * row
       add   di, cx          ; DI = (64+16=80) * row
       mov   cx, di          ; CX = 80 * row
       mov   bx, 0           ; Initialise the column counter

CLOOP:

       inc   ah              ; Increment colour number
       and   ah, 15          ; Valid colours are 0-15 only
       mov   di, cx          ; DI = 80 * row
       add   di, bx          ; DI = 80 * row + column
       stosw                 ; Move word to page 0
       add   di, 2046
       stosw                 ; Move word to page 1
       mov   di, cx          ; DI = 80 * row
       add   di, 78          ; DI = 80 * row + 78
       sub   di, bx          ; DI = 80 * row - column + 78
       stosw                 ; Move word to page 0
       add   di, 2046
       stosw                 ; Move word to page 1
       mov   di, cx          ; DI = 80 * row
       neg   di              ; DI = -80 * row
       add   di, 1920        ; DI = -80 * row + 1920
       add   di, bx          ; DI = -80 * row + column + 1920
       stosw                 ; Move word to page 0
       add   di, 2046
       stosw                 ; Move word to page 1
       mov   di, cx          ; DI = 80 * row
       neg   di              ; DI = -80 * row
       add   di, 1998        ; DI = -80 * row + 1998
       sub   di, bx          ; DI = -80 * row - column + 1998
       stosw                 ; Move word to page 0
       add   di, 2046
       stosw                 ; Move word to page 1
       add   bx, 2           ; Increment counter
       cmp   bx, 40          ; Columns done?
       je    CHKROW          ; Yes...check rows
       jmp   CLOOP           ; No....check column

CHKROW:

       inc   dx              ; Increment row
       cmp   dx, 13          ; Rows done?
       je    MOVEIT          ; Yes..move the patterns
       jmp   RLOOP           ; No...Next row

                             ; Increment or decrement the value of bits
                             ; 0-3 for every attribute byte on alternating
                             ; video pages 0 and 1 and swap active page

MOVEIT:

       mov   bx, 2049        ; BX = page offset
       mov   si, 0           ; Set flag to no swap

MLOOP:

       cmp   bx, 2049        ; Page 1 displayed ?
       je    PG0             ; Yes..display page 0
       mov   bx, 2049        ; No..display page 1
       mov   al, 1           ; Set page 1
       jmp   SETPG

PG0:
       mov   bx, 1           ; Set page offset
       mov   al, 0           ; Set page 0

SETPG:

       mov   di, bx
       mov   cx, 1000        ; 1000 bytes to move

ILOOP:

       mov   dh, BYTE[ES:DI] ; Get attribute byte
       
INCDEC:

       inc   dh              ; Modify attribute byte (self modifying here)
       jns   NOTNEG          ; Sign is plus
       mov   dh, 15          ; Sign is negative

NOTNEG:

       and   dh, 15          ; Valid values are 0-15
       mov   BYTE[ES:DI], DH ; Place in the new attribute
       inc   di              ; Point past the character
       inc   di              ; And to the next attribute
       loop  ILOOP           ; Repeat this 1000 times
       mov   ah, 5           ; Set video page
       int   $10
       mov   CX, $0FFFF      ; Time delay (lower this value for more speed)

DELAY:

       loop  DELAY           ; And wait

                             ; Check for keypress - if a space, swap the code
                             ; for inc and dec at label INCDEC - if ESC
                             ; then exit.

       cmp   si, 1           ; Is flag set?
       jz    SWAP            ; Yes..swap INC/DEC code
       mov   ah, 6           ; ReadKeyboard function
       mov   dl, $0FF        ; Set DL to read
       int   $21             ; Call DOS
       cmp   al, ' '         ; Space bar hit ?
       jne   CHKESC          ; No...check for ESC key
       cmp   bx, 2049        ; Are we displaying page 1 ?
       je    SWAP            ; Yes...swap INC/DEC code
       mov   si, 1           ; No...set flag
       jmp   MLOOP           ; Continue

SWAP:

       mov   si, 0           ; Reset flag

       cmp   BYTE[INCDEC + 1], $0C6   ; Are we incrementing ?
       je    DECIT                    ; Yes..swap functions
       mov   BYTE[INCDEC + 1], $0C6   ; Change to increment
       jmp   MLOOP                    ; And redo the display

DECIT:

       mov   BYTE[INCDEC + 1], $0CE   ; Change to decrement
       jmp   MLOOP                    ; And redo the display

CHKESC:

       cmp   al, 27           ; ESC key pressed ?
       jne   MLOOP            ; No..redo the display
       mov   ax, $0003        ; Yes..set to 80 column display
       int   $10              ; Call BIOS
       mov   ax, $4C00        ; Prepare to exit
       int   $21              ; Terminate programBad command or file name
