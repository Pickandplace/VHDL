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

entity OSCH is
    port (
	STDBY	:	IN	std_logic;
    OSC		:	OUT	std_logic;
    SEDSTDBY	:	OUT	std_logic
		);
end OSCH;

architecture Behavioral2 of OSCH is
constant OSC_PERIOD : time := 7.5187 ns;
begin
process
begin
	OSC <= '0';
	wait for OSC_PERIOD/2;
	OSC <= '1';
	wait for OSC_PERIOD/2;
end process;

end Behavioral2;