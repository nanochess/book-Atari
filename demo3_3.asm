	;
	; Horizontal/vertical positioning demo (Chapter 3 section 3)
	;
	; by Oscar Toledo G.
	; https://nanochess.org/
	;
	; Creation date: Jun/04/2022.
	;

	PROCESSOR 6502
	INCLUDE "vcs.h"

XPOS	= $0080		; Current X position
XDIR    = $0081         ; Current X direction
XPOS2   = $0082		; Current X position (2)
YPOS2	= $0083		; Current Y position (2)

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
	LDA #1
	STA XPOS2
	LDA #20
	STA YPOS2

SHOW_FRAME:
	LDA #$88	; Blue.
	STA COLUBK	; Background color.
	LDA #$0F	; White.
	STA COLUP0	; Player 0 color.
	LDA #$cF	; Green.
	STA COLUP1	; Player 1 color.

	STA HMCLR	; Clear horizontal motion registers

	STA WSYNC
	LDA #2		; Start of vertical retrace.
	STA VSYNC
	STA WSYNC
	STA WSYNC
	STA WSYNC
	LDA #42		; Time for NTSC top border
	STA TIM64T
	LDA #0		; End of vertical retrace.
	STA VSYNC

	LDA XPOS	; Desired X position
	LDX #0		; Player 0
	JSR x_position

	LDA XPOS2	; Desired X position
	LDX #1		; Player 1
	JSR x_position

	STA WSYNC	; Wait for scanline start
	STA HMOVE	; Write HMOVE, only can be done
			; just after STA WSYNC.

WAIT_FOR_TOP:
	LDA INTIM	; Read timer
	BNE WAIT_FOR_TOP	; Branch if not zero.
	STA WSYNC	; Resynchronize on last border scanline

	STA WSYNC
	LDA #0		; Disable blanking
	STA VBLANK

	LDX #183	; 183 scanlines in blue.
	LDY YPOS2	; Y position of fly.
SPRITE1:
	STA WSYNC	; Synchronize with scanline.
	LDA #0		; A = $00 no graphic.
	DEY		; Decrement Y.
	CPY #$F8	; Y >= $f8? (carry = 1)
	BCC L3		; No, jump if carry clear.
	LDA FLY_BITMAP-$F8,Y	; Load byte of graphic.
L3:	STA GRP1	; Update GRP1.
	DEX		; Decrease X.
	BNE SPRITE1	; Repeat until zero.

	LDX #9
	LDY #0
SPRITE0:
	STA WSYNC	; Synchronize with scanline.
	LDA #0		; A = $00 no graphic.
	DEY		; Decrement Y.
	CPY #$F8	; Y >= $f8? (carry = 1)
	BCC L4		; No, jump if carry clear.
	LDA SHIP_BITMAP-$F8,Y	; Load byte of graphic.
L4:	STA GRP0	; Update GRP0.
	DEX		; Decrease X.
	BNE SPRITE0	; Repeat until zero.

	LDA #2		; Enable blanking
	STA VBLANK
	LDX #30		; 30 scanlines of bottom border
BOTTOM:
	STA WSYNC
	DEX
	BNE BOTTOM

	; Move the ship
	LDA XPOS	; A = XPOS
	CLC		; Clear carry (becomes zero)
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

	; Move the fly
	LDA XPOS2	; A = XPOS2
	CLC		; Clear carry (becomes zero)
	ADC #1		; A = A + 1 + Carry
	CMP #153	; Reached X-position 153?
	BNE L5		; Branch if Not Equal
	LDA #0		; If equal, reset to zero
L5:	STA XPOS2	; XPOS2 = A

	AND #3		; Get modulo 4 of XPOS2
	ADC #20		; Add base Y-coordinate
	STA YPOS2	; YPOS2 = A

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

FLY_BITMAP:
	.byte %00000000
	.byte %01100000
	.byte %11100100
	.byte %01101000
	.byte %00010000
	.byte %00101100
	.byte %00101110
	.byte %00000100

SHIP_BITMAP:
	.byte %00100100
	.byte %11111111
	.byte %01100110
	.byte %00100100
	.byte %00111100
	.byte %00011000
	.byte %00011000
	.byte %00011000

	ORG $FFFC
	.word START
	.word START
