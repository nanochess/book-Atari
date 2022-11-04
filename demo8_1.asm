	;
	; The Lost Kingdom (chapter 8)
	;
	; by Oscar Toledo G.
	; https://nanochess.org/
	; 
	; Creation date: Jun/14/2022.
	; Revision date: Jun/19/2022. Completed.
	;

	PROCESSOR 6502
	INCLUDE "vcs.h"

FRAME	= $0080		; Frame number.
ROOM	= $0081		; Current room (0-9).
XPOS	= $0082		; X position of player.
YPOS	= $0083		; Y position of player.
FPLAYER	= $0084		; Frame for player.
SPRITE0	= $0085		; Player sprite.
XPREV	= $0087		; Previous X position of player.
YPREV	= $0088		; Previous Y position of player.
XOBJ	= $0089		; X position of object.
YOBJ	= $008a		; Y position of object.
SPRITE1	= $008b		; Object sprite.
TEMP1	= $008d		; Temporary 1.
TEMP2	= $008e		; Temporary 2.
TEMP3	= $008f		; Temporary 3.
SEQ	= $0090		; Animated sequence.
VOBJ	= $0091		; Current object on screen.
SOUND	= $0092		; Counter to turn off sound.
OBJ	= $0093		; List of objects (room+x,y)

ROOM_DATA	= $009f	; Pointers to room data (6 bytes)

SPRCOPY	= $00A5		; Sprite copy

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

	JSR restart_game

    if 0		; Enable to 1 to test sword.
	LDA #160
	STA YPOS
	LDA #4		; Current room
	STA ROOM
	LDA #$FF	; Sword carried
	STA OBJ+0
    endif

SHOW_FRAME:
	LDA #$88	; Blue.
	STA COLUBK	; Background color.
	LDA #$cF	; Green.
	STA COLUP1	; Player 1 color.
	LDA #$21	; Mirror right side. Ball 4px.
	STA CTRLPF

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

	LDA XPOS	; Desired X position
	LDX #0		; Player 0
	JSR x_position

	LDA ROOM	; Get current room
	ASL		; x2
	ASL		; x4
	ADC #map&255	; Add to map data (low byte)
	STA TEMP1	; Setup low byte of address.
	LDA #map>>8	; High-byte.
	ADC #0		; Carry add.
	STA TEMP2	; Setup high byte of address.
	LDY #0		; Offset into map data.
	LDA (TEMP1),Y	; Read first byte.
	STA ROOM_DATA	; Store low byte of address.
	INY
	LDA (TEMP1),Y	; Read second byte.
	STA ROOM_DATA+1	; Store high byte of address.
	INY
	LDA (TEMP1),Y	; Get room color.
	STA COLUPF	; Set color for playfield.
	INY
	LDA (TEMP1),Y	; Get extra wall.
	BEQ M9		; Jump if no walls.
	LDX #157	; X = 157 for right wall.
	CMP #1		; Right wall?
	BEQ M8		; Yes, jump.
	LDX #2		; X = 2 for left wall.
M8:	TXA		; A = X
	LDX #4		; Ball.
	JSR x_position	; Setup position.
	LDA #2		; Enable ball as wall.
	STA ENABL	; Remains enabled.
M9:

	LDA ROOM_DATA	; Low byte of room data address.
	CLC
	ADC #24		; Add 24 bytes (jump PF0 regs).
	STA ROOM_DATA+2	; Low byte of 2nd room data addr.
	LDA ROOM_DATA+1	; Low byte.
	ADC #0		; Carry for 2nd room data addr.
	STA ROOM_DATA+3	; High byte.
	LDA ROOM_DATA+2	
	CLC
	ADC #24		; Add 24 bytes (jump PF1 regs).
	STA ROOM_DATA+4	; Low byte of 3rd room data addr.
	LDA ROOM_DATA+3
	ADC #0		; Carry for 3rd room data addr.
	STA ROOM_DATA+5	; High byte.

	LDA FPLAYER	; Current frame for player.
	ASL		; x2
	TAY		; Put in Y to use as index.
	LDA ply_sprite,Y	; Read address of graphic data.
	STA SPRITE0	; Low-byte of address.
	LDA ply_sprite+1,Y	; Read address of graphic data.
	STA SPRITE0+1	; High-byte of address.
	LDY #$0F	; Point to highest byte of sprite.
M34:	LDA (SPRITE0),Y	; Copy from sprite data.
	STA SPRCOPY,Y	; Into zero-page memory.
	DEY		; Decrement counter.
	BPL M34		; Jump if it still is positive.

	LDA #$E0	; Y-coordinate for non-visible object.
	STA YOBJ	; Save.
	LDA #$FF	; No visible object.
	STA VOBJ	; Save.

	LDX #0		; Index into object table.
	LDY #0		; Index into graphics table.
M10:	LDA OBJ,X	; Read object room.
	CMP #$FF	; Object carried?
	BEQ M12		; Yes, jump.
	CMP ROOM	; Is it at same room?
	BNE M11		; No, jump.
M12:
	STY VOBJ	; Save current object on screen.
	LDA SEQ		; Sequency animation.
	CMP #3		; At step 3 or higher?
	BCC M30		; No, jump.
	TYA		
	CLC
	ADC SEQ		; Add sequency step x2
	ADC SEQ		; (for hand coming out of lake)
	ADC #2		; Add 2
	TAY		; Save as new graphics index.
M30:
	LDA obj_sprite,Y	; Graphic low-byte addr.
	STA SPRITE1	; Save.
	LDA obj_sprite+1,Y	; Graphic high-byte addr.
	STA SPRITE1+1	; Save.
	LDA OBJ,X
	CMP #$FF	; Object being carried?
	BNE M14		; No, jump.
	LDA XPOS	; Get X-coordinate of player.
	CLC
	ADC #8		; Put at right of player.
	STA XOBJ	; Save X-coordinate of object.
	LDA YPOS	; Get Y-coordinate of player.
	STA YOBJ	; Put object at same coordinate.
	JMP M15
M14:
	LDA OBJ+1,X	; Get X-coordinate from table.
	STA XOBJ
	LDA OBJ+2,X	; Get Y-coordinate from table.
	STA YOBJ
M11:	INY
	INY
	INX
	INX
	INX
	CPX #12		; All objects revised?
	BNE M10		; Branch if not.
M15:
	LDA XOBJ	; Desired X position
	LDX #1		; Player 1
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

	;
	; Macro for sprite handler.
	; This only defines the macro.
	;
	; No code is generated until the
	; macro is invoked.
	;
	MAC sprite_handler

	BCS .+9		; 2
	LDA player_color,X	; 6
	STA COLUP0	; 9
	LDA SPRCOPY,X	; 13
	STA GRP0	; 16

	LDA #$00	; 18
	CPY #$F0	; 20
	BCC .+4		; 22
	LDA (SPRITE1),Y	; 27
	STA GRP1	; 30

	ENDM
	; End of macro

	LDA #0		; Index into room data.
	STA TEMP1	; Save for counting.

	LDA YPOS	; Y-coordinate of player.
	CLC
	ADC #$10	; Plus $10 to simplify access.
	TAX		; Save into X for counting.

	LDA YOBJ	; Y-coordinate of object.
	STA TEMP3	; Save for counting.

M1:
	LDY TEMP1	; Get index of room data.
	LDA (ROOM_DATA),Y	; Read pixels PF0.
	STA WSYNC	; 3
	STA PF0		; 6
	LDA (ROOM_DATA+2),Y	; 11 Read pixels PF1.
	STA PF1		; 14
	LDA (ROOM_DATA+4),Y	; 19 Read pixels PF2.
	STA PF2		; 22
	LDY TEMP3	; 25 Y-coordinate of object.
	LDA #$00	; 27 For resetting GRP0.
	CPX #$10	; 29 Player is visible?
	sprite_handler	; 59 Invoke macro.
	DEX		; 61 Y counter of player.
	DEY		; 63 Y counter of object.

	LDA #$00	; 65
	CPX #$10	; 67

	STA WSYNC	
	sprite_handler	; Invoke macro.
	DEX		; Y counter of player.
	DEY		; Y counter of object.
	LDA #$00	; For resetting GRP0.	
	CPX #$10	; Player is visible?

	STA WSYNC
	sprite_handler	; Invoke macro.
	DEX		; Y counter of player.
	DEY		; Y counter of object.
	LDA #$00	; For resetting GRP0.	
	CPX #$10	; Player is visible?

	STA WSYNC
	sprite_handler	; Invoke macro.
	DEX		; Y counter of player.
	DEY		; Y counter of object.
	LDA #$00	; For resetting GRP0.	
	CPX #$10	; Player is visible?

	STA WSYNC
	sprite_handler	; Invoke macro.
	DEX		; Y counter of player.
	DEY		; Y counter of object.
	LDA #$00	; For resetting GRP0.	
	CPX #$10	; Player is visible?

	STA WSYNC
	sprite_handler	; Invoke macro.
	DEX		; Y counter of player.
	DEY		; Y counter of object.
	LDA #$00	; For resetting GRP0.	
	CPX #$10	; Player is visible?

	STA WSYNC
	sprite_handler	; Invoke macro.
	DEX		; Y counter of player.
	DEY		; Y counter of object.
	LDA #$00	; For resetting GRP0.	
	CPX #$10	; Player is visible?

	STA WSYNC
	sprite_handler	; Invoke macro.
	DEX		; Y counter of player.
	DEY		; Y counter of object.
	STY TEMP3	; Save Y counter of object.

	INC TEMP1	; Increment index into room data.
	LDA TEMP1
	CMP #24		; Has it reached 24 rows?
	BEQ M2		; Yes, exit loop.
	JMP M1		; No, jump back to display.
M2:

	LDA #2		; Enable blanking
	STA WSYNC
	STA VBLANK

	LDA #35		; Time for NTSC bottom border
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

	; Reset game.
	LDA SWCHB
	AND #$02	; Select pressed?
	BNE M25		; No, jump.
	JSR restart_game	; Restart game.
	JMP M17
M25:

	; Sequence animation.
	LDA SEQ		; Sequence animation.
	CMP #1		; Game won?
	BNE M26		; No, jump.
	JMP M17
M26:

	LDA SEQ		; Sequence animation.
	BEQ M27		; Active? Branch if not.
	LDA OBJ+2	; Use Y-coordinate of sword
	LSR		; as frequency for sound effect.
	LSR
	STA AUDF0
	LDA #12
	STA AUDV0
	LDA #6
	STA AUDC0
	LDA OBJ+2	; Y-coordinate of sword.
	CMP #$18	; Has it reached center of lake?
	BEQ M28		; Yes, jump.
	DEC OBJ+2	; Keep moving sword upwards.
	JMP WAIT_FOR_BOTTOM

M28:	LDA FRAME	; Read frame counter.
	AND #7		; Modulo 8.
	BNE M31		; Branch if not zero.
	LDA SEQ		; Use sequence counter as...
	STA AUDF0	; ...sound frequency.
	LDA #12
	STA AUDV0
	LDA #14
	STA AUDC0
	INC SEQ		; Increase sequence.
M31:	LDA SEQ
	CMP #11		; Hand disappears?
	BEQ M29		; Yes, jump.
	JMP WAIT_FOR_BOTTOM

M29:	LDA #0		; End animation sequence.
	STA SEQ
	LDA #$FF	; Now player carries crown
	STA OBJ+9
	LDA #4		; Sound effect.
	STA AUDF0
	LDA #6
	STA AUDC0
	LDA #12
	STA AUDV0
	LDA #30		; Duration: 30 frames.
	STA SOUND
	JMP WAIT_FOR_BOTTOM

	; Player catches object.
M27:
	LDA CXPPMM	; Player 0 vs Player 1.
	BPL M16		; Jump if no collision.
	LDA VOBJ	; Visible object?
	BMI M16		; Jump if no visible object.
	LSR		; /2
	ADC VOBJ	; +VOBJ = x3
	TAX		; Move to X to use as index.
	LDA #$FF
	STA OBJ,X	; Mark object as being carried.
	LDA #12		; Sound effect.
	STA AUDV0
	LDA #5
	STA AUDF0
	LDA #4
	STA AUDC0
	LDA #3		; Duration: 3 frames.
	STA SOUND
M16:
	; Player "rebounds" on wall.
	LDA CXP0FB	; Hit of player 0 vs Playfield/Ball
	AND #$C0	; Any of the two?
	BEQ M7		; No, jump.
	LDA XPREV	; Restore old X coordinate.
	STA XPOS
	LDA YPREV	; Restore old Y coordinate.
	STA YPOS
	LDA #12		; Sound effect.
	STA AUDV0
	LDA #30
	STA AUDF0
	LDA #6
	STA AUDC0
	LDA #3		; Duration: 3 frames.
	STA SOUND
M7:
	; Move player
	LDA XPOS	; Save current X coordinate.
	STA XPREV
	LDA YPOS	; Save current Y coordinate.
	STA YPREV

	LDA SWCHA	; Read joystick.
	AND #$f0	; 
	CMP #$e0	; Going up?
	BEQ M24		; Yes, jump.
	JMP M3		; No, jump.
M24:
	LDA FRAME	; Get current frame counter.
	LSR		; /2
	LSR		; /4
	AND #1		; Module 2 = 0 or 1.
	EOR #2		; Plus frame for going up sprite.
	STA FPLAYER	; Set new player frame.
	DEC YPOS	; Move player 2 pixels upward.
	DEC YPOS
	LDA YPOS
	CMP #$68	; Reached door position?
	BNE M20		; No, jump.
	LDA XPOS	; Current X-coordinate.
	CMP #$45	; At left of door?
	BCC M20		; Yes, jump.
	CMP #$56	; At right of door?
	BCS M20		; Yes, jump.
	LDA ROOM	; Get current room.
	CMP #1		; Castle?
	BNE M20		; No, jump.
	LDA VOBJ	; Current visible object
	CMP #$06	; Crown in room?
	BNE M20		; No, jump.
	LDA OBJ+9
	CMP #$FF	; Carrying it?
	BNE M20		; No, jump.
	LDA #0		; Hall room.
	STA ROOM	; Change room.
	STA OBJ+9	; Crown in room.
	LDA XPOS	; X-coordinate of player.
	STA OBJ+10	; Setup as X-coordinate of crown.
	LDA #156	; Y-coordinate at bottom...
	STA YPOS	; ...for player.
	SEC
	SBC #6		; Minus 6 pixels.
	STA OBJ+11	; Set for crown.
	LDA #8		; Triumphant face.
	STA FPLAYER
	LDA #1		; End of game.
	STA SEQ
	LDA #4		; Sound effect.
	STA AUDF0
	LDA #4
	STA AUDC0
	LDA #12
	STA AUDV0
	LDA #60		; Duration: 60 frames.
	STA SOUND
	JMP M3

M20:	LDA YPOS	; Current Y-coordinate.
	CMP #$88	; Border of lake?
	BNE M21		; No, jump.
	LDA ROOM	; Get current room.
	CMP #4		; Lake?
	BNE M21		; No, jump.
	LDA VOBJ	; Current visible object
	CMP #$00	; Sword in room?
	BNE M21		; No, jump.
	LDA OBJ+0
	CMP #$FF	; Carrying it?
	BNE M21		; No, jump.
	LDA #4		; Sword at room.
	STA OBJ+0
	LDA #80		; Sword X-coordinate.
	STA OBJ+1
	LDA #$78	; Sword Y-coordinate.
	STA OBJ+2
	LDA #2		; Start animated sequence
	STA SEQ
	JMP M3

M21:	LDA YPOS	; Get current Y-coordinate?
	CMP #0		; Reached top?
	BNE M22		; No, jump.
	LDA ROOM	; Get current room?
	CMP #5		; Dead woods (upper room)?
	BNE M22		; No, jump.
	LDA VOBJ	; Current visible object
	CMP #$04	; Key in room?
	BNE M23		; No, jump.
	LDA OBJ+6	; Get key room.
	CMP #$FF	; Carrying it?
	BNE M23		; No, jump.
	LDA #5		; Leave key in room.
	STA OBJ+6
	LDA #$10	; Setup X-coordinate for key.
	STA OBJ+7
	LDA #$08	; Setup Y-coordinate for key.
	STA OBJ+8
	JMP M22

M23:	INC YPOS	; Player doesn't move upward.
	INC YPOS
M22:
	LDA YPOS
	CMP #0		; Player reached top?
	BNE M3		; No, jump.
	LDA #170	; Player reappears at bottom.
	STA YPOS
	JSR get_connection	; Get connection map for room.
	LDA map_connect,X	; Get room connecting by north.
	STA ROOM	; Save as new room.
M3:
	LDA SWCHA	; Read joystick.
	AND #$f0	; 
	CMP #$d0	; Going down?
	BNE M4		; No, jump.
	LDA FRAME	; Get current frame counter.
	LSR		; /2
	LSR		; /4
	AND #1		; Module 2 = 0 or 1.
	STA FPLAYER	; Set new player frame.
	INC YPOS	; Move player downward 2 pixels.
	INC YPOS
	LDA YPOS
	CMP #174	; Reached bottom?
	BNE M4		; No, jump.
	LDA #8		; Player reappears at top.
	STA YPOS
	JSR get_connection	; Get connection map for room.
	LDA map_connect+2,X	; Get room connecting by south.
	STA ROOM	; Save as new room.
M4:
	LDA SWCHA	; Read joystick.
	AND #$f0	; 
	CMP #$b0	; Going left?
	BNE M5		; No, jump.
	LDA FRAME	; Get current frame counter.
	LSR		; /2
	LSR		; /4
	AND #1		; Module 2 = 0 or 1.
	EOR #6		; Plus frame for going left sprite.
	STA FPLAYER	; Set new player frame.
	DEC XPOS	; Move player to left one pixel.
	LDA XPOS
	CMP #2		; Reached left border?
	BNE M5		; No, jump.
	LDA #148	; Player reappears at right.
	STA XPOS
	JSR get_connection	; Get connection map for room.
	LDA map_connect+3,X	; Get room connecting by west.
	STA ROOM	; Save as new room.
M5:
	LDA SWCHA	; Read joystick.
	AND #$f0	; 
	CMP #$70	; Going right?
	BNE M6		; No, jump.
	LDA FRAME	; Get current frame counter.
	LSR		; /2
	LSR		; /4
	AND #1		; Module 2 = 0 or 1.
	EOR #4		; Plus frame for going right sprite.
	STA FPLAYER	; Set new player frame.
	INC XPOS	; Move player to right one pixel.
	LDA XPOS
	CMP #154	; Reached right border?
	BNE M18		; No, jump.
	LDA ROOM	; Get current room.
	CMP #7		; Dead woods (lower room)?
	BNE M18		; No, jump.
	LDA VOBJ	; Current visible object
	CMP #$02	; Cross in room?
	BNE M32		; No, jump.
	LDA OBJ+3
	CMP #$FF	; Carrying it?
	BEQ M19		; Yes, jump.
M32:	DEC XPOS	; Player cannot move to right.
	JMP M6

M19:	LDA ROOM	; Leave cross at room.
	STA OBJ+3
	LDA #$10
	STA OBJ+4
M18:	LDA XPOS	; Get current X-coordinate.
	CMP #154	; Reached right?
	BNE M6		; No, jump.
	LDA #8		; Reappear at left.
	STA XPOS
	JSR get_connection	; Get connection map for room.
	LDA map_connect+1,X	; Get room connecting by east.
	STA ROOM	; Save as new room.
M6:
	; Drop object
	LDA INPT4	; Get joystick button state.
	BMI M17		; Jump if not pressed.
	LDA VOBJ	; There is an object on screen?
	BMI M17		; No, jump.
	LSR		; /2
	ADC VOBJ	; +itself = x3
	TAX		; Index into object table.
	LDA OBJ,X	; Get room of object.
	CMP #$FF	; Is it carried?
	BNE M17		; No, jump.
	LDA ROOM	; Leave at current room.
	STA OBJ,X
	LDA #12		; Sound effect.
	STA AUDV0
	LDA #15
	STA AUDF0
	LDA #4
	STA AUDC0
	LDA #3		; Duration: 3 frames.
	STA SOUND
M17:
	; Counter to turn off sound effects.
	DEC SOUND	; Decrement counter.
	BNE M33		; Jump if not zero.
	LDA #0
	STA AUDV0	; Turn off volume.
M33:

WAIT_FOR_BOTTOM:
	LDA INTIM	; Read timer
	BNE WAIT_FOR_BOTTOM	; Branch if not zero.
	STA WSYNC	; Resynchronize on last border scanline

	INC FRAME	; Count frames

	JMP SHOW_FRAME	; Repeat the game loop.

	;
	; Gets the index into the connection table.
	; It is simply x = ROOM * 4
	;
get_connection:
	LDA ROOM
	ASL
	ASL
	TAX
	RTS

	;
	; Connection map for each room.
	;
map_connect:
	;     U R D L
	.byte 0,0,0,0	; 0 Hall.
	.byte 0,0,2,0	; 1 Castle.
	.byte 1,3,0,5	; 2 Woods.
	.byte 4,0,0,2	; 3 Shack.
	.byte 0,0,3,0	; 4 Lake.
	.byte 6,2,7,0	; 5 Dead woods.
	.byte 0,0,5,0	; 6 Cemetery.
	.byte 5,8,0,0	; 7 Dead woods.
	.byte 8,9,8,7	; 8 Caves.
	.byte 9,9,9,8	; 9 Caves.

	;
	; Restart the game.
	;
restart_game:
	LDA #0		; No animated sequence.
	STA SEQ

	LDA #1		; Start at room 1 (castle).
	STA ROOM

	LDA #80		; X-coordinate for player.
	STA XPOS
	LDA #130	; Y-coordinate for player.
	STA YPOS

	LDX #0		; Index into object initial data.
COPY:	LDA obj_init,X	; Read byte from ROM.
	STA OBJ,X	; Store byte in RAM.
	INX		; Increment index.
	CPX #12		; All 12 bytes copied?
	BNE COPY	; No, jump.

	RTS		; Return.

	;
	; Table with room, X, and Y coordinates of each object.
	;
obj_init:
	.byte 9,$80,$08	; Sword
	.byte 6,$20,$40	; Cross
	.byte 3,$80,$68	; Key
	.byte 0,$50,$50	; Crown (hidden)

	;
	; Table with addresses of graphics for each object.
	;
obj_sprite:
	.word objects_sprites+16-240	; Sword
	.word objects_sprites+32-240	; Cross
	.word objects_sprites+48-240	; Key
	.word objects_sprites+64-240	; Crown
	.word objects_sprites+0-240	; 4
	.word objects_sprites+1-240	; 5
	.word objects_sprites+2-240	; 6
	.word objects_sprites+3-240	; 7
	.word objects_sprites+4-240	; 8
	.word objects_sprites+5-240	; 9
	.word objects_sprites+6-240	; 10
	.word objects_sprites+7-240	; 11

	;
	; Map.
	; Contains the pointer to graphic room data.
	; Also the color for the room, and a flag to
	; indicate if there is a wall to left ($02)
	; or right ($01).
	;
	; The wall (created with the ball) is necessary
	; as the playfield is symmetric, and an opening
	; on the left, would put an opening on the right.
	;
map:
	.word room_pf60	; 0: Hall.
	.byte $7e,$00
	.word room_pf00	; 1: Castle.
	.byte $2e,$00
	.word room_pf10	; 2: Woods.
	.byte $ce,$00
	.word room_pf20	; 3: Shack.
	.byte $3e,$01
	.word room_pf50	; 4: Lake.
	.byte $80,$00
	.word room_pf30	; 5: Dead woods.
	.byte $04,$02
	.word room_pf70	; 6: Cemetery.
	.byte $0e,$00
	.word room_pf80	; 7: Dead woods.
	.byte $04,$02
	.word room_pf40	; 8: Caves.
	.byte $54,$00
	.word room_pf40	; 9: Caves.
	.byte $54,$00

	;
	; Rooms created with Tiny VCS Playfield editor.
	; https://www.masswerk.at/vcs-tools/TinyPlayfieldEditor/
	;
	; You can copy&paste the data for each room
	; to reedit it (set line height as 8px).
	;
; mode: symmetric mirrored line-height 8
room_pf00:
	.byte $F0,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$F0
room_pf01:
	.byte $FF,$55,$7F,$7F,$7F,$36,$37,$3E
	.byte $3E,$3E,$37,$37,$3F,$3F,$3F,$3F
	.byte $3F,$3F,$00,$00,$00,$00,$00,$FF
room_pf02:
	.byte $FF,$00,$00,$00,$00,$00,$AA,$00
	.byte $00,$55,$FF,$FF,$FA,$1A,$1F,$1F
	.byte $1F,$1F,$00,$00,$00,$00,$00,$3F

; mode: symmetric mirrored line-height 8
room_pf10:
	.byte $F0,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$00,$00,$00,$00,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$F0
room_pf11:
	.byte $FF,$00,$00,$38,$7C,$7C,$38,$10
	.byte $10,$10,$00,$00,$00,$0E,$1F,$1F
	.byte $0E,$04,$04,$00,$00,$00,$00,$FF
room_pf12:
	.byte $3F,$00,$00,$00,$00,$00,$1C,$3E
	.byte $3E,$1C,$08,$08,$08,$00,$00,$00
	.byte $00,$38,$7C,$7C,$38,$10,$00,$FF

; mode: symmetric mirrored line-height 8
room_pf20:
	.byte $F0,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$00,$00,$00,$00,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$F0
room_pf21:
	.byte $FF,$00,$00,$00,$00,$00,$00,$20
	.byte $70,$70,$F8,$F8,$70,$20,$20,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$FF
room_pf22:
	.byte $3F,$00,$00,$00,$00,$00,$00,$00
	.byte $F0,$FC,$FE,$AB,$FC,$6C,$7C,$7C
	.byte $00,$00,$00,$00,$00,$00,$00,$FF

; mode: symmetric mirrored line-height 8
room_pf30:
	.byte $F0,$10,$10,$90,$10,$10,$10,$10
	.byte $10,$10,$00,$00,$00,$00,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$F0
room_pf31:
	.byte $FF,$00,$00,$20,$A0,$58,$40,$40
	.byte $01,$00,$00,$00,$00,$00,$48,$2B
	.byte $1C,$68,$08,$08,$08,$00,$00,$FF
room_pf32:
	.byte $3F,$00,$00,$00,$00,$00,$00,$04
	.byte $02,$0F,$02,$02,$02,$00,$00,$00
	.byte $00,$28,$10,$1c,$10,$10,$00,$3F

; mode: symmetric mirrored line-height 8
room_pf40:
	.byte $30,$30,$30,$30,$30,$30,$30,$30
	.byte $F0,$F0,$00,$00,$00,$00,$F0,$E0
	.byte $20,$20,$20,$20,$20,$20,$20,$20
room_pf41:
	.byte $22,$20,$20,$20,$23,$02,$02,$02
	.byte $FE,$FE,$00,$00,$00,$00,$84,$84
	.byte $04,$04,$04,$3C,$20,$20,$20,$22
room_pf42:
	.byte $C4,$C0,$C0,$C0,$FF,$C0,$C0,$C0
	.byte $C4,$C4,$C0,$C0,$C0,$C0,$FC,$04
	.byte $04,$04,$C4,$C4,$C4,$C4,$C4,$C4

; mode: symmetric mirrored line-height 8
room_pf50:
	.byte $F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0
	.byte $F0,$F0,$F0,$F0,$F0,$D0,$30,$F0
	.byte $F0,$10,$10,$10,$10,$10,$10,$F0
room_pf51:
	.byte $FF,$FF,$F7,$0F,$FF,$FF,$FF,$FF
	.byte $FF,$FD,$C3,$FF,$FF,$FF,$78,$FF
	.byte $FF,$00,$00,$00,$00,$00,$00,$FF
room_pf52:
	.byte $FF,$FF,$FF,$FF,$FF,$DF,$E0,$FF
	.byte $FF,$FF,$DF,$3F,$FF,$FD,$FE,$FF
	.byte $FF,$00,$00,$00,$00,$00,$00,$3F

; mode: symmetric mirrored line-height 8
room_pf60:
	.byte $F0,$90,$90,$90,$90,$90,$90,$90
	.byte $90,$90,$50,$B0,$50,$30,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$F0
room_pf61:
	.byte $FF,$24,$24,$24,$2C,$34,$28,$50
	.byte $A1,$40,$80,$00,$00,$00,$01,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$FF
room_pf62:
	.byte $FF,$00,$50,$50,$E0,$C0,$C0,$01
	.byte $C3,$61,$61,$61,$D1,$F1,$63,$E0
	.byte $10,$10,$08,$08,$04,$04,$02,$3F

; mode: symmetric mirrored line-height 8
room_pf70:
	.byte $F0,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$F0
room_pf71:
	.byte $FF,$00,$00,$40,$E0,$40,$E0,$E0
	.byte $E0,$00,$00,$08,$1C,$08,$1C,$1C
	.byte $1C,$00,$00,$00,$00,$00,$00,$FF
room_pf72:
	.byte $FF,$00,$00,$00,$04,$0E,$04,$0E
	.byte $0E,$0E,$00,$00,$10,$38,$10,$38
	.byte $38,$38,$00,$00,$00,$00,$00,$3F

; mode: symmetric mirrored line-height 8
room_pf80:
	.byte $F0,$10,$10,$90,$10,$10,$10,$10
	.byte $10,$10,$00,$00,$00,$00,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$F0
room_pf81:
	.byte $FF,$00,$00,$20,$A0,$58,$40,$40
	.byte $01,$00,$00,$00,$00,$00,$48,$2B
	.byte $1C,$68,$08,$08,$08,$00,$00,$FF
room_pf82:
	.byte $3F,$00,$00,$00,$00,$00,$00,$04
	.byte $02,$0F,$02,$02,$02,$00,$00,$00
	.byte $00,$50,$20,$38,$20,$20,$00,$FF

	;
	; List of pointers to player graphics for
	; each frame.
	;
ply_sprite:
	.word player_graphics
	.word player_graphics+16
	.word player_graphics+32
	.word player_graphics+48
	.word player_graphics+64
	.word player_graphics+80
	.word player_graphics+96
	.word player_graphics+112
	.word player_graphics+128

player_graphics:
	.byte %01100000	; Walking down 1
	.byte %01100000
	.byte %00101110
	.byte %00101110
	.byte %00111101
	.byte %00111101
	.byte %10111101
	.byte %01111110
	.byte %00111100
	.byte %01000010
	.byte %01111110
	.byte %01011010
	.byte %01111110
	.byte %11111111
	.byte %01111110
	.byte %00111100

	.byte %00000110	; Walking down 2
	.byte %00000110
	.byte %01110100
	.byte %01110100
	.byte %10111100
	.byte %10111100
	.byte %10111101
	.byte %01111110
	.byte %00111100
	.byte %01000010
	.byte %01111110
	.byte %01011010
	.byte %01111110
	.byte %11111111
	.byte %01111110
	.byte %00111100

	.byte %01100000	; Walking up 1
	.byte %01100000
	.byte %00101110
	.byte %00101110
	.byte %00111101
	.byte %00111101
	.byte %10111101
	.byte %01111110
	.byte %00111100
	.byte %01111110
	.byte %01111110
	.byte %01111110
	.byte %01111110
	.byte %11111111
	.byte %01111110
	.byte %00111100

	.byte %00000110	; Walking up 2
	.byte %00000110
	.byte %01110100
	.byte %01110100
	.byte %10111100
	.byte %10111100
	.byte %10111101
	.byte %01111110
	.byte %00111100
	.byte %01111110
	.byte %01111110
	.byte %01111110
	.byte %01111110
	.byte %11111111
	.byte %01111110
	.byte %00111100

	.byte %00011110	; Walking right 1
	.byte %00011100
	.byte %00011000
	.byte %00011000
	.byte %00111100
	.byte %01011010
	.byte %01011010
	.byte %01011010
	.byte %00111100
	.byte %00111000
	.byte %01111111
	.byte %01111000
	.byte %01111110
	.byte %11111111
	.byte %01111110
	.byte %00111100

	.byte %01110011	; Walking right 2
	.byte %11000111
	.byte %01101101
	.byte %00011000
	.byte %00111100
	.byte %11011101
	.byte %11011110
	.byte %01101100
	.byte %00111100
	.byte %00111000
	.byte %01111111
	.byte %01111000
	.byte %01111110
	.byte %11111111
	.byte %01111110
	.byte %00111100

	.byte %01111000	; Walking left 1
	.byte %00111000
	.byte %00011000
	.byte %00011000
	.byte %00111100
	.byte %01011010
	.byte %01011010
	.byte %01011010
	.byte %00111100
	.byte %00011100
	.byte %11111110
	.byte %00011110
	.byte %01111110
	.byte %11111111
	.byte %01111110
	.byte %00111100

	.byte %11001110	; Walking left 2
	.byte %11100110
	.byte %10110110
	.byte %00011000
	.byte %00111100
	.byte %10111011
	.byte %01111011
	.byte %00110110
	.byte %00111100
	.byte %00011100
	.byte %11111110
	.byte %00011110
	.byte %01111110
	.byte %11111111
	.byte %01111110
	.byte %00111100

	.byte %01110110	; Triumph
	.byte %01110110
	.byte %00110100
	.byte %00110100
	.byte %10111101
	.byte %10111101
	.byte %10111101
	.byte %01111110
	.byte %01100110
	.byte %01011010
	.byte %01111110
	.byte %00011000
	.byte %01111110
	.byte %11111111
	.byte %01111110
	.byte %00111100

player_color:
	.byte $24
	.byte $24
	.byte $24
	.byte $24
	.byte $80
	.byte $80
	.byte $80
	.byte $80
	.byte $36
	.byte $36
	.byte $36
	.byte $36
	.byte $02
	.byte $02
	.byte $02
	.byte $02

	;
	; Graphic data for objects.
	;
	; We make the hand to submerge by
	; using one-pixel offsets on the
	; graphic data. 
	;
objects_sprites:
	.byte %00111100	; Hand+Sword
	.byte %00111100
	.byte %01111100
	.byte %01111110
	.byte %01111111
	.byte %01101101
	.byte %01101100
	.byte %01101100
	.byte %00011000
	.byte %00011000
	.byte %01111110
	.byte %00011000
	.byte %00011000
	.byte %00011000
	.byte %00011000
	.byte %00010000

	.byte %00000000	; Sword
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00011000
	.byte %00011000
	.byte %01111110
	.byte %00011000
	.byte %00011000
	.byte %00011000
	.byte %00011000
	.byte %00010000
	.byte %00000000

	.byte %00000000	; Cross
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %01000000
	.byte %11100000
	.byte %01110010
	.byte %00111111
	.byte %00011110
	.byte %00111111
	.byte %01111111
	.byte %00110010
	.byte %00000000

	.byte %00000000	; Key
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %01110000
	.byte %11011000
	.byte %01110000
	.byte %00110100
	.byte %00011101
	.byte %00001110
	.byte %00000100
	.byte %00000000

	.byte %00000000	; Crown
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00111100
	.byte %01000010
	.byte %01111110
	.byte %01000010
	.byte %01111110
	.byte %01011010
	.byte %10011001
	.byte %00100100

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

	ORG $FFFC
	.word START
	.word START
