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
entity mcp3301_testbench is

end mcp3301_testbench;


architecture arch of mcp3301_testbench is 
component mcp3301_acq 
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
end component;

component mcp3301_sim is
	 port(
		 clk_IC 	: in STD_LOGIC;
		 cs_n_IC 	: in STD_LOGIC;
		 dout_IC 	: out std_logic;
		 din_IC 	: in std_logic_vector(12 downto 0)
	     );
end component; 

constant CLK_PERIOD : time := 550 ns;
signal clk_acq 	: STD_LOGIC := '0';
signal cs_n : STD_LOGIC := '1';
signal dout 			: std_logic := '0';	
signal reset_n 			: std_logic := '0';
signal din, sample_X, sample_Y, sample_Z 	: std_logic_vector(12 downto 0) := (others => '0');
signal acq_finished 	: std_logic := '0';
signal acq_start 		: std_logic := '0'; 
signal data 			: signed(12 downto 0):= "1000000000000";
signal clk_X, clk_Y, clk_Z		: std_logic := '0'; 
signal din_X, din_Y, din_Z		: std_logic := '0'; 
signal cs_n_X, cs_n_Y, cs_n_Z	: std_logic := '0'; 
signal sample_signed_X, sample_signed_Y, sample_signed_Z: std_logic_vector(12 downto 0) := (others => '0'); 
signal new_sample : std_logic;
signal pen, pen_io : std_logic;
begin

mcp3301_IC_x: mcp3301_sim 
port map(
	clk_IC 		=> clk_X,
	cs_n_IC 	=> cs_n_X,
	dout_IC 	=> din_X,
	din_IC 		=> std_logic_vector(data)
);
mcp3301_IC_y: mcp3301_sim 
port map(
	clk_IC 		=> clk_Y,
	cs_n_IC 	=> cs_n_Y,
	dout_IC 	=> din_Y,
	din_IC 		=> std_logic_vector(data)
);	   
mcp3301_IC_z: mcp3301_sim 
port map(
	clk_IC 		=> clk_z,
	cs_n_IC 	=> cs_n_z,
	dout_IC 	=> din_z,
	din_IC 		=> std_logic_vector(data)
);
mcp3301_access: mcp3301_acq
port map(
	clk_acq => clk_acq,
	reset_n => reset_n,	 
	sample_X=> sample_X,
	sample_Y=> sample_Y,  	
	sample_z=> sample_z,  
	sample_signed_X=> sample_signed_X,
	sample_signed_Y=> sample_signed_Y, 	  
	sample_signed_z=> sample_signed_z, 
	new_sample => new_sample,
	
	pen 	=>	pen,
	clk_X	=>	clk_X,
	din_X	=>	din_X,
	cs_n_X	=>	cs_n_X,	
	        
	clk_Y	=>	clk_Y,	
	din_Y	=>	din_Y,
	cs_n_Y	=>	cs_n_Y,	

	clk_z	=>	clk_z,	
	din_z	=>	din_z,
	cs_n_z	=>	cs_n_z,
	
	pen_io 	=> pen_io
);	 
process 
begin
	reset_n <= '0';
	wait for CLK_PERIOD*4;
	reset_n <= '1';
	wait;
end process; 

process 
begin
	clk_acq <= '0';
	wait for CLK_PERIOD/2;
	clk_acq <= '1';
	wait for CLK_PERIOD/2;
end process;

process	 (clk_acq)
begin
	if rising_edge(clk_acq) then  
		if new_sample = '1' then
			data <= data + 10; 
		end if;
	end if;
end process;


end arch;
