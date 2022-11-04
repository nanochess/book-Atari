	;
	; Players NUSIZ demo with missiles
	;
	; by Oscar Toledo G.
	; https://nanochess.org/
	;
	; Creation date: Jun/02/2022.
	;

	PROCESSOR 6502
	INCLUDE "vcs.h"

FRAME   = $0080		; Frame number saved in this address.
SECONDS = $0081		; Seconds value saved in this address.
VPOS	= $0082		; Vertical position of missile.

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

SHOW_FRAME:
	LDA #$88	; Blue.
	STA COLUBK	; Background color.
	LDA #$0F	; White.
	STA COLUP0	; Player 0 color.
	LDA #$00	; Black.
	STA COLUP1	; Player 1 color.
	LDA #$03	; 3 copies shown of player.
	STA NUSIZ0
	STA NUSIZ1

	STA WSYNC
	LDA #2		; Start of vertical retrace.
	STA VSYNC
	STA WSYNC
	STA WSYNC
	STA WSYNC
	LDA #0		; End of vertical retrace.
	STA VSYNC

	; Player 0 and 1 horizontal position
	STA WSYNC	; Cycle 3
	NOP		; 5
	NOP		; 7
	NOP		; 9
	NOP		; 11
	NOP		; 13
	NOP		; 15
	NOP		; 17
	NOP		; 19
	NOP		; 21
	NOP		; 23
	NOP		; 25
	STA RESP0	; 28
	NOP		; 30
	NOP		; 32
	NOP		; 34
	NOP		; 36
	NOP		; 38
	NOP		; 40
	NOP		; 42
	NOP		; 44
	NOP		; 46
	STA RESP1	; 49

	STA WSYNC
	LDA #2		; Reset missile to player position
	STA RESMP0	; Reset missile 0	
	STA RESMP1	; Reset missile 1

	STA WSYNC
	LDA #0		; Allow missile to be displayed
	STA RESMP0	; 
	STA RESMP1	; 

	LDX #33		; Remains 33 scanlines of top border
TOP:
	STA WSYNC
	DEX
	BNE TOP
	LDA #0		; Disable blanking
	STA VBLANK

	LDX #92		; 92 scanlines in blue
VISIBLE:
	STA WSYNC
	DEX
	BNE VISIBLE

	STA WSYNC	; One scanline
	LDA #$42	; 
	STA GRP0
	STA GRP1

	STA WSYNC	; One scanline
	LDA #$24	; 
	STA GRP0
	STA GRP1

	STA WSYNC	; One scanline
	LDA #$3C	; 
	STA GRP0
	STA GRP1

	STA WSYNC	; One scanline
	LDA #$5A	; 
	STA GRP0
	STA GRP1

	STA WSYNC	; One scanline
	LDA #$FF	; 
	STA GRP0
	STA GRP1

	STA WSYNC	; One scanline
	LDA #$BD	; 
	STA GRP0
	STA GRP1

	STA WSYNC	; One scanline
	LDA #$A5	; 
	STA GRP0
	STA GRP1

	STA WSYNC	; One scanline
	LDA #$24	; 
	STA GRP0
	STA GRP1

	STA WSYNC	; One scanline
	LDA #$00	; 
	STA GRP0
	STA GRP1

	LDX #91		; 91 scanlines in deep blue
	LDY VPOS	; Load VPOS into Y register.
VISIBLE2:
	STA WSYNC
	LDA #0		; A = $00 Disable missiles
	CPY #0		; Y is zero?
	BNE L2		; Branch if Not Equal.
	LDA #2		; A = $02 Enable missiles
L2:	STA ENAM0	; Enable or disable missile 0
	STA ENAM1	; Enable or disable missile 1
	DEY		; Decrease Y (temporary copy of VPOS)
	DEX
	BNE VISIBLE2

	LDA #2		; Enable blanking
	STA VBLANK
	LDX #30		; 30 scanlines of bottom border
BOTTOM:
	STA WSYNC
	LDA #0		; Disable missile
	STA ENAM0
	STA ENAM1

	DEX
	BNE BOTTOM

	INC VPOS	; Increase vertical position
			; Doesn't mind limiting it as
			; it will cycle 0-255 and repeat.

	INC FRAME	; Increase frame number
	LDA FRAME	; Read frame number
	CMP #60		; Is it 60?
	BNE L1		; Branch if not equal.
	LDA #0		; Reset frame number to zero.
	STA FRAME
	INC SECONDS	; Increase number of seconds.
L1:
	JMP SHOW_FRAME

	ORG $FFFC
	.word START
	.word START
