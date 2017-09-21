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

entity buffer_interface is
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
end buffer_interface ;



architecture buffer_interface_behav of buffer_interface is 		 

component fifo_acq
    port (
	Data: in  std_logic_vector(24 downto 0); 
	WrClock: in  std_logic; 
	RdClock: in  std_logic; 
	WrEn: in  std_logic; 
	RdEn: in  std_logic; 
	Reset: in  std_logic; 
	RPReset: in  std_logic; 
	Q: out  std_logic_vector(24 downto 0); 
	Empty: out  std_logic; 
	Full: out  std_logic; 
	AlmostEmpty: out  std_logic; 
	AlmostFull: out  std_logic);
end component;
type state_type is (s0_reset, s1_wait_for_first_sample, s2_fill_fifo, s3_blank_ram, s4_write_fifo_to_buffer);
signal state: state_type := s0_reset; 

signal x_vector_i		:	integer range 0 to H_RES; 
signal y_vector_i		:	integer range 0 to V_RES; 
signal d_vector_i		:	std_logic_vector(15 downto 0);	  

signal x_var			: 	integer range 0 to H_RES := 0;
signal y_var			: 	integer range 0 to V_RES := 0;
signal last_pixel_r		:	std_logic := '0'; 
signal new_acq_frame	:	std_logic := '0';  
signal new_acq_frame_r	:	std_logic := '0';
signal new_acq_frame_r0	:	std_logic := '0';
signal new_acq_frame_r1	:	std_logic := '0'; 	
signal new_sample_r	:	std_logic := '0';
signal new_sample_r0	:	std_logic := '0';
signal new_sample_r1	:	std_logic := '0'; 

signal read_erase		:	std_logic := '0';	
signal start_acq_frame	:	std_logic := '0';
signal fifo_q,fifo_d	:	std_logic_vector(24 downto 0);	
signal insert_sample,fifo_empty,fifo_Afull,fifo_read,fifo_reset,fifo_write,fifo_write_en	:	std_logic := '0';	
signal state_dbg  		:	std_logic_vector(2 downto 0) := (others => '0'); 
signal x_vector_dbg,sample_X_s	:	std_logic_vector(8 downto 0);	
signal y_vector_dbg,sample_Y_s	:	std_logic_vector(8 downto 0);
signal new_sample_s : std_logic;
signal frame_end_r : std_logic;
begin	  

acq_fifo: fifo_acq
port map (
	Data 		=>	fifo_d, 
	WrClock		=>	clk_acq, 
	RdClock		=>	clk_sdr, 
	WrEn		=>	fifo_write, 
	RdEn		=>	fifo_read, 
	Reset		=>	fifo_reset, 
	RPReset		=>	'0', 
	Q			=> fifo_q, 
	Empty		=> fifo_empty, 
	Full		=> open, 
	AlmostEmpty	=> open, 
	AlmostFull	=> fifo_Afull
	);


	process (clk_sdr)
	begin
	if rising_edge(clk_sdr) then
		if reset_n = '0' then
			state <= s0_reset;
			x_var <= 0;
			y_var <= 0;	
			enable_lcd <= '0'; 
			last_pixel_r <= '0'; 
			fifo_reset <= '1'; 
			fifo_read <= '0';
			frame_end_r <= '0';
			data_valid <= '0'; 
		else   
			case (state) is
				when s0_reset =>  		
					x_var <= 0;
					y_var <= 0;	
					enable_lcd <= '0'; 
					last_pixel_r <= '0'; 
					fifo_reset <= '1'; 
					frame_end_r <= '0';
					fifo_write_en <= '0';
					fifo_read <= '0';
					data_valid <= '0'; 
					state <= s1_wait_for_first_sample;  
				
				when s1_wait_for_first_sample =>	  
					fifo_reset <= '1';
					last_pixel_r <= '0';  
					fifo_write_en <= '0';
					frame_end_r <= '0';
					fifo_read <= '0';
					data_valid <= '0'; 
					if new_acq_frame_r = '1' then
						state <= s2_fill_fifo;
					else
						state <= s1_wait_for_first_sample;
					end if;
				
				when s2_fill_fifo =>   
					fifo_reset <= '0';
					fifo_write_en <= '1';
					frame_end_r <= '0';
					fifo_read <= '0';
					data_valid <= '0'; 
					if new_acq_frame_r = '1' or fifo_Afull ='1' then
						state <= s3_blank_ram; 
						x_var <= 0;
						y_var <= 0;	 		
					else
						state <= s2_fill_fifo;
					end if;
					
				when s3_blank_ram =>		   
					fifo_write_en <= '0';	
					last_pixel_r <= '0'; 
					frame_end_r <= '0';
					fifo_read <= '0';
					
					if ready_for_data = '1' then
						data_valid <= '1';
						if x_var < H_RES-1 then
							x_var <= x_var + 1;
							last_pixel_r <= '0';
						else
							x_var <= 0;	
							if y_var < V_RES-1 then
								y_var <= y_var + 1;
							else
								y_var <= 0;	
								last_pixel_r <= '1'; 
							end if;
						end if;	 
					else
						last_pixel_r <= '0';
						data_valid <= '0'; 
					end if;
					
					if last_pixel_r = '1' then		 
						y_var <= 0;	
						x_var <= 0;			
						state <= s4_write_fifo_to_buffer;
					else
						state <= s3_blank_ram;
					end if;
				
				when s4_write_fifo_to_buffer =>
					last_pixel_r <= '0'; 
					frame_end_r <= '0';
					fifo_write_en <= '0';
					
					if ready_for_data = '1' then
						fifo_read <= '1';	
						data_valid <= '1'; 
						frame_end_r <= '0';
						fifo_reset <= '0';
						state <= s4_write_fifo_to_buffer;
						if x_var < H_RES-1 then
							x_var <= x_var + 1;
								
						else
								x_var <= 0;	
								y_var <= 0;	
								frame_end_r <= '1';
								enable_lcd <= '1';	
								fifo_reset <= '1';
								state <= s1_wait_for_first_sample;
						end if;
					else
						data_valid <= '0'; 
						fifo_read <= '0';
					end if;				
				
				when others =>
					state <= s0_reset;		
			end case;
		end if;	
	end if;
	end process;
				
--	process(clk_acq)   
--	variable x_v : integer range 0 to H_RES := 0;	 
--	variable y_v : integer range 0 to H_RES := 0;
--	begin
--		if rising_edge(clk_acq) then  
--			if reset_n = '0' then
--				x_v := 0;
--				y_v := 0;					   		  
--			elsif new_sample_s = '1' then		
--				if x_v < H_RES then
--					x_v := x_v + 1;
--					if x_v < V_RES then
--						y_v := y_v + 1;
--					end if;
--				else
--					x_v := 0; 
--					y_v := 0;
--				end if;
--				sample_X_s <= std_logic_vector(to_unsigned(x_v, 9)); 
--				sample_Y_s <= std_logic_vector(to_unsigned(y_v, 9));
--			end if;
--		end if;
--	end process; 

--	process(clk_acq)   
--	variable del : integer range 0 to 4 := 0;	  
--	begin
--		if rising_edge(clk_acq) then  
--			if reset_n = '0' then
--				del := 0; 
--				new_sample_s <= '0';
--			elsif  del < 4 then
--				del := del + 1;
--				new_sample_s <= '0';
--			else
--				del := 0;
--				new_sample_s <= '1';
--			end if;
--		end if;
--	end process;
	
	process(clk_acq)   
	variable sample_tmp : integer range 0 to H_RES := 0;
	begin
		if rising_edge(clk_acq) then 
			insert_sample <= '0';
			if reset_n = '0' then
				x_vector_i <= 0;
				y_vector_i <= 0;
				d_vector_i <= (others => '0');			  
			elsif new_sample = '1' then		
				sample_tmp := to_integer(unsigned(sample_X(8 downto 0)));
				--if sample_tmp /= x_vector_i then
					x_vector_i <= to_integer(unsigned(sample_X(9 downto 1)));	
					y_vector_i <= to_integer(unsigned(sample_Y(8 downto 1)));
					d_vector_i <= (others => '1');--"000" & sample_Z(12 downto 0);
					insert_sample <= '1';
				--else
					--insert_sample <= '0';
				--end if;	
				
			end if;
		end if;
	end process; 
	with state select	 
	state_dbg <= 	"000" when s0_reset,
					"001" when s1_wait_for_first_sample,
					"010" when s2_fill_fifo,
					"011" when s3_blank_ram,
					"100" when s4_write_fifo_to_buffer,
					"000" when others;

	--fifo_read <= '1' when state = s3_fill_ram and ready_for_data = '1' else '0';
	fifo_d <= "1111111" & std_logic_vector(to_unsigned(x_vector_i,9)) & std_logic_vector(to_unsigned(y_vector_i,9));--d_vector_i & std_logic_vector(to_unsigned(y_vector_i,9));
	new_acq_frame <= '1' when x_vector_i = 0 else '0';
													   
	x_vector <= to_integer(unsigned(fifo_q(17 downto 9))) when fifo_read = '1' and fifo_empty = '0' else x_var;
	y_vector <= to_integer(unsigned(fifo_q(8 downto 0))) when fifo_read = '1' and fifo_empty = '0' else y_var;
	d_vector <= "111111111" & fifo_q(24 downto 18) when state = s4_write_fifo_to_buffer and fifo_empty = '0' else (others => '0');--fifo_read = '1' and fifo_empty = '0' else (others => '0');	
	 
	frame_end <= frame_end_r ;	  
	fifo_write <= insert_sample and fifo_write_en;
	
	x_vector_dbg <= std_logic_vector(to_unsigned(x_vector_i, 9));
	y_vector_dbg <= std_logic_vector(to_unsigned(y_vector_i, 9));
	process(clk_sdr) 
	begin
		if rising_edge(clk_sdr) then
			new_acq_frame_r0 <= new_acq_frame;
			new_acq_frame_r1 <= new_acq_frame_r0;	   
		end if;
	end process;
	new_acq_frame_r <= not(new_acq_frame_r1) and new_acq_frame_r0;
	
	process(clk_sdr) 
	begin
		if rising_edge(clk_sdr) then
			new_sample_r0 <= new_sample_s;
			new_sample_r1 <= new_sample_r0;	   
		end if;
	end process;
	new_sample_r <= not(new_sample_r1) and new_sample_r0;		
end buffer_interface_behav;
