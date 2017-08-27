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
component sdram_simple 
   port(
      -- Host side
      clk_100m0_i    : in std_logic;            -- Master clock
      reset_i        : in std_logic := '0';     -- Reset, active high
      refresh_i      : in std_logic := '0';     -- Initiate a refresh cycle, active high
      rw_i           : in std_logic := '0';     -- Initiate a read or write operation, active high
      we_i           : in std_logic := '0';     -- Write enable, active low
      addr_i         : in std_logic_vector(23 downto 0) := (others => '0');   -- Address from host to SDRAM
      data_i         : in std_logic_vector(15 downto 0) := (others => '0');   -- Data from host to SDRAM
      ub_i           : in std_logic;            -- Data upper byte enable, active low
      lb_i           : in std_logic;            -- Data lower byte enable, active low
      ready_o        : out std_logic := '0';    -- Set to '1' when the memory is ready
      done_o         : out std_logic := '0';    -- Read, write, or refresh, operation is done
      data_o         : out std_logic_vector(15 downto 0);   -- Data from SDRAM to host

      -- SDRAM side
      sdCke_o        : out std_logic;           -- Clock-enable to SDRAM
      sdCe_bo        : out std_logic;           -- Chip-select to SDRAM
      sdRas_bo       : out std_logic;           -- SDRAM row address strobe
      sdCas_bo       : out std_logic;           -- SDRAM column address strobe
      sdWe_bo        : out std_logic;           -- SDRAM write enable
      sdBs_o         : out std_logic_vector(1 downto 0);    -- SDRAM bank address
      sdAddr_o       : out std_logic_vector(12 downto 0);   -- SDRAM row/column address
      sdData_io      : inout std_logic_vector(15 downto 0); -- Data to/from SDRAM
      sdDqmh_o       : out std_logic;           -- Enable upper-byte of SDRAM databus if true
      sdDqml_o       : out std_logic            -- Enable lower-byte of SDRAM databus if true
   );
end component;
constant OSC_STR  : string  := "133.00";
constant X_RESOLUTION : integer := 480;
constant Y_RESOLUTION : integer := 10;--272;		
constant REFRESH_DELAY : integer := 1000;
 
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
type state_type is (s0_wait_for_lock, s1_reset, s06_init_ram, s2_fill_buffer, s3_copy_lcd, s4_sdram_refresh);
signal state   : state_type := s0_wait_for_lock;


signal h_pixel_vector	:	std_logic_vector(8 downto 0) := (others => '0');
signal v_pixel_vector	:	std_logic_vector(8 downto 0) := (others => '0'); 


signal red_r 			:	std_logic_vector(7 downto 0) := (others => '0'); 
signal green_r			:	std_logic_vector(7 downto 0) := (others => '0'); 
signal blue_r 			:	std_logic_vector(7 downto 0) := (others => '0'); 
signal state_dbg 		:	std_logic_vector(2 downto 0) := (others => '0'); 
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
signal refresh_counter 	: integer range 0 to REFRESH_DELAY+30;	
signal filling_ram	 	:	std_logic := '0';   
signal reading_ram	 	:	std_logic := '0'; 	 
signal refresh_sdr		: 	std_logic := '0'; 
signal rw_sdr			: 	std_logic := '0'; 
signal we_sdr_n			: 	std_logic := '0'; 
signal addr_sdr			:	std_logic_vector(23 downto 0) := (others => '0'); 
signal data_to_sdr		:	std_logic_vector(15 downto 0) := (others => '0'); 
signal data_to_sdr_r	:	std_logic_vector(16 downto 0) := (others => '0'); 
signal mask_u_sdr		: 	std_logic := '0'; 
signal mask_l_sdr		: 	std_logic := '0'; 
signal sdr_ready		: 	std_logic := '0'; 
signal sdr_done			: 	std_logic := '0'; 
signal data_from_sdr	:	std_logic_vector(15 downto 0) := (others => '0'); 

begin  	
	
video_buffer: sdram_simple 
   port map(
      -- Host side
      clk_100m0_i    => clk_100MHz,
      reset_i        => reset,
      refresh_i      => refresh_sdr,
      rw_i           => rw_sdr,
      we_i           => we_sdr_n,
      addr_i         => addr_sdr,
      data_i         => data_to_sdr,
      ub_i           => mask_u_sdr,
      lb_i           => mask_l_sdr,
      ready_o        => sdr_ready,
      done_o         => sdr_done,
      data_o         => data_from_sdr,

      -- SDRAM side
      sdCke_o        => sdr_CKE,
      sdCe_bo        => sdr_CSn,
      sdRas_bo       => sdr_RASn,
      sdCas_bo       => sdr_CASn,
      sdWe_bo        => sdr_WEn,
      sdBs_o         => sdr_BA,
      sdAddr_o       => sdr_A  , 
      sdData_io      => sdr_DQ,
      sdDqmh_o       => sdr_UDQM,
      sdDqml_o       => sdr_LDQM
   ); 

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
				when s0_wait_for_lock =>
					if pll_locked = '1' then
						state <= s1_reset;
					else
						state <= s0_wait_for_lock;
					end if;
					
				when s1_reset =>
					if reset_finished = '1' then
						state <= s06_init_ram;
					else
						state <= s1_reset;
					end if;
				
				when s06_init_ram =>
					if  sdr_ready = '1' then
						state <= s2_fill_buffer;
					else
						state <= s06_init_ram;
					end if;
					
				when s2_fill_buffer =>
					if filling_ram = '1' then
						state <= s2_fill_buffer;
					else
						state <= s3_copy_lcd;
					end if;	 
					if refresh_counter >= REFRESH_DELAY then  
						state <= s4_sdram_refresh;
					end if;
					
				
				when s3_copy_lcd =>
					if refresh_counter >= REFRESH_DELAY then
						state <= s4_sdram_refresh;   
					else
						state <= s3_copy_lcd;
					end if;
					
						
				when s4_sdram_refresh =>
					if sdr_done = '1' then	  
						if filling_ram = '1' then
							state <= s2_fill_buffer;
						else
							state <= s3_copy_lcd;
						end if;				
					else
						state <= s4_sdram_refresh;
					end if;

					
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
				
				when s0_wait_for_lock =>
					state_dbg <= "000";
					delay_reset := 0;
					reset_finished <= '0';
					reset_n <= '0';	 
					disp_io <= '0';
					
				when s1_reset =>
					state_dbg <= "001";
					if delay_reset < 100 then
						delay_reset := delay_reset + 1;
						reset_finished <= '0';
						reset_n <= '0';	  
						en_clk_10MHz <= '0'; 
						disp_io <= '0';
					else
						reset_finished <= '1';
					end if;
				
				when s06_init_ram =>  
					state_dbg <= "010";
					reset_n <= '1';	
					rw_sdr <= '0';
					we_sdr_n <= '1';
					mask_u_sdr <= '0';
					mask_l_sdr <= '0';	
					addr_sdr <= (others => '0');   
					data_to_sdr <= (others => '0');	
					filling_ram <= '1';	
					
				when s2_fill_buffer =>					
					state_dbg <= "011"; 
					reset_n	 <= '1';  
					refresh_sdr <= '0';	
					refresh_counter <= refresh_counter + 1 ; 
					
					disp_io <= '0';
					if refresh_counter <= REFRESH_DELAY then   
						rw_sdr <= '1';
						we_sdr_n <= '0'; 						
						addr_sdr <= "00000" & '0' & std_logic_vector(to_unsigned(y_var, 9)) & std_logic_vector(to_unsigned(x_var, 9)); 
						data_to_sdr <=  std_logic_vector(to_unsigned(y_var, 9)(8 downto 2)) & std_logic_vector(to_unsigned(x_var, 9));	 
						if sdr_done = '1' then	
							x_var := x_var + 1;	
							if x_var >= X_RESOLUTION then
								y_var := y_var + 1;
								x_var := 0;	 
								if y_var >= Y_RESOLUTION-1 then
									x_var := 0;
									y_var := 0;	  
									filling_ram <= '0';
								end if;
							end if;	 
						end if;
					end if;	
	
				when s3_copy_lcd =>	
					state_dbg <= "100";
					refresh_sdr <= '0';	
					en_clk_10MHz <= '1';  
					disp_io <= '1';	
					fifo_wr <= '0';
					refresh_counter <= refresh_counter + 1 ; 
					if refresh_counter <= REFRESH_DELAY then 
						rw_sdr <= '1';
						we_sdr_n <= '1';
						if  frame_end = '1' then
							x_var := 0;
							y_var := 0;
						end if;	 
						if fifo_full = '0' then
							addr_sdr <= "00000" & '0' & std_logic_vector(to_unsigned(y_var, 9)) & std_logic_vector(to_unsigned(x_var, 9)); 
							if sdr_done = '1' then	
								fifo_D <=  data_from_sdr;
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
							end if;
						end if;
					end if;	

				when s4_sdram_refresh =>	
					state_dbg <= "101";
					refresh_sdr <= '1';	
					refresh_counter	<= 0;
					
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

	fifo_reset <= (frame_end) or (not reset_n);
	clk_io 		<= clk_10MHz;
	reset <= not reset_n;
	fifo_rd <= de;	--take DE directly, instead from a process clocked by the LCD clock, to avoid a 1 clk delay.
	sdr_CLK 	<= clk_100MHz;
	
end Behavioral1;