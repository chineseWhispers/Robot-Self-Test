
	ORG     &H000		;Begin program at x000
Init:
	LOAD    Zero
	OUT     SONAREN     ; Disable sonar
	OUT     LVELCMD     ; Stop motors
	OUT     RVELCMD
	
	LOAD	One			; "DE2 I|O Push KEY1"
	OUT		LCD
	
	CALL	BatteryVoltageSetup ;Initialize battery stuff
	
	
;DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD             DE2                DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD	
	
OutVer:					
	LOAD	FFFF		; Load full "FFFF" in hex
	OUT		LEDS		; Turn on all red LEDs
	OUT		LEDG		; Turn on all green LEDs
	OUT		SEVENSEG	; Print on first four of SEVENSEG
	OUT		SEVENSEG2	; Print on second four of SEVENSEG
	
	;OUT	BEEP
	;CALL	ReadBatteryVoltage
	
	IN		XIO
	AND		KeyMask2
	JZERO	MenuTop		; KEY2 sends you directly to the robot tests
	
	IN		XIO			; Now, wait for KEY1 to be pressed
	AND		Keymask		; Keymask for key1
	JPOS	OutVer
	JNEG	OutVer
	CALL	Key1sub		; Subroutine that waits for KEY1 to be released before going to next things

	LOAD	Zero		; Clear all the outputs
	OUT		LEDS		; 
	OUT		LEDG		; 
	OUT		SEVENSEG	; 
	OUT		SEVENSEG2	; 
	
	LOAD		Two		; "DE2 I|O Switch Input Test"
	OUT			LCD	


InVer:						;Switches Verification
	IN			SWITCHES	;Check the switches
	OUT 		LEDS		;Output so red LEDs correspond to switches
	ADD			One			;Add one- when all the switches are already on, this will flip from all 1's to all 0's
	
	JPOS		InVer		;Proceed if all switches up (and equal to 0), repeat if not
	JNEG		InVer
	
	LOAD		Zero
	OUT			LEDS
	
	LOAD		Zero		;"DE2 I|O PK Input Test"
	OUT			LCD	
	
InVer2:						;Test of KEYS
	

	LOAD		Keytest		;Loads a vector of all 0's except three keys to test
	STORE		Temp		;Store in temp
	
	
InVer22:					
	
			
	IN			XIO			;Take current input, AND with temp.
	AND			Temp		;AND'ing results in keys pressed changing their place in temp. to 0
	STORE		Temp

	SHIFT		5
	OUT			LEDG
	
	JPOS		InVer22		;When it's all zero, proceed to timer test
	JNEG		InVer22	
	
	LOAD		Three		;"DE2 I|O Timer Test"
	OUT			LCD
	
	CALL		Key1sub
	
TimerVer00:					;initialize things for test of TIMER

	LOAD		Zero		;Clear all the switch LEDs
	OUT			LEDS
	
	IN		XIO				; Now, wait for KEY1 to be pressed
	AND		Keymask			; Keymask for key1
	JPOS	TimerVer00
	JNEG	TimerVer00
	CALL	Key1sub			; If key1 pressed, go to next things
	
	LOAD	LEDwipe
	STORE	wipetemp
	
TimerVer:					;Start testing timer
	

	LOAD		wipetemp	;Load vector with only LSB 1
	OUT			LEDS		;Put out to LEDS
	
	CALL		Wait1		;Use wait routine, starts at waiting 1 second
		
	LOAD		wipetemp	;Shift active LED to the left
	SHIFT		1
	STORE		wipetemp
	
	ADDI	-512
	JZERO	TimerVer2	
	
	IN		XIO				; Now, wait for KEY1 to be pressed
	AND		Keymask			; Keymask for key1
	JPOS	TimerVer
	JNEG	TimerVer
	CALL	Key1sub			; Wait until KEY1 is released, go to next things
	
TimerVer2:	
		
	LOAD		Tspeed
	ADDI		5			;makes the timer speed up
	JZERO		BeepVer		;When the timing parameter has been reduced twice down to 0, go to beep test
	STORE		Tspeed

	
	LOAD		One			;reset position of moving LED back to beginning
	STORE		wipetemp
	
	JUMP		TimerVer
	
	
;BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB          BOT BASIC       BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBbBBB	
	
BeepVer:					;Test the BEEP Module

	Load		Four		;"BOTBASIC BEEP"
	Out			LCD
	
	Load		Zero		;Clear all the displays
	OUT			SEVENSEG
	OUT			SEVENSEG2
	OUT			LEDS
	OUT			LEDG
	
BeepVer2:
	
	IN		XIO				; Now, wait for KEY1 to be pressed
	AND		Keymask			; Keymask for key1
	JPOS	BeepVer2
	JNEG	BeepVer2
	CALL	Key1sub			; Wait until KEY1 is released, go to next things
	
Beeploop:					; Pushing KEY1 in this test part will have the BEEP sound for a little while
	
	OUT		BEEP
	;LOAD	beeptimer
	;ADDI	10
	;STORE	beeptimer
	;JNEG	Beeploop
	
	IN		XIO				; Now, wait for KEY1 to be pressed
	AND		Keymask			; Keymask for key1
	JPOS	Beeploop
	JNEG	Beeploop
	CALL	Key1sub			; Wait until KEY1 is released, go to next things
	
	Load	Five			;"BOTBASIC BATT"
	OUT		LCD
	
BattVer:

	CALL	ReadBatteryVoltage		;Print battery voltage to LCD in real time

	IN		XIO				; Now, wait for KEY1 to be pressed
	AND		Keymask			; Keymask for key1
	JPOS	BattVer
	JNEG	BattVer
	CALL	Key1sub			; Wait until KEY1 is released, go to next things

	
;UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU MENU SELECT UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU	
	
MenuTop:

	LOAD	Zero		; Clear all the outputs
	OUT		LEDG		; 
	OUT		SEVENSEG	; 
	OUT		SEVENSEG2	; 

	IN		SWITCHES	;Different menu options
	OUT		LEDS
	ADDI	-1
	JZERO	MenuBot
	ADDI	-1
	JZERO	MenuSonar
	ADDI	-2
	JZERO	MenuMotor
	ADDI	-4
	JZERO	MenuVel
	Jump	MenuErr
	
MenuErr:

	LOAD	Thirteen	;"MENU ?????"
	OUT		LCD
	CALL	Wait2
	
	JUMP	MenuTop
	
MenuBot:
	
	LOAD	Six				;"MENU BOTBASIC"
	OUT		LCD
	CALL	Wait2
	
	IN		XIO				; Now, wait for KEY1 to be pressed
	AND		Keymask			; Keymask for key1
	JPOS	MenuTop
	JNEG	MenuTop
	CALL	Key1sub			; Wait until KEY1 is released, go to next things
	
	JUMP	BeepVer
	
MenuSonar:
	
	LOAD	Seven			;"MENU SONAR"
	OUT		LCD
	CALL	Wait2
	
	IN		XIO				; Now, wait for KEY1 to be pressed
	AND		Keymask			; Keymask for key1
	JPOS	MenuTop
	JNEG	MenuTop
	CALL	Key1sub			; Wait until KEY1 is released, go to next things
	
	JUMP	SonarTest1
	
MenuMotor:
	
	LOAD	Eight			;"MENU MOTOR"
	OUT		LCD
	CALL	Wait2
	
	IN		XIO				; Now, wait for KEY1 to be pressed
	AND		Keymask			; Keymask for key1
	JPOS	MenuTop
	JNEG	MenuTop
	CALL	Key1sub			; Wait until KEY1 is released, go to next things
	
	JUMP	MotorTest1
	
MenuVel:					
	
	LOAD	Nine			;"MENU VELOCITY"
	OUT		LCD
	CALL	Wait2
	
	IN		XIO				; Now, wait for KEY1 to be pressed
	AND		Keymask			; Keymask for key1
	JPOS	MenuTop
	JNEG	MenuTop
	CALL	Key1sub			; Wait until KEY1 is released, go to next things
	
	JUMP	VelTest1
	
VelTest1:

	LOAD	Twelve			;"TEST VELOCITY"
	OUT		LCD
	
	LOAD	Twelve			;"TEST VELOCITY"
	OUT		LCD
	
	LOAD	Twelve			;"TEST VELOCITY"
	OUT		LCD

;VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV Velocity Test VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV	
	
VelTest:

	IN      LVEL        ; Read velocity of left wheel
	STORE	sevin
	CALL	sevcon
	LOAD	sevout
	OUT     SEVENSEG    ; Output sum of wheel velocities to 7-seg
	
	IN      RVEL	
	STORE	sevin
	CALL	sevcon
	LOAD	sevout
	OUT     SEVENSEG2    ; Output sum of wheel velocities to 7-seg
	
	IN		XIO				; Now, wait for KEY1 to be pressed
	AND		Keymask			; Keymask for key1
	JPOS	VelTest
	JNEG	VelTest
	CALL	Key1sub			; Wait until KEY1 is released, go to next things

	JUMP	MenuTop
		
MotorTest1:	
	
	LOAD	Ten			;"TEST MOTOR"
	OUT		LCD
	
	
;MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM MOTOR TEST MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM	
	
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
	
	IN			XIO				; Now, wait for KEY1 to be pressed
	AND			Keymask			; Keymask for key1
	JNEG		MotorTest
	JPOS		MotorTest
	CALL		Key1sub			; Wait until KEY1 is released, go to next things  
	JUMP        MenuTop
	
Right:
    LOAD        MotorSpeed
    STORE       MotorSpeed
    ADD         Two    
    OUT         RVELCMD
    LOAD        ZERO
	OUT         LVELCMD
	IN          RVEL
	OUT         SEVENSEG
	
	IN			XIO				; Now, wait for KEY1 to be pressed
	AND			Keymask			; Keymask for key1
	JNEG		MotorTest
	JPOS		MotorTest
	CALL		Key1sub			; Wait until KEY1 is released, go to next things  
	JUMP        MenuTop

;the end of motor test, infinite loops if KEY1 not pushed	
	




;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX SONAR TEST XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

SonarTest1:

	LOAD	Eleven				;"TEST SONAR"
	OUT		LCD	
	

SonarTest:

	IN      SWITCHES
	OUT		LEDG
	;JUMP	Sonar0
	
	IN			XIO				; Now, wait for KEY1 to be pressed
	AND			Keymask			; Keymask for key1
	JNEG		Sonar0
	JPOS		Sonar0
	CALL		Key1sub			; Wait until KEY1 is released, go to next things  
	JUMP        MenuTop
	        
Sonar0:		
	IN      SWITCHES
	SUB     EnSonar0
	JZERO   OutSonar0
	JUMP    Sonar1
	
Sonar1:
	IN      SWITCHES
    SUB     EnSonar1
    JZERO   OutSonar1
    JUMP    Sonar2	
    
Sonar2:		
	IN      SWITCHES
	SUB     EnSonar2
	JZERO   OutSonar2
	JUMP    Sonar3
	
Sonar3:
	IN     SWITCHES
    SUB     EnSonar3
    JZERO   OutSonar3
    JUMP    Sonar4	
    
Sonar4:		
	IN     SWITCHES
	SUB     EnSonar4
	JZERO   OutSonar4
	JUMP    Sonar5
	
Sonar5:
	IN      SWITCHES
    SUB     EnSonar5
    JZERO   OutSonar5
    JUMP    Sonar6	
    
Sonar6:		
	IN      SWITCHES
	SUB     EnSonar6
	JZERO   OutSonar6
	JUMP    Sonar7
	
Sonar7:
	IN     SWITCHES
    SUB    EnSonar7
    JZERO  OutSonar7
    Jump   SonarTest   
	
OutSonar0:
	LOAD    One	
	OUT     SONAREN     
	IN      DIST0
	
	STORE	sevin
	CALL	sevcon
	LOAD	sevout
	OUT     SEVENSEG2 
	
	
	STORE   LEDDIST 
	LOAD    SON
	ADD		EnSonar0    
	STORE   SON  
    JUMP    leddisp
    
OutSonar1:
	LOAD   Two
    OUT    SONAREN
    IN     DIST1
   
    STORE	sevin
	CALL	sevcon
	LOAD	sevout
	OUT     SEVENSEG2 
    
    STORE  LEDDIST 
    LOAD   SON
	ADD	   EnSonar1    
	STORE  SON  
    JUMP   leddisp

OutSonar2:	
	LOAD	Four
	OUT     SONAREN     
	IN      DIST2
	
	STORE	sevin
	CALL	sevcon
	LOAD	sevout
	OUT     SEVENSEG2 
	
	STORE   LEDDIST 
	LOAD    SON
	ADD		EnSonar2    
	STORE   SON       
    JUMP    leddisp
    
OutSonar3:
	LOAD   Eight
    OUT    SONAREN
    IN     DIST3
    
    STORE	sevin
	CALL	sevcon
	LOAD	sevout
	OUT     SEVENSEG2 
    
    STORE  LEDDIST 
    LOAD   SON
	ADD	   EnSonar3    
	STORE  SON  
    JUMP   leddisp
    
OutSonar4:	
	LOAD 	Sixteen
	OUT     SONAREN     
	IN      DIST4
	
	STORE	sevin
	CALL	sevcon
	LOAD	sevout
	OUT     SEVENSEG2 
	
	STORE  LEDDIST 
	LOAD    SON
	ADD		EnSonar4    
	STORE   SON        
    JUMP    leddisp
    
OutSonar5:
	LOAD   ThirtyTwo
    OUT    SONAREN
    IN     DIST5
    
    
    STORE	sevin
	CALL	sevcon
	LOAD	sevout
	OUT     SEVENSEG2 
    
    STORE  LEDDIST 
    LOAD    SON
	ADD		EnSonar5    
	STORE   SON  
    JUMP   leddisp

OutSonar6:	
	LOAD    SixtyFour
	OUT     SONAREN     
	IN      DIST6 
	
	STORE	sevin
	CALL	sevcon
	LOAD	sevout
	OUT     SEVENSEG2 
		
	STORE  LEDDIST 
	LOAD    SON
	ADD		EnSonar6    
	STORE   SON       
    JUMP    leddisp
    
OutSonar7:
	LOAD   OneTwentyEight
    OUT    SONAREN
    IN     DIST7

	STORE	sevin
	CALL	sevcon
	LOAD	sevout
	OUT     SEVENSEG2     
    
    STORE  LEDDIST 
    LOAD    SON
	ADD		EnSonar7    
	STORE   SON  
    JUMP   leddisp

leddisp:
	LOAD	LEDDIST
	SUB		OneFifty
	JNEG	led0
	JZERO   led0
	SUB		TwoHundred
	JNEG	led0-1
	JZERO   led0-1	
	SUB		TwoFifty
	JNEG	led0-2
	JZERO   led0-2
	SUB		ThreeHundred
	JNEG	led0-3
	JZERO   led0-3
	SUB		ThreeFifty
	JNEG	led0-4
	JZERO   led0-4
	SUB		FourHundred
	JNEG	led0-5
	JZERO   led0-5
	SUB		FourFifty
	JNEG	led0-6
	JZERO   led0-6
	SUB		FiveHundred
	JNEG	led0-7
	JZERO   led0-7
	SUB		FiveFifty
	JNEG	led0-8
	JZERO   led0-8
	SUB		SixHundred
	JNEG	led0-9
	JZERO   led0-9
	SUB		SixFifty
	JNEG	led0-10
	JZERO   led0-10
	SUB		SevenHundred
	JNEG	led0-11
	JZERO   led0-11
	SUB		SevenFifty
	JNEG	led0-11
	JZERO   led0-11
	SUB		EightHundred
	JNEG	led0-12
	JZERO   led0-12
	SUB		EightFifty
	JNEG	led0-13
	JZERO   led0-13
	SUB		NineHundred
	JNEG	led0-14
	JZERO   led0-14
	SUB		NineFifty
	JNEG	led0-15
	JZERO   led0-15
	SUB	    OneThousand
	JNEG	led0-16
	JZERO   led0-16
	jump	read
       
read:
	  
	IN 		SWITCHES
		OUT		LEDG
	JZERO	read2
	ADDI	-1
	JZERO	read2
	ADDI	-1
	JZERO	read2
	ADDI	-2
	JZERO	read2
	ADDI	-4
	JZERO	read2
	ADDI	-8
	JZERO	read2
	ADDI	-16
	JZERO	read2
	ADDI	-32
	JZERO	read2
	ADDI	-64
	JZERO	read2
	

	LOAD	ZERO
	OUT		LEDS
	OUT		BEEP
	JUMP	read
	
read2:	
	
	JZERO   stop
	LOAD    SON
	SUB     SWITCHES
	JPOS    stop
	JNEG    stop
	jump	SonarTest      
	;CALL    Wait2        ; Repeat forever

led0:
	LOAD	Zero
	OUT		LEDS
	jump 	read
led0-1:
	LOAD	One
	OUT		LEDS
	jump 	read
led0-2:
	LOAD	Three
	OUT		LEDS
	jump 	read
led0-3:
	LOAD	Seven
	OUT		LEDS
	jump 	read
led0-4:
	LOAD	Fifteen
	OUT		LEDS
	jump 	read
led0-5:
	LOAD	ThirtyOne
	OUT		LEDS
	jump 	read
led0-6:
	LOAD	SixtyThree
	OUT		LEDS
	jump 	read
led0-7:
	LOAD	OneTwentySeven
	OUT		LEDS
	jump 	read
led0-8:
	LOAD	TwoFiftyFive
	OUT		LEDS
	jump 	read
led0-9:
	LOAD	FiveEleven
	OUT		LEDS
	jump 	read
led0-10:
	LOAD	OneThousandTwentyThree
	OUT		LEDS
	jump 	read
led0-11:
	LOAD	TwoThousandFortySeven
	OUT		LEDS
	jump 	read
led0-12:
	LOAD	FourThousandNinetyFive
	OUT		LEDS
	jump 	read
led0-13:
	LOAD	EightThousandOneHundredNinetyOne
	OUT		LEDS
	jump 	read
led0-14:
	LOAD	SixteenThousandThreeHundredEightyThree 
	OUT		LEDS
	jump 	read
led0-15:
	LOAD	ThirtyTwothousandSevenHundredSixtySeven 
	OUT		LEDS
	jump 	read
led0-16:
	LOAD	SixtyFiveThousandFiveHundredThirtyFive 
	OUT		LEDS
	jump 	read
led0-17:
	LOAD	OneHundredThirtyOneThouandSeventyOne
	OUT		LEDS
	jump 	read	
	
stop:
	LOAD   Zero
	OUT	   SONAREN
	;CALL   Wait2
	OUT    LEDS
	CALL   SonarTest
	
stopBeep:
	OUT	   BEEP
	LOAD   Zero
	OUT	   SONAREN
	;CALL   Wait2
	OUT    LEDS 	
	CALL   SonarTest
	
;end sonar test




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

	
	LOAD	sevout0
	OR		hhun
	SHIFT	4
	OR		tten
	SHIFT	4
	OR		oone
	STORE	sevout
	
	LOAD	negone ; This resets all the values needed for the sevenseg conversion
	STORE	oone
	STORE	tten
	STORE	hhun
	LOAD	sev
	STORE	sevout0
	STORE	sevin
	
	RETURN	

		
Key1sub:
	IN		XIO			; Now, wait for KEY1 to be pressed
	AND		Keymask		; Keymask for key1
	JZERO	Key1sub		; If key1 pressed, repeat
	CALL	Wait2	
	RETURN
	
Wait2:
	OUT     TIMER		; One second pause subroutine
Wloop2:
	IN      TIMER
	ADDI    -10			; 111111 1000001010
	JNEG    Wloop2
	RETURN	
	
Wait1:
	OUT     TIMER		; One second pause subroutine
Wloop:
	IN      TIMER
	ADD    Tspeed		; 111111 1000001010
	JNEG    Wloop
	RETURN

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
	CALL	ReadI2CBUSY	; Wait for BUSY to return zero after every instruction.
	CALL	ReadI2CData	; This data value is useless.
	RETURN
	
ReadBatteryVoltage:		; This will work after calling BatteryVoltageSetup only once.
	CALL	ReadI2CData	; Ordering the I2C to prepare a useful data point.
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
	OUT		SEVENSEG2
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
	
	
	
; This is a good place to put variables
Temp:     DW 0
TempV:	  DW 0
wipetemp: DW &B0000000000000001

; Having some constants can be very useful

DivNum:		DW 0
DivDen:		DW 0
DivResult:	DW 0
Writeone:	DW	&H1090
Readone:	DW	&H0190
sev:	  DW &B0000000000000000
tthou:    DW -1
hhun:     DW -1
tten:     DW -1
oone:     DW -1
negone:     DW -1

sevin:	  DW &B0000000000000000
sevout:   DW &B0000000000000000
sevout0:   DW &B0000000000000000
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
Thirteen: DW 13
Fifteen:  DW 15
Sixteen:  DW 16
ThirtyOne: DW 31
ThirtyTwo: DW 32
Fifty: DW 50
SixtyThree: DW 63
SixtyFour: DW 64
OneHundred: DW 100
OneFifty: DW 150
TwoHundred: DW 200
TwoFifty: DW 250
ThreeHundred: DW 300
ThreeFifty: DW 350
FourHundred: DW 400
FourFifty: DW 450
FiveHundred: DW 500
FiveFifty: DW 550
SixHundred: DW 600
SixFifty: DW 650
SevenHundred: DW 700
SevenFifty: DW 750
EightHundred: DW 800
EightFifty: DW 850
NineHundred: DW 900
NineFifty: DW 950
OneThousand: DW 1000
OneTwentySeven: DW 127
OneTwentyEight: DW 128
TwoFiftyFive: DW 255
FiveEleven: DW 511
OneThousandTwentyThree: DW 1023
TwoThousandFortySeven: DW 2047
FourThousandNinetyFive: DW 4095
EightThousandOneHundredNinetyOne: DW 8191
SixteenThousandThreeHundredEightyThree: DW 16383
ThirtyTwothousandSevenHundredSixtySeven: DW 32767
SixtyFiveThousandFiveHundredThirtyFive: DW 65535
OneHundredThirtyOneThouandSeventyOne: DW 131071
TwoHundredSixtyTwoThousandOneHundredFourtyThree: DW 262143

beeptimer:  DW -100000
LEDwipe:  DW &B0000000000000001

EnSonar0: DW &B00000001
EnSonar1: DW &B00000010
EnSonar2: DW &B00000100
EnSonar3: DW &B00001000
EnSonar4: DW &B00010000
EnSonar5: DW &B00100000
EnSonar6: DW &B01000000
EnSonar7: DW &B10000000
EnSonars: DW &B11111111
SON: DW &B01111111
LEDDIST: DW &B00111111

tf:		  DW &B00011000





Keymask: DW &B0000001
Keymask2: DW &B0000010
Keytest: DW &B0000111
Tspeed:	 DW -10
	

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


; IO address space map
SWITCHES: EQU &H00  ; slide switches
LEDS:     EQU &H01  ; red LEDs
LEDG:    EQU &H11	
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
