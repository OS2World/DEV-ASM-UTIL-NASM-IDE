; Information
; ßßßßßßßßßßß
;
;  Program Title : NASM-IDE Copper Bars Demo
;  External name : BAR.COM
;  Version       : 1.0
;  Start date    : 18/12/1997
;  Last update   : 18/12/1997
;  Author        : Rob Anderton
;  Copyright     : (c)1997 Rob Anderton
;  Description   : An example of a copper bars effect programmed using
;                  NASM-IDE 1.1 and NASM 0.95.
;
;                  Based on code by Patch (hamell@rigel.cs.pdx.edu)
;                  (written using TASM) dated 4/9/93.


[BITS 16]                    ; Set 16 bit code generation
[ORG 0x0100]                 ; Set code start address to 100h (COM file)

; Variables are at the end of this file

[SECTION .text]              ; Text section containing code 

START:   mov  ax, $0013      ; Set 320x200x256 VGA mode 13h
         int  $10

         in   al, $21        ; Get IRQ mask
         mov  [IRQSave], al  ; Save it
         mov  al, 11111101b  ; Mask all but keyboard off
         out  $21, al        ; Set new IRQ mask
         in   al, $0A1       ; Get NMI mask
         mov  [NMISave], al  ; Save it
         mov  al, 11111111b  
         out  $0A1, al       ; Set new NMI mask

         mov  dx, $03C8
         mov  al, 01h
         out  dx, al
         xor  al, al
         inc  dx
         out  dx, al
         out  dx, al
         out  dx, al

         mov  ax, $0A000
         mov  es, ax

         xor  di, di
         mov  ax, $0101
         mov  cx, 32000
         cld
         rep  stosw

         push ds
         pop  es
         mov  bx, BarLine

STARTBAR:

         cli                 ; Don't poll keyboard
         mov  si, Palette    ; Set up pointer
         mov  bp, $01        ; Bar number = 1

PALSETUP:

         push bp
         mov  di, [bx]
         mov  al, [SinTable + di] ; Top bar line

         mov  di, BarPal
         dec  al             ; Decrement for 0th index element
         xor  ah, ah         ; Clear high byte
         mov  cx, ax
         shl  ax, 1
         add  ax, cx
         add  di, ax
         add  di, ax
         mov  bp, BarPriority           
         add  bp, cx            ; Set to proper spot in priority check
         mov  cx, [BarHeight]

CHECKLINE:

         cmp    BYTE [bp], $00  ; Is the line empty?
         jne    NODRAWLINE      ; If not, jump
         mov    BYTE [bp], $01  ; It's full now
         movsw
         movsb
         sub    si, 3
         movsw
         movsb
         jmp    NEXTPRIORITY

NODRAWLINE:

         add  si, 3          ; Increment palette pointer
         add  di, 6          ; Increment bar palette

NEXTPRIORITY:

         inc  bp             ; Next priority line
         loop CHECKLINE

BARSPOT:

         add  WORD [bx], $03    ; Increment table index
         cmp  WORD [bx], 359    ; End of table?
         jle  NEXTBAR

RESETBARSPOT:

         mov  WORD [bx], $00    ; reset table index

NEXTBAR:

         pop  bp                ; Restore bar num
         inc  bx                ; Next bar line address
         inc  bx                ; Word size = + 2
         inc  bp                ; Increment bar counter

         cmp  bp, [BarCount]    ; Bar count at max?
         jle  PALSETUP          ; If <= , go back

         mov  si, BarPal
         mov  cx, 400

         mov  dx, $03DA         ; Setup Input Status 1 reg

VRETRACE:

         in   al, dx
         test al, 00001000b     ; Test bit 3, vertical retrace
         jnz  VRETRACE          ; If active, go back

VNORETRACE:

         in   al, dx
         test al, 00001000b     ; Test bit 3, vertical retrace
         jz   VNORETRACE        ; If active, go back

PALDUMP:

         mov   al, $01
         mov   dx, $03C8
         out   dx, al
         inc   dx
         outsb                  ; Dump it out
         outsb
         mov   dx, $03DA

PUCK1:

         in   al,dx
         test al, 00000001b
         jz   PUCK1

         mov  dx, $03C9
         outsb

         mov  dx, $03DA          ; Setup Input Status 1 reg

HRETRACE:

         in   al, dx
         test al, 00000001b      ; Test bit 1, horizontal retrace
         jnz  HRETRACE           ; If not active, go back

HNORETRACE:

         in   al, dx
         test al, 00000001b      ; Test bit 1, horizontal retrace
         jz   HNORETRACE         ; If active, go back;

         mov  dx, $03DA
         loop PALDUMP

         mov  di, BarPriority
         mov  cx, 100            ; 100 of them WORD sized
         xor  ax, ax             ; AH = 0, AL = 0
         rep  stosw              ; Zero them all out

         mov  di, BarPal
         mov  cx, 600
         xor  ax, ax
         rep  stosw

         sub  bx, [BarCount]      ; Reset bar line address
         sub  bx, [BarCount]      ; Twice for word size

         sti                      ; Poll keyboard
         mov  ah, $01
         int  $16
         jnz  EXIT
         jmp  STARTBAR

EXIT:

         mov  al, [IRQSave]       ; Get old IRQ mask
         out  $21, al             ; Restore IRQ mask
         mov  al, [NMISave]       ; Get old NMI mask
         out  $0A1, al            ; Restore NMI mask
         mov  ax, $0003
         int  $10
         mov  ax, $4C00
         int  $21


[SECTION .data]    ; Initialised variables

; SinTable - holds top to bottom and bottom to top palette values

SinTable  db    1,   1,   1,   1,   1,   1,   1,   1,   1,   2,   2,   2
          db    3,   3,   3,   4,   4,   5,   5,   6,   6,   7,   7,   8
          db    8,   9,  10,  11,  11,  12,  13,  14,  14,  15,  16,  17
          db   18,  19,  20,  21,  22,  23,  24,  25,  26,  27,  29,  30
          db   31,  32,  33,  35,  36,  37,  38,  40,  41,  42,  44,  45
          db   46,  48,  49,  51,  52,  54,  55,  57,  58,  60,  61,  63
          db   64,  66,  67,  69,  70,  72,  73,  75,  77,  78,  80,  81
          db   83,  84,  86,  88,  89,  91,  93,  94,  96,  97,  99, 101
          db  102, 104, 105, 107, 108, 110, 112, 113, 115, 116, 118, 119
          db  121, 122, 124, 125, 127, 128, 130, 131, 133, 134, 136, 137
          db  138, 140, 141, 143, 144, 145, 147, 148, 149, 150, 152, 153
          db  154, 155, 156, 158, 159, 160, 161, 162, 163, 164, 165, 166
          db  167, 168, 169, 170, 171, 171, 172, 173, 174, 174, 175, 176
          db  177, 177, 178, 178, 179, 179, 180, 180, 181, 181, 182, 182
          db  182, 183, 183, 183, 184, 184, 184, 184, 184, 184, 184, 184
          db  184, 184, 184, 184, 184, 184, 184, 184, 184, 183, 183, 183
          db  182, 182, 182, 181, 181, 180, 180, 179, 179, 178, 178, 177
          db  177, 176, 175, 174, 174, 173, 172, 171, 171, 170, 169, 168
          db  167, 166, 165, 164, 163, 162, 161, 160, 159, 158, 156, 155
          db  154, 153, 152, 150, 149, 148, 147, 145, 144, 143, 141, 140
          db  139, 137, 136, 134, 133, 131, 130, 128, 127, 125, 124, 122
          db  121, 119, 118, 116, 115, 113, 112, 110, 108, 107, 105, 104
          db  102, 101,  99,  97,  96,  94,  93,  91,  89,  88,  86,  84
          db   83,  81,  80,  78,  77,  75,  73,  72,  70,  69,  67,  66
          db   64,  63,  61,  60,  58,  57,  55,  54,  52,  51,  49,  48
          db   47,  45,  44,  42,  41,  40,  38,  37,  36,  35,  33,  32
          db   31,  30,  29,  27,  26,  25,  24,  23,  22,  21,  20,  19
          db   18,  17,  16,  15,  14,  14,  13,  12,  11,  11,  10,   9
          db    8,   8,   7,   7,   6,   6,   5,   5,   4,   4,   3,   3
          db    3,   2,   2,   2,   1,   1,   1,   1,   1,   1,   1,   1

Palette         db       7, 7, 7                        ; gray bar start
                db      10,10,10
                db      13,13,13
                db      16,16,16
                db      19,19,19
                db      22,22,22
                db      25,25,25
                db      28,28,28
                db      31,31,31                        ; middle
                db      28,28,28
                db      25,25,25
                db      22,22,22
                db      19,19,19
                db      16,16,16
                db      13,13,13
                db      10,10,10
                db       7, 7, 7                        ; gray bar end
                db       7, 0, 0                        ; red bar start
                db      10, 0, 0
                db      13, 0, 0
                db      16, 0, 0
                db      19, 0, 0
                db      22, 0, 0
                db      25, 0, 0
                db      28, 0, 0
                db      31, 0, 0                        ; middle
                db      28, 0, 0
                db      25, 0, 0
                db      22, 0, 0
                db      19, 0, 0
                db      16, 0, 0
                db      13, 0, 0
                db      10, 0, 0
                db       7, 0, 0                        ; red bar end
                db       0, 7, 0                        ; green bar start
                db       0,10, 0
                db       0,13, 0
                db       0,16, 0
                db       0,19, 0
                db       0,22, 0
                db       0,25, 0
                db       0,28, 0
                db       0,31, 0                        ; middle
                db       0,28, 0
                db       0,25, 0
                db       0,22, 0
                db       0,19, 0
                db       0,16, 0
                db       0,13, 0
                db       0,10, 0
                db       0, 7, 0                        ; green bar end
                db       0, 0, 7                        ; blue bar start
                db       0, 0,10
                db       0, 0,13
                db       0, 0,16
                db       0, 0,19
                db       0, 0,22
                db       0, 0,25
                db       0, 0,28
                db       0, 0,31                        ; middle
                db       0, 0,28
                db       0, 0,25
                db       0, 0,22
                db       0, 0,19
                db       0, 0,16
                db       0, 0,13
                db       0, 0,10
                db       0, 0, 7                        ; blue bar end
                db       7, 7, 0                        ; yellow bar start
                db      10,10, 0
                db      13,13, 0
                db      16,16, 0
                db      19,19, 0
                db      22,22, 0
                db      25,25, 0
                db      28,28, 0
                db      31,31, 0                        ; middle
                db      28,28, 0
                db      25,25, 0
                db      22,22, 0
                db      19,19, 0
                db      16,16, 0
                db      13,13, 0
                db      10,10, 0
                db       7, 7, 0                        ; yellow bar end
                db       7, 0, 7                        ; purple bar start
                db      10, 0,10
                db      13, 0,13
                db      16, 0,16
                db      19, 0,19
                db      22, 0,22
                db      25, 0,25
                db      28, 0,28
                db      31, 0,31                        ; middle
                db      28, 0,28
                db      25, 0,25
                db      22, 0,22
                db      19, 0,19
                db      16, 0,16
                db      13, 0,13
                db      10, 0,10
                db       7, 0, 7                        ; purple bar end
                db       0, 7, 7                        ; cyan bar start
                db       0,10,10
                db       0,13,13
                db       0,16,16
                db       0,19,19
                db       0,22,22
                db       0,25,25
                db       0,28,28
                db       0,31,31                        ; middle
                db       0,28,28
                db       0,25,25
                db       0,22,22
                db       0,19,19
                db       0,16,16
                db       0,13,13
                db       0,10,10
                db       0, 7, 7                        ; cyan bar end
                db      18, 8, 1                        ; copper bar start
                db      23,13, 5
                db      28,18, 9
                db      33,23,13
                db      38,28,17
                db      43,33,21
                db      48,38,25
                db      53,43,29
                db      58,48,33                        ; middle
                db      53,43,29
                db      48,38,25
                db      43,33,21
                db      38,28,17
                db      33,23,13
                db      28,18, 9
                db      23,13, 5
                db      18, 8, 1                        ; copper bar end

BarLine         dw    175, 150, 125, 100, 75, 50, 25, 0
BarHeight       dw    17
BarCount        dw    8
BarPal          times 400 * 3 db 0
BarPriority     times 200 db 0


[SECTION .bss]     ; Uninitialised variables

IRQSave resb 1
NMISave resb 1


