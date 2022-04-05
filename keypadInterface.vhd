-----------------------------------------------------------------------------
-----------------															 ----------------
----------------- This RTL Code written by Matan Leizerovich ----------------
-----------------															 ----------------
-----------------------------------------------------------------------------
----------------- This entity interfaces with a 4x4 keypad  -----------------
-----------------------------------------------------------------------------

------------------------------- Keypad pinout -------------------------------
--                        Pins 1 & 10 are not connected!                   --
-- 																								--
--    Pin 2 => Col 1 , Pin 3 => Col 2 , Pin 4 => Col 3 , Pin 5 => Col 4    --
--    Pin 6 => Row 1 , Pin 7 => Row 2 , Pin 8 => Row 3 , Pin 9 => Row 4    --
-----------------------------------------------------------------------------

------------------------------- Keypad Outputs ----------------------------------
---- #1 <==> Pins 2&6 , #2 <==> Pins 3&6 , #3 <==> Pins 4&6 , #4 <==> Pins 2&7 --
---- #5 <==> Pins 3&7 , #6 <==> Pins 4&7 , #7 <==> Pins 2&8 , #8 <==> Pins 3&8 --
---- #9 <==> Pins 4&8 , #0 <==> Pins 3&9 ,  * <==> Pins 2&9 ,  # <==> Pins 4&9 --
----  A <==> Pins 5&6 ,  B <==> Pins 5&7 ,  C <==> Pins 5&8 ,  D <==> Pins 5&9 --
---------------------------------------------------------------------------------

------------------------------- Algorithm ----------------------------------
--  The goal is to scan the rows by giving '1' to each row individually   --
-- and then perform a search in which column has a '1' in order to know   --
--                         which button is pressed.                       --
--                                                                        --
-- 1. Set first row to '1' and check which row has a '1'                  --
-- 2. Set second row to '1' and check which row has a '1'                 --
-- 3. Set third row to '1' and check which row has a '1'  			        --
-- 4. Set fourth row to '1' and check which row has a '1'.                --
-- 5. Back to step 1.                                             		  --
--                             *~*~* Note *~*~*                           --   
-- In case there was a match between row and column at each step, then    --
-- output the information of the key pressed and proceed to the next step --
----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity keypadInterface is
	generic(g_SCAN_FREQUENCY : natural := 20); -- Desired scan frequency
	port (
			-- Inputs --
		i_clk    : in std_logic;
		i_reset  : in std_logic;
		i_columns : in std_logic_vector (3 downto 0);

		-- Outputs -- 
		o_rows : out std_logic_vector (3 downto 0);
		o_keyPressed_Char : out character;
		o_keyPressed_Byte : out std_logic_vector (7 downto 0)
			);
end entity keypadInterface;

architecture rtl of keypadInterface is
	-- Functions --
	
	-- Converts the character to ASCII byte --
	function charToASCIIbyte (i_char: character) return std_logic_vector is
		begin
			case (i_char) is
				when '0' 	=> return X"30";
				when '1' 	=> return X"31";
				when '2' 	=> return X"32";
				when '3' 	=> return X"33";
				when '4' 	=> return X"34";
				when '5' 	=> return X"35";
				when '6' 	=> return X"36";
				when '7' 	=> return X"37";
				when '8' 	=> return X"38";
				when '9' 	=> return X"39";
				when '*'	   => return X"2A";
				when '#' 	=> return X"23";
				when 'A' 	=> return X"41";
				when 'B' 	=> return X"42";
				when 'C' 	=> return X"43";
				when 'D' 	=> return X"44";
			   when others => return X"55"; -- 'U'
			end case;
	end function charToASCIIbyte;
	
	-- Types & Subtypes --
	type t_char_array is array (0 to 3) of character;
	type t_keypad_matrix is array (0 to 3) of t_char_array;
	
	-- Finitie State Machine - Enumeration -- 
	type t_state is (s_row1 , s_row2 , s_row3 , s_row4);
	
	-- Constants --
	
	-- Lookup table -- C_KEYPAD_MATRIX(row_index)(column_index) --
	constant C_KEYPAD_MATRIX : t_keypad_matrix := (
															('1', '2', '3', 'A') ,
															('4', '5', '6', 'B') ,
															('7', '8', '9', 'C') ,
															('*', '0', '#', 'D')
															);
	

	-- Signals --
	signal r_state : t_state := s_row1;
	signal r_rows : std_logic_vector(3 downto 0) := X"1";
	signal r_char : character := 'U';
	signal w_20hz_clk : std_logic;
	
begin

	------- instance of clock divider -------
	i_20Hz_clk : entity work.clockDivider
	generic map(g_FREQ => g_SCAN_FREQUENCY)
	port map (
			i_clk   => i_clk ,
			i_reset => i_reset ,  
			o_clk   => w_20hz_clk,
			o_tick  => open);
	-------------------------------------------
	
	
	-- This process scans the button matrix to find the key being pressed --
	p_scan_key : process (w_20hz_clk , i_reset) is
	begin
		if (i_reset = '0') then -- asynchronous reset
			r_state <= s_row1;
			r_rows <= X"1";
			
		elsif (rising_edge(w_20hz_clk)) then
			case (r_state) is
			
				-- Scan all columns on the first row --
				when s_row1 =>
					
					-- Check which column is HIGH in order to check the pressed key
					if (i_columns = X"0") then -- key not pressed
						r_char <= 'U';
					elsif (i_columns = X"1") then -- key '1' pressed
						r_char <= C_KEYPAD_MATRIX(0)(0);
					elsif (i_columns = X"2") then -- key '4' pressed
						r_char <= C_KEYPAD_MATRIX(0)(1);
					elsif (i_columns = X"4") then -- key '7' pressed
						r_char <= C_KEYPAD_MATRIX(0)(2);
					elsif (i_columns = X"8") then -- key '*' pressed
						r_char <= C_KEYPAD_MATRIX(0)(3);
					else -- two buttons or more were pressed
						r_char <= 'U';
					end if; -- i_columns
					
					-- Update outputs --
					r_state <= s_row2;
					r_rows <= X"2";
					
				-- Scan all columns on the second row --
				when s_row2 =>
					
					-- Check which column is HIGH in order to check the pressed key
					if (i_columns = X"0") then -- key not pressed
						r_char <= 'U';
					elsif (i_columns = X"1") then -- key '2' pressed
						r_char <= C_KEYPAD_MATRIX(1)(0);
					elsif (i_columns = X"2") then -- key '5' pressed
						r_char <= C_KEYPAD_MATRIX(1)(1);
					elsif (i_columns = X"4") then -- key '8' pressed
						r_char <= C_KEYPAD_MATRIX(1)(2);
					elsif (i_columns = X"8") then -- key '0' pressed
						r_char <= C_KEYPAD_MATRIX(1)(3);
					else -- two buttons or more were pressed
						r_char <= 'U';
					end if; -- i_columns
					
					-- Update outputs --
					r_state <= s_row3;
					r_rows <= X"4";
					
				-- Scan all columns on the third row --
				when s_row3 =>
					
					-- Check which column is HIGH in order to check the pressed key
					if (i_columns = X"0") then -- key not pressed
						r_char <= 'U';
					elsif (i_columns = X"1") then -- key '3' pressed
						r_char <= C_KEYPAD_MATRIX(2)(0);
					elsif (i_columns = X"2") then -- key '6' pressed
						r_char <= C_KEYPAD_MATRIX(2)(1);
					elsif (i_columns = X"4") then -- key '9' pressed
						r_char <= C_KEYPAD_MATRIX(2)(2);
					elsif (i_columns = X"8") then -- key '#' pressed
						r_char <= C_KEYPAD_MATRIX(2)(3);
					else -- two buttons or more were pressed
						r_char <= 'U';
					end if; -- i_columns
					
					-- Update outputs --
					r_state <= s_row4;
					r_rows <= X"8";
				
				-- Scan all columns on the fourth row --
				when s_row4 =>
					
					-- Check which column is HIGH in order to check the pressed key
					if (i_columns = X"0") then -- key not pressed
						r_char <= 'U';
					elsif (i_columns = X"1") then -- key 'A' pressed
						r_char <= C_KEYPAD_MATRIX(3)(0);
					elsif (i_columns = X"2") then -- key 'B' pressed
						r_char <= C_KEYPAD_MATRIX(3)(1);
					elsif (i_columns = X"4") then -- key 'C' pressed
						r_char <= C_KEYPAD_MATRIX(3)(2);
					elsif (i_columns = X"8") then -- key 'D' pressed
						r_char <= C_KEYPAD_MATRIX(3)(3);
					else -- two buttons or more were pressed
						r_char <= 'U';
					end if; -- i_columns
					
					-- Update outputs --
					r_state <= s_row1;
					r_rows <= X"1";
					
				-- None button was pressed --
				when others => 
					r_rows <= X"1";
					r_state <= s_row1;
					r_char <= 'U';
					
			end case;
			
		end if; -- rising_edge(i_clk)
		
	end process p_scan_key;
	

	-- Update output ports --
	o_rows <= r_rows;
	o_keyPressed_Char <= r_char;
	o_keyPressed_Byte <= charToASCIIbyte(r_char);

end architecture rtl;
