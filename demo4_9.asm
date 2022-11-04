	;
	; Music demo with drums #9
	;
	; by Óscar Toledo G.
	; https://nanochess.org/
	;
	; Creation date: Jun/07/2022.
	;

	PROCESSOR 6502
	INCLUDE "vcs.h"

MUSIC1:	EQU $80

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
	; Joystick 1 button launches music
	;
	LDA INPT4	; Read joystick 1 button.
	BMI L1		; Jump if not pressed.
	LDA MUSIC1	; Already playing music?
	BNE L1		; Yes, jump.
	LDA #16*16-1	; 16 notes at 16 frames each one.
	STA MUSIC1
L1:

	;
	; This code plays the music.
	;
	LDA MUSIC1	; Read music counter.
	BEQ L2		; Jump if zero.
	TAY
	EOR #$FF
	LSR
	LSR
	LSR
	LSR
	TAX
	LDA music_table,X
	STA AUDF1	; Counter directly to frequency.
	TYA
	LSR
	AND #7
	STA AUDV1
	LDA #12		; Pure sound.
	STA AUDC1

	LDA MUSIC1	; Get music counter
	AND #$3F	; Modulo 64 (each 4 notes)
	CMP #$30	; First note?
	BCC L4		; No, jump.
	AND #$0F	; Modulo 16 (first note duration)
	LSR		; Divide by two.
	STA AUDV0	; Slowly decreasing volume.
	LDA #7		; Frequency similar to drum.
	STA AUDF0
	LDA #8		; White noise.
	STA AUDC0
	JMP L5

L4:	LDA #0
	STA AUDV0
L5:

	DEC MUSIC1
	JMP L3

L2:	LDA #0
	STA AUDV0	; Turn off sound channel 0.
	STA AUDV1	; Turn off sound channel 1.
L3:

WAIT_FOR_BOTTOM:
	LDA INTIM	; Read timer
	BNE WAIT_FOR_BOTTOM	; Branch if not zero.
	STA WSYNC	; Resynchronize on last border scanline

	JMP SHOW_FRAME

music_table:
	.byte $11	; D4
	.byte $11	; D4
	.byte $08	; D5
	.byte $08	; D5
	.byte $0E	; F4
	.byte $06	; F5#
	.byte $11	; D4
	.byte $08	; D5
	.byte $15	; A3#
	.byte $15	; A3#
	.byte $0a	; A4#
	.byte $08	; D5
	.byte $17	; A3
	.byte $17	; A3
	.byte $0b	; A4
	.byte $08	; D5

	ORG $FFFC
	.word START
	.word START
