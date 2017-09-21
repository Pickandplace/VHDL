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

entity frame_buffer is	 
	generic (
		constant X_RESOLUTION		: integer := 480;
		constant Y_RESOLUTION		: integer := 272  
	);
    port (    	
	clk_lcd		:	in std_logic;
	clk_sdr		:	in std_logic;
	en_clk_lcd	:	out  std_logic;
	reset_n		:	in std_logic; 
	
	--Video in
	x_pos		:	in integer range 0 to X_RESOLUTION-1;  
	y_pos		:	in integer range 0 to Y_RESOLUTION-1;
	w_data		:	in	std_logic_vector (15 downto 0);
	data_valid	:	in std_logic;
	last_pixel	:	in std_logic; 
	enable_lcd	: 	in std_logic;
	ready		:	out std_logic;
	
	--LCD drive
	red 		: 	out std_logic_vector(7 downto 0);
	green		: 	out std_logic_vector(7 downto 0);
	blue	 	: 	out std_logic_vector(7 downto 0);
	disp		:	out std_logic;
	hsync		:	out std_logic;
	vsync		:	out std_logic;
	de			:	out std_logic;
	
	--SDRAM interface
	Dq 			:	inout std_logic_vector(15 downto 0);
	Addr		:	out std_logic_vector(12 downto 0);
	Ba			:	out std_logic_vector(1 downto 0);
	Cke			:	out std_logic;
	Cs_n		:	out std_logic;
	Ras_n		:	out std_logic;
	Cas_n		:	out std_logic;
	We_n		:	out std_logic;
	Dqm			:	out std_logic_vector(1 downto 0);
	
	--make the FIFO external for simulation by Lattice Diamond or Vivado
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
end frame_buffer;

		
architecture Behavioral3 of frame_buffer is
component lcd 
	generic (
		constant H_RES		: integer := 480;
		constant V_RES		: integer := 272
);
    port (
		clk_lcd		:	in std_logic;
		hsync		:	out std_logic;
		vsync		:	out std_logic;
		de			:	out std_logic;
		reset_n		:	in std_logic;
		frame_start	: 	out std_logic;
		frame_end 	: 	out std_logic
	);
end component;

constant Y_RESOLUTION_RAM : integer := Y_RESOLUTION;	
constant SDR_REFRESH_DELAY : integer := 512;	
constant RAM_SIZE : integer := 16#100000#;	   --16#1000000#;	 --



component sdram_simple is
   port(
   -- Host side
   clk_100m0_i    : in std_logic;            -- Master clock
   reset_i        : in std_logic := '0';     -- Reset, active high
   refresh_i      : in std_logic := '0';     -- Initiate a refresh cycle, active high
   rw_i           : in std_logic := '0';     -- Initiate a read or write operation, active high
   we_i           : in std_logic := '0';     -- Write enable, active low
   addr_i         : in std_logic_vector(23 downto 0) := (others => '0');   -- Address from host to SDRAM
   data_i         : in std_logic_vector(15 downto 0) := (others => '0');   -- Data from host to SDRAM
   ub_i           : in std_logic;            -- Data upper byte enable, active low
   lb_i           : in std_logic;            -- Data lower byte enable, active low
   ready_o        : out std_logic := '0';    -- Set to '1' when the memory is ready
   done_o         : out std_logic := '0';    -- Read, write, or refresh, operation is done
   data_o         : out std_logic_vector(15 downto 0);   -- Data from SDRAM to host

   -- SDRAM side
   sdCke_o        : out std_logic;           -- Clock-enable to SDRAM
   sdCe_bo        : out std_logic;           -- Chip-select to SDRAM
   sdRas_bo       : out std_logic;           -- SDRAM row address strobe
   sdCas_bo       : out std_logic;           -- SDRAM column address strobe
   sdWe_bo        : out std_logic;           -- SDRAM write enable
   sdBs_o         : out std_logic_vector(1 downto 0);    -- SDRAM bank address
   sdAddr_o       : out std_logic_vector(12 downto 0);   -- SDRAM row/column address
   sdData_io      : inout std_logic_vector(15 downto 0); -- Data to/from SDRAM
   sdDqmh_o       : out std_logic;           -- Enable upper-byte of SDRAM databus if true
   sdDqml_o       : out std_logic            -- Enable lower-byte of SDRAM databus if true
);
end component;		



signal reset, reset_n_i			:	std_logic := '0'; 
		
signal osc_int			:	std_logic := '0'; 
signal reset_finished	:	std_logic := '0'; 
signal ram_filled		:	std_logic := '0'; 
signal frame_start		:	std_logic := '0'; 
signal frame_end		:	std_logic := '0'; 
signal clk_10MHz		:	std_logic := '0'; 
--signal en_clk_lcd_r		:	std_logic := '0'; 	   
 
type state_type is (s0_reset, s2_init_ram, s3_fill_ram, s4_copy_lcd, s5_refresh_ram, s6_fifo_ok);
signal state, next_state   : state_type := s0_reset;

signal de_int			:	std_logic := '0'; 
signal red_r 			:	std_logic_vector(7 downto 0) := (others => '0'); 
signal green_r			:	std_logic_vector(7 downto 0) := (others => '0'); 
signal blue_r 			:	std_logic_vector(7 downto 0) := (others => '0'); 
signal disp_r	 		:	std_logic := '0'; 
signal state_dbg,state_dbg_r  		:	std_logic_vector(2 downto 0) := (others => '0'); 
signal frame_start_rising : std_logic := '0';
signal frame_end_rising : std_logic := '0';
signal frame_end_rising_r0 : std_logic := '0';
signal frame_end_rising_r1 : std_logic := '0';
signal frame_end_rising_r2 : std_logic := '0';
signal frame_end_rising_r3 : std_logic := '0';
signal frame_start_r0 : std_logic := '0';
signal frame_start_rising_r1 : std_logic := '0';
signal frame_start_rising_r2 : std_logic := '0';
signal frame_start_rising_r3 : std_logic := '0';


--signal fifo_d			:   std_logic_vector(15 downto 0) := (others => '0');  
--signal fifo_wr			:   std_logic := '0'; 
--signal fifo_rd			:   std_logic := '0'; 
--signal fifo_Reset		:   std_logic := '0';
--signal fifo_RPreset		:   std_logic := '0';
--signal fifo_Q			:   std_logic_vector(15 downto 0) := (others => '0'); 
--signal fifo_Empty		:   std_logic := '0';
--signal fifo_Full		:   std_logic := '0';
--signal fifo_Aempty		:   std_logic := '0';
--signal fifo_Afull		:   std_logic := '0';
signal hsync_r			:   std_logic := '0'; 
signal hsync_1r			:   std_logic := '0'; 
signal vsync_r			:   std_logic := '0'; 	 
signal vsync_1r			:   std_logic := '0'; 
signal de_r				:   std_logic := '0'; 


signal      sdCke        	:  std_logic := '0';                                       
signal      sdCe        	:  std_logic := '0';                                       
signal      sdRas       	:  std_logic := '0';                                       
signal      sdCas       	:  std_logic := '0';                                       
signal      sdWe        	:  std_logic := '0';                                       
signal      sdBs         	:  std_logic_vector(1 downto 0) := (others =>'0');         
signal      sdAddr       	:  std_logic_vector(12 downto 0) := (others =>'0');        
signal      sdData      	:  std_logic_vector(15 downto 0) := (others =>'0');      
signal      sdDqm       	:  std_logic_vector(1 downto 0) := (others =>'0');                                                                     

signal sdr_refresh 		: std_logic := '0';         
signal sdr_rw 			: std_logic := '0';              
signal sdr_we_n 		: std_logic := '0';            
signal sdr_addr 		:std_logic_vector(23 downto 0) := (others =>'0');            
signal sdr_wr_data 		: std_logic_vector(15 downto 0) := (others =>'0');                                            
signal sdr_ready 		: std_logic := '0';           
signal sdr_done 		: std_logic := '0';            
signal sdr_rd_data 		: std_logic_vector(15 downto 0) := (others =>'0');   
signal sdr_compare 		: std_logic_vector(15 downto 0) := (others =>'0'); 
signal sdr_refresh_counter	: integer range 0 to SDR_REFRESH_DELAY + 64;
signal reset_counter	:	integer range 0 to 50 := 0;	
signal x_var_r			: 	integer range 0 to X_RESOLUTION := 0;
signal y_var_r			: 	integer range 0 to Y_RESOLUTION := 0;	 
signal x_var_w			: 	integer range 0 to X_RESOLUTION := 0;
signal y_var_w			: 	integer range 0 to Y_RESOLUTION := 0; 
signal buffer_index 	: std_logic := '0';  
signal buffer_index_next: std_logic := '0';   
signal buffer_ready		: std_logic := '0';

signal buffer_end 		: std_logic := '0'; 
signal enable_lcd_i		: std_logic := '0';
begin  
lcd_0:lcd	
generic map(
	H_RES => X_RESOLUTION,
	V_RES => Y_RESOLUTION
)
port map(
		clk_lcd 	=> 	clk_10MHz,
		hsync		=>	hsync_r,
		vsync		=>	vsync_r,
		de			=>	de_int,	
		reset_n 	=>	reset_n_i,
		frame_start	=>	frame_start_r0,
		frame_end	=>	frame_end
);



  
video_buffer: sdram_simple
  port map(
  	                            
-- Host side          
	clk_100m0_i		=>  clk_sdr,   
	reset_i    		=>  reset,   
	refresh_i  		=>  sdr_refresh,   
	rw_i       		=>  sdr_rw,   
	we_i       		=>  sdr_we_n,   
	addr_i     		=>  sdr_addr,   
	data_i     		=>  sdr_wr_data,   
	ub_i       		=>  '0',   
	lb_i       		=>  '0',   
	ready_o    		=>  sdr_ready,   
	done_o     		=>  sdr_done,   
	data_o     		=>  sdr_rd_data,   
  
	-- SDRAM side         
	sdCke_o   		=>  Cke,   
	sdCe_bo   		=>  Cs_n,   
	sdRas_bo  		=>  Ras_n,   
	sdCas_bo  		=>  Cas_n,   
	sdWe_bo   		=>  We_n,   
	sdBs_o    		=>  Ba,   
	sdAddr_o  		=>  Addr,   
	sdData_io 		=>  Dq,   
	sdDqmh_o  		=>  Dqm(1),   
	sdDqml_o  		=>  Dqm(0)    
  );	
 	


	process (clk_sdr, reset_n)
	begin
	if reset_n = '0' then
			state <= s0_reset;
			sdr_refresh_counter <= 0;	
			sdr_refresh <= '0';	
			sdr_rw <= '0';
			sdr_we_n <= '1'; 
 			--en_clk_lcd <= '0';
			reset <= '1';
			reset_counter <= 0;	   
			--disp_r <= '0'; 
			x_var_r <= 0;
			y_var_r <= 0; 		 
			buffer_index_next <= '0'; 
			ram_filled <= '0'; 	
			buffer_ready <= '0';
		elsif rising_edge(clk_sdr) then
		sdr_rw <= '0';
		fifo_wr <= '0';	   
		case (state) is
			when s0_reset =>
				sdr_refresh_counter <= 0;	
				sdr_refresh <= '0';	
				sdr_rw <= '0';
				sdr_we_n <= '1';  	
				reset <= '1'; 	
				--en_clk_lcd <= '0';	
				reset_counter <= reset_counter + 1;	   
				fifo_wr <= '0';
				--disp_r <= '0';  
				x_var_r <= 0;
				y_var_r <= 0; 		 
				buffer_index_next <= '0';	  
				ram_filled <= '0';	
				buffer_ready <= '0';
				if reset_counter >= 49 then
					state <= s2_init_ram;	
				else
					state <= s0_reset;
				end if;			 
				
				
			when s2_init_ram =>	 
				--en_clk_lcd <= '0'; 
				sdr_we_n <= '1';  
				sdr_rw <= '0';
				reset <= '0';	
				sdr_refresh <= '0';	  
				sdr_refresh_counter <= 0;	
				fifo_wr <= '0';		 
				--disp_r <= '0';   
				x_var_r <= 0;
				y_var_r <= 0; 		 
				buffer_index_next <= '0';
				ram_filled <= '0';	
				buffer_ready <= '0';
				if sdr_ready = '1' then
					state <= s3_fill_ram; 
				else
					state <= s2_init_ram; 
				end if;
			
			when s3_fill_ram =>	   
				sdr_rw <= '1';  
				sdr_refresh <= '0';	
				reset <= '0';	
				sdr_we_n <= '0';
				sdr_refresh_counter <= sdr_refresh_counter + 1;	 
				fifo_wr <= '0';	 	
				ram_filled <= '0'; 	
				buffer_ready <= '0';
				if sdr_done = '1' then
					if (sdr_refresh_counter > SDR_REFRESH_DELAY)  then	
						state <= s5_refresh_ram;	 
					else			
						buffer_ready <= '1';
						if buffer_end = '1' then 
							--if buffer_index_next = buffer_index then
								buffer_index_next <= not buffer_index;
							--end if;
						end if;
						if fifo_Aempty = '1' and enable_lcd_i = '1' then
							state <= s4_copy_lcd;
						else
							state <= s3_fill_ram;
						end if;
					end if;
				else
					state <= s3_fill_ram;
					buffer_ready <= '0';
				end if;
						
			
			when s4_copy_lcd =>	  
				reset <= '0';
				--en_clk_lcd <= '1';
				sdr_rw <= '1';   
				sdr_we_n <= '1';  
				sdr_refresh <= '0';
				sdr_refresh_counter <= sdr_refresh_counter + 1;	 
				fifo_wr <= '0';	
				--disp_r <= '1'; 
				ram_filled <= '1'; 
				buffer_ready <= '0';
				if sdr_done = '1' then
					if (sdr_refresh_counter > SDR_REFRESH_DELAY)  then	
						state <= s5_refresh_ram;	 
					else
						if fifo_Full = '0' then	
							fifo_wr <= '1';
							if x_var_r = X_RESOLUTION-1 then
								x_var_r <= 0;	 
								if y_var_r = Y_RESOLUTION-1 then	 
									y_var_r <= 0;
								else
									y_var_r <= y_var_r + 1;		
								end if;
							else
								x_var_r <= x_var_r + 1;	
							end if;	
						else
							fifo_wr <= '0';
							state <= s3_fill_ram;
						end if;			
					end if;	 
				else
					state <= s4_copy_lcd;
				end if;					


				
			when s5_refresh_ram =>	  
				fifo_wr <= '0';
				sdr_we_n <= '0';
				sdr_rw <= '0';  
				sdr_refresh <= '1';	 
				reset <= '0';
				sdr_refresh_counter <= 0;	 
				buffer_ready <= '0';
				if sdr_done = '1' then	
					if ram_filled = '0' then
						state <= s3_fill_ram;
					else
						state <= s4_copy_lcd;
					end if;
				else
					state <= s5_refresh_ram;
				end if;
			
				
			when others =>
				state <= s0_reset;		
		end case;
		--end if;
	end if;
	end process;	 
	
	with state select	 
	state_dbg <= 	"000" when s0_reset,
					"001" when s2_init_ram,
					"010" when s3_fill_ram,
					"011" when s4_copy_lcd,
					"100" when s5_refresh_ram,
					"101" when s6_fifo_ok,
					"000" when others;

	
	--Video data to write

	x_var_w <= x_pos;
	y_var_w <= y_pos;	
 	sdr_wr_data <= w_data;
	buffer_end <= last_pixel;	   
	enable_lcd_i <= enable_lcd;
	ready <= buffer_ready;
				
					
	fifo_rd <= de_int;	--take DE directly, instead from a process clocked by the LCD clock, to avoid a 1 clk delay.
	clk_10MHz <= clk_lcd;
	fifo_D <= sdr_rd_data;	 

	sdr_addr <= "00000" & buffer_index & std_logic_vector(to_unsigned(y_var_r, 9)) & std_logic_vector(to_unsigned(x_var_r, 9)) when sdr_we_n = '1' else "00000" & buffer_index_next  & std_logic_vector(to_unsigned(y_var_w, 9)) & std_logic_vector(to_unsigned(x_var_w, 9));	   
	
	buffer_index <= buffer_index_next when frame_end_rising = '1' else buffer_index;	
		
	red <= fifo_Q(8 downto 1);
	green <= fifo_Q(15 downto 10) & "00";
	blue <= fifo_Q(8 downto 1);
	process(clk_lcd)	 --delay the LCD signals 2 clocks, because the FIFO has a 2 clock read latency.  
		begin  	 
		if rising_edge(clk_lcd) then
			de_r <= de_int;
			de <= de_r;
			hsync_1r <= hsync_r;
			hsync <= hsync_1r; 
			vsync_1r <= vsync_r;
			vsync <= vsync_1r;
		end if;
	end process;   
	
	process(clk_sdr) 
	begin
		if rising_edge(clk_sdr) then
			frame_end_rising_r0 <= frame_end;
			frame_end_rising_r1 <= frame_end_rising_r0;	   
		end if;
	end process;
	frame_end_rising <= not(frame_end_rising_r1) and frame_end_rising_r0;	 
	
	disp <= enable_lcd_i;
	en_clk_lcd <= enable_lcd_i;
	fifo_reset <= (not reset_n);
	reset_n_i  <= ( reset_n);
	
end Behavioral3;