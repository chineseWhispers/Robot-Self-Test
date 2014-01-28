; MotorTest.asm
; Created by Yingyan Samantha Wang

	ORG     &H000		;Begin program at x000
Init:
	LOAD    Zero
	OUT     SONAREN     ; Disable sonar
	OUT     LVELCMD     ; Stop motors
	OUT     RVELCMD
	
Main:					; Initial test to confirm basic input switch working
	LOAD	FFFF		; Load full "FFFF" in hex
	OUT		LEDS		; Turn on all red LEDs
	OUT		LEDSG		; Turn on all green LEDs
	OUT		LCD			; Print to LCD
	OUT		SEVENSEG	; Print on first four of SEVENSEG
	OUT		SEVENSEG2	; Print on second four of SEVENSEG
	IN		XIO			; Now, wait for KEY1 to be pressed
	AND		Keymask		; Keymask for key1
	JZERO	MotorTest	;   If key1 pressed, go to next things
	JUMP	Main

;Motor Test Starts Here
	
MotorTest:	
	IN			SWITCHES
	OUT			LEDS
	STORE		Motor
	AND         Selectmask      ;select wheel
	Store       Select
	LOAD        Motor
	STORE       Motor
	AND         Dirmask         ;get direction
	Store       Dir
	JZERO       MotorOut        ;if sw2 is off
	JUMP        MotorRev        ;if se2 is on, reverse direction

motorOut:
	LOAD		Motor
	AND			Motormask       ;get the speed
	ADD         tt
	STORE       MotorSpeed
	LOAD        Select
	STORE       Select
	JZERO       Left            ;if sw1 is off, test left wheel
	JUMP        Right           ;if sw1 is on, test right wheel

motorRev: 
    LOAD		Motor		
    AND			Motormask       ;get the speed
    XOR         Switchmask     
    ADD         One             ;two's complement reverse direction
    SUB         tt
    STORE       MotorSpeed
   	LOAD        Select
   	STORE       Select
	JZERO       Left
	JUMP        Right
  	
Left:
    LOAD        MotorSpeed
    STORE       MotorSpeed
	OUT			LVELCMD
	LOAD        ZERO
	OUT         RVELCMD
	IN          LVEL            ;read velocity
	OUT         SEVENSEG        ;output to seven-seg
	IN          XIO             ;if keybutton pushed, exit motor test
	JZERO       MotorTest
	JUMP		Init
	
Right:
    LOAD        MotorSpeed
    STORE       MotorSpeed
    ADD         Two    
    OUT         RVELCMD
    LOAD        ZERO
	OUT         LVELCMD
	IN          RVEL
	OUT         SEVENSEG
	IN          XIO
	JZERO       MotorTest      ;if keybutton pushed, exit motor test
	JUMP        Init

;the end of motor test, infinite loops if keybutton not pushed
    	    
	    
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
Fifteen:  DW 15
tt:       DW 23
Forward:  DW 100
Reverse:  DW -100
Switchmask: DW &B11111111
Selectmask: DW &B00000001
Select:     DW &B00000000
motorspeed: DW &B00000000
Dirmask:    DW &B00000010
Dir:        DW &B00000000
Motormask:  DW &B00111100
Motor:      DW &B00000000
Keymask:     DW &B0000001

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
