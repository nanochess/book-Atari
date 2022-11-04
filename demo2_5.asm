	;
	; Playfield demo.
	;
	; by Oscar Toledo G.
	; https://nanochess.org/
	;
	; Creation date: Jun/02/2022.
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
	LDA #$28	; White.
	STA COLUPF	; Playfield color.
	LDA #$40	; Red
	STA COLUP0	; Player 0 color.
	LDA #$c0	; Green
	STA COLUP1	; Player 1 color.
	LDA #$01	; Right side of playfield is reflected.
	STA CTRLPF	

	STA WSYNC
	LDA #2		; Start of vertical retrace.
	STA VSYNC
	STA WSYNC
	STA WSYNC
	STA WSYNC
	LDA #0		; End of vertical retrace.
	STA VSYNC

	LDX #36		; Remains 36 scanlines of top border
TOP:
	STA WSYNC
	DEX
	BNE TOP
	LDA #0		; Disable blanking
	STA VBLANK

	LDX #8		; 8 scanlines
PART1:
	STA WSYNC
	LDA #$F0
	STA PF0
	LDA #$F0
	STA PF1
	LDA #$FF
	STA PF2

	DEX
	BNE PART1

	LDX #176	; 176 scanlines
PART2:
	STA WSYNC
	LDA #$10
	STA PF0
	LDA #$00
	STA PF1
	LDA #$00
	STA PF2

	DEX
	BNE PART2

	LDX #8		; 8 scanlines
PART3:
	STA WSYNC
	LDA #$F0
	STA PF0
	LDA #$FF
	STA PF1
	LDA #$3F
	STA PF2

	DEX
	BNE PART3

	LDA #2		; Enable blanking
	STA VBLANK
	LDX #30		; 30 scanlines of bottom border
BOTTOM:
	STA WSYNC
	LDA #0		; Disable playfield
	STA PF0
	STA PF1
	STA PF2

	DEX
	BNE BOTTOM

	JMP SHOW_FRAME

	ORG $FFFC
	.word START
	.word START
