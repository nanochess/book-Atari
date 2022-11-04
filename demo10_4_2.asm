	;
	; 8K ROM demo (bank 1)
	;
	; by Óscar Toledo G.
	; https://nanochess.org/
	;
	; Creation date: Jun/17/2022.
	;

	PROCESSOR 6502
	INCLUDE "vcs.h"

EFFECT1	= $0080

	; Bank switching
BANK0	= $FFF8		; Bank 0
BANK1	= $FFF9		; Bank 1

	ORG $F000
START:
	STA BANK1
	SEI
	CLD
	JMP START2

ALT_CODE:
	STA BANK0
	NOP
	NOP
	NOP

EXT_BANK:
	STA BANK1
	JMP SHOW_FRAME

START2:
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

WAIT_FOR_TOP:
	LDA INTIM	; Read timer
	BNE WAIT_FOR_TOP	; Branch if not zero.
	STA WSYNC	; Resynchronize on last border row

	STA WSYNC
	LDA #0		; Disable blanking
	STA VBLANK

	LDX #192
VISIBLE:
	STA WSYNC
	DEX
	BNE VISIBLE

	STA WSYNC
	LDA #2
	STA VBLANK

	LDA #35		; Time for NTSC bottom border
	STA TIM64T

	JMP ALT_CODE

	ORG $FFFC
	.word START
	.word START
