	ORG     &H000		;Begin program at x000


BatteryVoltageSetup:	;This subroutine need only be called once, before reading data.
	LOAD	negone ; This resets all the values needed for the sevenseg conversion
	STORE	oone
	STORE	tten
	STORE	hhun
	LOAD	sev
	STORE	sevout
	STORE	sevin
	LOAD    Zero
	OUT		I2C_CMD		; Sets up the I2C bus for use
	LOAD	Writeone	; Write one bit, read zero bits to the ADC
	OUT		I2C_CMD		; Writing this value to I2C_CMD
	LOAD	Zero		; This zero is necessary to set up the ADC
	OUT		I2C_DATA
	CALL	ReadBUSY	; Wait for BUSY to return zero after every instruction.
	CALL	ReadData	; This data value is useless.
	RETURN
	

ReadBatteryVoltage:		; This will work after calling BatteryVoltageSetup only once.
	CALL	ReadData	; Ordering the I2C to prepare a useful data point.
	IN		I2C_DATA	; This is a useful data point.
	STORE	DivNum		; Preparing for division, by declaring it the numerator.
	LOAD	Ten
	STORE	DivDen		; Sets ten as the denominator.
	LOAD	Zero
	STORE	DivResult	; Resets the quotient to zero.
	LOAD	negone		; Resets the values needed for the sevenseg display.
	STORE	oone
	STORE	tten
	STORE	hhun
	LOAD	sev			
	STORE	sevout
	STORE	sevin
	LOAD    Zero
	CALL	Divide		; Calling the divide subroutine to convert the raw data to readable voltage.
	LOAD	DivResult
	STORE	sevin	; Sending it to the seven-segment display subroutine.
	CALL	sevcon
; Displaying the calculated voltage
	OUT		TIMER	; This code tells the display to wait one tenth of a second, so the seven-seg will be legible.
WloopTenth:
	IN		TIMER
	ADDI	-1
	JNEG	WloopTenth
	LOAD	sevout	; Outputting the final result to the seven-seg.
	OUT		SEVENSEG
	RETURN

		
; Division subroutine
Divide:
	LOAD	DivNum
	SUB		DivDen
	STORE	DivNum
	JNEG	StopDivide
	LOAD	DivResult
	ADD		One
	STORE	DivResult
	JUMP	Divide
StopDivide:
	RETURN


ReadI2CBUSY:			; A subroutine to read I2C_BUSY until it returns zero.
	IN		I2C_BUSY
	JZERO	BUSYReturn
	JUMP	ReadI2CBUSY
BUSYReturn:
	RETURN
	
ReadI2CData:	
	LOAD	Readone		; Write zero bits, read one bit from the ADC
	OUT		I2C_CMD
	LOAD	Zero
	OUT		I2C_DATA
	CALL	ReadI2CBUSY
	IN		I2C_DATA
	RETURN
	
; Seven segment conversion code
sevcon:

hundredplace:

	LOAD	hhun
	ADDI	1
	STORE	hhun
	LOAD	sevin
	ADDI	-100
	STORE	sevin
	JPOS	hundredplace
	JZERO	hundredplace
	ADDI	100
	STORE	sevin
tenplace:

	LOAD	tten
	ADDI	1
	STORE	tten
	LOAD	sevin
	ADDI	-10
	STORE	sevin
	JPOS	tenplace
	JZERO	tenplace	
	ADDI	10
	STORE	sevin
oneplace:

	LOAD	oone
	ADDI	1
	STORE	oone
	LOAD	sevin
	ADDI	-1
	STORE	sevin
	JPOS	oneplace
	JZERO	oneplace
	ADDI	1
	STORE   sevin

	
	LOAD	sevout
	;OR		tthou
	;SHIFT	4
	OR		hhun
	SHIFT	4
	OR		tten
	SHIFT	4
	OR		oone
	STORE	sevout
	
	RETURN	
	
; This is a good place to put variables
Temp:     DW 0

; New to this program
DivNum:			DW 0
DivDen:			DW 0
DivResult:		DW 0
Writeone:	DW	&H1090
Readone:	DW	&H0190
sev:	  DW &B0000000000000000
sevin:	  DW &B0000000000000000
sevout:   DW &B0000000000000000
tthou:    DW -1
hhun:     DW -1
tten:     DW -1
oone:     DW -1
negone:     DW -1

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
Fifteen:      DW 15
Forward:  DW 100
Reverse:  DW -100
EnSonar0: DW &B0000000000000001
EnSonar1: DW &B00000010
EnSonar2: DW &B00000100
EnSonar3: DW &B00001000
EnSonar4: DW &B00010000
EnSonar5: DW &B00100000
EnSonar6: DW &B01000000
EnSonar7: DW &B10000000
EnSonars: DW &B1111111111111111

Keymask: DW &B0000001
FiveVolt:		DW &H5		;5 in hex, maximum battery voltage used for calculation
Two-fifty-six:	DW &H100	;256 in Hex, used for calculating battery voltage

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