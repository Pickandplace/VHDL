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

entity mcp3301_acq is  
	port(
		clk_acq	: in std_logic;
		reset_n : in std_logic;	
		sample_X: out std_logic_vector(12 downto 0); 
		sample_signed_X: out std_logic_vector(12 downto 0);
		sample_Y: out std_logic_vector(12 downto 0);
		sample_signed_Y: out std_logic_vector(12 downto 0); 
		sample_Z: out std_logic_vector(12 downto 0);
		sample_signed_Z: out std_logic_vector(12 downto 0); 
		
		new_sample : out std_logic;
		
		pen		: out std_logic;
		
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
	);
end mcp3301_acq;



architecture mcp3301_acq_arch of mcp3301_acq is	
signal acq_start_X		: std_logic := '0';
signal acq_start_Y		: std_logic := '0';	
signal acq_start_z		: std_logic := '0';
signal acq_end_X		: std_logic := '0';
signal acq_end_Y		: std_logic := '0';
signal acq_end_z		: std_logic := '0';

component mcp3301
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
end component;
begin

	mcp3301_X: mcp3301
	port map(
		clk				=> 	clk_acq,			
		reset_n			=> 	reset_n,	
		acq_start 		=>	acq_start_X,	
		acq_finished	=> 	acq_end_X,
		cs_n			=>	cs_n_X,			
		din				=> 	din_X,		
		sample			=> 	sample_X,
		sample_signed	=> 	sample_signed_X
	);
	
	mcp3301_Y: mcp3301
	port map(
		clk				=> 	clk_acq,			
		reset_n			=> 	reset_n,	
		acq_start 		=>	acq_start_Y,	
		acq_finished	=> 	acq_end_Y,
		cs_n			=>	cs_n_Y,			
		din				=> 	din_Y,		
		sample			=> 	sample_Y,
		sample_signed	=> 	sample_signed_Y	
	);			   
	
	mcp3301_z: mcp3301
	port map(
		clk				=> 	clk_acq,			
		reset_n			=> 	reset_n,	
		acq_start 		=>	acq_start_z,	
		acq_finished	=> 	acq_end_z,
		cs_n			=>	cs_n_z,			
		din				=> 	din_z,		
		sample			=> 	sample_z,
		sample_signed	=> 	sample_signed_z	
	);			   
	

	clk_X <= clk_acq; 
	clk_Y <= clk_acq; 
	clk_z <= clk_acq;
   
	process (clk_acq) is
	begin
		if rising_edge(clk_acq) then
			if reset_n = '0' then 
				acq_start_X <= '0';
				acq_start_Y <= '0';	
				acq_start_z <= '0';
			else
				acq_start_X <= '1';
				acq_start_Y <= '1';
				acq_start_z <= '1';
			end if;
		end if;
	end process;
	
	new_sample <= acq_end_X or acq_end_Y or acq_end_z;   
	pen <= not pen_io;
end mcp3301_acq_arch;


