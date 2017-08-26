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
		pll_locked_o	: out std_logic;
		int_osc_clk	:out std_logic;
		state_dbg 	: out	std_logic_vector(1 downto 0) 
		);
end top;

architecture Behavioral1 of top is
component lcd 
    port (
		clk_lcd		:	in std_logic;
		hsync		:	out std_logic;
		vsync		:	out std_logic;
		de			:	out std_logic;
		reset_n		:	in std_logic;
		pixel_vector	: 	out std_logic_vector(16 downto 0);
		h_pixel_vector	:	out	std_logic_vector(8 downto 0);
		v_pixel_vector	:	out	std_logic_vector(8 downto 0);
		frame_start	: 	out std_logic;
		frame_end 	: 	out std_logic
	);
end component;


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
constant X_RESOLUTION : integer := 480;
constant Y_RESOLUTION : integer := 272;	
constant Y_RESOLUTION_RAM : integer := 272;	

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
	
signal reset_n			:	std_logic := '0'; 
signal reset			:	std_logic := '0'; 
signal de 				:	std_logic := '0'; 
		
signal stdby, stdby_sed :  	std_logic := '0'; 
signal osc_int			:	std_logic := '0'; 
signal reset_finished	:	std_logic := '0'; 
signal ram_filled		:	std_logic := '0'; 
signal frame_start		:	std_logic := '0'; 
signal frame_end		:	std_logic := '0'; 
signal clk_100MHz		:	std_logic := '0'; 
signal clk_10MHz		:	std_logic := '0'; 
signal en_clk_10MHz		:	std_logic := '0'; 
signal pll_locked		:	std_logic := '0'; 	   

signal pixel_vector		: 	std_logic_vector(16 downto 0) := (others => '0');  
signal pixel_vector_old	: 	std_logic_vector(16 downto 0) := (others => '1'); 
type state_type is (s05_wait_for_lock, s0_reset, s2_copy_lcd);
signal state   : state_type := s05_wait_for_lock;


signal h_pixel_vector	:	std_logic_vector(8 downto 0) := (others => '0');
signal v_pixel_vector	:	std_logic_vector(8 downto 0) := (others => '0'); 


signal red_r 			:	std_logic_vector(7 downto 0) := (others => '0'); 
signal green_r			:	std_logic_vector(7 downto 0) := (others => '0'); 
signal blue_r 			:	std_logic_vector(7 downto 0) := (others => '0'); 
--signal state_dbg 		:	std_logic_vector(1 downto 0) := (others => '0'); 
signal frame_start_rising : std_logic := '0';
signal frame_end_rising : std_logic := '0';
signal frame_start_rising_r : std_logic := '0';
signal frame_end_rising_r : std_logic := '0';

signal fifo_d			:   std_logic_vector(15 downto 0) := (others => '0');  
signal fifo_wr			:   std_logic := '0'; 
signal fifo_rd			:   std_logic := '0'; 
signal fifo_Reset		:   std_logic := '0';
signal fifo_RPreset		:   std_logic := '0';
signal fifo_Q			:   std_logic_vector(15 downto 0) := (others => '0'); 
signal fifo_Empty		:   std_logic := '0';
signal fifo_Full		:   std_logic := '0';
signal fifo_Aempty		:   std_logic := '0';
signal fifo_Afull		:   std_logic := '0';
signal hsync_r			:   std_logic := '0'; 
signal hsync_1r			:   std_logic := '0'; 
signal vsync_r			:   std_logic := '0'; 	 
signal vsync_1r			:   std_logic := '0'; 
signal de_r				:   std_logic := '0'; 
begin  
lcd_0:lcd	port map(
		clk_lcd 	=> 	clk_10MHz,
		hsync		=>	hsync_r,
		vsync		=>	vsync_r,
		de			=>	de,	
		reset_n 	=>	reset_n,
		pixel_vector	=> pixel_vector, 
		h_pixel_vector 	=> h_pixel_vector,
		v_pixel_vector	=> v_pixel_vector,
		frame_start	=>	frame_start,
		frame_end	=>	frame_end
);

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
		CLKOP	=>	clk_10MHz, 
		ENCLKOP	=>	en_clk_10MHz,
		CLKOS	=>	clk_100MHz, 
		ENCLKOS	=>	'1',
		LOCK	=>	pll_locked	
	);

fifo_c: fifo_dc
    port map (
		Data	=>	Fifo_D, 
		WrClock	=>	clk_100MHz, 
		RdClock	=>	clk_10MHz, 
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
		
	--small state machine : reset and wait for the PLL lock
	process(osc_int, pll_locked) 
	begin
		if rising_edge(osc_int) then
			case state is 
				when s05_wait_for_lock =>
					if pll_locked = '1' then
						state <= s0_reset;
					else
						state <= s05_wait_for_lock;
					end if;
					
				when s0_reset =>
					if reset_finished = '1' then
						state <= s2_copy_lcd;
					else
						state <= s0_reset;
					end if;
										
				when s2_copy_lcd =>
				state <= s2_copy_lcd;
				
				when others =>
					NULL;
			end case;
		end if;
	end process;
	
	process (clk_100MHz) 
		variable delay_reset : integer range 0 to 101;
		variable x_var : integer range 0 to X_RESOLUTION := 0;
		variable y_var : integer range 0 to Y_RESOLUTION := 0;	
	begin
		if rising_edge(clk_100MHz) then
			case state is
				when s0_reset =>
					state_dbg <= "00";
					if delay_reset < 100 then
						delay_reset := delay_reset + 1;
						reset_finished <= '0';
						reset_n <= '0';	  
						en_clk_10MHz <= '0'; 
						disp_io <= '0';
					else
						reset_finished <= '1';
					end if;
				
				when s05_wait_for_lock =>
					state_dbg <= "01";
					delay_reset := 0;
					reset_finished <= '0';
					reset_n <= '0';	 
					disp_io <= '0';
			
					
				when s2_copy_lcd =>					
					state_dbg <= "10";
					en_clk_10MHz <= '1'; 
					reset_n	 <= '1';  
					disp_io <= '1';	
					
					if frame_start_rising = '1' or frame_end = '1' then
						x_var := 0;
						y_var := 0;
					end if;
					
					fifo_wr <= '0'; --Must be only one period long, of course, and captured by the slower LCD clock
  

					if frame_start = '1' then
						if fifo_Full = '0' then	
							  
							if x_var > 190 and x_var < 290 and y_var > 86 and y_var < 186 then
								fifo_D <= (others => '0');	
							else
								fifo_D <=  std_logic_vector(to_unsigned(y_var, 9)(8 downto 2)) & std_logic_vector(to_unsigned(x_var, 9));--data_from_sdr;
							end if;
							fifo_wr <= '1';	  
							x_var := x_var + 1;	
							if x_var >= X_RESOLUTION then
								y_var := y_var + 1;
								x_var := 0;	 
								if y_var >= Y_RESOLUTION-1 then
									x_var := 0;
									y_var := 0;
								end if;
							end if;
						else
							fifo_wr <= '0';
						end if;
					end if;	 		
					
				when others	=>
				NULL;
			end case;  
		end if;
	end process;
	
	
	process( clk_10MHz)	   
	begin  	 
		if rising_edge(clk_10MHz) then		 
					if de = '1' then   
						red_io <= fifo_Q(8 downto 1);
						green_io <= fifo_Q(15 downto 10) & "00";
						blue_io <= fifo_Q(8 downto 1);	
						--fifo_rd <= '1';	
					else
						--fifo_rd <= '0';
						red_io <= (others => '0');
						green_io <= (others => '0');
						blue_io <= (others => '0');
					end if;
			end if;
	end process;   
	
	--detect edge of the frame start
	process(clk_100MHz) 
	begin
		if rising_edge(clk_100MHz) then
			frame_start_rising_r <= frame_start;
		end if;
	end process;
	frame_start_rising <= not(frame_start_rising_r) and frame_start;
	
	
	
	process( clk_10MHz)	 --delay the LCD signals 2 clocks, because the FIFO has a 2 clock read latency.  
	begin  	 
		if rising_edge(clk_10MHz) then
			de_r <= de;
			de_io <= de_r;
			hsync_1r <= hsync_r;
			hsync_io <= hsync_1r; 
			vsync_1r <= vsync_r;
			vsync_io <= vsync_1r;
		end if;
	end process;   

	fifo_reset <= (not frame_start) or (not reset_n);
	clk_io 		<= clk_10MHz;
	reset <= not reset_n;
	fifo_rd <= de;	--take DE directly, instead from a process clocked by the LCD clock, to avoid a 1 clk delay.
	
end Behavioral1;