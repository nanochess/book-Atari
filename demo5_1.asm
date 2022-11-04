	;
	; Game of Ball (chapter 5)
	;
	; by Oscar Toledo G.
	; https://nanochess.org/
	;
	; Creation date: Jun/08/2022.
	;

	PROCESSOR 6502
	INCLUDE "vcs.h"

Y1POS	= $0080		; Player 1 Y-position
Y2POS	= $0081		; Player 2 Y-position
BALLX	= $0082		; Ball X-position
BALLY	= $0083		; Ball Y-position
DIRX	= $0084		; Ball X-direction
DIRY	= $0085		; Ball Y-direction
SPEED	= $0086		; Ball speed
CURRENT	= $0087		; Current speed counter
SCORE1	= $0089		; Score of player 1
SCORE2	= $008a		; Score of player 2
TEMP1	= $008b		; Temporary variable 1
TEMP2	= $008c		; Temporary variable 2
FRAME	= $008d		; Frame counter
SOUND	= $008e		; Sound duration

X_LEFT	= 16		; X-coordinate of player 1 paddle
X_RIGHT	= 144		; X-coordinate of player 2 paddle
INITIAL_SPEED = 32	; Initial speed of ball

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

	LDA #80		; Center of screen.
	STA Y1POS	; Paddle 1.
	STA Y2POS	; Paddle 2.
	STA BALLX	; Ball X-coordinate.
	STA BALLY	; Ball Y-coordinate.
	LDA #INITIAL_SPEED
	STA SPEED	; Speed of ball.

	LDA #$00	; Configure SWCHA as input
	STA SWACNT
	STA SWBCNT	; Also SWCHB

	LDA #$10	; Ball 2px width.
	STA CTRLPF
	LDA #$25	; Missile 4px width.
	STA NUSIZ0	; Player x2 width.
	STA NUSIZ1

SHOW_FRAME:
	LDA #$88	; Blue.
	STA COLUBK	; Background color.
	LDA #$48	; Red.
	STA COLUP0	; Player 0 color.
	LDA #$cF	; Green.
	STA COLUP1	; Player 1 color.
	LDA #$0F	; White.
	STA COLUPF	; Ball/playfield color.

	STA HMCLR	; Clear horizontal motion registers

	STA CXCLR	; Clear collision registers

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

	LDA #56		; Desired X position
	LDX #0		; Player 0
	JSR x_position

	LDA #88		; Desired X position
	LDX #1		; Player 1
	JSR x_position

	LDA #X_LEFT	; Desired X position
	LDX #2		; Missile 0
	JSR x_position

	LDA #X_RIGHT	; Desired X position
	LDX #3		; Missile 1
	JSR x_position

	LDA BALLX	; Desired X position
	LDX #4		; Ball
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

	LDA SCORE1	; Score of player 1.
	ASL		; x2
	ASL		; x4
	ASL		; x8
	STA TEMP1	; Use as offset to read bitmap.

	LDA SCORE2	; Score of player 2.
	ASL		; x2
	ASL		; x4
	ASL		; x8
	STA TEMP2	; Use as offset to read bitmap.

	LDY #8		; 8 scanlines for score
M1:	STA WSYNC	; Synchronize with scanline.
	LDX TEMP1	; Row on score 1.
	LDA numbers_bitmaps,X	; Read bitmap.
	STA GRP0	; Write as graphic for player 0.
	LDX TEMP2	; Row on score 2.
	LDA numbers_bitmaps,X	; Read bitmap.
	STA GRP1	; Write as graphic for player 1.
	INC TEMP1	; Increase row of score 1.
	INC TEMP2	; Increase row of score 2.
	DEY		; Decrease scanlines to display.
	BNE M1		; Jump if still there are some.

	LDA Y1POS	; Paddle 1 vertical position.	
	STA TEMP1	; Use as counter.
	LDA Y2POS	; Paddle 2 vertical position.
	STA TEMP2	; Use as counter.
	LDX #184	; 184 scanlines in blue.
	LDY BALLY	; Y position of ball.
DISPLAY:
	STA WSYNC	; Synchronize with scanline.
	DEC TEMP1	; Decrease paddle 1 scanline
	DEC TEMP2	; Decrease paddle 2 scanline
	DEY		; Decrease ball scanline
	LDA TEMP1	; Paddle 1 scanline.
	CMP #$E0	; Inside visual area?
	PHP		; Save processor state.
	PLA		; Restore into accumulator.
	ASL		; Move Carry flag to position.
	STA ENAM0	; Enable/disable missile 0.
	LDA TEMP2	; Paddle 2 scanline.
	CMP #$E0	; Inside visual area?
	PHP		; Save processor state.
	PLA		; Restore into accumulator.
	ASL		; Move carry flag to position.
	STA ENAM1	; Enable/disable missile 1.
	CPY #$FC	; Inside visual area?
	PHP		; Save processor state.
	PLA		; Restore into accumulator.
	ASL		; Move Carry flag to position.
	STA ENABL	; Enable/disable ball.
	DEX		; Decrease X.
	BNE DISPLAY	; Repeat until zero.

	LDA #2		; Enable blanking
	STA VBLANK

	LDA #35		; Time for NTSC bottom border
	STA TIM64T

	; Move the paddles

	LDA SWCHA	; Read joystick.
	AND #$10	; Up? (player 1)
	BNE M2		; No, jump.
	LDA Y1POS	; Read current position.
	CMP #4		; At top?
	BEQ M2		; Yes, jump.
	DEC Y1POS	; Move upwards 2 pixels.
	DEC Y1POS
M2:

	LDA SWCHA	; Read joystick.
	AND #$20	; Down? (player 1)
	BNE M3		; No, jump.
	LDA Y1POS	; Read current position.
	CMP #148	; At bottom?
	BEQ M3		; Yes, jump.
	INC Y1POS	; Move downwards 2 pixels.
	INC Y1POS
M3:

	LDA SWCHA	; Read joystick.
	AND #$01	; Up? (player 2)
	BNE M4		; No, jump.
	LDA Y2POS	; Read current position.
	CMP #4		; At top?
	BEQ M4		; Yes, jump.
	DEC Y2POS	; Move upwards 2 pixels.
	DEC Y2POS
M4:

	LDA SWCHA	; Read joystick.
	AND #$02	; Down? (player 2)
	BNE M5		; No, jump.
	LDA Y2POS	; Read current position.
	CMP #148	; At bottom?
	BEQ M5		; Yes, jump.
	INC Y2POS	; Move downwards 2 pixels.
	INC Y2POS
M5:

	; Move the ball
	LDA CURRENT	; Speed counter.
	CLC
	ADC SPEED	; Add current speed.
	STA CURRENT	; Save again.

M7:
	LDA CURRENT	; Read speed counter.
	SEC
	SBC #$40	; Completed one frame?
	BCS M6		; Yes, jump.
	JMP M16		; No, exit loop.
M6:
	STA CURRENT	; Update speed counter.

	LDA BALLX	; Ball X-coordinate.
	CLC
	ADC DIRX	; Add X direction.
	STA TEMP1	; Save in temporary.
	LDA BALLY	; Ball Y-coordinate.
	CLC
	ADC DIRY	; Add Y direction.
	STA TEMP2	; Save in temporary.

	; Check hit against paddle 1
	LDA TEMP1	; X-coordinate.
	CMP #X_LEFT-1	; If X < X_LEFT-1 then EXIT
	BCC M8
	CMP #X_LEFT+4	; If X >= X_LEFT+4 then EXIT
	BCS M8
	LDA Y1POS	; If Y1POS-4 >= Y then EXIT
	SEC
	SBC #4
	CMP TEMP2
	BCS M8
	CLC		; If Y1POS+31 < Y then EXIT
	ADC #35
	CMP TEMP2
	BCC M8
	LDA TEMP2
	SEC
	SBC Y1POS	; A = Y - Y1POS
	JSR paddle_hit	; Calculate new ball direction.
	JMP M10
M8:
	; Check hit against paddle 2
	LDA TEMP1	; X-coordinate.
	CMP #X_RIGHT-1	; If X < X_RIGHT-1 then EXIT
	BCC M9
	CMP #X_RIGHT+4	; If X >= X_RIGHT+4 then EXIT
	BCS M9
	LDA Y2POS	; If Y2POS-4 >= Y then EXIT
	SEC
	SBC #4
	CMP TEMP2
	BCS M9
	CLC		; If Y2POS+31 < Y then EXIT
	ADC #35
	CMP TEMP2
	BCC M9
	LDA TEMP2
	SEC
	SBC Y2POS	; A = Y - Y2POS
	JSR paddle_hit	; Calculate new ball direction.
	LDA #0
	SEC
	SBC DIRX	; Reverse DIRX (dirx = -dirx)
	STA DIRX
	JMP M10
M9:
	; Detect wall hit (top and bottom)
	LDA TEMP2	; Y-coordinate.
	CMP #2		; If Y < 2 then wall hit
	BCC M11
	CMP #181	; If Y >= 181 then wall hit
	BCC M12
M11:	LDA #0
	SEC
	SBC DIRY	; Just reverse DIRY (diry = -diry)
	STA DIRY

	; Sound effect for wall hit.
	LDA #$17
	STA AUDF0
	LDA #$0C
	STA AUDC0
	LDA #$0C
	STA AUDV0
	LDA #10		; Effect duration: 10 frames.
	STA SOUND
	JMP M10
M12:
	; Detect if the ball exits the courtyard
	LDA TEMP1	; X-coordinate.
	CMP #2		; If X < 2 then ball out
	BCC M14
	CMP #157	; If X >= 157 then ball out
	BCC M15
	LDA SCORE1	; Read score for player 1.
	CMP #9		; Already 9?
	BEQ M19		; Yes, jump.
	INC SCORE1	; No, increase it.
	JMP M19		; Jump.
M14:
	LDA SCORE2	; Read score for player 2.
	CMP #9		; Already 9?
	BEQ M19		; Yes, jump.
	INC SCORE2	; No, increase it.
M19:
	LDA #80		; Restart X,Y coordinates for ball.
	STA TEMP1
	STA TEMP2
	LDA #0		; Make ball static.
	STA DIRX
	STA DIRY
	LDA #INITIAL_SPEED	; Restart ball speed.
	STA SPEED

	; Sound effect for ball out.
	LDA #$02
	STA AUDF0
	LDA #$06
	STA AUDC0
	LDA #$0C
	STA AUDV0
	LDA #15		; Effect duration: 15 frames.
	STA SOUND
M15:
	; Nothing special happened.
	; The ball can move to the new coordinates.
	LDA TEMP1
	STA BALLX
	LDA TEMP2
	STA BALLY

M10:

	JMP M7

M16:
	; Launch the ball
	LDA INPT4	; Joystick 1 button pressed?
	BPL M17		; Yes, jump.
	LDA INPT5	; Joystick 2 button pressed?
	BMI M18		; No, jump.
M17:
	LDA DIRX	; Ball moving?
	BNE M18		; Yes, jump.
	LDA FRAME	; Get current frame.
	AND #$03	; Modulo 4.
	TAX
	LDA ball_directions,X
	STA DIRX	; Random X direction.
	LDA FRAME	; Get current frame.
	LSR		; Divide by 4.
	LSR
	AND #$03	; Modulo 4.
	TAX
	LDA ball_directions,X
	STA DIRY	; Random Y direction.
	
M18:

	DEC SOUND	; Decrease sound counter.
	BNE M20		; Is it zero? No, jump.
	LDA #0		; Turn off sound effect.
	STA AUDV0
M20:

	LDA #0		; Remove remains of ball...
	STA ENABL	; ...as it can touch border.

WAIT_FOR_BOTTOM:
	LDA INTIM	; Read timer
	BNE WAIT_FOR_BOTTOM	; Branch if not zero.
	STA WSYNC	; Resynchronize on last border scanline

	INC FRAME	; Count frames

	JMP SHOW_FRAME	; Repeat the game loop.

	; Ball directions (for random startup)
ball_directions:
	.byte $fe,$ff,$01,$02

	; Paddle hit.
	; A = Relative coordinate where ball hit.
	;
paddle_hit:
	PHA
	; Start sound effect for paddle hit.
	LDA #$1F
	STA AUDF0
	LDA #$0C
	STA AUDC0
	LDA #$0C
	STA AUDV0
	LDA #5		; Effect duration: 5 frames.
	STA SOUND

	INC SPEED	; Increase ball speed by 2.
	INC SPEED
	PLA

	CMP #4		
	BPL p1
	LDA #1
	STA DIRX
	LDA #-2
	STA DIRY
	RTS

p1:	CMP #9
	BCS p2
	LDA #2
	STA DIRX
	LDA #-2
	STA DIRY
	RTS

p2:	CMP #14
	BCS p3
	LDA #2
	STA DIRX
	LDA #-1
	STA DIRY
	RTS

p3:	CMP #19
	BCS p4
	LDA #2
	STA DIRX
	LDA #0
	STA DIRY
	RTS

p4:	CMP #24
	BCS p5
	LDA #2
	STA DIRX
	LDA #1
	STA DIRY
	RTS

p5:	CMP #29
	BCS p6
	LDA #2
	STA DIRX
	LDA #2
	STA DIRY
	RTS

p6:	LDA #1
	STA DIRX
	LDA #2
	STA DIRY
	RTS

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

numbers_bitmaps:
	.byte %11111110	; 0
	.byte %10000010
	.byte %10000010
	.byte %10000110
	.byte %10000110
	.byte %10000110
	.byte %11111110
	.byte %00000000

	.byte %00010000	; 1
	.byte %00010000
	.byte %00010000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00000000

	.byte %11111110	; 2
	.byte %00000010
	.byte %00000010
	.byte %11111110
	.byte %11000000
	.byte %11000000
	.byte %11111110
	.byte %00000000

	.byte %11111110	; 3
	.byte %00000010
	.byte %00000010
	.byte %11111110
	.byte %00000110
	.byte %00000110
	.byte %11111110
	.byte %00000000

	.byte %10000010	; 4
	.byte %10000010
	.byte %10000010
	.byte %11111110
	.byte %00000110
	.byte %00000110
	.byte %00000110
	.byte %00000000

	.byte %11111110	; 5
	.byte %10000000
	.byte %10000000
	.byte %11111110
	.byte %00000110
	.byte %00000110
	.byte %11111110
	.byte %00000000

	.byte %11111110	; 6
	.byte %10000000
	.byte %10000000
	.byte %11111110
	.byte %11000110
	.byte %11000110
	.byte %11111110
	.byte %00000000

	.byte %11111110	; 7
	.byte %00000010
	.byte %00000010
	.byte %00000010
	.byte %00000110
	.byte %00000110
	.byte %00000110
	.byte %00000000
	
	.byte %11111110	; 8
	.byte %10000010
	.byte %10000010
	.byte %11111110
	.byte %11000110
	.byte %11000110
	.byte %11111110
	.byte %00000000

	.byte %11111110	; 9
	.byte %10000010
	.byte %10000010
	.byte %11111110
	.byte %00000110
	.byte %00000110
	.byte %11111110
	.byte %00000000

	ORG $FFFC
	.word START
	.word START
