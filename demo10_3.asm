	;
	; Road demo
	;
	; by Óscar Toledo G.
	; https://nanochess.org/
	;
	; Creation date: Jun/16/2022.
	;

	PROCESSOR 6502
	INCLUDE "vcs.h"

frame:		EQU $80
road_move:	EQU $81
car_frame:	EQU $82

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
	LDA #$98
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

	LDA #50
	LDX #1		; Player 1
	JSR x_position

	LDA #88
	LDX #2		; Missile 0 (left side of road)
	JSR x_position

	LDA #147
	LDX #4		; Ball (right side of road)
	JSR x_position

	LDA #$30	; Missiles 8px width
	STA NUSIZ0
	STA CTRLPF
	LDA #$07	; Player 1 width x4
	STA NUSIZ1

WAIT_FOR_TOP:
	LDA INTIM	; Read timer
	BNE WAIT_FOR_TOP	; Branch if not zero.
	STA WSYNC	; Resynchronize on last border row

	STA WSYNC	
	STA HMOVE	
	LDA #0		; Disable blanking
	STA VBLANK

	LDX #96
SKY1:
	STA WSYNC
	DEX
	BNE SKY1

	STA HMCLR
	LDA #$C4
	STA COLUBK
	LDA #$00
	STA COLUP1
	LDA #$02
	STA ENAM0
	STA ENABL

	LDX #(car_sprite-240)&255
	LDA frame
	AND #4
	BEQ GRASS0
	LDX #(car_sprite+16-240)&255
GRASS0:
	STX car_frame
	LDX #(car_sprite-240)>>8
	STX car_frame+1
	LDX #0
	LDY #$48
GRASS1:
	STA WSYNC
	STA HMOVE
	LDA road_color,X
	EOR road_move
	STA COLUP0
	STA COLUPF
	LDA #0
	DEY
	CPY #$F0
	BCC GRASS2
	LDA (car_frame),Y
GRASS2:	STA GRP1
	LDA road_adjust0,X
	STA HMM0
	LDA road_adjust1,X
	STA HMBL

	INX
	CPX #96
	BNE GRASS1

	STA WSYNC
	LDA #2
	STA VBLANK

	LDA #35		; Time for NTSC bottom border
	STA TIM64T

	LDA #0
	STA ENAM0
	STA ENAM1
	STA ENABL
	STA GRP1

	LDA #12		; Volume.
	STA AUDV0
	LDA #6		; Noise.
	STA AUDC0
	LDA #$18	
	STA AUDF0

	INC frame
	LDA frame
	AND #$07
	BNE M1
	LDA road_move
	EOR #$4E
	STA road_move
M1:

WAIT_FOR_BOTTOM:
	LDA INTIM	; Read timer
	BNE WAIT_FOR_BOTTOM	; Branch if not zero.
	STA WSYNC	; Resynchronize on last border row

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
	
	org $fdf1	; Table at last page of ROM
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

road_adjust0:
	.byte $30,$30,$30,$30,$30,$30,$30,$30
	.byte $20,$20,$20,$20,$20,$20,$20,$20
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$00,$10,$00,$10,$00,$10,$00
	.byte $10,$00,$00,$10,$00,$00,$10,$00
	.byte $10,$00,$00,$10,$00,$00,$10,$00
	.byte $10,$00,$00,$10,$00,$00,$10,$00
	.byte $10,$00,$00,$10,$00,$00,$10,$00
	.byte $10,$00,$00,$10,$00,$00,$10,$00
	.byte $10,$00,$00,$10,$00,$00,$10,$00
	.byte $10,$00,$00,$10,$00,$00,$10,$00
	.byte $10,$00,$00,$10,$00,$00,$10,$00

road_adjust1:
	.byte $30,$30,$30,$30,$30,$30,$30,$30
	.byte $20,$20,$20,$20,$20,$20,$20,$20
	.byte $10,$00,$10,$00,$10,$00,$10,$00
	.byte $F0,$00,$F0,$00,$F0,$00,$F0,$00
	.byte $F0,$00,$00,$F0,$00,$00,$F0,$00
	.byte $F0,$00,$00,$F0,$00,$00,$F0,$00
	.byte $F0,$00,$00,$F0,$00,$00,$F0,$00
	.byte $F0,$00,$00,$F0,$00,$00,$F0,$00
	.byte $F0,$00,$00,$F0,$00,$00,$F0,$00
	.byte $F0,$00,$00,$F0,$00,$00,$F0,$00
	.byte $F0,$00,$00,$F0,$00,$00,$F0,$00
	.byte $F0,$00,$00,$F0,$00,$00,$F0,$00

road_color:
	.byte $0a,$44,$0a,$44,$0a,$44,$0a,$44
	.byte $0a,$0a,$44,$44,$0a,$0a,$44,$44
	.byte $0a,$0a,$44,$44,$0a,$0a,$44,$44
	.byte $0a,$0a,$44,$44,$0a,$0a,$44,$44
	.byte $0a,$0a,$44,$44,$0a,$0a,$44,$44
	.byte $0a,$0a,$0a,$44,$44,$44,$0a,$0a
	.byte $44,$44,$44,$0a,$0a,$0a,$44,$44
	.byte $0a,$0a,$0a,$44,$44,$44,$0a,$0a
	.byte $44,$44,$44,$0a,$0a,$0a,$44,$44
	.byte $0a,$0a,$0a,$0a,$44,$44,$44,$44
	.byte $0a,$0a,$0a,$0a,$44,$44,$44,$44
	.byte $0a,$0a,$0a,$0a,$44,$44,$44,$44

car_sprite:
	.byte %10000010
	.byte %01011001
	.byte %10111110
	.byte %01111101
	.byte %10111110
	.byte %01011001
	.byte %10100110
	.byte %01111101
	.byte %00011000
	.byte %00000000
	.byte %00011000
	.byte %00011000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000

	.byte %01000001
	.byte %10011010
	.byte %01111101
	.byte %10111110
	.byte %01111101
	.byte %10011010
	.byte %01100101
	.byte %10111110
	.byte %00011000
	.byte %00000000
	.byte %00011000
	.byte %00011000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000

	ORG $FFFC
	.word START
	.word START
