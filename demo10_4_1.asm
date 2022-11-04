	;
	; 8K ROM demo (bank 0)
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

	ORG $D000

START:
	STA BANK1
	NOP
	NOP
	NOP
	NOP
	NOP

ALT_CODE:
	STA BANK0
	JMP KERNEL

EXT_BANK:
	STA BANK1
	NOP
	NOP
	NOP

START2:
KERNEL:
	;
	; Joystick 1 button launches sound effect
	;
	LDA INPT4	; Read joystick 1 button.
	BMI L1		; Jump if not pressed.
	LDA #10		; Counter for effect 1.
	STA EFFECT1
L1:

	;
	; This code plays the sound effect.
	;
	LDA EFFECT1	; Read effect 1 counter.
	BEQ L2		; Jump if zero.
	DEC EFFECT1	; Count towards zero.
	LDA #12		; Volume.
	STA AUDV0
	LDA #4		; Pure tone.
	STA AUDC0
	LDA #$11	; 880 hz frequency (NTSC).
	STA AUDF0
	JMP L3

L2:	LDA #0
	STA AUDV0	; Turn off sound.
L3:

WAIT_FOR_BOTTOM:
	LDA INTIM	; Read timer
	BNE WAIT_FOR_BOTTOM	; Branch if not zero.
	STA WSYNC	; Resynchronize on last border row

	JMP EXT_BANK

	ORG $DFFC
	.word START
	.word START
