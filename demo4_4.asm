	;
	; Sound effect demo #4
	;
	; by Óscar Toledo G.
	; https://nanochess.org/
	;
	; Creation date: Jun/06/2022.
	;

	PROCESSOR 6502
	INCLUDE "vcs.h"

EFFECT1:	EQU $80

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

WAIT_FOR_TOP:
	LDA INTIM	; Read timer
	BNE WAIT_FOR_TOP	; Branch if not zero.
	STA WSYNC	; Resynchronize on last border scanline

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

	;
	; Joystick 1 button launches sound effect
	;
	LDA INPT4	; Read joystick 1 button.
	BMI L1		; Jump if not pressed.
	LDA EFFECT1	; Already playing effect 1?
	BNE L1		; Yes, jump.
	LDA #10		; Counter for effect 1.
	STA EFFECT1
L1:

	;
	; This code plays the sound effect.
	;
	LDA EFFECT1	; Read effect 1 counter.
	BEQ L2		; Jump if zero.
	DEC EFFECT1	; Count towards zero.
	CLC
	ADC #2		; Volume based on counter (12-2)
	STA AUDV0
	LSR		; Logical shift to right (1 bit)
	STA AUDF0
	LDA #4		; Pure tone.
	STA AUDC0
	JMP L3

L2:	LDA #0
	STA AUDV0	; Turn off sound.
L3:

WAIT_FOR_BOTTOM:
	LDA INTIM	; Read timer
	BNE WAIT_FOR_BOTTOM	; Branch if not zero.
	STA WSYNC	; Resynchronize on last border scanline

	JMP SHOW_FRAME

	ORG $FFFC
	.word START
	.word START
