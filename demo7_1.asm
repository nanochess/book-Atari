	;
	; Invaders (chapter 7)
	;
	; by Oscar Toledo G.
	; https://nanochess.org/
	;
	; Creation date: Jun/11/2022.
	; Revision date: Jun/12/2022. Stabilized scanline count.
	; Revision date: Jun/13/2022. Added missing things.
	;

	PROCESSOR 6502
	INCLUDE "vcs.h"

XPOS	= $0080		; Player X-position
HIT	= $0081		; Player hit
SHOTX	= $0082		; Shot X-position
SHOTY	= $0083		; Shot Y-position
INVS	= $0084		; Invaders state
INVW	= $0085		; Invaders width
INVX	= $0086		; Invaders X-position
INVY	= $0087		; Invaders Y-position
BOMBX	= $0088		; Bomb X-position
BOMBY	= $0089		; Bomb Y-position
SPEED	= $008a		; Invaders speed
CURRENT	= $008b		; Current speed counter
SCORE1	= $008c		; Score digit 1
SCORE2	= $008d		; Score digit 2
TEMP1	= $008e		; Temporary variable 1
TEMP2	= $008f		; Temporary variable 2
TEMP3	= $0090		; Temporary variable 3
TEMP4	= $0091		; Temporary variable 4
TEMP5	= $0092		; Temporary variable 5
TEMP6	= $0093		; Temporary variable 6
FRAME	= $0094		; Frame counter
SOUND0	= $0095		; Sound 0 duration
SOUND1	= $0096		; Sound 1 duration
ALT	= $0097		; Alternate invader frames
ARMY	= $0098		; Army of invaders (5 bytes)

INITIAL_SPEED = 2	; Initial speed of invaders

INVH	= 13	; Height in pixels of invader row.
INVROWS	= 5	; Total of invader rows

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
	STA XPOS	; Spaceship.

	LDA #$00	; Configure SWCHA as input
	STA SWACNT
	STA SWBCNT	; Also SWCHB

	JSR reset_invaders

SHOW_FRAME:
	LDA #$00	; Black.
	STA COLUBK	; Background color.
	LDA #$38	; Orange.
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
	INX		; Player 1
	JSR x_position

	LDA BOMBX	; Desired X position
	INX		; Missile 0
	JSR x_position

	LDA SHOTX	; Desired X position
	LDX #4		; Ball
	JSR x_position

	STA WSYNC	; Wait for scanline start
	STA HMOVE	; Write HMOVE, only can be done
			; just after STA WSYNC.

	LDA #$05	; Missile 1px width.
	STA NUSIZ0	; Player x2 width.
	STA NUSIZ1

	LDA #$00	; Ball 1px width.
	STA CTRLPF

	LDX SHOTY	; Y-position of shot.
	INX		; Increment by one.
	STX TEMP5	; Start temporary counter.
	LDX BOMBY	; Y-position of bomb.
	INX		; Increment by one.
	STX TEMP6	; Start temporary counter.

WAIT_FOR_TOP:
	LDA INTIM	; Read timer
	BNE WAIT_FOR_TOP	; Branch if not zero.
	STA WSYNC	; Resynchronize on last border scanline

	STA WSYNC
	LDA #0		; Disable blanking
	STA VBLANK
	STA HMCLR

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

	LDX INVY	; Y-position of invaders = scanlines of space.
INVADE1:
	STA WSYNC	; Synchronize with scanline.

	DEC TEMP5	; Counter for shot.
	PHP		; Copy Z...
	PLA		; ...into accumulator.
	STA ENABL	; Enable/disable ball.

	DEC TEMP6	; Counter for bomb.
	PHP		; Copy Z...
	PLA		; ...into accumulator.
	STA ENAM0	; Enable/disable missile 0.

	DEX		; Decrease X.
	BNE INVADE1	; Repeat until zero.

	LDA #$C8	; Green color for invaders.
	STA COLUP0
	STA COLUP1

	; Show invaders army.
	LDY ARMY
	JSR show_invaders_row
	LDY ARMY+1
	JSR show_invaders_row
	LDY ARMY+2
	JSR show_invaders_row
	LDY ARMY+3
	JSR show_invaders_row
	LDY ARMY+4
	JSR show_invaders_row

	LDA #177-INVH*5	; 177 scanlines - 5 rows of aliens
	SEC
	SBC INVY	; Subtract current origin Y of aliens.
	TAX		; Copy into X to use as counter.
INVADE2:
	STA WSYNC	; Synchronize with scanline.

	DEC TEMP5	; Counter for shot.
	PHP		; Copy Z...
	PLA		; ...into accumulator.
	STA ENABL	; Enable/disable ball.

	DEC TEMP6	; Counter for bomb.
	PHP		; Copy Z...
	PLA		; ...into accumulator.
	STA ENAM0	; Enable/disable missile 0.

	DEX		; Decrease X.
	BNE INVADE2	; Repeat until zero.

	;
	; Start positioning code for spaceship
	;
	sta WSYNC	; 3: Start scanline synchro.
	sec		; 5: Set carry (so SBC doesn't subtract extra)
	LDA XPOS	; 8: X-position for spaceship.
x4_p1:
	sbc #15		; 10: Divide X by 15
	bcs x4_p1	; 12: If the loop goes on, add +5 each time
x4_p2:
	tay		; 14:
	lda fine_adjust-$f1,y	; 18:
	sta HMBL	; 21: Fine position
	nop		; 23:
	sta RESBL	; 26: Time of setup for coarse position.

	STA WSYNC	; Synchronize to next scanline.
	STA HMOVE
	LDA #$10	; 2px width ball.
	STA CTRLPF
	LDA #$02	; Enable ball.
	STA ENABL
	LDX #$a8	; Turquoise color.
	LDA HIT		; Spaceship has been hit?
	BEQ M38		; No, jump.
	LDX #$48	; Red color.
M38:	STX COLUPF	; Update playfield/ball color.
	
	STA WSYNC	; Synchronize to next scanline.
	STA HMCLR	; Clear fine movement counters.
	LDA #$10	; Move ball 1 pixel to left.
	STA HMBL

	STA WSYNC	; Synchronize to next scanline.
	STA HMOVE	; Do fine movement.
	LDA #$20	; 4px width ball
	STA CTRLPF	; Update.
	
	STA WSYNC	; Synchronize to next scanline.
	STA HMCLR	; Clear fine movement counters.
	LDA #$20	; Move ball 2 pixels to left.
	STA HMBL

	STA WSYNC	; Synchronize to next scanline.
	STA HMOVE	; Do fine movement.
	LDA #$30	; 8px width ball.
	STA CTRLPF
	
	STA WSYNC	; Synchronize to next scanline.
	STA HMCLR	; Do fine movement.

	LDA #2		; Enable blanking
	STA WSYNC
	STA VBLANK

	LDA #35		; Time for NTSC bottom border
	STA TIM64T

	; Move the spaceship

	LDA SWCHA	; Read joystick.
	AND #$40	; Left? (player 1)
	BNE M2		; No, jump.
	LDA XPOS	; Read current position.
	CMP #14		; At left?
	BEQ M2		; Yes, jump.
	DEC XPOS	; Move to left 2 pixels.
	DEC XPOS
M2:

	LDA SWCHA	; Read joystick.
	AND #$80	; Right? (player 1)
	BNE M3		; No, jump.
	LDA XPOS	; Read current position.
	CMP #136	; At right?
	BEQ M3		; Yes, jump.
	INC XPOS	; Move to right 2 pixels.
	INC XPOS
M3:

	; Move the invaders
	LDA CURRENT	; Speed counter.
	CLC
	ADC SPEED	; Add current speed.
	STA CURRENT	; Save again.

	LDA CURRENT	; Read speed counter.
	SEC
	SBC #$40	; Completed one frame?
	BCS M6		; Yes, jump.
	JMP M16		; No, exit loop.
M6:
	STA CURRENT	; Update speed counter.
	
	LDA ALT
	EOR #$08	; Alternate animation frame.
	STA ALT
	BNE M10		; Happened twice? No, jump.

	LDA SOUND0	; Playing another sound?
	BPL M10		; Yes, jump.
	
	LDA #$10	; Marching sound effect.
	STA AUDF0
	LDA #$06
	STA AUDC0
	LDA #$0C
	STA AUDV0
	LDA #2		; Two frame duration.
	STA SOUND0
M10:
	LDA INVS	; Invaders state.
	CMP #0		; Is it zero?
	BNE M11		; No, jump.
	DEC INVX	; Move invaders to left.
	DEC INVX	; Move invaders to left.
	LDA INVX
	CMP #10		; Reached left limit?
	BNE M12		; No, jump.
	LDA #3		; State = Down + Right.
	STA INVS
	JMP M12

M11:	CMP #1		; Is it one?
	BNE M14		; No, jump.
	INC INVX	; Move invaders to right.
	INC INVX	; Move invaders to right.
	LDA INVW	; Get current width of rectangle.
	ASL		; x2
	ASL		; x4
	ASL		; x8
	ASL		; x16
	EOR #$FF	; Negate.
	ADC #151	; Add to right limit.
	CMP INVX	; Reached right limit?
	BNE M12		; No, jump.
	LDA #2		; State = Down + Left
	STA INVS
	JMP M12

M14:
	INC INVY	; Other state: Go downwards.
	LDA INVS
	CLC
	ADC #2		; Advance state
	STA INVS
	SEC
	SBC #2+INVH/2*2	; Advanced a full row?
	BCC M12		; No, jump.
	STA INVS	; Update state to 0 or 1.

M12:

M16:
	; Start the game
	LDA SWCHB
	AND #$02	; Select button pressed?
	BNE M19		; No, jump.
	LDA SPEED	; Already started?
	BNE M19		; Yes, jump.
	JSR reset_invaders	; Reset invaders.
	LDA #INITIAL_SPEED	; Set initial speed.
	STA SPEED
M19:

	; Spaceship shot
	LDA SHOTY	; Read Y-coordinate of shot.
	CMP #$FF	; Active?
	BEQ M18		; No, jump.
	SEC
	SBC #2		; Move two pixels upward.
	BCS M21		; Crossed zero? No, jump.
	LDA #$FF	; Set to inactive.
M21:
	STA SHOTY	; Update Y-coordinate of shot.

	LDA SHOTX	; Get X-coordinate of shot.
	SEC
	SBC INVX	; Subtract invaders X origin.
	BCC M22		; Exit if lesser than X origin.
	CMP #96		; Exceeds maximum width?
	BCS M22		; Yes, jump.
	LSR		; /2
	LSR		; /4
	LSR		; /8
	LSR		; /16
	BCS M22		; Jump if it is space between invaders.
	TAY		; Number of invader column in Y.

	LDA SHOTY	; Get Y-coordinate of shot.
	SEC
	SBC INVY	; Subtract invaders Y origin.
	CMP #INVROWS*INVH	; Not inside height of invaders?
	BCS M22		; No, jump.
			; Succesive subtraction for division.
	LDX #$FF	; X = Final result.
M23:	INX		; X = X + 1
	SEC
	SBC #INVH	; Divide by invader row height.
	BCS M23		; Completed? No, repeat.
	CMP #$FD	; Shot in space between invaders?
	BCS M22		; Yes, jump.
	
	LDA ARMY,X	; Get row of invaders.
	AND invader_bit,Y	; Logical AND with specific invader.
	BEQ M22		; There is one? No, jump.

	; Remove bullet
	LDA #$FF
	STA SHOTY

	; Destroy invader
	LDA invader_bit,Y	; Invader bit.
	EOR #$FF	; Complement.
	AND ARMY,X	; AND-out the invader.
	STA ARMY,X	; Update memory.
	
	; Explosion sound effect.
	LDA #$06
	STA AUDF0
	LDA #$08
	STA AUDC0
	LDA #$0C
	STA AUDV0
	LDA #16		; Duration: 16 frames.
	STA SOUND0

	; Speed up game
	INC SPEED

	; Score a point
	INC SCORE2	; Increase second digit.
	LDA SCORE2
	CMP #10		; Is it 10?
	BNE M22		; No, jump.
	LDA #0		; Put back to zero.
	STA SCORE2
	INC SCORE1	; Increase first digit.
	LDA SCORE1	
	CMP #10		; Is it 10?
	BNE M22		; No, jump.
	LDA #9		; Set score to maximum 99.
	STA SCORE1
	STA SCORE2
M22:
	JMP M15
M18:
	LDA INPT4	; Joystick 1 button pressed?
	BMI M15		; No, jump.
	LDA SPEED	; Game started?
	BEQ M15		; No, jump.

	LDA XPOS	; Shot X = Spaceship X.
	STA SHOTX
	LDA #175	; Shot Y = 175.
	STA SHOTY

	; Shoot sound effect.
	LDA #$06
	STA AUDF1
	LDA #$03
	STA AUDC1
	LDA #$0C
	STA AUDV1
	LDA #5		; Duration: 5 frames.
	STA SOUND1

M15:
	; Turn off sound
	DEC SOUND0	; Decrease sound counter.
	BNE M20		; Is it zero? No, jump.
	LDA #0		; Turn off sound effect.
	STA AUDV0
M20:
	DEC SOUND1	; Decrease sound counter.
	BNE M39		; Is it zero? No, jump.
	LDA #0		; Turn off sound effect.
	STA AUDV1
M39:

	; Move invaders bomb
	LDA SPEED	; Game active?
	BEQ M32		; No, jump.
	LDX BOMBY	; Read bomb Y-coordinate.
	CPX #$FF	; Active?
	BEQ M34		; No, jump.
	INX		; Make it to go down.
	CPX #177	; Reached Y-limit?
	BNE M33		; No, jump?
	LDA CXM0FB	; Collision of M0 against...
	AND #$40	; ...Ball?
	BEQ M37		; No, jump.
	JMP M36		; Spaceship hit.
M37:
	LDX #$FF	; Y-coordinate to inactive bomb.
M33:	STX BOMBY	; Update bomb.
	JMP M32

M34:
	LDA ARMY+INVROWS-1	; Read bottommost invader row.
	AND #$07	; Are there invaders?
	BEQ M32		; No, jump.
	TAX
	LDA invaders_offset0,X	; Get offset of leftmost one.
	ADC INVX	; Add origin X of invaders rectangle.
	ADC #4		; Center under invader.
	STA BOMBX	; Set X-coordinate of bomb.
	LDA INVY	; Get origin Y of invaders rectangle.
	ADC #5*INVH-3	; Add offset to bottommost row.
	STA BOMBY	; Set Y-coordinate of bomb.

	; Invaders shoot sound effect.
	LDA #$03
	STA AUDF1
	LDA #$0E
	STA AUDC1
	LDA #$0C
	STA AUDV1
	LDA #3		; Duration: 3 frames.
	STA SOUND1

M32:

	; Verify if it should realign invaders vertically.
	LDA ARMY+INVROWS-1	; Bottommost row destroyed?
	BNE M26		; No, jump.
	LDA INVY	; Get current origin Y of rectangle.
	SEC
	SBC #INVH	; Minus height of invader row.
	BCC M26		; If negative, exit this code.
	CMP #16		; If too low, exit this code.
	BCC M26
	STA INVY	; Invaders relocated on Y.
	LDX #INVROWS-2	; Displace all bytes of invaders.
M27:	LDA ARMY,X	; Upper row...
	STA ARMY+1,X	; ...going down.
	DEX
	BPL M27
	LDA #0		; Uppermost row set to nothing.
	STA ARMY
M26:

	; Verify if the invaders are destroyed.
M17:	LDA #0		; Load accumulator with zero.
	LDX #INVROWS-1	; Bottommost invaders row.
M24:	ORA ARMY,X	; Logical OR of accumulator with data.
	DEX		; Go one row up.
	BPL M24		; Jump if still positive row.

	CMP #0		; Is it zero?
	BNE M25		; No, jump.
	JSR reset_invaders	; Yes, reset invaders.
	LDA #2		; Restart march.
	STA SPEED
	LDA #2		; Make them go down.
	STA INVS
	JMP M28

	; Realign invaders horizontally?
M25:	TAX		; Save in X (it will be used again)
	AND #$01	; Left column open?
	BNE M30		; No, jump.
	LDA INVX	; Current X-origin for invaders.
	CLC
	ADC #16		; Add 16 pixels.
	STA INVX	; Update X-origin.
	LDX #INVROWS-1	; Bottommost invaders row.
M29:	LSR ARMY,X	; Displace row one bit to right.
	DEX		; Go one row up.
	BPL M29		; Jump if still positive row.
M35:	DEC INVW	; Decrease rectangle width.
	JMP M28

M30:	LDY INVW	; Get current rectangle width.
	DEY		; Minus 1.
	TXA		; Get current OR'ed column.
	AND invader_bit,Y	; Right column open?
	BEQ M35		; Yes, jump backwards.

M28:
	; Verify if invaders won.
	LDA INVY	; Y origin of invaders?
	CMP #177-INVH*INVROWS-2	; 177 scanlines - rows of aliens
	BCC M31		; Reached limit? No, jump.
M36:
	LDA #0		; Stop the game.
	STA SPEED
	LDA #$FF	
	STA BOMBY	; Remove any bomb.
	STA SHOTY	; Remove any shot.
	LDA #1		; Spaceship is hit.
	STA HIT

	; Big explosion sound effect.
	LDA #$0F
	STA AUDF0
	LDA #$08
	STA AUDC0
	LDA #$0F
	STA AUDV0
	LDA #32		; Duration: 32 frames.
	STA SOUND0

M31:
	LDA #0		
	STA ENABL	; Remove ball. 
	STA ENAM0	; Remove missile 0.

WAIT_FOR_BOTTOM:
	LDA INTIM	; Read timer
	BNE WAIT_FOR_BOTTOM	; Branch if not zero.
	STA WSYNC	; Resynchronize on last border scanline

	INC FRAME	; Count frames

	JMP SHOW_FRAME	; Repeat the game loop.

	;
	; Reset invaders
	;
reset_invaders:
	LDX #INVROWS-1	; Bottommost row of invaders.
	LDA #$3f	; 6 invaders present on row.
INVADER:
	STA ARMY,X	; Set invader row.
	DEX
	BPL INVADER
	LDA #36		; Invaders X start
	STA INVX
	LDA #16		; Invaders Y start
	STA INVY
	LDA #0		; Invaders state = 0
	STA INVS
	LDA #6		; Width of invaders rectangle.
	STA INVW
	LDA #0		; Static
	STA SPEED	; Speed of invaders.
	STA HIT		; Not hit.
	LDA #$FF
	STA BOMBY	; No active bomb.
	STA SHOTY	; No active shot.
	RTS

	;
	; Show a row of invaders.
	;
show_invaders_row:
	STA WSYNC	; 3:
	DEC TEMP5	; 8: Decrease position for shot.
	PHP		; 11:
	PLA		; 15:
	STA ENABL	; 18: Enable/disable shot.
	DEC TEMP6	; 23: Decrease position for bomb.
	PHP		; 26:
	PLA		; 30:
	STA ENAM0	; 33: Enable/disable bomb.
	LDA invaders_bits0,Y	; 37: Read repeat table...
	STA NUSIZ0	; 40: ...for left-side invaders.
	LDA invaders_frame0,Y	; 44: Graphic bitmap...
	NOP		; 46:
	EOR ALT		; 49: ...with alternate animation...
	STA TEMP3	; 52: ...to be used.
	DEC TEMP6	; 57: Decrease position for bomb.
	PHP		; 60: Save for later use.
	DEC TEMP5	; 65: Decrease position for shot.
	PHP		; 68: Save for later use.
	PLA		; 72: Time is now.
	STA.W ENABL	; 76: Enable/disable shot.
			;     STA.W instruction is one cycle
			;     slower than direct STA.

	LDA invaders_offset0,Y	; 4: Start row synchro
	ADC INVX	; 7: Eat 3 cycles
	sec		; 9: Set carry (so SBC doesn't subtract extra)
x2_p1:
	sbc #15		; 11: Divide X by 15
	bcs x2_p1	; 13: If the loop goes on, add +5 each time
x2_p2:
	tax		; 15:
	lda fine_adjust-$f1,x	; 19:
	sta.W HMP0	; 23: Fine position
	sta RESP0	; 26: Time of setup for coarse position.

	PLA		; 
	STA ENAM0	; Enable/disable bomb.

	STA WSYNC	; 3:
	DEC TEMP5	; 8: Decrease position for shot.
	PHP		; 11:
	PLA		; 15:
	STA ENABL	; 18: Enable/disable shot.
	DEC TEMP6	; 23: Decrease position for bomb.
	PHP		; 26:
	PLA		; 30:
	STA ENAM0	; 33: Enable/disable bomb.
	LDA invaders_bits1,Y	; 37: Read repeat table...
	STA NUSIZ1	; 40: ...for right-side invaders.
	LDA invaders_frame1,Y	; 44: Graphic bitmap...
	NOP		; 46:
	EOR ALT		; 49: ...with alternate animation...
	STA TEMP4	; 52: ...to be used.
	DEC TEMP6	; 57: Decrease position for bomb...
	PHP		; 60: ...to be used later.
	DEC TEMP5	; 65: Decrease position for shot...
	PHP		; 68: ...to be used later...
	PLA		; 72: ...time is now.
	STA.W ENABL	; 76: Enable/disable shot.

	LDA invaders_offset1,Y	; 4: Start row synchro
	ADC INVX	; 7:
	sec		; 9: Set carry (so SBC doesn't subtract extra)
x3_p1:
	sbc #15		; 11: Divide X by 15
	bcs x3_p1	; 13: If the loop goes on, add +5 each time
x3_p2:
	tax		; 15:
	lda fine_adjust-$f1,x	; 19:
	sta.W HMP1	; 23: Fine position
	sta RESP1	; 26: Time of setup for coarse position.
	PLA		;
	STA ENAM0	; Enable/disable bomb.

	; Draw the proper invaders.
	LDY #8		; Height of 8 pixels.
sv1:	STA WSYNC	; 3: Wait for next screen row.
	STA HMOVE	; 6: Fine movement.
	LDX TEMP3	; 9: Offset for left-side invaders.
	LDA invaders_bitmaps,X	; 13: Read bitmap.
	STA GRP0	; 16: Update bitmap.
	LDX TEMP4	; 19: Offset for right-side invaders.
	LDA invaders_bitmaps,X	; 23: Read bitmap.
	STA GRP1	; 26: Update bitmap.
	DEC TEMP5	; 31: Decrease position for shot.
	PHP		; 34:
	PLA		; 38:
	STA ENABL	; 41: Enable/disable shot.
	DEC TEMP6	; 46: Decrease position for bomb.
	PHP		; 49:
	PLA		; 53:
	STA ENAM0	; 56: Enable/disable bomb.
	INC TEMP3	; 61: Next bitmap offset left-side.
	INC TEMP4	; 66: Next bitmap offset right-side.
	STA HMCLR	; 69: Clear fine movement.

	DEY		; 71: Count height.
	BNE sv1		; 73: Loop if not finished.

	; Cannot make previous loop to be LDY #9...
	; ...as we need time to execute:...
	; ...RTS + LDY # + JSR...
	STA WSYNC	; 3: Wait for next row.
	LDA #0		; 5: Turn off invaders graphics.
	STA GRP0	; 8:
	STA GRP1	; 11:
	DEC TEMP5	; 16: We cannot miss update of
	PHP		; 19: bomb/shot in each row.
	PLA		; 23:
	STA ENABL	; 26:
	DEC TEMP6	; 31:
	PHP		; 34:
	PLA		; 38:
	STA ENAM0	; 41:
	RTS		; 47: Return.
			; 49: LDY (in caller code)
			; 55: JSR (in caller code)
			;     Again in this subroutine.

	.org $fd00

	; Repeat bits for NUSIZx
	; bit 0 - Leftmost invader.
	; bit 1 - Center invader.
	; bit 2 - Right invader.
	;
invaders_bits0:
	.byte $00,$00,$00,$01,$00,$02,$01,$03
	.byte $00,$00,$00,$01,$00,$02,$01,$03
	.byte $00,$00,$00,$01,$00,$02,$01,$03
	.byte $00,$00,$00,$01,$00,$02,$01,$03
	.byte $00,$00,$00,$01,$00,$02,$01,$03
	.byte $00,$00,$00,$01,$00,$02,$01,$03
	.byte $00,$00,$00,$01,$00,$02,$01,$03
	.byte $00,$00,$00,$01,$00,$02,$01,$03

	; Graphics frames for invader.
	; $00 when there are no invaders to show.
invaders_frame0:
	.byte $00,$10,$10,$10,$10,$10,$10,$10
	.byte $00,$10,$10,$10,$10,$10,$10,$10
	.byte $00,$10,$10,$10,$10,$10,$10,$10
	.byte $00,$10,$10,$10,$10,$10,$10,$10
	.byte $00,$10,$10,$10,$10,$10,$10,$10
	.byte $00,$10,$10,$10,$10,$10,$10,$10
	.byte $00,$10,$10,$10,$10,$10,$10,$10
	.byte $00,$10,$10,$10,$10,$10,$10,$10

	; NUSIZx cannot offset a player
	; So we need the offset for the leftmost invader.
	;
invaders_offset0:
	.byte $00,$00,$10,$00,$20,$00,$10,$00
	.byte $00,$00,$10,$00,$20,$00,$10,$00
	.byte $00,$00,$10,$00,$20,$00,$10,$00
	.byte $00,$00,$10,$00,$20,$00,$10,$00
	.byte $00,$00,$10,$00,$20,$00,$10,$00
	.byte $00,$00,$10,$00,$20,$00,$10,$00
	.byte $00,$00,$10,$00,$20,$00,$10,$00
	.byte $00,$00,$10,$00,$20,$00,$10,$00
invaders_bits1:
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $01,$01,$01,$01,$01,$01,$01,$01
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $02,$02,$02,$02,$02,$02,$02,$02
	.byte $01,$01,$01,$01,$01,$01,$01,$01
	.byte $03,$03,$03,$03,$03,$03,$03,$03
invaders_frame1:
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
invaders_offset1:
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $30,$30,$30,$30,$30,$30,$30,$30
	.byte $40,$40,$40,$40,$40,$40,$40,$40
	.byte $30,$30,$30,$30,$30,$30,$30,$30
	.byte $50,$50,$50,$50,$50,$50,$50,$50
	.byte $30,$30,$30,$30,$30,$30,$30,$30
	.byte $40,$40,$40,$40,$40,$40,$40,$40
	.byte $30,$30,$30,$30,$30,$30,$30,$30

	; Invader bit on row (leftmost to rightmost)
invader_bit:
	.byte $01,$02,$04,$08,$10,$20


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
		echo "Error: Page crossing 1"
		err	; Force assembler error
        endif
	if (x2_p1 & $ff00) != (x2_p2 & $ff00)
		echo "Error: Page crossing 2"
		err	; Force assembler error
        endif
	if (x3_p1 & $ff00) != (x3_p2 & $ff00)
		echo "Error: Page crossing 3"
		err	; Force assembler error
        endif
	if (x4_p1 & $ff00) != (x4_p2 & $ff00)
		echo "Error: Page crossing 4"
		err	; Force assembler error
        endif
	
	org $fef1	; Table at last page of ROM
			; Shouldn't cross page
fine_adjust:
	.byte $70,$60,$50,$40,$30,$20,$10,$00
	.byte $f0,$e0,$d0,$c0,$b0,$a0,$90


invaders_bitmaps:
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000

	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000

	.byte %01100110
	.byte %00111100
	.byte %01011010
	.byte %11111111
	.byte %10111101
	.byte %10100101
	.byte %00100100
	.byte %00000000

	.byte %00100100
	.byte %00100100
	.byte %00111100
	.byte %01011010
	.byte %11111111
	.byte %10111101
	.byte %01000010
	.byte %10000001

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
