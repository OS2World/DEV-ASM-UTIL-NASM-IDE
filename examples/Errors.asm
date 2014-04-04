 Information
 ßßßßßßßßßßß

  Program Title : NASM-IDE error information test
;  External name : ERRORS.COM
;  Version       : 1.0
;  Start date    : 21/12/1997
;  Last update   : 21/12/1997
;  Author        : Rob Anderton
;  Description   : A simple example error information display.
                   Written using NASM-IDE 1.1 and NASM 0.95.

;                  NOTE: This code is full of errors and will not assemble!

BITS 16]                    ; Set 16 bit code generation
[ORG x0100]                 ; Set code start address to 100h (COM file)

[SECTION .texts]              ; Section containing code

    jmp    START             ; Jump to label 'START' in .text section

END:	                     ; Define label 'END'

    mov    ax, $4C00         ; This function exits the program
    int    $21               ; and returns control to DOS.

START:	

    mov    BYTE [bss_sym], 'I   ; Reference a symbol in the .bss section
    mov    bx, [bssptr]	         ; Reference a symbol in the .data section
    mov    al, [bx]
    mov    bx, [DATAPTR]	
    mov    [bx, al
    mov    cx, 2

.LOOP:                           ; Define a local label

    mov    dx, datasym	
    mov    ah, 9
    push   cx
    int    $21
    pop    cx
    loop   .LOOP		
    mov    bx, [textptr]	
    jmp    bx


[SECTION .dataandstuff]                 ; Section containing initialised data

datasym	  db 'NASM-EDE!', 13, 10, '$'
bssptr	  dw bss_sym		
DATAPTR	  dw datasym + 5	
textptr	  dw END	        ; Pointer to a label in the .text section


[SECTION .bss                  ; Section containing unitialised data

bss_sym	  resb 1		 Reserve 1 byte of data

