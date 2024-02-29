	;
	; Horizontal positioning demo (Chapter 3 section 1)
	;
	; by Oscar Toledo G.
	; https://nanochess.org/
	;
	; Creation date: Jun/03/2022.
	;

	PROCESSOR 6502
	INCLUDE "vcs.h"

XPOS	= $0080		; Current X position
XDIR    = $0081         ; Current X direction

	ORG $F000
START:
	SEI		; Disable interrupts.
	CLD		; Clear decimal mode.
	LDX #$FF	; X = $ff
	TXS		; S = $ff
	LDA #$00	; A = $00
CLEAR:
	STA 0,X		; Clear memory.
	DEX		; Decrement X.
	BNE CLEAR	; Branch if not zero.

	LDA #76		; Center of screen
	STA XPOS
	LDA #1		; Go to right
	STA XDIR

SHOW_FRAME:
	LDA #$88	; Blue.
	STA COLUBK	; Background color.
	LDA #$0F	; White.
	STA COLUP0	; Player 0 color.

	STA HMCLR	; Clear horizontal motion registers

	STA WSYNC
	LDA #2		; Start of vertical retrace.
	STA VSYNC
	STA WSYNC
	STA WSYNC
	STA WSYNC
	LDA #0		; End of vertical retrace.
	STA VSYNC

	LDA XPOS	; Desired X position
	LDX #0		; Player 0
	JSR x_position

	STA WSYNC	; Wait for scanline start
	STA HMOVE	; Write HMOVE, only can be done
			; just after STA WSYNC.

	LDX #34		; Remains 34 scanline of top border
TOP:
	STA WSYNC
	DEX
	BNE TOP
	LDA #0		; Disable blanking
	STA VBLANK

	LDX #183	; 183 scanlines in blue
VISIBLE:
	STA WSYNC
	DEX
	BNE VISIBLE

	STA WSYNC	; One scanline
	LDA #$18	; 
	STA GRP0

	STA WSYNC	; One scanline
	LDA #$18	; 
	STA GRP0

	STA WSYNC	; One scanline
	LDA #$18	; 
	STA GRP0

	STA WSYNC	; One scanline
	LDA #$3c	; 
	STA GRP0

	STA WSYNC	; One scanline
	LDA #$24	; 
	STA GRP0

	STA WSYNC	; One scanline
	LDA #$66	; 
	STA GRP0

	STA WSYNC	; One scanline
	LDA #$ff	; 
	STA GRP0

	STA WSYNC	; One scanline
	LDA #$24	; 
	STA GRP0

	STA WSYNC	; One scanline
	LDA #$00	; 
	STA GRP0

	LDA #2		; Enable blanking
	STA VBLANK
	LDX #30		; 30 scanlines of bottom border
BOTTOM:
	STA WSYNC
	DEX
	BNE BOTTOM

	LDA XPOS	; A = XPOS
	CLC		; Clear carry (C flag in P register becomes zero)
	ADC XDIR	; A = A + XDIR + Carry
	STA XPOS	; XPOS = A
	CMP #1		; Reached minimum X-position 1?
	BEQ L1		; Branch if EQual
	CMP #153	; Reached maximum X-position 153?
	BNE L2		; Branch if Not Equal
L1:
	LDA #0		; A = 0
	SEC		; Set carry (it means no borrow for subtraction)
	SBC XDIR	; A = 0 - XDIR (reverses direction)
	STA XDIR	; XDIR = A
L2:
	JMP SHOW_FRAME

	;
	; Position an item in X
	; Input:
	;   A = X position (1-159)
	;   X = Object to position (0=P0, 1=P1, 2=M0, 3=M1, 4=BALL)
	;
	; The internal loop should fit a 256-byte page.
	;
x_position:		; Start cycle
	sta WSYNC	; 3: Start scanline synchro
	sec		; 5: Set carry (so SBC doesn't subtract extra)
	ldy $80		; 7: Eat 3 cycles
x_p1:
	sbc #15		; 10: Divide X by 15
	bcs x_p1	; 12: If the loop goes on, add 5 cycles each time
x_p2:
	tay		; 14:
	lda fine_adjust-$f1,y	; 18:
	sta HMP0,x	; 22: Fine position
	sta RESP0,x	; 26: Time of setup for coarse position.
	rts

x_position_end:

	; Detect code divided between two pages
	; Cannot afford it because it takes one cycle more
	if (x_p1 & $ff00) != (x_p2 & $ff00)
		echo "Error: Page crossing"
		err	; Force assembler error
        endif
	
	org $fef1	; Table at last page of ROM
			; Shouldn't cross page
fine_adjust:
	.byte $70	; 7px to left.
	.byte $60	; 6px to left.
	.byte $50	; 5px to left.
	.byte $40	; 4px to left.
	.byte $30	; 3px to left.
	.byte $20	; 2px to left.
	.byte $10	; 1px to left.
	.byte $00	; No adjustment.
	.byte $f0	; 1px to right.
	.byte $e0	; 2px to right.
	.byte $d0	; 3px to right.
	.byte $c0	; 4px to right.
	.byte $b0	; 5px to right.
	.byte $a0	; 6px to right.
	.byte $90	; 7px to right.

	ORG $FFFC
	.word START
	.word START
