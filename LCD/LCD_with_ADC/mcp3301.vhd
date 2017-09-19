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
-------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity mcp3301 is
	 port(
		 clk 			: in std_logic;
		 reset_n 		: in std_logic;
		 acq_start 		: in std_logic;
		 acq_finished 	: out std_logic; 
		 cs_n			: out std_logic; 
		 din 			: in std_logic;
		 sample 		: out std_logic_vector(12 downto 0);
		 sample_signed	: out std_logic_vector(12 downto 0)
	     );
end mcp3301 ;



architecture Behav of mcp3301 is 

signal acq_started	:	std_logic := '0'; 
signal sample_i		:  	std_logic_vector(12 downto 0) := (others => '0'); 
signal sample_t		:  	std_logic_vector(12 downto 0) := (others => '0'); 

begin

	process (clk) 
	variable clock_cnt	:	integer range 0 to 16 := 0;
	begin
		if rising_edge(clk) then
			if reset_n = '0' then
				sample_i <= (others => '0');   
				sample_signed <= (others => '0');
				cs_n <= '1';
				acq_finished <= '0';
				clock_cnt := 0;
				acq_started <= '0';
			else
				if acq_start = '1' then
					acq_started <= '1';
					cs_n <= '0';
				end if;
				
				if acq_started = '1' then
					if clock_cnt < 15 then
						clock_cnt := clock_cnt + 1;
						if clock_cnt > 2  then 
							sample_i(15-clock_cnt) <= din;
						end if;		 
					else
						clock_cnt := 0;
						acq_finished <= '1';					  
						sample_signed <= sample_i;	
						sample_t <= sample_i;
						cs_n <= '1';
						acq_started <= '0';
					end if;
				else
					acq_finished <= '0';
					--cs_n <= '1';
					clock_cnt := 0;
					sample_i <= (others => '0');  
					--sample <= (others => '0');
				end if;
			end if;
		end if;
	end process;  

	sample <= '1' & sample_t(11 downto 0) when sample_t(12) = '0' else '0' & sample_t(11 downto 0);
end Behav;
