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
library MACHXO2;
use MACHXO2.components.all;

entity buffer_writer is	 
	generic (
		constant H_RES		: integer := 480;
		constant V_RES		: integer := 272
);
port (		
	clk		:	in	std_logic;
	reset_n	:	in	std_logic;
	x_pos	:	out integer range 0 to H_RES;  
	y_pos	:	out integer range 0 to V_RES;
	w_data	:	out	std_logic_vector (15 downto 0);
	last_pixel	:	out std_logic; 
	enable_lcd	:	out std_logic;
	ready	:	in std_logic
);
end buffer_writer;

architecture Behavioral_buffer_writer of buffer_writer is	 

constant BALL_SIZE : integer := 10;
constant BALL_STEP : integer := 1;

signal x_var			: 	integer range 0 to H_RES := 0;
signal y_var			: 	integer range 0 to V_RES := 0;
signal last_pixel_r		:	std_logic := '0'; 
signal ball_x 			: integer range 0 to H_RES := 0;	
signal ball_y 			: integer range 0 to V_RES := 0;
signal ball_x_dir, ball_y_dir : std_logic := '0';
begin
	process(clk) 
	begin
		if rising_edge(clk) then
			if reset_n = '0' then
				last_pixel_r <= '0';
				x_var <= 0;
				y_var <= 0;	
				enable_lcd <= '0';
			else
				if ready = '1' then
					if x_var < H_RES then
						x_var <= x_var + 1;
						last_pixel_r <= '0';
					else
						x_var <= 0;
						if y_var < V_RES then
							y_var <= y_var + 1;
						else
							y_var <= 0;	
							last_pixel_r <= '1';
							enable_lcd <= '1';
						end if;
					end if;	 
				else
					last_pixel_r <= '0';
				end if;
			end if;
		end if;
	end process;   
	
	
	process(clk) 
	begin
		if rising_edge(clk) then  
			if reset_n = '0' then
				ball_x <= 50;
				ball_y <= 50;
				ball_x_dir <= '0';
				ball_y_dir <= '0';
			elsif last_pixel_r = '1' then
					if ball_x_dir = '0' then
						ball_x <= ball_x + BALL_STEP;
					else
						ball_x <= ball_x - BALL_STEP;
					end if;
					if ball_y_dir = '0' then
						ball_y <= ball_y + BALL_STEP;
					else
						ball_y <= ball_y - BALL_STEP;
					end if;
					if ball_x > H_RES - BALL_SIZE then
						ball_x_dir <= '1';
					end if;			
					if ball_x < 3 then
						ball_x_dir <= '0';
					end if;
					if ball_y > V_RES - BALL_SIZE then
						ball_y_dir <= '1';
					end if;
					if ball_y < 3 then
						ball_y_dir <= '0';
					end if;	
			end if;
		end if;
	end process; 
	
	x_pos <= x_var;
	y_pos <= y_var;	 
	w_data <= (others => '0') when ((x_var >= ball_x) and (x_var <= ball_x + BALL_SIZE) and (y_var >= ball_y) and (y_var <= ball_y + BALL_SIZE)) else  std_logic_vector(to_unsigned(y_var, 9)(8 downto 2)) & std_logic_vector(to_unsigned(x_var, 9));	
	last_pixel <= last_pixel_r;
end Behavioral_buffer_writer;