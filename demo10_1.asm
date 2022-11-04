	;
	; 48 pixel kernel demo
	;
	; by Óscar Toledo G.
	; https://nanochess.org/
	;
	; Creation date: Jun/16/2022.
	;

	PROCESSOR 6502
	INCLUDE "vcs.h"

digits:	EQU $80		; 12 bytes for each digit address.
score:	EQU $8C		; Current score in BCD (3 bytes).
temp1:	EQU $91
temp2:	EQU $92

SCORE_COLOR	= $38

	ORG $F000
START:
	SEI
	CLD
	LDX #$FF
	TXS
	LDA #$00
CLEAR:
	STA 0,X
	DEX
	BNE CLEAR

	LDA #$00	; Allow to read console switches
	STA SWACNT
	STA SWBCNT

SHOW_FRAME:
	LDA #$88
	STA COLUBK

	STA WSYNC
	LDA #2
	STA VSYNC
	STA WSYNC
	STA WSYNC
	STA WSYNC
	LDA #42		; Time for NTSC top border
	STA TIM64T
	LDA #0
	STA VSYNC

	; Convert each digit of the score to the...
	; ...addresses of each digit graphics.
	LDX #digits
	LDA score
	JSR two_digits
	LDA score+1
	JSR two_digits
	LDA score+2
	JSR two_digits


WAIT_FOR_TOP:
	LDA INTIM	; Read timer
	BNE WAIT_FOR_TOP	; Branch if not zero.
	STA WSYNC	; Resynchronize on last border row

	STA WSYNC
	LDA #0		; Disable blanking
	STA VBLANK

	LDX #183
VISIBLE:
	STA WSYNC
	DEX
	BNE VISIBLE

        LDA #$01            
        LDX #0              
        STA WSYNC           ; 3
        STA HMOVE           ; 6
        STA CTRLPF          ; 9
        STX ENABL           ; 12
        STX GRP0            ; 15
        STX GRP1            ; 18
        STX ENAM0           ; 21
        STX ENAM1           ; 24
        STX COLUBK          ; 27
        LDA #SCORE_COLOR    ; 29
        STA COLUP0          ; 32
        STA COLUP1          ; 35
        LDA #$03            ; 37 Three copies together
        LDX #$f0            ; 39
        STX RESP0           ; 42
        STX RESP1           ; 45
        STX HMP0            ; 48
        STA NUSIZ0          ; 51
        STA NUSIZ1          ; 54
        LSR                 ; 56
        STA VDELP0          ; 59
        STA VDELP1          ; 61
        STA WSYNC           ; 3
        STA HMOVE           ; 6
        LDA #6              ; 8
        STA temp2           ; 11
mp1:    LDY temp2           ; 14/67
        LDA (digits),y      ; 19/72
        STA GRP0            ; 22/75
        STA WSYNC           ; 3
        LDA (digits+2),y    ; 8
        STA GRP1            ; 11
        LDA (digits+4),y    ; 16
        STA GRP0            ; 19
        LDA (digits+6),y    ; 24
        STA temp1           ; 27
        LDA (digits+8),y    ; 32
        TAX                 ; 34
        LDA (digits+10),y   ; 39
        TAY                 ; 41
        LDA temp1           ; 44
        STA GRP1            ; 47
        STX GRP0            ; 50
        STY GRP1            ; 53
        STA GRP0            ; 56
        DEC temp2           ; 61
        BPL mp1             ; 63
mp3:
        ; Detect code isn't going across pages
        IF (mp1&$ff00)!=(mp3&$ff00)
		ECHO "Error: Page crossing"
		ERR
        ENDIF

	STA WSYNC
	LDA #2
	STA VBLANK

	LDA #35		; Time for NTSC bottom border
	STA TIM64T

        LDY #0              
        STY VDELP0          
        STY VDELP1          
	STY GRP0
	STY GRP1

	SED		; Set decimal mode.
	LDA score+2	; Get lower two digits.
	CLC		; Clear carry.
	ADC #1		; Add one.
	STA score+2	; Store lower two digits.
	LDA score+1	; Get middle two digits.
	ADC #0		; Add carry.
	STA score+1	; Store middle two digits.
	LDA score	; Get upper two digits.
	ADC #0		; Add carry.
	STA score	; Store upper two digits.
	CLD		; Clear decimal mode.

WAIT_FOR_BOTTOM:
	LDA INTIM	; Read timer
	BNE WAIT_FOR_BOTTOM	; Branch if not zero.
	STA WSYNC	; Resynchronize on last border row

	JMP SHOW_FRAME

	; Separate two BCD digits
two_digits:
	PHA
	LSR		; Shift right 4 bits.
	LSR
	LSR
	LSR
	JSR one_digit	; Process upper digit.
	PLA
one_digit:
	AND #$0F	; Process lower digit.
	ASL		; x2
	ASL		; x4
	ASL		; x8
	STA 0,X		; Store lower byte of address.
	INX		; Advance one byte.
	LDA #numbers_bitmaps>>8	; High byte of address.
	STA 0,X		; Store byte.
	INX		; Advance one byte.
	RTS

	ORG $fe00

numbers_bitmaps:
	.byte $fe,$86,$86,$86,$82,$82,$fe,$00	; 0
	.byte $30,$30,$30,$30,$10,$10,$10,$00	; 1
	.byte $fe,$c0,$c0,$fe,$02,$02,$fe,$00	; 2
	.byte $fe,$06,$06,$fe,$02,$02,$fe,$00	; 3
	.byte $06,$06,$06,$fe,$82,$82,$82,$00	; 4
	.byte $fe,$06,$06,$fe,$80,$80,$fe,$00	; 5
	.byte $fe,$c6,$c6,$fe,$80,$80,$fe,$00	; 6
	.byte $06,$06,$06,$02,$02,$02,$fe,$00	; 7
	.byte $fe,$c6,$c6,$fe,$82,$82,$fe,$00	; 8
	.byte $fe,$06,$06,$fe,$82,$82,$fe,$00	; 9

	ORG $FFFC
	.word START
	.word START
