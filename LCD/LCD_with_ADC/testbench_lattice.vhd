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

entity testbench is
   
end testbench;

architecture Behavioral of testbench is

		
component lattice_wrapper
	generic (
		constant X_RESOLUTION		: integer := 480;
		constant Y_RESOLUTION		: integer := 272  
		);		
		
	port (    	
--ADC Hardware Interface
   clk_X    : out std_logic;
   din_X    : in std_logic;     
   cs_n_X    : out std_logic;
   
   clk_Y    : out std_logic;
   din_Y    : in std_logic;
   cs_n_Y    : out std_logic;

   clk_Z    : out std_logic;
   din_Z    : in std_logic;
   cs_n_Z    : out std_logic;      
   
   pen_io    : in std_logic;

-- LCD Hardware Interface
   red_io         : out std_logic_vector(7 downto 0);
   green_io    : out std_logic_vector(7 downto 0);
   blue_io     : out std_logic_vector(7 downto 0);
   disp_io        :    out std_logic;
   hsync_io    :    out std_logic;
   vsync_io    :    out std_logic;
   de_io        :    out std_logic;
   clk_io        :    out std_logic;
   
-- SDRAM Hardware Interface
   sdr_DQ                :inout std_logic_vector( 15 downto 0);
   sdr_A                :out std_logic_vector(12 downto 0);
   sdr_BA                :out std_logic_vector(1 downto 0);
   sdr_CKE                :out std_logic;
   sdr_CSn                :out std_logic;
   sdr_RASn            :out std_logic;
   sdr_CASn            :out std_logic;
   sdr_WEn                :out std_logic;
   sdr_UDQM             :out std_logic;
   sdr_LDQM             :out std_logic;
   sdr_CLK             :out std_logic  
		);
end component;

component mt48lc16m16a2
	port(
		Dq : inout  std_logic_vector (16-1 downto 0);
		Addr: in std_logic_vector(12 downto 0);
		Ba: in std_logic_vector(1 downto 0);
		Clk: in std_logic; 
		Cke: in std_logic; 
		Cs_n: in std_logic; 
		Ras_n: in std_logic; 
		Cas_n: in std_logic; 
		We_n: in std_logic; 
		Dqm: in std_logic_vector(1 downto 0)
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

constant X_RESOLUTION : integer := 480;
constant Y_RESOLUTION : integer := 272;
constant CLK_PERIOD : time := 550 ns;

signal	Fifo_D		:  std_logic_vector(15 downto 0) := (others => '0');  
signal	fifo_wr		:  std_logic := '0'; 
signal	fifo_rd		:  std_logic := '0'; 
signal	fifo_reset	:  std_logic := '0';
signal	fifo_Q		:  std_logic_vector(15 downto 0) := (others => '0'); 
signal	fifo_Empty	:  std_logic := '0'; 
signal	fifo_Afull	:  std_logic := '0'; 
signal	fifo_Aempty	:  std_logic := '0'; 
signal	fifo_Full	:  std_logic := '0';

signal	clk_X		:  std_logic :='0';
signal	din_X		: std_logic :='0';	 
signal	cs_n_X		:  std_logic;
	
signal	clk_Y		:  std_logic :='0';
signal	din_Y		: std_logic :='0';
signal	cs_n_Y		:  std_logic;

signal	clk_Z		:  std_logic :='0';
signal	din_Z		: std_logic :='0';
signal	cs_n_Z		:  std_logic;	  
	
signal	pen_io		: std_logic :='0';

-- LCD Hardware Interface
signal	red_io 		: std_logic_vector(7 downto 0);
signal	green_io	: std_logic_vector(7 downto 0);
signal	blue_io 	: std_logic_vector(7 downto 0);
signal	disp_io		: std_logic :='0';
signal	hsync_io	: std_logic :='0';
signal	vsync_io	: std_logic :='0';
signal	de_io		: std_logic :='0';
signal	clk_io		: std_logic :='0';
	
-- SDRAM Hardware Interface
signal	sdr_DQ		: std_logic_vector( 15 downto 0);
signal	sdr_A		: std_logic_vector(12 downto 0);
signal	sdr_BA		: std_logic_vector(1 downto 0);
signal	sdr_CKE		: std_logic :='0';
signal	sdr_CSn		: std_logic :='0';
signal	sdr_RASn	: std_logic :='0';
signal	sdr_CASn	: std_logic :='0';
signal	sdr_WEn		: std_logic :='0';
signal	sdr_Dqm 	: std_logic_vector (1 downto 0);
signal	sdr_CLK 	: std_logic :='0';

signal clk_acq 	: STD_LOGIC := '0';
signal data 			: signed(12 downto 0):= "1000000000000";

signal sample_signed_X, sample_signed_Y, sample_signed_Z: std_logic_vector(12 downto 0) := (others => '0'); 
signal new_sample : std_logic;

begin
lattice_wrapper_comp: lattice_wrapper
generic map(
		X_RESOLUTION	=>	X_RESOLUTION,
		Y_RESOLUTION	=>	Y_RESOLUTION
)
port map (
	clk_X		=>	clk_X,		
	din_X		=>	din_X,		
	cs_n_X		=>	cs_n_X,		
	            	        
	clk_Y		=>	clk_Y,	
	din_Y		=>	din_Y,	
	cs_n_Y		=>	cs_n_Y,	
	             	        
	clk_Z		=>	clk_Z,	
	din_Z		=>	din_Z,	
	cs_n_Z		=>	cs_n_Z,	
	            	        
	pen_io		=>	pen_io,	
	             	        
	red_io 		=>	red_io, 	
	green_io	=>	green_io,
	blue_io 	=>	blue_io ,
	disp_io		=>	disp_io	,
	hsync_io	=>	hsync_io,
	vsync_io	=>	vsync_io,
	de_io		=>	de_io,	
	clk_io		=>	clk_io,	
							
					        
	sdr_DQ		=>	sdr_DQ,	
	sdr_A		=>	sdr_A,	
	sdr_BA		=>	sdr_BA,	
	sdr_CKE		=>	sdr_CKE,	
	sdr_CSn		=>	sdr_CSn	,
	sdr_RASn	=>	sdr_RASn,
	sdr_CASn	=>	sdr_CASn,
	sdr_WEn		=>	sdr_WEn	,
	sdr_UDQM	=> 	sdr_Dqm(1),
	sdr_LDQM 	=>	sdr_Dqm(0),
	sdr_CLK 	=>	sdr_CLK 
);
	
sdr_module_c:mt48lc16m16a2
port map(
	Dq => sdr_DQ,
    Addr => sdr_A,
    Ba => sdr_BA,
    Clk => sdr_CLK,
    Cke => sdr_CKE,
    Cs_n => sdr_CSn,
    Ras_n => sdr_RASn,
    Cas_n => sdr_CASn,
    We_n => sdr_WEn,
    Dqm => sdr_Dqm
);	


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




process	 (clk_X)
begin
	if rising_edge(clk_X) then  
		if cs_n_X = '1' then
			data <= data + 10; 
		end if;
	end if;
end process;

end Behavioral;