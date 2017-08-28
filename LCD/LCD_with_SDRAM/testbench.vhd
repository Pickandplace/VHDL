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
library MACHXO2;
use MACHXO2.components.all;

entity testbench is
   
end testbench;

architecture Behavioral of testbench is
constant clk_133_period : time := 7.5187 ns;

signal	clk_100		:	std_logic := '0';
signal	reset_n		:	std_logic := '0';	
signal	we_m		:	std_logic := '0';	

signal	s_Dq 		:   std_logic_vector (16-1 downto 0) := (others => '0');
signal  s_Addr		:  std_logic_vector(12 downto 0) := (others => '0');
signal  s_Ba		:  std_logic_vector(1 downto 0) := (others => '0');
signal  s_Cke		: std_logic := '0'; 
signal  s_Cs_n		: std_logic := '0'; 
signal  s_Ras_n		: std_logic := '0'; 
signal  s_Cas_n		: std_logic := '0'; 
signal  s_We_n		: std_logic := '0'; 
signal  s_Dqm		: std_logic_vector(1 downto 0) := (others => '0');	

signal  red_io 		: std_logic_vector(7 downto 0) := (others => '0');
signal  green_io	: std_logic_vector(7 downto 0) := (others => '0');
signal  blue_io 	: std_logic_vector(7 downto 0) := (others => '0');
signal  disp_io		: std_logic := '0';
signal  hsync_io	: std_logic := '0';
signal  vsync_io	: std_logic := '0';
signal  de_io		: std_logic := '0';
signal  clk_io		: std_logic := '0';
signal  pll_locked_o: std_logic := '0';
signal  int_osc_clk	: std_logic := '0';
		
component top
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

begin
top_comp: top
port map (
	sdr_DQ 		=> s_Dq,
	sdr_A 		=> s_Addr,
	sdr_BA 		=> s_Ba,
	sdr_CKE 	=> s_Cke,
	sdr_Csn 	=> s_Cs_n,
	sdr_RASn 	=> s_Ras_n,
	sdr_CASn 	=> s_Cas_n, 
	sdr_WEn 	=> s_We_n,
	sdr_UDQM 	=> s_Dqm(1),
	sdr_LDQM	=> s_Dqm(0),
	sdr_CLK		=> clk_100
);
	
sdr_module_c:mt48lc16m16a2
port map(
	Dq => s_Dq,
    Addr => s_Addr,
    Ba => s_Ba,
    Clk => clk_100,
    Cke => s_Cke,
    Cs_n => s_Cs_n,
    Ras_n => s_Ras_n,
    Cas_n => s_Cas_n,
    We_n => s_We_n,
    Dqm => s_Dqm
);	

end Behavioral;