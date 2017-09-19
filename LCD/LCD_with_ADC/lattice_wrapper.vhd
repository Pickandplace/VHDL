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
library MACHXO2;
use MACHXO2.components.all;

entity lattice_wrapper is
	generic (
	constant X_RESOLUTION		: integer := 480;
	constant Y_RESOLUTION		: integer := 272;
	constant RES_VEC			: integer := 9  
);
	 port(

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
end lattice_wrapper ;



architecture lattice_wrapper_beh of lattice_wrapper is 

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
		CLKOS2	: 	out  	std_logic;
		ENCLKOP	: 	in  	std_logic; 
		ENCLKOS	: 	in  	std_logic;
		ENCLKOS2: 	in  	std_logic;
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
		AlmostFull: out  std_logic
		);
end component; 


component  frame_buffer 
	generic (
	constant X_RESOLUTION		: integer := 480;
	constant Y_RESOLUTION		: integer := 272  
);
    port (    	
	clk_lcd		:	in std_logic;
	clk_sdr		:	in std_logic;
	en_clk_lcd	:	out  std_logic;
	reset_n		:	in std_logic;

	x_pos		:	in integer range 0 to X_RESOLUTION-1;  
	y_pos		:	in integer range 0 to Y_RESOLUTION-1;
	w_data		:	in	std_logic_vector (15 downto 0);
	data_valid	:	in std_logic;
	last_pixel	:	in std_logic; 
	enable_lcd	: 	in std_logic;
	ready		:	out std_logic;
		
	red 		: 	out std_logic_vector(7 downto 0);
	green		: 	out std_logic_vector(7 downto 0);
	blue	 	: 	out std_logic_vector(7 downto 0);
	disp		:	out std_logic;
	hsync		:	out std_logic;
	vsync		:	out std_logic;
	de			:	out std_logic;
	
	Dq 			:	inout std_logic_vector(15 downto 0);
	Addr		:	out std_logic_vector(12 downto 0);
	Ba			:	out std_logic_vector(1 downto 0);
	Cke			:	out std_logic;
	Cs_n		:	out std_logic;
	Ras_n		:	out std_logic;
	Cas_n		:	out std_logic;
	We_n		:	out std_logic;
	Dqm			:	out std_logic_vector(1 downto 0);
	
	Fifo_D		: out  std_logic_vector(15 downto 0);  
	fifo_wr		: out  std_logic; 
	fifo_rd		: out  std_logic; 
	fifo_reset	: out  std_logic; 
	fifo_Q		: in  std_logic_vector(15 downto 0); 
	fifo_Empty	: in  std_logic; 
	fifo_Afull	: in  std_logic; 
	fifo_Aempty	: in  std_logic; 
	fifo_Full	: in  std_logic
	);
end component;

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

component acq_interface 
port(
		clk_acq				: in std_logic;
		reset_n 			: in std_logic;	
		
		sample_X_acq		: in std_logic_vector(12 downto 0); 
		sample_signed_X_acq	: in std_logic_vector(12 downto 0);
		sample_Y_acq		: in std_logic_vector(12 downto 0);
		sample_signed_Y_acq	: in std_logic_vector(12 downto 0); 
		sample_Z_acq		: in std_logic_vector(12 downto 0);
		sample_signed_Z_acq	: in std_logic_vector(12 downto 0); 
		new_sample_acq 		: in std_logic;
		pen_acq				: in std_logic;
		
		sample_X		: out std_logic_vector(12 downto 0); 
		sample_signed_X	: out std_logic_vector(12 downto 0);
		sample_Y		: out std_logic_vector(12 downto 0);
		sample_signed_Y	: out std_logic_vector(12 downto 0); 
		sample_Z		: out std_logic_vector(12 downto 0);
		sample_signed_Z	: out std_logic_vector(12 downto 0); 
		new_sample 		: out std_logic;
		pen				: out std_logic
);
end component ;

component buffer_interface 
	generic (
		constant H_RES		: integer := 480;
		constant V_RES		: integer := 272;
		constant RES_VEC		: integer := 9
	);
	port(
	clk_acq			:	in std_logic;
	clk_sdr			:	in std_logic;
	reset_n			:	in std_logic;
	
	--signals from the acquisition interface
	sample_X		: 	in std_logic_vector(12 downto 0); 
    sample_signed_X	: 	in std_logic_vector(12 downto 0);
    sample_Y		: 	in std_logic_vector(12 downto 0);
    sample_signed_Y	: 	in std_logic_vector(12 downto 0); 
    sample_Z		: 	in std_logic_vector(12 downto 0);
    sample_signed_Z	: 	in std_logic_vector(12 downto 0); 
	new_sample     	: 	in std_logic;
    pen        		: 	in std_logic;
	
	--Signals to the frame buffer writer
	x_vector		:	out integer range 0 to H_RES; 
	y_vector		:	out integer range 0 to V_RES; 
	d_vector		:	out std_logic_vector(15 downto 0);
	data_valid		:	out std_logic;
	ready_for_data	: 	in std_logic;
	frame_end		:	out std_logic; --last pixel of the frame to write to the frame buffer 
	enable_lcd		:	out std_logic
	);
end component ;

signal	Fifo_D		:  std_logic_vector(15 downto 0) := (others => '0');  
signal	fifo_wr		:  std_logic := '0'; 
signal	fifo_rd		:  std_logic := '0'; 
signal	fifo_reset	:  std_logic := '0';
signal	fifo_Q		:  std_logic_vector(15 downto 0) := (others => '0'); 
signal	fifo_Empty	:  std_logic := '0'; 
signal	fifo_Afull	:  std_logic := '0'; 
signal	fifo_Aempty	:  std_logic := '0'; 
signal	fifo_Full	:  std_logic := '0';
	
signal 	osc_int		:	std_logic := '0';
signal 	pll_locked	:	std_logic := '0';
signal 	clk_lcd		:	std_logic := '0';
signal 	clk_sdr		:	std_logic := '0';
signal 	en_clk_lcd	:	std_logic := '0';
signal 	reset_n		:	std_logic := '0';

signal 	en_clk_S	:	std_logic := '0'; 
signal 	en_clk_S2	:	std_logic := '0';
signal 	Dqm_int		: 	std_logic_vector(1 downto 0) := (others => '0');	


signal sample_X_i			:  std_logic_vector(12 downto 0) := (others => '0'); 
signal sample_signed_X_i	:  std_logic_vector(12 downto 0) := (others => '0');
signal sample_Y_i			:  std_logic_vector(12 downto 0) := (others => '0');
signal sample_signed_Y_i	:  std_logic_vector(12 downto 0) := (others => '0');
signal sample_Z_i			:  std_logic_vector(12 downto 0) := (others => '0');
signal sample_signed_Z_i	:  std_logic_vector(12 downto 0) := (others => '0');
signal new_sample_i			:	std_logic := '0';
signal pen_i				:	std_logic := '0';

signal sample_X_o			:  std_logic_vector(12 downto 0) := (others => '0'); 
signal sample_signed_X_o	:  std_logic_vector(12 downto 0) := (others => '0');
signal sample_Y_o			:  std_logic_vector(12 downto 0) := (others => '0');
signal sample_signed_Y_o	:  std_logic_vector(12 downto 0) := (others => '0');
signal sample_Z_o			:  std_logic_vector(12 downto 0) := (others => '0');
signal sample_signed_Z_o	:  std_logic_vector(12 downto 0) := (others => '0');
signal new_sample_o			:	std_logic := '0';
signal pen_o				:	std_logic := '0';

signal x_vector_o			:	integer range 0 to X_RESOLUTION := 0; 
signal y_vector_o			:	integer range 0 to X_RESOLUTION := 0;
signal d_vector_o			:	std_logic_vector(15 downto 0) := (others => '0');
signal data_valid_o		:	std_logic := '0';
signal ready_for_data_o	: 	std_logic := '0';
signal frame_end_o		:	std_logic := '0';
signal enable_lcd_o		:	std_logic := '0';
signal clk_acq			:	std_logic := '0';
	
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
		CLKOS2	=>	clk_acq,
		ENCLKOS2	=>	en_clk_S2,
		LOCK	=>	pll_locked
	);

fifo_c: fifo_dc
    port map (
		Data	=>	Fifo_D, 
		WrClock	=>	clk_sdr, 
		RdClock	=>	clk_lcd, 
		WrEn	=>	fifo_wr, 
        RdEn	=>	fifo_rd, 
		Reset	=>	fifo_reset, 
		RPReset	=>	'0', 
		Q		=>	fifo_Q, 
		Empty	=>	fifo_Empty, 
        Full	=>	fifo_Afull, 
		AlmostEmpty	=>	fifo_Aempty, 
		AlmostFull	=>	fifo_Full
	);	
      
frame_buffer0: frame_buffer
generic map(
		X_RESOLUTION	=>	X_RESOLUTION,
		Y_RESOLUTION	=>	Y_RESOLUTION
)
port map(
	clk_lcd		=> 	clk_lcd,	
	clk_sdr		=> 	clk_sdr,	
	en_clk_lcd	=> 	en_clk_lcd,	
	reset_n		=> 	reset_n,	

	x_pos		=>  x_vector_o,
	y_pos		=>	y_vector_o,
	w_data		=> 	d_vector_o,
	data_valid	=>	data_valid_o,
	last_pixel	=> 	frame_end_o,
	enable_lcd	=>	enable_lcd_o,
	ready		=>	ready_for_data_o,
		                
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
	Dqm			=> 	Dqm_int,	
	
	Fifo_D		=> Fifo_D,
	fifo_wr		=> fifo_wr,
	fifo_rd		=> fifo_rd,
	fifo_reset	=> fifo_reset,
	fifo_Q		=> fifo_Q,
	fifo_Empty	=> fifo_Empty,	
	fifo_Afull	=> fifo_Afull,	
	fifo_Aempty	=> fifo_Aempty,	
	fifo_Full	=> fifo_Full	
	
);	

mcp3301_acquisition: mcp3301_acq
port map(
	clk_acq 		=> clk_acq,
	reset_n 		=> reset_n,	
	
	--sample outputs 
	sample_X		=> sample_X_i,
	sample_Y		=> sample_Y_i,  	
	sample_z		=> sample_z_i,  
	sample_signed_X	=> sample_signed_X_i,
	sample_signed_Y	=> sample_signed_Y_i, 	  
	sample_signed_z	=> sample_signed_z_i, 
	new_sample 		=> new_sample_i,
	pen 			=>	pen_i,
	
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

acq_interface_comp: acq_interface
port map(
		clk_acq				=> clk_acq,
		reset_n 			=> reset_n,	
		--sample inputs
		sample_X_acq		=> sample_X_i,
		sample_signed_X_acq	=> sample_signed_X_i,
		sample_Y_acq		=> sample_Y_i,
		sample_signed_Y_acq	=> sample_signed_Y_i,
		sample_Z_acq		=> sample_z_i,
		sample_signed_Z_acq	=> sample_signed_z_i,
		
		new_sample_acq 		=> new_sample_i,
		pen_acq				=> pen_i,
		
		--sample outputs
		sample_X		=> sample_X_o,
		sample_signed_X	=> sample_signed_X_o,
		sample_Y		=> sample_Y_o,
		sample_signed_Y	=> sample_signed_Y_o,
		sample_Z		=> sample_Z_o,
		sample_signed_Z	=> sample_signed_Z_o,
		
		new_sample 		=> new_sample_o,
		pen				=> pen_o
);

buffer_interface_comp: buffer_interface
generic map(
		H_RES	=>	X_RESOLUTION,
		V_RES	=>	Y_RESOLUTION,
		RES_VEC	=>	RES_VEC
)
port map(
		clk_acq				=> clk_acq,
		clk_sdr				=> clk_sdr,
		reset_n 			=> reset_n,	
		--sample inputs
		sample_X			=> sample_X_o,
		sample_signed_X		=> sample_signed_X_o,
		sample_Y			=> sample_Y_o,
		sample_signed_Y		=> sample_signed_Y_o,
		sample_Z			=> sample_z_o,
		sample_signed_Z		=> sample_signed_z_o,
		
		new_sample	 		=> new_sample_o,
		pen					=> pen_o,
		
		x_vector			=> 		x_vector_o,			
		y_vector			=> 	 	y_vector_o,			
		d_vector			=> 	 	d_vector_o,			
		data_valid			=>	 	data_valid_o,	 	
		ready_for_data		=>	 	ready_for_data_o,
		frame_end			=>	 	frame_end_o,
		enable_lcd			=>		enable_lcd_o		
		
);

	en_clk_S <= '1';
	en_clk_S2 <= '1';	
	
	reset_n <= pll_locked;
	sdr_UDQM <= Dqm_int(1);
	sdr_LDQM <= Dqm_int(0);

	sdr_CLK <= clk_sdr;
	clk_io <= clk_lcd;


end lattice_wrapper_beh;