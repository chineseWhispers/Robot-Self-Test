-- I2C_CONTROLLER.vhd
-- An SCOMP peripheral to interface with I2C devices.
-- Capable of sending up to two bytes and reading up to two bytes at a time.
-- Created by Kevin Johnson.  Last modified 2013-03-07

-- SCOMP interface:
-- Three IO addresses are used: I2C_CMD, I2C_DATA, and I2C_BUSY.
--
--   I2C_CMD contains the bits [00WW 00RR AAAAAAAA] where:
--    WW is the number of bytes to write (0, 1, or 2)
--    RR is the number of bytes to read (0, 1, or 2)
--    AAAAAAAA is the 8-bit I2C address of the device
--
--   I2C_DATA is a read/write register.  Write to it the data you wish to send,
--   and read from it any data received.  Writing to this register starts the
--   I2C transaction, so:
--     I2C_CMD must be set BEFORE writing to I2C_DATA.
--     Even if no data is to be sent, something must still be written to I2C_DATA
--
--   I2C_BUSY is a read-only register that allows for polling the progess
--   of the I2C transaction.  A non-zero value indicates that this device
--   is busy and will not accept additional commands or data.
--   Zero indicates that this device is ready to accept commands or data.

-- Example of typical usage:
-- Write 0x2134 to I2C_CMD     ; command to write two bytes then read one byte, I2C address 0x34
-- Write 0xAA55 to I2C_DATA    ; send the bytes 0xAA and 0x55 over I2C, then read one byte from I2C
-- Read I2C_BUSY until it returns 0
-- Read I2C_DATA to retrieve the byte that was read from the I2C device.

LIBRARY IEEE;
USE  IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
LIBRARY LPM;
USE LPM.LPM_COMPONENTS.ALL;

ENTITY I2C_CONTROLLER IS
	PORT (
		CS_CMD, CS_DATA, CS_BUSY, WR, I2C_CLK, RESETN : IN  STD_LOGIC; 
		IO_DATA     : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);  -- must be INOUT, 
		SCL, SDA    : INOUT STD_LOGIC -- also must be INOUT.
	) ;
END I2C_CONTROLLER;

ARCHITECTURE a OF I2C_CONTROLLER IS
	
	SIGNAL CMD_W_REQ : STD_LOGIC;	-- used to latch data during IN
	SIGNAL DATA_W_REQ : STD_LOGIC;	-- used to latch data during IN
	SIGNAL DRIVE_IO     : STD_LOGIC;	-- controls driving of data bus
	SIGNAL IO_DATA_INT	: STD_LOGIC_VECTOR(15 DOWNTO 0);	-- driven to data bus during IN
 
	SIGNAL	SDA_INT		: STD_LOGIC;	-- internal signal for SDA.  This does not need to be tri-stated
	SIGNAL	SCL_INT		: STD_LOGIC;	-- internal signal for SDA.  This does not need to be tri-stated
	TYPE I2CSTATE_TYPE IS ( IDLE, SEND_BITS, GET_BITS, PRE_STOP, SEND_STOP, SEND_START, GET_ACK, SEND_ACK, SEND_ACK2 );
	SIGNAL I2C_STATE : I2CSTATE_TYPE;	-- state variable
	SIGNAL COUNT : INTEGER RANGE 0 TO 24;	-- used to keep track of which bit is being sent

	TYPE	  REGISTER_ARRAY	IS ARRAY(6 DOWNTO 0) OF STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL	CMD_BUFF		: STD_LOGIC_VECTOR(16 DOWNTO 0);	-- stores the command (including address)
	SIGNAL	TX_BUFF		: STD_LOGIC_VECTOR(23 DOWNTO 0);	-- stores the packet being transmitted
	SIGNAL	RX_BUFF		: STD_LOGIC_VECTOR(15 DOWNTO 0);	-- stores the packet being received
	SIGNAL	DATA_RCVD	: STD_LOGIC;	-- flag to let the state machine know that data has arrived
	SIGNAL	I2C_BUSY	: STD_LOGIC;	-- flag that the state machine is busy using the I2C bus
	SIGNAL	CS_DB		: STD_LOGIC_VECTOR(1 DOWNTO 0);	-- for selecting output signal
	SIGNAL	RnW			: STD_LOGIC;	-- flag for read or write sequence

BEGIN

	-- Use LPM function to create bidirectional I/O data bus
	IO_BUS: lpm_bustri
	GENERIC MAP (
		lpm_width => 16
	)
	PORT MAP (
		data     => IO_DATA_INT,
		enabledt => DRIVE_IO,
		tridata  => IO_DATA
	);
 
	DRIVE_IO <= ((CS_DATA OR CS_CMD OR CS_BUSY) AND NOT(WR));  -- drives I/O bus when "IN" is occurring
	
	CS_DB <= CS_DATA & CS_BUSY;	-- to make the following SELECT statement easier...
	WITH CS_DB SELECT IO_DATA_INT <=	-- SELECT statement to decide what data needs to be driven during an IN
		RX_BUFF WHEN "10",	-- send any received data
		"00000000000000"&DATA_RCVD&I2C_BUSY WHEN "01", -- creates non-zero busy indicator
		"XXXXXXXXXXXXXXXX" WHEN OTHERS;	-- don't care
 	
	-- the following two signals are used to know when to read the data bus (during an SCOMP OUT)
	-- On the rising edge of [CS AND WR], the data bus is guaranteed to be stable.
 	CMD_W_REQ <= CS_CMD AND WR;
 	DATA_W_REQ <= CS_DATA AND WR;
 	
	-- the following statements handle the open-collector emulation for SDA and SCL
	WITH SCL_INT SELECT SCL <= 
		'0' WHEN '0',	-- only allowed to pull the line low
		'Z' WHEN OTHERS;	-- otherwise, it must be hi-Z
	WITH SDA_INT SELECT SDA  <= 
		'0' WHEN '0',
		'Z' WHEN OTHERS;
  
	-- This process handles the parallel IO interface with SCOMP.
	-- During an SCOMP IN, data is driven to the bus using the tri-state driver
	-- During an SCOMP OUT, data is latched to the appropriate register on the rising
	--  edge of [CS AND WR]
	PROCESS (I2C_CLK, RESETN, CS_DATA, CMD_W_REQ, DATA_W_REQ, I2C_STATE, DATA_RCVD)
	BEGIN
		IF RESETN = '0' THEN
			DATA_RCVD <= '0';
			TX_BUFF <= "000000000000000000000000";
		ELSE
			IF I2C_STATE = IDLE THEN	-- the state machine isn't busy
				-- since the state machine is idle, look for incoming data from SCOMP,
				-- unless there is already pending data (indicated by DATA_RCVD)
				IF RISING_EDGE(DATA_W_REQ) AND DATA_RCVD='0' THEN
					-- receiving new data; save it.
					TX_BUFF(15 DOWNTO 0) <= IO_DATA;
					DATA_RCVD <= '1';	-- let the state machine know
				END IF;
				IF RISING_EDGE(CMD_W_REQ) THEN
					-- receiving an address; save it
					TX_BUFF(23 DOWNTO 16) <= IO_DATA(7 DOWNTO 0);
					CMD_BUFF(15 DOWNTO 0) <= IO_DATA(15 DOWNTO 0);
				END IF;
			ELSE -- the state machine is not idle
				DATA_RCVD <= '0';	-- so we can clear this flag
			END IF;
		END IF;
	END PROCESS;

	-- The following process is a state machine used to handle the I2C protocol.
	-- To achieve proper timing for SDA and SCL, they are controlled by alternating
	--- edges of I2C_CLK; i.e. SDA is updated on the rising edges and SCL is updated
	--- on the falling edges.  Do not confuse I2C_CLK with SCL: I2C_CLK is to control
	--- the state machine only.  The state machine in turn controls SCL.
	-- This allows the state machine to perform actions in the middle of each SCL state,
	--- e.g. setting SDA while SCL is low, or reading SDA while SCL is high.
	-- However because of this, I2C_CLK must be twice the desired I2C frequency
	--- e.g. 200kHz I2C_CLK will result in an SCL frequency of 100kHz
	PROCESS (I2C_CLK, RESETN)
	BEGIN
		IF ( RESETN = '0' ) THEN
			SDA_INT <= '1';	-- SDA idle high
			SCL_INT <= '1';	-- SCL idle high
			I2C_BUSY <= '0';
			I2C_STATE <= IDLE;
		ELSE 
			IF ( I2C_CLK'EVENT AND I2C_CLK = '1'  ) THEN
				-- state (and thus SDA) will change on rising clocks
				CASE I2C_STATE  IS
				
					WHEN IDLE =>
						SDA_INT <= '1';	-- ensure idle SDA
						IF DATA_RCVD = '1' THEN	-- if new data is available from the IO
							I2C_STATE <= SEND_START;	-- begin the I2C transfer
							I2C_BUSY <= '1';	-- flag that the I2C bus is busy
							RX_BUFF <= x"0000";
							IF CMD_BUFF(13 DOWNTO 12)="00" AND CMD_BUFF(9 DOWNTO 8)/="00" THEN	-- check read/write requirements
								RnW <= '1';	-- immediate read (no write)
							ELSE
								RnW <= '0';	-- there is a write, or there is nothing
							END IF;
						ELSE
							I2C_BUSY <= '0';	-- important to clear the flag after returning to idle from a transmission
						END IF;

					WHEN SEND_START =>
						IF SCL_INT = '1' THEN -- SCL is ready for start bit.
							SDA_INT <= '0';	-- start bit
							I2C_STATE <= SEND_BITS;
							COUNT <= 24;		-- initialize the counter
						END IF;

					-- SEND_BITS is always used to send the address, and is used to send data when writing
					WHEN SEND_BITS =>
						IF SCL_INT = '0' THEN	-- only change SDA when SCL is low
							IF (COUNT = 16) OR (COUNT = 8) OR (COUNT = 0) THEN -- need to check ack
								SDA_INT <= '1';	-- release SDA for ack read
								I2C_STATE <= GET_ACK; 
							ELSE
								IF COUNT = 17 THEN	-- sending the R/W bit
									SDA_INT <= RnW;
								ELSE
									SDA_INT <= TX_BUFF(COUNT-1);	-- output the current bit of the packet
								END IF;
								COUNT <= COUNT-1;	-- move on to next bit
							END IF;
						END IF;
						
					WHEN GET_BITS =>
						IF SCL_INT = '1' THEN	-- only read when SCL high
							RX_BUFF(count-1) <= SDA;
						ELSE	-- SCL low; we can change state if needed
							IF (COUNT = 9) THEN 
								SDA_INT <= '0';	-- ack
								I2C_STATE <= SEND_ACK2; 
							END IF;
							IF (COUNT = 1) THEN
								SDA_INT <= '1';	-- nack to end transmission
								I2C_STATE <= SEND_ACK2;
							END IF;
							COUNT <= COUNT-1;
						END IF;
						
					-- this is a fairly complicated state, since following the ack, the
					--- transmission can change from write to read, or end.
					--- COUNT is also updated in the case of <2 bytes to write or read
					WHEN GET_ACK =>
						IF SCL_INT = '1' THEN	-- only sample when SCL is high.
							-- note that we don't transition state here;
							--- we only transition state when SCL is low
							IF SDA = '1' THEN 
								I2C_STATE <= PRE_STOP;	-- nack; send stop and terminate transmission
							END IF;							
						ELSE	-- SCL is low; change state
							IF COUNT = 0 THEN	-- end of write
								IF CMD_BUFF(9 DOWNTO 8)="00" THEN	-- no read, end of packet; send stop
									I2C_STATE <= SEND_STOP;
									SDA_INT <= '0';	-- sda needs to be low for stop bit
								ELSE	-- transition to read
									RnW <= '1';	-- flag read
									SDA_INT <= '1';	-- prepare for restart
									I2C_STATE <= SEND_START;
								END IF;
							ELSE
								IF RnW = '0' THEN -- R/W bit is WRITE - either just sent address or data
									IF CMD_BUFF(13 DOWNTO 12) /= "01" THEN
										COUNT <= COUNT-1;		-- next bit
										SDA_INT <= TX_BUFF(COUNT-1); -- output the next bit
									ELSE
										COUNT <= COUNT-9;		-- skip high byte
										SDA_INT <= TX_BUFF(COUNT-9); -- output the next bit
									END IF;
									I2C_STATE <= SEND_BITS;	-- go back to sending bits
								ELSE	-- R/W bit is READ - i.e. we just finished sending the read address
									I2C_STATE <= GET_BITS;	-- transition to receiving bits.
									IF CMD_BUFF(9 DOWNTO 8) = "01" THEN
										COUNT <= COUNT - 8;	-- if only getting one byte, skip the high byte
									ELSIF CMD_BUFF(9 DOWNTO 8) = "00" THEN
										COUNT <= COUNT - 16;	-- if for some reason we're not getting anything after all...
									END IF;
									SDA_INT <= '1';	-- release SDA
								END IF;
							END IF;
						END IF;
						
					WHEN SEND_ACK =>
						IF SCL_INT = '0' THEN	-- only change SDA when SCL is low
							SDA_INT <= '0';	-- output the ack
							I2C_STATE <= SEND_ACK2;	-- hold ack for a clock cycle
						END IF;
						
					WHEN SEND_ACK2 =>
						IF SCL_INT = '0' THEN	-- only change SDA when SCL is low
							IF COUNT = 0 THEN	-- end of packet; send stop bit
								SDA_INT <= '0';	-- prepare for stop bit
								I2C_STATE <= SEND_STOP;
							ELSE
								SDA_INT <= '1';	-- release SDA
								I2C_STATE <= GET_BITS;	-- return to reading bits
							END IF;
						END IF;
						
					WHEN PRE_STOP =>
						IF SCL_INT = '0' THEN
							SDA_INT <= '0';	-- prepare for the stop condition
							I2C_STATE <= SEND_STOP;
						END IF;
					
					WHEN SEND_STOP =>
						IF SCL_INT = '1' THEN
							SDA_INT <= '1';	-- SCL is high; SDA going high will create the stop bit
							I2C_STATE <= IDLE;
						END IF;
						
				END CASE;
			END IF;	-- end rising clock
			
			-- SCL will transition on falling edges of I2C_CLK
			IF ( I2C_CLK'EVENT AND I2C_CLK = '0'  ) THEN
				IF NOT(I2C_STATE = IDLE OR I2C_STATE = SEND_START) THEN
					SCL_INT <= NOT SCL;	-- toggle SCL, testing the actual pin.  This allows clock stretching.
				ELSE
					SCL_INT <= '1';	-- idle
				END IF;
			END IF; -- end falling clock
			
		END IF;	-- end resetn.
	END PROCESS;
END a;

