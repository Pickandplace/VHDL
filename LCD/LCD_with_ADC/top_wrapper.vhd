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
use IEEE.STD_LOGIC_1164.all;


entity top_wrapper is
	 port(
   
    --ADC Hardware Interface
		clk_X	: out std_logic;
		din_X	: in std_logic;	 
		cs_n_X	: out std_logic;
		
		clk_Y	: out std_logic;
		din_Y	: in std_logic;
		cs_n_Y	: out std_logic;

		clk_Z	: out std_logic;
		din_Z	: in std_logic;
		cs_n_Z	: out std_logic;	  
		
		pen_io	: in std_logic
    
    -- LCD Hardware Interface
		red_io 		: out std_logic_vector(7 downto 0);
		green_io	: out std_logic_vector(7 downto 0);
		blue_io 	: out std_logic_vector(7 downto 0);
		disp_io		:	out std_logic;
		hsync_io	:	out std_logic;
		vsync_io	:	out std_logic;
		de_io		:	out std_logic;
		clk_io		:	out std_logic;
		
    -- SDRAM Hardware Interface
		sdr_DQ				:inout std_logic_vector( 15 downto 0);
		sdr_A				:out std_logic_vector(12 downto 0);
		sdr_BA				:out std_logic_vector(1 downto 0);
		sdr_CKE				:out std_logic;
		sdr_CSn				:out std_logic;
		sdr_RASn			:out std_logic;
		sdr_CASn			:out std_logic;
		sdr_WEn				:out std_logic;
		sdr_UDQM 			:out std_logic;
		sdr_LDQM 			:out std_logic;
		sdr_CLK 			:out std_logic		
		);
end top_wrapper ;



architecture top_wrapper_beh of top_wrapper is 


begin



end top_wrapper_beh;