	;
	; Wall Breaker (chapter 6)
	;
	; by Oscar Toledo G.
	; https://nanochess.org/
	;
	; Creation date: Jun/10/2022.
	;

	PROCESSOR 6502
	INCLUDE "vcs.h"

XPOS	= $0080		; Player X-position
BALLX	= $0081		; Ball X-position
BALLY	= $0082		; Ball Y-position
DIRX	= $0083		; Ball X-direction
DIRY	= $0084		; Ball Y-direction
SPEED	= $0085		; Ball speed
CURRENT	= $0086		; Current speed counter
SCORE1	= $0087		; Score digit 1
SCORE2	= $0088		; Score digit 2
TEMP1	= $008b		; Temporary variable 1
TEMP2	= $008c		; Temporary variable 2
TEMP3	= $008d		; Temporary variable 3
FRAME	= $008e		; Frame counter
SOUND	= $008f		; Sound duration
TOTAL	= $0090		; Total bricks
BRICKS	= $0091		; Bricks (5 * 5 bytes)

INITIAL_SPEED = 32	; Initial speed of ball

BAND1COL	= $48	; Band 1 color
BAND2COL	= $28	; Band 2 color
BAND3COL	= $18	; Band 3 color
BAND4COL	= $C8	; Band 4 color
BAND5COL	= $0C	; Band 5 color

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
	STA XPOS	; Paddle.

	LDA #$00	; Configure SWCHA as input
	STA SWACNT
	STA SWBCNT	; Also SWCHB

	LDA #$10	; Ball 2px width.
	STA CTRLPF
	LDA #$35	; Missile 8px width.
	STA NUSIZ0	; Player x2 width.
	STA NUSIZ1

	JSR reset_wall

SHOW_FRAME:
	LDA #$88	; Blue.
	STA COLUBK	; Background color.
	LDA #$cF	; Green.
	STA COLUP0	; Player 0 color.
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

	LDA #64		; Desired X position
	LDX #0		; Player 0
	JSR x_position

	LDA #80		; Desired X position
	LDX #1		; Player 1
	JSR x_position

	LDA XPOS	; Desired X position
	LDX #2		; Missile 0
	JSR x_position

	LDA XPOS	; Desired X position
	CLC
	ADC #8
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

	LDA SCORE1	; Score digit 1.
	ASL		; x2
	ASL		; x4
	ASL		; x8
	STA TEMP1	; Use as offset to read bitmap.

	LDA SCORE2	; Score digit 2.
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

	LDY BALLY	; Y position of ball.
	DEY

	LDX #16		; 16 scanlines of space.
BRICK1:
	STA WSYNC	; Synchronize with scanline.
	CPY #$FC	; Inside visual area?
	ROL
	ROL		; Move carry flag to position.
	STA ENABL	; Enable/disable ball.
	DEY		; Decrease ball scanline
	DEX		; Decrease X.
	BNE BRICK1	; Repeat until zero.

	LDA #BAND1COL

	LDX #8		; 8 scanlines of bricks.
BRICK2:
	STA WSYNC	; 3: Synchronize with scanline.
	STA COLUPF	; 6: Set color of playfield.
	LDA BRICKS+0	; 9: 
	STA PF0		; 12: 4 pixels.
	LDA BRICKS+1	; 15:
	STA PF1		; 18: 8 pixels.
	CPY #$FC	; 20: Inside visual area?
	ROL		; 22:
	ROL		; 24: Move Carry flag to position.
	STA ENABL	; 27: Enable/disable ball.
	LDA BRICKS+2	; 30:
	STA PF2		; 33: 8 pixels.
	LDA BRICKS+0	; 36:
	ASL		; 38:
	ASL		; 40:
	ASL		; 42:
	ASL		; 44:
	STA PF0		; 47: 4 pixels.
	LDA BRICKS+3	; 50:	
	STA PF1		; 53: 8 pixels.
	LDA BRICKS+4	; 56:
	STA PF2		; 59: 8 pixels.
	LDA #BAND1COL	; 61: Color of playfield.
	DEY		; 63: Decrease ball row.
	DEX		; 65: Decrease X.
	BNE BRICK2	; 67: Repeat until zero.

	LDA #BAND2COL	; 69:

	LDX #8		; 71: scanlines of bricks.

BRICK3:
	STA WSYNC	; 3: Synchronize with scanline.
	STA COLUPF	; 6: Set color of playfield.
	LDA BRICKS+5	; 9:
	STA PF0		; 12: 4 pixels.
	LDA BRICKS+6	; 15:
	STA PF1		; 18: 8 pixels.
	CPY #$FC	; 20: Inside visual area?
	ROL		; 22:
	ROL		; 24: Move Carry flag to position.
	STA ENABL	; 27: Enable/disable ball.
	LDA BRICKS+7	; 30:
	STA PF2		; 33: 8 pixels.
	LDA BRICKS+5	; 36:
	ASL		; 38:
	ASL		; 40:
	ASL		; 42:
	ASL		; 44:
	STA PF0		; 47: 4 pixels.
	LDA BRICKS+8	; 50:	
	STA PF1		; 53: 8 pixels.
	LDA BRICKS+9	; 56:
	STA PF2		; 59: 8 pixels.
	LDA #BAND2COL	; 61: Color of playfield.
	DEY		; 63: Decrease ball scanline.
	DEX		; 65: Decrease X.
	BNE BRICK3	; 67: Repeat until zero.

	LDX #8		; 69:
	LDA #BAND3COL	; 71:

BRICK4:
	STA WSYNC	; 3: Synchronize with scanline.
	STA COLUPF	; 6: Set color of playfield.
	LDA BRICKS+10	; 9:
	STA PF0		; 12: 4 pixels.
	LDA BRICKS+11	; 15:
	STA PF1		; 18: 8 pixels.
	CPY #$FC	; 20: Inside visual area?
	ROL		; 22:
	ROL		; 24: Move Carry flag to position.
	STA ENABL	; 27: Enable/disable ball.
	LDA BRICKS+12	; 30:
	STA PF2		; 33: 8 pixels.
	LDA BRICKS+10	; 36:
	ASL		; 38:
	ASL		; 40:
	ASL		; 42:
	ASL		; 44:
	STA PF0		; 47: 4 pixels.
	LDA BRICKS+13	; 50:	
	STA PF1		; 53: 8 pixels.
	LDA BRICKS+14	; 56:
	STA PF2		; 59: 8 pixels.
	LDA #BAND3COL	; 61: Color of playfield.
	DEY		; 63: Decrease ball scanline.
	DEX		; 65: Decrease X.
	BNE BRICK4	; 67: Repeat until zero.

	LDA #BAND4COL	; 69:
	LDX #8		; 71:

BRICK5:
	STA WSYNC	; 3: Synchronize with scanline.
	STA COLUPF	; 6: Set color of playfield.
	LDA BRICKS+15	; 9:
	STA PF0		; 12: 4 pixels.
	LDA BRICKS+16	; 15:
	STA PF1		; 18: 8 pixels.
	CPY #$FC	; 20: Inside visual area?
	ROL		; 22:
	ROL		; 24: Move Carry flag to position.
	STA ENABL	; 27: Enable/disable ball.
	LDA BRICKS+17	; 30:
	STA PF2		; 33: 8 pixels.
	LDA BRICKS+15	; 36:
	ASL		; 38:
	ASL		; 40:
	ASL		; 42:
	ASL		; 44:
	STA PF0		; 47: 4 pixels.
	LDA BRICKS+18	; 50:	
	STA PF1		; 53: 8 pixels.
	LDA BRICKS+19	; 56:
	STA PF2		; 59: 8 pixels.
	LDA #BAND4COL	; 61: Color of playfield.
	DEY		; 63: Decrease ball scanline.
	DEX		; 65: Decrease X.
	BNE BRICK5	; 67: Repeat until zero.

	LDA #120	; 69: Y-position.
	STA TEMP1	; 72: For paddle.
	LDA #BAND5COL	; 74:
	LDX #8		; 76:

BRICK6:
	STA WSYNC	; 3: Synchronize with scanline.
	STA COLUPF	; 6: Set color of playfield.
	LDA BRICKS+20	; 9:
	STA PF0		; 12: 4 pixels.
	LDA BRICKS+21	; 15:
	STA PF1		; 18: 8 pixels.
	CPY #$FC	; 20: Inside visual area?
	ROL		; 22:
	ROL		; 24: Move Carry flag to position.
	STA ENABL	; 27: Enable/disable ball.
	LDA BRICKS+22	; 30:
	STA PF2		; 33: 8 pixels.
	LDA BRICKS+20	; 36:
	ASL		; 38:
	ASL		; 40:
	ASL		; 42:
	ASL		; 44:
	STA PF0		; 47: 4 pixels.
	LDA BRICKS+23	; 50:	
	STA PF1		; 53: 8 pixels.
	LDA BRICKS+24	; 56:
	STA PF2		; 59: 8 pixels.
	LDA #BAND5COL	; 61: Color of playfield.
	DEY		; 63: Decrease ball scanline.
	DEX		; 65: Decrease X.
	BNE BRICK6	; 67: Repeat until zero.

	DEC TEMP1
	LDA #$00
	LDX #128	; 128 scanlines of space.
BRICK7:
	STA WSYNC	; Synchronize with scanline.
	STA PF0		; Clean playfield
	STA PF1		; 
	STA PF2		; 
	LDA TEMP1	; Paddle scanline.
	CMP #$FC	; Inside visual area?
	ROL
	ROL		; Move Carry flag to position.
	STA ENAM0	; Enable/disable missile 0.
	STA ENAM1	; Enable/disable missile 1.
	CPY #$FC	; Inside visual area?
	ROL		;  
	ROL		; Move Carry flag to position.
	STA ENABL	; Enable/disable ball.
	LDA #$00
	DEC TEMP1
	DEY		; Decrease ball scanline.
	DEX		; Decrease X.
	BNE BRICK7	; Repeat until zero.

	LDA #2		; Enable blanking
	STA WSYNC
	STA VBLANK

	LDA #35		; Time for NTSC bottom border
	STA TIM64T

	; Move the paddle

	LDA SWCHA	; Read joystick.
	AND #$40	; Left? (player 1)
	BNE M2		; No, jump.
	LDA XPOS	; Read current position.
	CMP #2		; At left?
	BEQ M2		; Yes, jump.
	DEC XPOS	; Move to left 2 pixels.
	DEC XPOS
M2:

	LDA SWCHA	; Read joystick.
	AND #$80	; Right? (player 1)
	BNE M3		; No, jump.
	LDA XPOS	; Read current position.
	CMP #144	; At right?
	BEQ M3		; Yes, jump.
	INC XPOS	; Move to right 2 pixels.
	INC XPOS
M3:

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

	; Check hit against paddle
	LDA XPOS	; X-coordinate.
	SEC
	SBC #1
	CMP TEMP1	; If X < X_POS-1 then EXIT
	BCS M8
	CLC
	ADC #16
	CMP TEMP1	; If X >= X_POS+15 then EXIT
	BCC M8
	LDA #176-4	; If YPOS-4 >= Y then EXIT
	CMP TEMP2
	BCS M8
	LDA #176+3	; If YPOS+3 < Y then EXIT
	CMP TEMP2
	BCC M8
	LDA TEMP1
	SEC
	SBC XPOS	; A = X - XPOS
	JSR paddle_hit	; Calculate new ball direction.
	JMP M10
M8:
	; Detect wall hit (top, left and right)
	LDA TEMP2	; Y-coordinate
	CMP #2		; If Y < 2 then wall hit
	BCS M14
	LDA #0
	SEC
	SBC DIRY	; Just reverse DIRY (diry = -diry)
	STA DIRY
	LDA TEMP1	; X-coordinate.
	CMP #2		; If X < 2 then wall hit
	BCC M11
	CMP #158	; If X >= 158 then wall hit
	BCS M11
	JMP M19
M14:
	LDA TEMP1	; X-coordinate.
	CMP #2		; If X < 2 then wall hit
	BCC M11
	CMP #158	; If X >= 158 then wall hit
	BCC M12
M11:	LDA #0
	SEC
	SBC DIRX	; Just reverse DIRX (dirx = -dirx)
	STA DIRX

	; Sound effect for wall hit.
M19:	LDA #$17
	STA AUDF0
	LDA #$0C
	STA AUDC0
	LDA #$0C
	STA AUDV0
	LDA #10		; Effect duration: 10 frames.
	STA SOUND
	JMP M10
M12:
	; Detect if the ball hits a brick
	LDX TEMP1
	LDY TEMP2
	JSR hit_brick
	BCS M10		; Jump if brick hit.
	LDX TEMP1
	INX
	LDY TEMP2
	JSR hit_brick
	BCS M10		; Jump if brick hit.
	LDX TEMP1
	LDY TEMP2
	INY
	INY
	INY
	JSR hit_brick
	BCS M10		; Jump if brick hit.
	LDX TEMP1
	INX
	LDY TEMP2
	INY
	INY
	INY
	JSR hit_brick
	BCS M10		; Jump if brick hit.
 
M21:
	; Detect if the ball exits the courtyard
	LDA TEMP2	; X-coordinate.
	CMP #180	; If X >= 180 then ball out
	BCC M15
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
	BMI M18		; No, jump.
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
	; Turn off sound
	DEC SOUND	; Decrease sound counter.
	BNE M20		; Is it zero? No, jump.
	LDA #0		; Turn off sound effect.
	STA AUDV0
M20:

	; Verify if the wall is destroyed
M17:	LDA TOTAL
	BNE M23
	JSR reset_wall
M23:
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

	;
	; Reset wall
	;
reset_wall:
	LDX #BRICKS	; Get address into X
	LDY #25		; 5 * 5 bytes.
	LDA #$ff	; Set to brick present.
BRICK:	STA 0,X		; Set bricks.
	INX
	DEY
	BNE BRICK
	LDA #100	; Total of bricks
	STA TOTAL
	LDA #80		; Center of screen.
	STA BALLX	; Ball X-coordinate.
	STA BALLY	; Ball Y-coordinate.
	LDA #INITIAL_SPEED
	STA SPEED	; Speed of ball.
	RTS

	; Detect brick hit
	; X = X-coordinate
	; Y = Y-coordinate
hit_brick:
	TYA		; Copy Y into A
	SEC
	SBC #16		; Y-coordinate too upwards?
	BCC no_hit	; Yes, jump.
	CMP #40		; Y-coordinate too downwards?
	BCS no_hit	; Yes, jump.
	LSR		; /2
	LSR		; /4
	LSR		; /8
	STA TEMP3
	ASL		; x2
	ASL		; x4
	ADC TEMP3	; x5 as each row is 5 bytes in RAM
	STA TEMP3
	TXA		; Copy X into A.
	LSR		; Divide by 4 as each playfield...
	LSR		; ...pixel is 4 pixels.
	TAX
	LDA brick_mapping,X
	PHA
	LSR
	LSR
	LSR
	CLC
	ADC TEMP3
	TAY		; Y = brick byte offset
	PLA
	AND #$07
	TAX
	LDA bit_mapping,X
	AND BRICKS,Y
	BEQ no_hit

	LDA bit_mapping,X
	EOR #$FF
	AND BRICKS,Y
	STA BRICKS,Y

	DEC TOTAL	; One brick less on the wall

	LDA #$00
	SEC
	SBC DIRY
	STA DIRY

	INC SCORE2
	LDA SCORE2
	CMP #10
	BNE h1
	LDA #0
	STA SCORE2
	INC SCORE1
	LDA SCORE1
	CMP #10
	BNE h1
	LDA #9
	STA SCORE1
	STA SCORE2
h1:
	; Start sound effect for brick hit.
	LDA #$05
	STA AUDF0
	LDA #$06
	STA AUDC0
	LDA #$0c
	STA AUDV0
	LDA #10		; Effect duration: 10 frames.
	STA SOUND

	SEC
	RTS

no_hit:	CLC
	RTS

brick_mapping:
	.byte 4,5,6,7
	.byte 15,14,13,12,11,10,9,8
	.byte 16,17,18,19,20,21,22,23
	.byte 0,1,2,3
	.byte 31,30,29,28,27,26,25,24
	.byte 32,33,34,35,36,37,38,39
bit_mapping:
	.byte $03,$03,$0c,$0c,$30,$30,$c0,$c0

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

	INC SPEED	; Increase ball speed
	PLA

	CMP #2	
	BPL p1
	LDA #-2
	STA DIRX
	LDA #-1
	STA DIRY
	RTS

p1:	CMP #4
	BCS p2
	LDA #-2
	STA DIRX
	LDA #-2
	STA DIRY
	RTS

p2:	CMP #7
	BCS p3
	LDA #-1
	STA DIRX
	LDA #-2
	STA DIRY
	RTS

p3:	CMP #9
	BCS p4
	LDA #0
	STA DIRX
	LDA #-2
	STA DIRY
	RTS

p4:	CMP #12
	BCS p5
	LDA #1
	STA DIRX
	LDA #-2
	STA DIRY
	RTS

p5:	CMP #14
	BCS p6
	LDA #2
	STA DIRX
	LDA #-2
	STA DIRY
	RTS

p6:	LDA #2
	STA DIRX
	LDA #-1
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
	.byte $70,$60,$50,$40,$30,$20,$10,$00
	.byte $f0,$e0,$d0,$c0,$b0,$a0,$90

numbers_bitmaps:
	.byte $fe,$82,$82,$86,$86,$86,$fe,$00	; 0
	.byte $10,$10,$10,$30,$30,$30,$30,$00	; 1
	.byte $fe,$02,$02,$fe,$c0,$c0,$fe,$00	; 2
	.byte $fe,$02,$02,$fe,$06,$06,$fe,$00	; 3
	.byte $82,$82,$82,$fe,$06,$06,$06,$00	; 4
	.byte $fe,$80,$80,$fe,$06,$06,$fe,$00	; 5
	.byte $fe,$80,$80,$fe,$c6,$c6,$fe,$00	; 6
	.byte $fe,$02,$02,$02,$06,$06,$06,$00	; 7
	.byte $fe,$82,$82,$fe,$c6,$c6,$fe,$00	; 8
	.byte $fe,$82,$82,$fe,$06,$06,$fe,$00	; 9

	ORG $FFFC
	.word START
	.word START
