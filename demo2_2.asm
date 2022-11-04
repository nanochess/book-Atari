	;
	; Players demo
	;
	; by Oscar Toledo G.
	; https://nanochess.org/
	;
	; Creation date: Jun/01/2022.
	;

	PROCESSOR 6502
	INCLUDE "vcs.h"

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

SHOW_FRAME:
	LDA #$88	; Blue.
	STA COLUBK	; Background color.
	LDA #$0F	; White.
	STA COLUP0	; Player 0 color.
	LDA #$00	; Black.
	STA COLUP1	; Player 1 color.

	STA WSYNC
	LDA #2		; Start of vertical retrace.
	STA VSYNC
	STA WSYNC
	STA WSYNC
	STA WSYNC
	LDA #0		; End of vertical retrace.
	STA VSYNC

	; Player 0 and 1 horizontal position
	STA WSYNC	; Cycle 3
	NOP		; 5
	NOP		; 7
	NOP		; 9
	NOP		; 11
	NOP		; 13
	NOP		; 15
	NOP		; 17
	NOP		; 19
	NOP		; 21
	NOP		; 23
	NOP		; 25
	STA RESP0	; 28
	NOP		; 30
	NOP		; 32
	NOP		; 34
	NOP		; 36
	NOP		; 38
	NOP		; 40
	NOP		; 42
	NOP		; 44
	NOP		; 46
	STA RESP1	; 48

	LDX #35		; Remains 35 scanlines of top border
TOP:
	STA WSYNC
	DEX
	BNE TOP
	LDA #0		; Disable blanking
	STA VBLANK

	LDX #92		; 92 scanlines in blue
VISIBLE:
	STA WSYNC
	DEX
	BNE VISIBLE

	STA WSYNC	; One scanline
	LDA #$3c	; 
	STA GRP0
	STA GRP1

	STA WSYNC	; One scanline
	LDA #$42	; 
	STA GRP0
	STA GRP1

	STA WSYNC	; One scanline
	LDA #$a5	; 
	STA GRP0
	STA GRP1

	STA WSYNC	; One scanline
	LDA #$81	; 
	STA GRP0
	STA GRP1

	STA WSYNC	; One scanline
	LDA #$a5	; 
	STA GRP0
	STA GRP1

	STA WSYNC	; One scanline
	LDA #$99	; 
	STA GRP0
	STA GRP1

	STA WSYNC	; One scanline
	LDA #$42	; 
	STA GRP0
	STA GRP1

	STA WSYNC	; One scanline
	LDA #$3c	; 
	STA GRP0
	STA GRP1

	STA WSYNC	; One scanline
	LDA #$00	; 
	STA GRP0
	STA GRP1

	LDA #$F8	; Sand color
	STA COLUBK

	LDX #91		; 91 scanlines
VISIBLE2:
	STA WSYNC
	DEX
	BNE VISIBLE2

	LDA #2		; Enable blanking
	STA VBLANK
	LDX #30		; 30 scanlines of bottom border
BOTTOM:
	STA WSYNC
	DEX
	BNE BOTTOM

	JMP SHOW_FRAME

	ORG $FFFC
	.word START
	.word START
