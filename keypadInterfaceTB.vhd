-----------------------------------------------------------------------------
----------------  This RTL Code written by Matan Leizerovich  ---------------
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-------			        Keypad Interface TestBench			   	      -------
-----------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity keypadInterfaceTB is
end entity keypadInterfaceTB;


architecture sim of keypadInterfaceTB is
	-- Constants --
	constant c_CLK_PERIOD : time := 20 ns; -- 50 MHz main clock
	constant c_DELAY : time := 100 us; -- 10KHz
	constant c_SCAN_FREQUENCY : natural := 40000; -- Desired test frequency - 40KHz
	
	-- Signals --
	
	-- Stimulus signals --
	signal i_clk       : std_logic;
	signal i_reset     : std_logic;
	signal o_rows      : std_logic_vector(3 downto 0);
	signal i_columns   : std_logic_vector(3 downto 0);
	
	-- Observed signal --
	signal o_keyPressed_Char : character;
	signal o_keyPressed_Byte : std_logic_vector(7 downto 0);

begin

	-- Unit Under Test port map --
	UUT : entity work.keypadInterface(rtl)
	generic map(g_SCAN_FREQUENCY => c_SCAN_FREQUENCY)
	port map (
			i_clk  			   => i_clk ,
			i_reset  		   => i_reset ,
			i_columns 			=> i_columns ,
			o_rows			   => o_rows ,
			o_keyPressed_Char	=> o_keyPressed_Char ,
			o_keyPressed_Byte => o_keyPressed_Byte
			   );
	
	
	-- Testbench process --
	p_TB : process
	begin
		-- Initial Setup --
		i_reset <= '0';
		i_columns <= "0000";
		wait for c_DELAY;
		
		-- Test --
		i_reset <= '1';

		i_columns <= "0001";
		wait for c_DELAY;
		i_columns <= "0010";
		wait for c_DELAY;
		i_columns <= "0000";
		wait for c_DELAY;
		i_columns <= "0100";
		wait for c_DELAY;
		i_columns <= "1000";
		wait for c_DELAY;
		i_columns <= "0000";
		wait for c_DELAY;

		
		assert false report "The tests are complete!" severity failure;
		
		
	wait;
	end process p_TB;
	
	
	-- 50 MHz clock in duty cycle of 50% - 20 ns -- 
	p_clock : process 
	begin 
		i_clk <= '0'; wait for c_CLK_PERIOD/2; -- 10 ns
		i_clk <= '1'; wait for c_CLK_PERIOD/2; -- 10 ns
	end process p_clock;

end architecture sim;