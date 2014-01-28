LIBRARY IEEE;
USE  IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY LCD_Display IS

-----------------------------------------------------------------------
-- LCD Displays 16 Characters on 2 lines
-- LCD_display string is an ASCII character string entered in hex for 
-- the two lines of the  LCD Display   (See ASCII to hex table below)
-- Edit LCD_Display_String entries above to modify display
-- Enter the ASCII character's 2 hex digit equivalent value
-- (see table below for ASCII hex values)
-- To display character assign ASCII value to LCD_display_string(x)
-- To skip a character use X"20" (ASCII space)
-- To dislay "live" hex values from hardware on LCD use the following: 
--   make array element for that character location X"0" & 4-bit field from Hex_Display_Data
--   state machine sees X"0" in high 4-bits & grabs the next lower 4-bits from Hex_Display_Data input
--   and performs 4-bit binary to ASCII conversion needed to print a hex digit
--   Num_Hex_Digits must be set to the count of hex data characters (ie. "00"s) in the display
--   Connect hardware bits to display to Hex_Display_Data input
-- To display less than 32 characters, terminate string with an entry of X"FE"
--  (fewer characters may slightly increase the LCD's data update rate)
------------------------------------------------------------------- 
--                        ASCII HEX TABLE
--  Hex						Low Hex Digit
-- Value  0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
------\----------------------------------------------------------------
--H  2 |  SP  !   "   #   $   %   &   '   (   )   *   +   ,   -   .   /
--i  3 |  0   1   2   3   4   5   6   7   8   9   :   ;   <   =   >   ?
--g  4 |  @   A   B   C   D   E   F   G   H   I   J   K   L   M   N   O
--h  5 |  P   Q   R   S   T   U   V   W   X   Y   Z   [   \   ]   ^   _
--   6 |  `   a   b   c   d   e   f   g   h   i   j   k   l   m   n   o
--   7 |  p   q   r   s   t   u   v   w   x   y   z   {   |   }   ~ DEL
-----------------------------------------------------------------------
-- Example "A" is row 4 column 1, so hex value is X"41"
-- *see LCD Controller's Datasheet for other graphics characters available
--
	PORT(reset, clk_48Mhz,state13,state12,state11,state10,state9,state8,state7,state6,state5,state4,state3,state2,state1, CS: IN	STD_LOGIC;
		 Hex_Display_Data			: IN    STD_LOGIC_VECTOR(15 DOWNTO 0);
		 LCD_RS, LCD_E				: OUT	STD_LOGIC;
		 LCD_RW						: OUT   STD_LOGIC;
		 DATA_BUS					: INOUT	STD_LOGIC_VECTOR(7 DOWNTO 0));
		
END ENTITY LCD_Display;

ARCHITECTURE a OF LCD_Display IS
TYPE character_string IS ARRAY ( 0 TO 31 ) OF STD_LOGIC_VECTOR( 7 DOWNTO 0 );

TYPE STATE_TYPE IS (HOLD, FUNC_SET, DISPLAY_ON, MODE_SET, Print_String, LINE2, RETURN_HOME, DROP_LCD_E, RESET1, RESET2, RESET3, RESET4, DISPLAY_OFF, DISPLAY_CLEAR);
SIGNAL state, next_command: STATE_TYPE;
SIGNAL LCD_display_string	: character_string;
-- Enter new ASCII hex data above for LCD Display
SIGNAL DATA_BUS_VALUE, Next_Char: STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL CLK_COUNT_400HZ: STD_LOGIC_VECTOR(19 DOWNTO 0);
SIGNAL CHAR_COUNT: STD_LOGIC_VECTOR(4 DOWNTO 0);
SIGNAL CLK_400HZ_Enable,LCD_RW_INT : STD_LOGIC;
SIGNAL Line1_chars, Line2_chars: STD_LOGIC_VECTOR(127 DOWNTO 0);
BEGIN

-- BIDIRECTIONAL TRI STATE LCD DATA BUS
	DATA_BUS <= DATA_BUS_VALUE WHEN LCD_RW_INT = '0' ELSE "ZZZZZZZZ";
-- get next character in display string
	Next_Char <= LCD_display_string(CONV_INTEGER(CHAR_COUNT));
	LCD_RW <= LCD_RW_INT;
PROCESS
	BEGIN
	 WAIT UNTIL CLK_48MHZ'EVENT AND CLK_48MHZ = '1';
		IF RESET = '0' OR state1 = '1' OR state2 = '1' OR state3 = '1' OR state4 = '1' OR state5 = '1' OR state6 = '1' OR state7 = '1' OR state8 = '1' OR state9 = '1'  OR state10 = '1' OR state11 = '1' OR state12 = '1' OR state13 = '1' THEN --if a reset occurs, reset the clock count to zero, and set enable to 0
		 CLK_COUNT_400HZ <= X"00000";										
		 CLK_400HZ_Enable <= '0';
		ELSE
				IF CLK_COUNT_400HZ < X"107AC" THEN 		-- wait 60,000 cycles; at 50 MHz this corresponds to 1.2 ms
				 CLK_COUNT_400HZ <= CLK_COUNT_400HZ + 1;-- if it hasn't exceeded 60000 cycles, keep counting
				 CLK_400HZ_Enable <= '0';				-- keep it enabled
				ELSE
		    	 CLK_COUNT_400HZ <= X"00000";			-- if it's above 60,000, reset to 0 and disable
				 CLK_400HZ_Enable <= '1';
				END IF;
		END IF;
		
	END PROCESS;
	PROCESS (CLK_48MHZ, reset, state13,state12,state11,state10,state9,state8,state7,state6,state5,state4,state3,state2,state1)
	BEGIN
	
	
		IF reset = '0' THEN
			state <= RESET1;
			DATA_BUS_VALUE <= X"38";
			 LCD_display_string <= (
			-- ASCII hex values for LCD Display
			-- Enter Live Hex Data Values from hardware here
			
			--"DE2 I|O"
			X"44",X"45",X"32",X"20",X"49",X"7C",X"4F",X"20",X"20",X"20",X"20",X"6D",X"20",X"20",X"20",X"20",
			
			-- "PK INPUT TEST"
			X"50",X"4B",X"20",X"49",X"4E",X"50",X"55",X"54",X"20",X"54",X"45",X"53",X"54",X"20",X"20",X"20");
			next_command <= RESET2;
			LCD_E <= '1';
			LCD_RS <= '0';
			LCD_RW_INT <= '1';
		
		
		ELSIF state1 = '1'THEN
			state <= RESET1;
			DATA_BUS_VALUE <= X"38";
			LCD_display_string <= (
			-- ASCII hex values for LCD Display
			-- Enter Live Hex Data Values from hardware here
			
			--"DE2 I|O"
			X"44",X"45",X"32",X"20",X"49",X"7C",X"4F",X"20",X"20",X"20",X"20",X"6D",X"20",X"20",X"20",X"20",
			
			--"PRESS KEY1"
			X"50",X"52",X"45",X"53",X"53",X"20",X"4B",X"45",X"59",X"31",X"FE",X"20",X"20",X"20",X"20",X"20"); 
			next_command <= RESET2;
			LCD_E <= '1';
			LCD_RS <= '0';
			LCD_RW_INT <= '1';
		
		
		ELSIF state2 = '1' THEN
			state <= RESET1;
			DATA_BUS_VALUE <= X"38";
			LCD_display_string <= (
			-- ASCII hex values for LCD Display
			-- Enter Live Hex Data Values from hardware here
			
			-- Line 1 "_DE2_I/O_
			X"20",X"44",X"45",X"32",X"20",X"49",X"7C",X"4F",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",
			
			-- Line 2 "_SW_Input Test"
			X"20",X"53",X"57",X"20",X"49",X"6E",X"70",X"75",X"74",X"20",X"54",X"65",X"73",X"74",X"FE",X"20");
			next_command <= RESET2;
			LCD_E <= '1';
			LCD_RS <= '0';
			LCD_RW_INT <= '1';


		ELSIF state3 = '1' THEN
			state <= RESET1;
			DATA_BUS_VALUE <= X"38";
			LCD_display_string <= (
			-- ASCII hex values for LCD Display
			-- Enter Live Hex Data Values from hardware here
			
			-- Line 1 "_DE2_I/O_
			X"20",X"44",X"45",X"32",X"20",X"49",X"7C",X"4F",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",
			
			-- "TIMER TEST"
			X"54",X"49",X"4D",X"45",X"52",X"20",X"54",X"45",X"53",X"54",X"FE",X"20",X"20",X"20",X"20",X"20");

			next_command <= RESET2;
			LCD_E <= '1';
			LCD_RS <= '0';
			LCD_RW_INT <= '1';
			
			
		ELSIF state4 = '1' THEN
			state <= RESET1;
			DATA_BUS_VALUE <= X"38";
			LCD_display_string <= (
			-- ASCII hex values for LCD Display
			-- Enter Live Hex Data Values from hardware here
			
			-- "BOTBASIC"
			X"42",X"4F",X"54",X"42",X"41",X"53",X"49",X"43",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",
			
			-- "BEEP"
			X"42",X"45",X"45",X"50",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");

			next_command <= RESET2;
			LCD_E <= '1';
			LCD_RS <= '0';
			LCD_RW_INT <= '1';
			
			
		ELSIF state5 = '1'THEN
			state <= RESET1;
			DATA_BUS_VALUE <= X"38";
			LCD_display_string <= (
			-- ASCII hex values for LCD Display
			-- Enter Live Hex Data Values from hardware here
			
			-- "BOTBASIC"
			X"42",X"4F",X"54",X"42",X"41",X"53",X"49",X"43",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",
			
			-- "BATT"
			X"42",X"41",X"54",X"54",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");
			
			next_command <= RESET2;
			LCD_E <= '1';
			LCD_RS <= '0';
			LCD_RW_INT <= '1';
		
		
		ELSIF state6 = '1' THEN
			state <= RESET1;
			DATA_BUS_VALUE <= X"38";
			LCD_display_string <= (
			-- ASCII hex values for LCD Display
			-- Enter Live Hex Data Values from hardware here
			
			-- "MENU"
			X"4D",X"45",X"4E",X"55",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",
			
			-- "BOTBASIC"
			X"42",X"4F",X"54",X"42",X"41",X"53",X"49",X"43",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");

			next_command <= RESET2;
			LCD_E <= '1';
			LCD_RS <= '0';
			LCD_RW_INT <= '1';


		ELSIF state7 = '1' THEN
			state <= RESET1;
			DATA_BUS_VALUE <= X"38";
			LCD_display_string <= (
			-- ASCII hex values for LCD Display
			-- Enter Live Hex Data Values from hardware here
			
			-- "MENU"
			X"4D",X"45",X"4E",X"55",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",
			
			-- "SONAR"
			X"53",X"4F",X"4E",X"41",X"52",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");
			
			next_command <= RESET2;
			LCD_E <= '1';
			LCD_RS <= '0';
			LCD_RW_INT <= '1';
			
			
		ELSIF state8 = '1' THEN
			state <= RESET1;
			DATA_BUS_VALUE <= X"38";
			LCD_display_string <= (
			-- ASCII hex values for LCD Display
			-- Enter Live Hex Data Values from hardware here
			
			-- "MENU"
			X"4D",X"45",X"4E",X"55",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",
			
			-- "MOTOR"
			X"4D",X"4F",X"54",X"4F",X"52",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");

			next_command <= RESET2;
			LCD_E <= '1';
			LCD_RS <= '0';
			LCD_RW_INT <= '1';


		ELSIF state9 = '1'THEN
			state <= RESET1;
			DATA_BUS_VALUE <= X"38";
			LCD_display_string <= (
			-- ASCII hex values for LCD Display
			-- Enter Live Hex Data Values from hardware here
			
			-- "MENU"
			X"4D",X"45",X"4E",X"55",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",
			
			-- "VELOCITY"
			X"56",X"45",X"4C",X"4F",X"43",X"49",X"54",X"59",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");
			next_command <= RESET2;
			LCD_E <= '1';
			LCD_RS <= '0';
			LCD_RW_INT <= '1';
		
		
		ELSIF state10 = '1' THEN
			state <= RESET1;
			DATA_BUS_VALUE <= X"38";
			LCD_display_string <= (
			-- ASCII hex values for LCD Display
			-- Enter Live Hex Data Values from hardware here
			
			-- "TEST"
			X"54",X"45",X"53",X"54",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",
			
			-- "MOTOR"
			X"4D",X"4F",X"54",X"4F",X"52",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");
			next_command <= RESET2;
			LCD_E <= '1';
			LCD_RS <= '0';
			LCD_RW_INT <= '1';


		ELSIF state11 = '1' THEN
			state <= RESET1;
			DATA_BUS_VALUE <= X"38";
			LCD_display_string <= (
			-- ASCII hex values for LCD Display
			-- Enter Live Hex Data Values from hardware here
			
			-- "TEST"
			X"54",X"45",X"53",X"54",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",
			
			-- "SONAR"
			X"53",X"4F",X"4E",X"41",X"52",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");

			next_command <= RESET2;
			LCD_E <= '1';
			LCD_RS <= '0';
			LCD_RW_INT <= '1';
			
			
		ELSIF state12 = '1' THEN
			state <= RESET1;
			DATA_BUS_VALUE <= X"38";
			LCD_display_string <= (
			-- ASCII hex values for LCD Display
			-- Enter Live Hex Data Values from hardware here
			
			-- "TEST"
			X"54",X"45",X"53",X"54",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",
			
			-- "VELOCITY"
			X"56",X"45",X"4C",X"4F",X"43",X"49",X"54",X"59",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");

			next_command <= RESET2;
			LCD_E <= '1';
			LCD_RS <= '0';
			LCD_RW_INT <= '1';
			
		ELSIF state13 = '1' THEN
			state <= RESET1;
			DATA_BUS_VALUE <= X"38";
			LCD_display_string <= (
			-- ASCII hex values for LCD Display
			-- Enter Live Hex Data Values from hardware here
			
			-- "MENU"
			X"4D",X"45",X"4E",X"55",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",
			
			-- "????"
			X"20",X"3F",X"3F",X"3F",X"3F",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");

			next_command <= RESET2;
			LCD_E <= '1';
			LCD_RS <= '0';
			LCD_RW_INT <= '1';
			

		ELSIF CLK_48MHZ'EVENT AND CLK_48MHZ = '1' THEN
-- State Machine to send commands and data to LCD DISPLAY			
		  IF CLK_400HZ_Enable = '1' THEN
			CASE state IS
-- Set Function to 8-bit transfer and 2 line display with 5x8 Font size
-- see Hitachi HD44780 family data sheet for LCD command and timing details
				WHEN RESET1 =>
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						DATA_BUS_VALUE <= X"38";
						state <= DROP_LCD_E;
						next_command <= RESET2;
						CHAR_COUNT <= "00000";
				WHEN RESET2 =>
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						DATA_BUS_VALUE <= X"38";
						state <= DROP_LCD_E;
						next_command <= RESET3;
				WHEN RESET3 =>
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						DATA_BUS_VALUE <= X"38";
						state <= DROP_LCD_E;
						next_command <= RESET4;
				WHEN RESET4 =>
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						DATA_BUS_VALUE <= X"38";
						state <= DROP_LCD_E;
						next_command <= FUNC_SET;
-- EXTRA STATES ABOVE ARE NEEDED FOR RELIABLE PUSHBUTTON RESET OF LCD
				WHEN FUNC_SET =>
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						DATA_BUS_VALUE <= X"38";
						state <= DROP_LCD_E;
						next_command <= DISPLAY_OFF;
-- Turn off Display and Turn off cursor
				WHEN DISPLAY_OFF =>
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						DATA_BUS_VALUE <= X"08";
						state <= DROP_LCD_E;
						next_command <= DISPLAY_CLEAR;
-- Clear Display and Turn off cursor
				WHEN DISPLAY_CLEAR =>
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						DATA_BUS_VALUE <= X"01";
						state <= DROP_LCD_E;
						next_command <= DISPLAY_ON;
-- Turn on Display and Turn off cursor
				WHEN DISPLAY_ON =>
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						DATA_BUS_VALUE <= X"0C";
						state <= DROP_LCD_E;
						next_command <= MODE_SET;
-- Set write mode to auto increment address and move cursor to the right
				WHEN MODE_SET =>
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						DATA_BUS_VALUE <= X"06";
						state <= DROP_LCD_E;
						next_command <= Print_String;
-- Write ASCII hex character in first LCD character location
				WHEN Print_String =>
						state <= DROP_LCD_E;
						LCD_E <= '1';
						LCD_RS <= '1';
						LCD_RW_INT <= '0';
-- ASCII character to output
						IF Next_Char(7 DOWNTO  4) /= X"0" THEN
						DATA_BUS_VALUE <= Next_Char;
						ELSE
-- Convert 4-bit value to an ASCII hex digit
							IF Next_Char(3 DOWNTO 0) >9 THEN
-- ASCII A...F
							 DATA_BUS_VALUE <= X"4" & (Next_Char(3 DOWNTO 0)-9);
							ELSE
-- ASCII 0...9
							 DATA_BUS_VALUE <= X"3" & Next_Char(3 DOWNTO 0);
							END IF;
						END IF;
						state <= DROP_LCD_E;
-- Loop to send out 32 characters to LCD Display  (16 by 2 lines)
						IF (CHAR_COUNT < 31) AND (Next_Char /= X"FE") THEN 
						 CHAR_COUNT <= CHAR_COUNT +1;
						ELSE 
						 CHAR_COUNT <= "00000"; 
						END IF;
-- Jump to second line?
						IF CHAR_COUNT = 15 THEN next_command <= line2;
-- Return to first line?
						ELSIF (CHAR_COUNT = 31) OR (Next_Char = X"FE") THEN 
						 next_command <= return_home; 
						ELSE next_command <= Print_String; END IF;
-- Set write address to line 2 character 1
				WHEN LINE2 =>
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						DATA_BUS_VALUE <= X"C0";
						state <= DROP_LCD_E;
						next_command <= Print_String;
-- Return write address to first character postion on line 1
				WHEN RETURN_HOME =>
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						DATA_BUS_VALUE <= X"80";
						state <= DROP_LCD_E;
						next_command <= Print_String;
-- The next three states occur at the end of each command or data transfer to the LCD
-- Drop LCD E line - falling edge loads inst/data to LCD controller
				WHEN DROP_LCD_E =>
						LCD_E <= '0';
						state <= HOLD;
-- Hold LCD inst/data valid after falling edge of E line				
				WHEN HOLD =>
						state <= next_command;
			END CASE;
		  END IF;
		END IF;
	END PROCESS;
END a;
