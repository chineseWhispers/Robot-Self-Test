	ORG     &H000		;Begin program at x000
Init:
	LOAD    Zero
	OUT     SONAREN     ; Disable sonar
	OUT     LVELCMD     ; Stop motors
	OUT     RVELCMD

BeepVer:

	Load		Twelve		;print 12 to LCD
	Out			LCD
	
	IN			XIO			;when KEY1 is pressed, beep
	AND			Keymask
	JPOS		BeepVer
	OUT			BEEP
	Jump		BeepVer
	
Wait1:
	OUT     TIMER		; One second pause subroutine
Wloop:
	IN      TIMER
	ADDI    Tspeed
	JNEG    Wloop
	RETURN

; This is a good place to put variables
Temp:     DW 0

; Having some constants can be very useful
FFFF:	  DW &HFFFF
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
Eleven:	  DW 11
Twelve:   DW 12
Fifteen:  DW 15
Forward:  DW 100
Reverse:  DW -100
LEDwipe:  DW &B0000000000000001
EnSonar1: DW &B00000010
EnSonar2: DW &B00000100
EnSonar3: DW &B00001000
EnSonar4: DW &B00010000
EnSonar5: DW &B00100000
EnSonar6: DW &B01000000
EnSonar7: DW &B10000000
EnSonars: DW &B1111111111111111

tf:		  DW &B00011000
Switchmask: DW &B01111111
Motormask:  DW &B10000000
Motor:   DW &B00000000
Keymask: DW &B0000001
Keytest: DW &B0000111
Tspeed:	 DW -10

; IO address space map
SWITCHES: EQU &H00  ; slide switches
LEDS:     EQU &H01  ; red LEDs
LEDSG:    EQU &H11	
TIMER:    EQU &H02  ; timer, usually running at 10 Hz
XIO:      EQU &H03  ; pushbuttons and some misc. I/0
SEVENSEG: EQU &H04  ; seven-segment display (4-digits only)
SEVENSEG2: EQU &H14 ; second seven-segment display (4-digits only)
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
BEEP:	  EQU &H16  ; Beep module
