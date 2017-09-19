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
--
-------------------------------------------------------------------------------
--
-- Description : 
--
-------------------------------------------------------------------------------s


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity mcp3301_sim is
	 port(
		 clk_IC : in STD_LOGIC;
		 cs_n_IC : in STD_LOGIC;
		 dout_IC : out std_logic;
		 din_IC : in std_logic_vector(12 downto 0)
	     );
end mcp3301_sim;


architecture Behav of mcp3301_sim is 
signal sample_IC : std_logic_vector(12 downto 0) := (others => '0');
begin

	process (clk_IC, cs_n_IC)
		variable clk_num_IC : integer range 0 to 28;
	begin
		if cs_n_IC = '1' then
			dout_IC <= 'Z';
			clk_num_IC := 0;  
		else
			if falling_edge(clk_IC) then
				if clk_num_IC <= 27 then
					if clk_num_IC  <= 1 then
						dout_IC <= 'Z';
						sample_IC <= din_IC; -- the acquisition happens here. Register the input
					else		
						--if clk_num_IC = 2 then
						--	dout_IC <= sample_IC(12);  
						--else
							if clk_num_IC < 15 then   --outputting MSB first
								dout_IC <= sample_IC(14 - clk_num_IC);
							else
								dout_IC <= sample_IC( clk_num_IC - 14);
							end if;
						--end if;
					end if;
					clk_num_IC := clk_num_IC + 1;
				else
					dout_IC <= '0';
				end if;
			end if;
		end if;
	end process;

end Behav;
