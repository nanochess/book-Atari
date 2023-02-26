	;
	; Diamond Craze (chapter 9 of Programming Games for Atari 2600)
	;
	; by Oscar Toledo G.
	; https://nanochess.org/
	;
	; Creation date: Jul/01/2022.
	; Revision date: Jul/03/2022. Completed.
	; Revision date: Nov/13/2022. Added NTSC definition to choose NTSC/PAL.
	;

	PROCESSOR 6502
	INCLUDE "vcs.h"

NTSC	= 1		; Define to 1 for NTSC, 0 for PAL

FRAME	= $80		; Displayed frames count.
NEXTSPR	= $81		; Next sprite to show.
MODE	= $82		; Game mode.
LIVES	= $83		; Total lives remaining.
TEMP1	= $84		; Temporary variable 1.
TEMP2	= $85		; Temporary variable 2.
TEMP3	= $86		; Temporary variable 3.
RAND	= $87		; Pseudorandom number.
SPRITE0	= $88		; Pointer to bitmap for sprite 0.
SPRITE1	= $90		; Pointer to bitmap for sprite 1.
YPOS0	= $98		; Y-position for sprite 0.
YPOS1	= $99		; Y-position for sprite 1.
XPOS	= $9a		; X-position of things.
YPOS	= $9f		; Y-position of things.
SPRITE	= $a4		; Sprite number of things.
DIR	= $a9		; Direction/state of things.
SCORE1	= $ae		; First digit of score.
SCORE2	= $af		; Second digit of score.
ROW	= $b0		; Maze row.
SOUND	= $b1		; Sound effect duration.

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

	LDA #$00	; Configure SWCHA as input
	STA SWACNT
	STA SWBCNT	; Also SWCHB

	LDA #0		; Game stopped.
	STA MODE	; Set mode.

	JSR restart_game	; Prepare variables.

SHOW_FRAME:
	LDA #$00	; Black.
	STA COLUBK	; Background color.
	LDA #$88	; Blue.
	STA COLUPF	; Playfield color.
	LDA #$01	; Mirror right side.
	STA CTRLPF

	STA HMCLR	; Clear horizontal motion registers

	STA CXCLR	; Clear collision registers

	STA WSYNC
	LDA #2		; Start of vertical retrace.
	STA VSYNC
	STA WSYNC
	STA WSYNC
	STA WSYNC
    IF NTSC
	LDA #42		; Time for NTSC top border
    ELSE
	LDA #71		; Time for PAL top border
    ENDIF
	STA TIM64T
	LDA #0		; End of vertical retrace.
	STA VSYNC

	LDX NEXTSPR	; Get current sprite.
	INX		; Increment.
	CPX #5		; Is it 5?
	BNE M1		; No, jump.
	LDX #0		; Make it zero.
M1:	STX NEXTSPR	; Save new current sprite.
	
	LDA YPOS,X	; Get Y-position of sprite.
	CLC
	ADC #8		; Adjust for faster drawing.
	STA YPOS0	; Save Y-position for player 0.

	LDA SPRITE,X	; Get frame of sprite.
	TAY
	LDA sprites_color,Y	; Get color.
	STA COLUP0	; Set color for player 0.

	TYA		; Index frame to bitmaps.
	ASL		; x2
	ASL		; x4
	ASL		; x8
	TAY
 	LDA sprites_bitmaps,Y	; Copy in RAM for faster drawing.
	STA SPRITE0
 	LDA sprites_bitmaps+1,Y
	STA SPRITE0+1
 	LDA sprites_bitmaps+2,Y
	STA SPRITE0+2
 	LDA sprites_bitmaps+3,Y
	STA SPRITE0+3
 	LDA sprites_bitmaps+4,Y
	STA SPRITE0+4
 	LDA sprites_bitmaps+5,Y
	STA SPRITE0+5
 	LDA sprites_bitmaps+6,Y
	STA SPRITE0+6
 	LDA sprites_bitmaps+7,Y
	STA SPRITE0+7

	LDA XPOS,X	; Desired X position
	LDX #0		; Player 0
	JSR x_position	; Set position.

	LDX NEXTSPR	; Get current sprite.
	INX		; Increment.
	CPX #5		; Is it 5?
	BNE M2		; No, jump.
	LDX #0		; Make it zero.
M2:	STX NEXTSPR	; Save new current sprite.

	LDA YPOS,X	; Get Y-position of sprite.
	CLC
	ADC #8		; Adjust for faster drawing.
	STA YPOS1	; Save Y-position for player 1.

	LDA SPRITE,X	; Get frame of sprite.
	TAY
	LDA sprites_color,Y	; Get color.
	STA COLUP1	; Set color for player 1.

	TYA		; Index frame to bitmaps.
	ASL		; x2
	ASL		; x4
	ASL		; x8
	TAY
 	LDA sprites_bitmaps,Y	; Copy in RAM for faster drawing.
	STA SPRITE1
 	LDA sprites_bitmaps+1,Y
	STA SPRITE1+1
 	LDA sprites_bitmaps+2,Y
	STA SPRITE1+2
 	LDA sprites_bitmaps+3,Y
	STA SPRITE1+3
 	LDA sprites_bitmaps+4,Y
	STA SPRITE1+4
 	LDA sprites_bitmaps+5,Y
	STA SPRITE1+5
 	LDA sprites_bitmaps+6,Y
	STA SPRITE1+6
 	LDA sprites_bitmaps+7,Y
	STA SPRITE1+7

	LDA XPOS,X	; Desired X position.
	LDX #1		; Player 1.
	JSR x_position	; Set position.

	STA WSYNC	; Wait for scanline start.
	STA HMOVE	; Write HMOVE, only can be done
			; just after STA WSYNC.

	LDA #0
	STA ROW		; Index into maze data.

	;
	; Macros for sprite handler.
	; This only defines the macros.
	;
	; No code is generated until the
	; macros are invoked.
	;

	MAC sprite_handler_prev

	DEC YPOS0	; 5: Decrement Y-coordinate for player 0.
	DEC YPOS1	; 10: Decrement Y-coordinate for player 1.

	LDA #$00	; 12: No graphic for player 1.
	LDX YPOS1	; 15: Get Y-coordinate for player 1.
	CPX #$08	; 17: Is it visible?
	BCS .+4		; 19: No, jump.
	LDA SPRITE1,X	; 23: Load graphic from bitmap.
	TAY		; 25: Save into Y register.

	LDA #$00	; 27: No graphic for player 0.
	LDX YPOS0	; 30: Get Y-coordinate for player 0.
	CPX #$08	; 32: Is it visible?
	BCS .+4		; 34: No, jump.
	LDA SPRITE0,X	; 38: Load graphic from bitmap.
	TAX		; 40: Save into X register.

	ENDM

	MAC sprite_handler_post

	STX GRP0	; 3: Setup graphic for player 0.
	STY GRP1	; 6: Setup graphic for player 1.

	ENDM

	; Move player
	LDA MODE	; Read game state.
	CMP #1		; Game playing?
	BNE M27		; No, jump.
	LDA SWCHA	; Read the joystick.
	AND #$F0	; Separate joystick 1 bits.
	CMP #$F0	; Any movement?
	BEQ M27		; No, jump.
	LDY #$83	; Right + bitmask.
	ROL		; Move to right? (rotate bit into carry)
	BCC M5		; Yes, jump. (carry = 0)
	LDY #$42	; Left + bitmask.
	ROL		; Move to left? (rotate bit into carry)
	BCC M5		; Yes, jump. (carry = 0)
	LDY #$21	; Down + bitmask.
	ROL		; Move to down? (rotate bit into carry)
	BCC M5		; Yes, jump. (carry = 0)
	LDY #$10	; Up + bitmask (it must be)
M5:	STY TEMP2	; Desired direction.
	LDX #0		; X = 0 (player index)
	JSR aligned	; Player is grid-aligned?
	BCC M6		; No, jump.
	JSR can_move	; Get possible directions
	LDA TEMP2	; Get desired direction.
	AND #$F0	; Separate bitmask.
	BIT TEMP1	; Can it move?
	BNE M28		; No, jump.
	LDA TEMP2	; Get desired direction.
	AND #$03	; Separate number.
	STA DIR		; Put as new direction.
M28:	LDY DIR		; Get current direction.
	LDA bit_mapping+4,Y	; Get bitmask.
	BIT TEMP1	; Can it move?
	BNE M27		; No, jump.
M6:	JSR move_sprite	; Move player.
M27:

	sprite_handler_prev

WAIT_FOR_TOP:
	LDA INTIM	; Read timer
	BNE WAIT_FOR_TOP	; Branch if not zero.
	STA WSYNC	; Resynchronize on last border scanline

	LDA #$88	; Color of playfield
	STA COLUPF
	LDA #1
	STA CTRLPF	; Mirrored playfield

	STA WSYNC
	LDA #0		; Disable blanking
	STA VBLANK
	STA HMCLR

M3:
	STA WSYNC	; 3:
	sprite_handler_post	; 9:
	LDX ROW		; 12:
	LDA Maze_PF0,X	; 16: Read maze pixels PF0.
	STA PF0		; 19: Set TIA PF0
	LDA Maze_PF1,X	; 23: Read maze pixels PF1.
	STA PF1		; 27: Set TIA PF1
	LDA Maze_PF2,X	; 30: Read maze pixels PF2.
	STA PF2		; 34: Set TIA PF2

	sprite_handler_prev	; 74: Just in time.

	STA WSYNC	; 3:
	sprite_handler_post	; 9:
	INC ROW		; 14:
	sprite_handler_prev	; 54:

	STA WSYNC	; 3:
	sprite_handler_post	; 9:
	sprite_handler_prev	; 49:

	STA WSYNC	; 3:
	sprite_handler_post	; 9:
	sprite_handler_prev	; 49:

	LDA ROW		; 52:
	CMP #46		; 54: Has it displayed all rows?
	BEQ M4		; 56: Yes, exit loop.
	JMP M3		; 59: No, jump back to display.
M4:

	STA WSYNC	
	LDA #$C8	; Green color.
	STA COLUP0	; For score digit 0.
	STA COLUP1	; For score digit 1.
	LDX LIVES	; Get current number of lifes.
	LDA bitmap_lives,X	; Index into table.
	LDY #0		; Zero for other playfield registers.
	STY PF0		; Zero for PF0.
	STA PF1		; Lifes in PF1.
	STY PF2		; Zero for PF2.
	LDA SCORE1	; First score digit.
	ASL		; x2
	ASL		; x4
	ASL		; x8
	STA TEMP1	; Store offset.
	LDA SCORE2	; Second score digit.
	ASL		; x2
	STA RESP0	; Position first digit.
	STA RESP1	; Position second digit.
	ASL		; x4
	ASL		; x8
	STA TEMP2	; Store offset.

	LDY #7		; 7 scanlines for score
M38:	STA WSYNC	; Synchronize with scanline.
	LDX TEMP1	; Row on score 1.
	LDA numbers_bitmaps,X	; Read bitmap.
	STA GRP0	; Write as graphic for player 0.
	LDX TEMP2	; Row on score 2.
	LDA numbers_bitmaps,X	; Read bitmap.
	STA GRP1	; Write as graphic for player 1.
	INC TEMP1	; Increase row of score 1.
	INC TEMP2	; Increase row of score 2.
	DEY		; Decrease scanlines to display.
	BNE M38		; Jump if still there are some.

	LDA #2		; Enable blanking
	STA WSYNC
	STA VBLANK

    IF NTSC
	LDA #35		; Time for NTSC bottom border
    ELSE
	LDA #64		; Time for PAL bottom border
    ENDIF
	STA TIM64T

	LDA #0		; Disable ALL graphics.
	STA PF0		; Playfield.
	STA PF1
	STA PF2
	STA GRP0	; Player 0.
	STA GRP1	; Player 1.
	STA ENAM0	; Missile 0.
	STA ENAM1	; Missile 1.
	STA ENABL	; Ball.

	;
	; Detect reset pressed (stops the game)
	;
	LDA SWCHB	; Read console switches.
	AND #1		; Reset pressed?
	BNE M33		; No, jump.
	LDA #0		; Disable game.
	STA MODE	; Set mode.
M33:
	;
	; Detect select pressed (starts the game)
	;
	LDA SWCHB	; Read console switches.
	AND #2		; Select pressed?
	BNE M32		; No, jump.
	LDA #1		; Start game.
	STA MODE	; Set mode.
	LDA #3		; 3 lifes to start.
	STA LIVES	; Set variable.
	LDA #0		; Reset score.
	STA SCORE1
	STA SCORE2
	JSR restart_game	; Reset enemies/diamond.
M32:
	;
	; Detect gameplay mode
	;
	LDA MODE
	CMP #1		; Gameplay enabled?
	BEQ M34		; Yes, jump.
	LDX #0		; Turn off background "music"
	STX AUDV1
	CMP #2		; Dead player?
	BNE M36		; No, jump.
	DEC TEMP3	; Countdown.
	BNE M36		; Completed? No, jump.
	DEC LIVES	; Decrease one life.
	BEQ M37		; Zero? Yes, jump.
	JSR restart_game	; Reset enemies/diamond.
	LDA #1		; Restart game.
	STA MODE
	JMP M35

M37:	LDA #0		; Disable game.
	STA MODE
M36:
	JMP M35
M34:
	; Background siren (arcade-like)
	LDA FRAME	; Get frame number.
	AND #$10	; In alternate 16 frames?
	BEQ M41		; No, jump.
	LDA FRAME	; Read frame number.
	AND #$0F	; Modulo 16.
	EOR #$0F	; Exclusive OR gets value 15-0
	JMP M42

M41:	LDA FRAME	; Read frame number.
	AND #$0F	; Modulo 16 (0-15)
M42:	STA AUDF1	; Set frequency.
	LDA #12		; Set volume.
	STA AUDC1
	LDA #6		; Set shape.
	STA AUDV1

	; Catch diamond
	LDA XPOS	; X-position of player.
	CMP XPOS+4	; Is same as X-position of diamond?
	BNE M7		; No, jump.
	LDA YPOS	; Y-position of player.
	CMP YPOS+4	; Is same as Y-position of player?
	BNE M7		; No, jump.
	LDA #6		; Start sound effect.
	STA AUDF0
	LDA #6
	STA AUDC0
	LDA #12
	STA AUDV0
	LDA #15		; Duration: 15 frames.
	STA SOUND
	JSR restart_diamond	; Put another diamond.
	INC SCORE2	; Increase low-digit of score.
	LDA SCORE2
	CMP #10
	BNE M7
	LDA #0
	STA SCORE2
	INC SCORE1	; Increase high-digit of score.
	LDA SCORE1
	CMP #10
	BNE M7
	LDA #9		; Limit to 99.
	STA SCORE2
	STA SCORE1
M7:

	; Enemy catches player
	LDX #1		; Enemy 1
M8:	LDA XPOS	; X-position of player.
	SEC
	SBC XPOS,X	; Minus X-position of enemy.
	BCS M29		; Jump if result is positive (no borrow).
	EOR #$FF	; Negate.
	ADC #1
M29:	CMP #4		; Near to less than 4 pixels?
	BCS M30		; No, jump.
	LDA YPOS	; Y-position of player.
	SEC
	SBC YPOS,X	; Minus Y-position of enemy.
	BCS M31		; Jump if result is positive (no borrow).
	EOR #$FF	; Negate.
	ADC #1
M31:	CMP #4		; Near to less than 4 pixels?
	BCS M30		; No, jump.
	LDA #2		; Player dead.
	STA MODE	; Set mode.
	LDA #60		; 60 frames.
	STA TEMP3	; Set counter.
	LDA #30		; Start sound effect.
	STA AUDF0
	LDA #6
	STA AUDC0
	LDA #12
	STA AUDV0
	LDA #30		; Duration: 30 frames.
	STA SOUND
M30:
	INX		; Go to next enemy.
	CPX #4		; All enemies checked?
	BNE M8		; No, continue.

	;
	; Move enemies.
	;
	LDA SWCHB	; Read console switches.
	AND #$40	; Difficulty 1 is (A)dvanced?
	BNE M39		; Yes, jump.
	LDA FRAME	; Get current frame number.
	AND #1		; Only move each 2 frames.
	BNE M39		; Jump if enemies can move.
	JMP M26		; Or avoid code.
M39:
	LDA #1		; Enemy 1.
M16:	PHA		; Save counter.
	TAX		; Put into X to access enemy.
	JSR aligned	; Enemy is grid-aligned?
	BCC M17		; No, jump to move.
	JSR can_move	; Get possible directions.
	LDA DIR,X	; Current direction.
	CMP #2		; Is it up or down?
	BCS M21		; No, jump.
	LDA XPOS,X	; Get enemy X-coordinate.
	CMP XPOS	; Compare with player X-coordinate.
	BEQ M25		; Same? Try to move in same direction.
	BCC M22		; If enemy is to the left, jump.
	LDY #2
	LDA #$40	; Left direction.
	BIT TEMP1	; Can it go?
	BEQ M23		; Yes, jump.
M22:	LDY #3		
	LDA #$80	; Right direction.
	BIT TEMP1	; Can it go?
	BEQ M23		; Yes, jump.
	LDY #2
	LDA #$80	; Left direction.
	BIT TEMP1	; Can it go?
	BEQ M23		; Yes, jump.
M25:	LDY DIR,X	; Get current direction.
	LDA bit_mapping+4,Y	; Get bitmask.
	BIT TEMP1	; Can keep going?
	BEQ M23		; Yes, jump.
	INY		; Try other direction.
	TYA
	AND #$03	; Limit to four.
	STA DIR,X	; Update direction.
	JMP M25		; Verify if can move.

M21:	LDA YPOS,X	; Get enemy Y-coordinate.
	CMP YPOS	; Compare with player Y-coordinate.
	BEQ M25		; Same? Try to move in same direction.
	BCC M24		; If the enemy is above player, jump.
	LDY #0
	LDA #$10	; Up direction.
	BIT TEMP1	; Can it go?
	BEQ M23		; Yes, jump.
M24:	LDY #1
	LDA #$20	; Down direction.
	BIT TEMP1	; Can it go?
	BEQ M23		; Yes, jump.
	LDY #0
	LDA #$10	; Up direction.
	BIT TEMP1	; Can it go?
	BNE M25		; No, try same direction or another.

M23:	STY DIR,X	; Write new movement direction.

M17:	JSR move_sprite	; Move enemy
	LDA FRAME	; Get current frame number.
	AND #4		; Each four frames change animation.
	LSR
	LSR
	ADC #1
	STA SPRITE,X	; Update animation frame.
	PLA		; Restore counter.
	CLC		; Increment by one.
	ADC #1
	CMP #4		; Processed all three enemies?
	BEQ M26		; Yes, jump.
	JMP M16		; No, continue.
M26:

M35:
	;
	; Turn off sound effect when playing finished.
	;
	DEC SOUND	; Decrement duration of sound effect.
	BNE M40		; Jump if not zero.
	LDA #0		; Turn off volume.
	STA AUDV0
M40:

WAIT_FOR_BOTTOM:
	LDA INTIM	; Read timer
	BNE WAIT_FOR_BOTTOM	; Branch if not zero.
	STA WSYNC	; Resynchronize on last border scanline

	INC FRAME	; Count frames

	JMP SHOW_FRAME	; Repeat the game loop.

	;
	; Restart the game.
	;
restart_game:
	LDX #19		; 5 XPOS + 5 YPOS + 5 SPRITE + 5 DIR - 1
M9:
	LDA start_positions,X	; Load initialization table.
	STA XPOS,X	; Update RAM.
	DEX		; Decrement counter.
	BPL M9		; Jump if still positive.
restart_diamond:
	JSR random	; Get a pseudorandom number.
	AND #$07	; Modulo 8.
	TAX		; Copy to X for index.
	LDA x_diamond,X	; Get X position for diamond.
	STA XPOS+4	; Set X of diamond.
	LDA y_diamond,X	; Get Y position for diamond.
	STA YPOS+4	; Set Y of diamond.
	RTS

	;
	; Start positions for all sprites.
	;
start_positions:
	.byte 77,61,69,85,85	; Values for XPOS.
	.byte 100,76,76,76,76	; Values for YPOS.
	.byte 0,1,1,1,3		; Sprite frame number.
	.byte 0,2,0,0,0		; Starting movement direction.

	; Coordinates where diamonds can appear
	; X and Y coordinates are paired.
x_diamond:
	.byte 5,149,81,81,81,89,149,5
y_diamond:
	.byte 4,4,28,76,132,156,172,172

	; Playfield bitmap for available lives.
bitmap_lives:
	.byte $00,$80,$a0,$a8

	;
	; Generates a pseudo-random number.
	;
random:
	LDA RAND
	SEC
	ROR
	EOR FRAME
	ROR
	EOR RAND
	ROR
	EOR #9
	STA RAND
	RTS

	;
	; Detect if a sprite is grid-aligned
	;
	; X = Sprite number (0-4)
	;
	; Returns: Carry flag set if it is grid-aligned.
	;
aligned:
	LDA XPOS,X	; Get the X-position of sprite.
	SEC
	SBC #5		; Minus 5.
	AND #7		; Modulo 8.
	BNE M15		; If not zero, jump.
	LDA YPOS,X	; Get the Y-position of sprite.
	SEC
	SBC #4		; Minus 4.
	AND #7		; Modulo 8.
	BNE M15		; If not zero, jump.
	SEC		; Set carry flag (aligned).
	RTS

M15:	CLC		; Clear carry flag (unaligned).
	RTS

	;
	; Detect possible directions for a sprite.
	; The sprite should be grid-aligned.
	;
	; X = Sprite number (0-4)
	;
can_move:
	TXA
	PHA
	; Test for up direction.
	LDA YPOS,X	; Y-coordinate of sprite.
	TAY		; Copy into Y.
	DEY		; One pixel upwards
	LDA XPOS,X	; X-coordinate of sprite.
	TAX		; Copy into X.
	JSR hit_wall	; Hit wall?
	ROR TEMP1	; Insert carry into bit 7.

	PLA
	TAX
	PHA
	; Test for down direction.
	LDA YPOS,X	; Y-coordinate of sprite.
	CLC
	ADC #8		; 8 pixels downward.
	TAY		; Put into Y.
	LDA XPOS,X	; X-coordinate of sprite.
	TAX		; Copy into X.
	JSR hit_wall	; Hit wall?
	ROR TEMP1	; Insert carry into bit 7.

	PLA
	TAX
	PHA
	; Test for left direction.
	LDA YPOS,X	; Y-coordinate of sprite.
	TAY		; Put into Y.
	LDA XPOS,X	; X-coordinate of sprite.
	TAX		; Put into X.
	DEX		; One pixel to left.
	JSR hit_wall	; Hit wall?
	ROR TEMP1	; Insert carry into bit 7.

	PLA
	TAX
	PHA
	; Test for right direction.
	LDA YPOS,X	; Y-coordinate of sprite.
	TAY		; Put into Y.
	LDA XPOS,X	; X-coordinate of sprite.
	CLC
	ADC #8		; 8 pixels to the right.
	TAX		; Put into X.
	JSR hit_wall	; Hit wall?
	ROR TEMP1	; Insert carry into bit 7.
	PLA
	TAX
	RTS

	; Detect wall hit
	; X = X-coordinate
	; Y = Y-coordinate
hit_wall:
	TYA		; Copy Y into A
	LSR		; /2
	LSR		; /4
	STA TEMP3	; Maze row to test.
	DEX		
	TXA		; Copy X into A.
	LSR		; Divide by 4 as each playfield...
	LSR		; ...pixel is 4 pixels.
	TAX
	LDA wall_mapping,X
	AND #$F8	; Playfield register to test (PF0/PF1/PF2)
	CLC
	ADC TEMP3	; Add to maze row to create byte offset.
	TAY		; Y = Playfield byte offset
	LDA wall_mapping,X
	AND #$07	; Extract bit number.
	TAX
	LDA bit_mapping,X	; Convert to bit mask.
	AND Maze_PF0,Y	; Check against maze data
	BEQ no_hit	; Jump if zero (no hit).

	SEC		; Wall hit.
	RTS

no_hit:	CLC		; No wall hit.
	RTS

	; Mapping of horizontal pixel to maze byte.
wall_mapping:
	.byte $04,$05,$06,$07
	.byte $37,$36,$35,$34,$33,$32,$31,$30
	.byte $60,$61,$62,$63,$64,$65,$66,$67
	.byte $67,$66,$65,$64,$63,$62,$61,$60
	.byte $30,$31,$32,$33,$34,$35,$36,$37
	.byte $07,$06,$05,$04

	; Conversion of bit to bitmask.
bit_mapping:
	.byte $01,$02,$04,$08,$10,$20,$40,$80

	;
	; Move a sprite in the current direction.
	;
move_sprite:
	LDA DIR,X	; Get the current direction of sprite.
	CMP #3		; Right?
	BEQ M20		; Yes, jump.
	CMP #2		; Left?
	BEQ M19		; Yes, jump.
	CMP #1		; Down?
	BEQ M18		; Yes, jump.
	DEC YPOS,X	; Must be up. Decrease Y-coordinate.
	RTS

M18:	INC YPOS,X	; Increase Y-coordinate.
	RTS

M19:	DEC XPOS,X	; Decrease X-coordinate.
	RTS

M20:	INC XPOS,X	; Increase X-coordinate.
	RTS

	org $fe00

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

; mode: symmetric mirrored line-height 4

Maze_PF0:
	.byte $F0,$10,$10,$90,$90,$90,$90,$10
	.byte $10,$90,$90,$90,$90,$10,$10,$F0
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$F0,$10,$10,$90
	.byte $90,$10,$10,$70,$40,$40,$70,$10
	.byte $10,$90,$90,$10,$10,$F0,$00,$00
Maze_PF1:
	.byte $FF,$00,$00,$E7,$24,$24,$E7,$00
	.byte $00,$E6,$26,$26,$E6,$06,$06,$E7
	.byte $24,$24,$27,$26,$26,$20,$20,$26
	.byte $26,$26,$26,$26,$E6,$00,$00,$E7
	.byte $E7,$60,$60,$66,$66,$66,$66,$06
	.byte $06,$FF,$FF,$00,$00,$FF,$00,$00
Maze_PF2:
	.byte $3F,$20,$20,$27,$24,$24,$E7,$00
	.byte $00,$FE,$02,$02,$FE,$80,$80,$9F
	.byte $90,$90,$9F,$00,$00,$FE,$02,$02
	.byte $FE,$00,$00,$FE,$FE,$80,$80,$9F
	.byte $9F,$00,$00,$FE,$02,$02,$FE,$80
	.byte $80,$9F,$9F,$00,$00,$FF,$00,$00

	; Color for each sprite frame
sprites_color:
	.byte $2e,$5e,$5e,$0e

	; Bitmaps for each sprite frame.
sprites_bitmaps:
	.byte %00111100	; 0: Happy face.
	.byte %01111110
	.byte %11000011
	.byte %10111101
	.byte %11111111
	.byte %10011001
	.byte %01111110
	.byte %00111100

	.byte %11000000	; 1: Monster 1.
	.byte %01111100
	.byte %01000011
	.byte %11100110
	.byte %11111111
	.byte %11011011
	.byte %10111101
	.byte %01111110

	.byte %00000011	; 2: Monster 2.
	.byte %00111110
	.byte %11000010
	.byte %01100111
	.byte %11111111
	.byte %11011011
	.byte %10111101
	.byte %01111110

	.byte %00000000	; 3: Diamond.
	.byte %00011000
	.byte %00110100
	.byte %01111010
	.byte %11111101
	.byte %10000011
	.byte %01111110
	.byte %00000000

	ORG $FFFC
	.word START
	.word START
