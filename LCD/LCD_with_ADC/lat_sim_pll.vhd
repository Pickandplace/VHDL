--Copyright (C) 2017 Jean Wlodarski

--KaZjjW at gmailcom

--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU General Public License as published by
--the Free Software Foundation, either version 3 of the License, or
--(at your option) any later version.

--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU General Public License for more details.

--You should have received a copy of the GNU General Public License
--along with this program.  If not, see <http://www.gnu.org/licenses/>.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity pll_1 is
    port (
		CLKI	: 	in  	std_logic; 
		CLKOP	: 	out  	std_logic; 
		CLKOS	: 	out  	std_logic; 
		CLKOS2	: 	out  	std_logic;
		ENCLKOP	: 	in  	std_logic; 
		ENCLKOS	: 	in  	std_logic;
		ENCLKOS2: 	in  	std_logic;
		LOCK	: 	out  	std_logic
	);
end pll_1;

architecture Behavioral1 of pll_1 is
constant OP_PERIOD : time := 192.2 ns;
constant OS_PERIOD : time := 12.53 ns;
constant OS2_PERIOD : time := 626.566 ns;
signal os_clk, op_clk, os2_clk : std_logic := '0';

begin

process  
begin
	LOCK <= '0';
	wait for 10 ns;
	LOCK <= '1';
	wait;
end process;

process  
begin
	op_clk <= '0';
	wait for OP_PERIOD/2;
	op_clk <= '1';
	wait for OP_PERIOD/2;
end process;

process  
begin
	os_clk <= '0';
	wait for OS_PERIOD/2;
	os_clk <= '1';
	wait for OS_PERIOD/2;
end process;

process  
begin
	os2_clk <= '0';
	wait for OS2_PERIOD/2;
	os2_clk <= '1';
	wait for OS2_PERIOD/2;
end process;

CLKOP <= op_clk when ENCLKOP = '1' else '0';
CLKOS <= os_clk when ENCLKOS = '1' else '0';
CLKOS2 <= os2_clk when ENCLKOS2 = '1' else '0';
end Behavioral1;