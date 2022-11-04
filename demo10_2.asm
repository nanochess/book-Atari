	;
	; Rainbow sky demo
	;
	; by Óscar Toledo G.
	; https://nanochess.org/
	;
	; Creation date: Jun/16/2022.
	;

	PROCESSOR 6502
	INCLUDE "vcs.h"

FRAME:	EQU $80
TEMP0:	EQU $81

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

	LDA #$00	; Allow to read console switches.
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
	LDA #42		; Time for NTSC top border.
	STA TIM64T
	LDA #0
	STA VSYNC

	LDA #0		; Clear playfield.
	STA PF0
	STA PF1
	STA PF2

WAIT_FOR_TOP:
	LDA INTIM	; Read timer.
	BNE WAIT_FOR_TOP	; Branch if not zero.
	STA WSYNC	; Resynchronize on last border row.

	STA WSYNC
	LDA #0		; Disable blanking.
	STA VBLANK

	LDA FRAME	; Current frame counter.
	LSR		; Divide by 2.
	LSR		; Divide by 4.
	LSR		; Divide by 8.
	STA TEMP0	; Use as base offset for sky color.

	LDX #12		; 12 rows.
SKY1:
	STA WSYNC
	LDA TEMP0	; Load offset for sky color.
	AND #$1F	; Modulo 32.
	TAY		; Put in register Y.
	LDA color_bgnd,Y	; Read sky color.
	STA COLUBK	; Setup as background color.
	INC TEMP0	; Advance sky color offset.
	DEX
	BNE SKY1
	
	LDA FRAME	; Current frame counter.
	LSR		; Divide by 2.
	LSR		; Divide by 4.
	LSR		; Divide by 8.
	LSR		; Divide by 16.
	AND #$0F	; Modulo 16.
	TAX		; Put in register X.
	LDA mountains_color,X	; Read mountains color.
	STA COLUPF

	LDX #0		; Offset into playfield graphics.
MOUNTAIN1:
	STA WSYNC
	LDA mountains_pf,X	; Read mountain byte.
	STA PF0		; Setup PF0.
	INX
	LDA mountains_pf,X	; Read mountain byte.
	STA PF1		; Setup PF1.
	INX
	LDA mountains_pf,X	; Read mountain byte.
	STA PF2		; Setup PF2.
	LDA TEMP0	; Load offset for sky color.
	AND #$1F	; Modulo 32.
	TAY		; Put in register Y.
	LDA color_bgnd,Y	; Read sky color.
	STA COLUBK	; Setup as background color.
	INC TEMP0	; Advance sky color offset.
	INX		; Increase playfield offset.
	CPX #48		; Reached 16*3 bytes?
	BNE MOUNTAIN1	; No, branch back.

	LDX #164
EMPTY1:
	STA WSYNC
	DEX
	BNE EMPTY1

	STA WSYNC
	LDA #2
	STA VBLANK

	LDA #35		; Time for NTSC bottom border.
	STA TIM64T

	INC FRAME

WAIT_FOR_BOTTOM:
	LDA INTIM	; Read timer.
	BNE WAIT_FOR_BOTTOM	; Branch if not zero.
	STA WSYNC	; Resynchronize on last border row.

	JMP SHOW_FRAME

	; Colors for background.
color_bgnd:
	.byte $68,$66,$58,$56,$48,$46,$38,$36,$28,$26,$f8,$f6
	.byte $b8,$b6,$ae,$ac,$aa,$a8,$a6,$9e,$9c,$9a,$98,$96
	.byte $94,$8c,$8a,$88,$86,$84,$78,$76

	; Colors for mountains.
mountains_color:
	.byte $c8,$c6,$c4,$c2
	.byte $c0,$c0,$c0,$c0
	.byte $c2,$c4,$c6,$c8
	.byte $ca,$cc,$ce,$ce

mountains_pf:
; mode: symmetric repeat line-height 1
	.byte $80,$00,$00 ;|   X                | (  0)
	.byte $C0,$80,$00 ;|  XXX               | (  1)
	.byte $E0,$C0,$00 ;| XXXXX              | (  2)
	.byte $F0,$E0,$00 ;|XXXXXXX             | (  3)
	.byte $F0,$F0,$80 ;|XXXXXXXX           X| (  4)
	.byte $F0,$F8,$C1 ;|XXXXXXXXX   X     XX| (  5)
	.byte $F0,$FD,$E3 ;|XXXXXXXXXX XXX   XXX| (  6)
	.byte $F0,$FF,$F7 ;|XXXXXXXXXXXXXXX XXXX| (  7)
	.byte $F0,$FF,$FF ;|XXXXXXXXXXXXXXXXXXXX| (  8)
	.byte $F0,$FF,$FF ;|XXXXXXXXXXXXXXXXXXXX| (  9)
	.byte $F0,$FF,$FF ;|XXXXXXXXXXXXXXXXXXXX| ( 10)
	.byte $F0,$FF,$FF ;|XXXXXXXXXXXXXXXXXXXX| ( 11)
	.byte $F0,$FF,$FF ;|XXXXXXXXXXXXXXXXXXXX| ( 12)
	.byte $F0,$FF,$FF ;|XXXXXXXXXXXXXXXXXXXX| ( 13)
	.byte $F0,$FF,$FF ;|XXXXXXXXXXXXXXXXXXXX| ( 14)
	.byte $F0,$FF,$FF ;|XXXXXXXXXXXXXXXXXXXX| ( 15)

	ORG $FFFC
	.word START
	.word START
