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


entity lcd is
	generic (
		constant H_RES		: integer := 480;
		constant V_RES		: integer := 272
	);
    port (
    	reset_n		:	in std_logic;
		clk_lcd	:	in std_logic;
		hsync	:	out std_logic;
		vsync	:	out std_logic;
		de		:	out std_logic;	   
		frame_end 	: 	out std_logic;
		frame_start : 	out std_logic
	);
end lcd;

architecture Behavioral of lcd is

constant H_FRONT_P	: integer := 2;
constant H_BACK_P	: integer := 2;
constant H_PULSE_P	: integer := 41; 
constant V_FRONT_P	: integer := 2;
constant V_BACK_P	: integer := 2;
constant V_PULSE_P	: integer := 10; 

	
 
begin  	
	process (clk_lcd,reset_n) 
	variable h_count : integer range 0 to H_FRONT_P+H_PULSE_P+H_RES+H_BACK_P+1;
	variable v_count : integer range 0 to V_FRONT_P+V_PULSE_P+V_RES+V_BACK_P+1;
	begin
		if reset_n = '1' then
			if rising_edge(clk_lcd) then
				if (h_count = H_FRONT_P+H_PULSE_P+H_RES+H_BACK_P -1) then 
					h_count := 0;
					v_count := v_count + 1;
				else
					h_count := h_count +1;
					
				end if;
				
				if (v_count = V_FRONT_P+V_PULSE_P+V_RES+V_BACK_P ) then
					v_count := 0;
				end if;
				
				if h_count < H_PULSE_P then
					hsync <= '0';
				else
					hsync <= '1';
				end if;
				
				if v_count < V_PULSE_P then 
					vsync <= '0';
				else
					vsync <= '1';
				end if;
				
				if ((h_count >= H_FRONT_P+H_PULSE_P ) and (h_count < H_FRONT_P+H_PULSE_P+H_RES) and (v_count >= V_FRONT_P+V_PULSE_P) and (v_count <= V_FRONT_P+V_PULSE_P+V_RES-1)) then
					de <= '1';  
				else
					de <= '0';
				end if;
						   
				if (v_count = V_FRONT_P+V_PULSE_P+V_RES) then  
					frame_end <= '1';  
				else
					frame_end <= '0';  
				end if;	    
				
				if (h_count = H_PULSE_P )	 then
					frame_start <= '1';						
				end if;	
				
				if (v_count > V_FRONT_P+V_PULSE_P+V_RES) or (v_count < V_FRONT_P+V_PULSE_P) then
					frame_start <= '0';
				end if;				
			end if;	   
		else	 	--reset
			h_count	:= 0;
			v_count	:= 0;
			vsync <= '0';
			hsync <= '0';
			de  <= '0';	  
			frame_start <= '0';	
			frame_end <= '0';
		end if;	
	end process;

end Behavioral;
	