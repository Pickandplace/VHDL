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


entity buffer_writer is	 
	generic (
		constant H_RES		: integer := 480;
		constant V_RES		: integer := 272;
		constant RES_VEC	: integer := 9
);
port (		
	clk			:	in	std_logic;
	reset_n		:	in	std_logic;
	x_pos		:	out integer range 0 to H_RES;  
	y_pos		:	out integer range 0 to V_RES;
	w_data		:	out	std_logic_vector (15 downto 0);
	last_pixel	:	out std_logic; 
	enable_lcd	:	out std_logic;
	ready		:	in std_logic
);
end buffer_writer;

architecture Behavioral_buffer_writer of buffer_writer is	 

component buffer_interface
	generic (
		constant H_RES		: integer := 480;
		constant V_RES		: integer := 272;
		constant RES_VEC		: integer := 9
	);
	port(
	clk			:	in	std_logic;
	reset_n		:	in	std_logic;
	x_vector	:	out integer range 0 to H_RES; 
	y_vector	:	out integer range 0 to V_RES; 
	d_vector	:	out std_logic_vector(24 downto 0);
	data_valid	:	out std_logic;
	ready_for_data: in std_logic;
	frame_end	:	out std_logic
	);
end component;

signal w_data_24 : std_logic_vector(23 downto 0) := (others =>'0');
signal data_valid : std_logic := '0';
begin

data0:buffer_interface	
generic map(
	H_RES 	=> H_RES,
	V_RES 	=> V_RES,
	RES_VEC => RES_VEC
)
port map(
		clk			=>	clk,
		reset_n		=>	reset_n,
		x_vector 	=> 	x_pos,
		y_vector	=>	y_pos,
		d_vector	=>	w_data_24,
		data_valid	=>	data_valid,
		ready_for_data => ready,
		frame_end => last_pixel
);


	process(clk) 
	begin
		if rising_edge(clk) then
			if reset_n = '0' then
				enable_lcd <= '0';
				elsif data_valid = '1' then
					enable_lcd <= '1';
			end if;
		end if;
	end process;   
	
	w_data <= w_data_24(15 downto 0);
	
	
end Behavioral_buffer_writer;