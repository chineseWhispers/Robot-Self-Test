; SimpleRobotProgram.asm
; Created by Kevin Johnson
; This program performs extremely simple tests on a handful of 
; IO peripherals and robot hardware.

	ORG     &H000		;Begin program at x000
Init:
	LOAD    Zero
	OUT     SONAREN     ; Disable sonar
	OUT     LVELCMD     ; Stop motors
	OUT     RVELCMD
	
Main:
	IN      SWITCHES
	OUT     LEDS        ; Output switches to LEDs
	AND     EnSonars    ; Discard all but 8 bits
	OUT     SONAREN     ; Turn on whichever sonars correspond to UP switches
	IN      DIST0       ; Read the distance from Sonar 0
	OUT     LCD         ; Output to LCD
	IN      LVEL        ; Read velocity of left wheel
	STORE   Temp
	IN      RVEL
	ADD     Temp
	OUT     SEVENSEG    ; Output sum of wheel velocities to 7-seg
	JUMP    Main        ; Repeat forever


Wait1:
	OUT     TIMER		; One second pause subroutine
Wloop:
	IN      TIMER
	ADDI    -10
	JNEG    Wloop
	RETURN

; This is a good place to put variables
Temp:     DW 0

; Having some constants can be very useful
Zero:     DW 0
One:      DW 1
Two:      DW 2
Three:    DW 3
Four:     DW 4
Five:     DW 5
Six:      DW 6
Seven:    DW 7
Eight:    DW 8
Nine:     DW 9
Ten:      DW 10
Forward:  DW 100
Reverse:  DW -100
EnSonar0: DW &B00000001
EnSonar1: DW &B00000010
EnSonar2: DW &B00000100
EnSonar3: DW &B00001000
EnSonar4: DW &B00010000
EnSonar5: DW &B00100000
EnSonar6: DW &B01000000
EnSonar7: DW &B10000000
EnSonars: DW &B11111111

; IO address space map
SWITCHES: EQU &H00  ; slide switches
LEDS:     EQU &H01  ; red LEDs
TIMER:    EQU &H02  ; timer, usually running at 10 Hz
XIO:      EQU &H03  ; pushbuttons and some misc. I/0
SEVENSEG: EQU &H04  ; seven-segment display (4-digits only)
LCD:      EQU &H06  ; primitive 4-digit LCD display
LPOS:     EQU &H80  ; left wheel encoder position (read only)
LVEL:     EQU &H82  ; current left wheel velocity (read only)
LVELCMD:  EQU &H83  ; left wheel velocity command (write only)
RPOS:     EQU &H88  ; same values for right wheel...
RVEL:     EQU &H8A  ; ...
RVELCMD:  EQU &H8B  ; ...
I2C_CMD:  EQU &H90  ; I2C module's CMD register,
I2C_DATA: EQU &H91  ; ... DATA register,
I2C_BUSY: EQU &H92  ; ... and BUSY register
SONAR:    EQU &HA0  ; base address for more than 16 registers....
DIST0:    EQU &HA8  ; the eight sonar distance readings
DIST1:    EQU &HA9  ; ...
DIST2:    EQU &HAA  ; ...
DIST3:    EQU &HAB  ; ...
DIST4:    EQU &HAC  ; ...
DIST5:    EQU &HAD  ; ...
DIST6:    EQU &HAE  ; ...
DIST7:    EQU &HAF  ; ...
SONAREN:  EQU &HB2  ; register to control which sonars are enabled
XPOS:     EQU &HC0  ; Current X-position (read only)
YPOS:     EQU &HC1  ; Y-position
THETA:    EQU &HC2  ; Current rotational position of robot (0-701)
