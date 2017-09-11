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

entity top is
    port (
		red_io 		: out std_logic_vector(7 downto 0);
		green_io	: out std_logic_vector(7 downto 0);
		blue_io 	: out std_logic_vector(7 downto 0);
		disp_io		:	out std_logic;
		hsync_io	:	out std_logic;
		vsync_io	:	out std_logic;
		de_io		:	out std_logic;
		clk_io		:	out std_logic;
		
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
end top;

architecture Behavioral1 of top is



COMPONENT OSCH
   -- synthesis translate_off
	GENERIC  (NOM_FREQ: string := "133.00");
   -- synthesis translate_on
	PORT (
	STDBY	:	IN	std_logic;
	OSC		:	OUT	std_logic;
	SEDSTDBY	:	OUT	std_logic
	);
END COMPONENT;	

constant OSC_STR  : string  := "133.00";
 
attribute NOM_FREQ : string;
attribute NOM_FREQ of OSCinst0 : label is "133.00";

component pll_1
    port (
		CLKI	: 	in  	std_logic; 
		CLKOP	: 	out  	std_logic; 
		CLKOS	: 	out  	std_logic; 
		ENCLKOP	: 	in  	std_logic; 
		ENCLKOS	: 	in  	std_logic;
		LOCK	: 	out  	std_logic
	);
end component;

component fifo_dc
    port (
		Data: in  std_logic_vector(15 downto 0); 
		WrClock: in  std_logic; 
		RdClock: in  std_logic; 
		WrEn: in  std_logic; 
		RdEn: in  std_logic; 
		Reset: in  std_logic; 
		RPReset: in  std_logic; 
		Q: out  std_logic_vector(15 downto 0); 
		Empty: out  std_logic; 
		Full: out  std_logic; 
		AlmostEmpty: out  std_logic; 
		AlmostFull: out  std_logic);
end component;
component frame_buffer is
    port (    	
	clk_lcd		:	in std_logic;
	clk_sdr		:	in std_logic;
	en_clk_lcd	:	out  std_logic;
	reset_n		:	in std_logic;
	
	red 		: 	out std_logic_vector(7 downto 0);
	green		: 	out std_logic_vector(7 downto 0);
	blue	 	: 	out std_logic_vector(7 downto 0);
	disp		:	out std_logic;
	hsync		:	out std_logic;
	vsync		:	out std_logic;
	de			:	out std_logic;
	
	Dq 		:	inout std_logic_vector(15 downto 0);
	Addr	:	out std_logic_vector(12 downto 0);
	Ba		:	out std_logic_vector(1 downto 0);
	Cke		:	out std_logic;
	Cs_n	:	out std_logic;
	Ras_n	:	out std_logic;
	Cas_n	:	out std_logic;
	We_n	:	out std_logic;
	Dqm		:	out std_logic_vector(1 downto 0)
	);
end component;
signal 	osc_int		:	std_logic := '0';
signal 	pll_locked	:	std_logic := '0';
signal 	clk_lcd		:	std_logic := '0';
signal 	clk_sdr		:	std_logic := '0';
signal 	en_clk_lcd	:	std_logic := '0';
signal 	reset_n		:	std_logic := '0';

signal 	en_clk_S	:	std_logic := '0';
signal 	Dqm_int		: 	std_logic_vector(1 downto 0) := (others => '0');	
begin

OSCInst0: OSCH
   -- synthesis translate_off
         GENERIC MAP( NOM_FREQ  => OSC_STR )
   -- synthesis translate_on
	PORT MAP (
		STDBY		=> '0', --always run 
		OSC 		=> osc_int, 
		SEDSTDBY 	=> OPEN
);

pll_comp0:pll_1
	port map(
		CLKI	=>	osc_int, 
		CLKOP	=>	clk_lcd, 
		ENCLKOP	=>	en_clk_lcd,
		CLKOS	=>	clk_sdr, 
		ENCLKOS	=>	en_clk_S,
		LOCK	=>	pll_locked
	);


fb0: frame_buffer
port map(
	clk_lcd		=> 	clk_lcd,	
	clk_sdr		=> 	clk_sdr,	
	en_clk_lcd	=> 	en_clk_lcd,	
	reset_n		=> 	reset_n,	
	                
	red		 	=> 	red_io, 
	green		=> 	green_io, 
	blue		=> 	blue_io, 
	disp		=> 	disp_io, 
	hsync		=> 	hsync_io, 
	vsync		=> 	vsync_io, 
	de			=> 	de_io, 
	                
	Dq		 	=> 	sdr_DQ,	
	Addr		=> 	sdr_A,	
	Ba			=> 	sdr_BA, 
	Cke			=> 	sdr_CKE,	
	Cs_n		=> 	sdr_CSn,	
	Ras_n		=> 	sdr_RASn,	
	Cas_n		=> 	sdr_CASn,	
	We_n		=> 	sdr_WEn,	
	Dqm			=> 	Dqm_int	
);		


	en_clk_S <= '1';
	
	reset_n <= pll_locked;
	sdr_UDQM <= Dqm_int(1);
	sdr_LDQM <= Dqm_int(0);

	sdr_CLK <= clk_sdr;
	clk_io <= clk_lcd;
end Behavioral1;