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
constant RAM_SIZE : integer := 16#1000000#;	   --16#100#;	 --
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


	
signal we_i, reset_n	:	std_logic := '0'; 
signal reset			:	std_logic := '0'; 
signal de 				:	std_logic := '0'; 
		
signal stdby, stdby_sed :  	std_logic := '0'; 
signal osc_int			:	std_logic := '0'; 
signal reset_finished	:	std_logic := '0'; 
signal ram_filling		:	std_logic := '0'; 

signal clk_100MHz		:	std_logic := '0'; 
signal clk_10MHz		:	std_logic := '0'; 
signal en_clk_10MHz		:	std_logic := '0'; 
signal pll_locked		:	std_logic := '0'; 	   

type state_type is (s0_reset, s05_wait_for_lock, s06_init_ram, s1_fill_ram, s2_compare_ram, s3_refresh_ram);
signal state   : state_type;

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

signal state_dbg 		:	std_logic_vector(2 downto 0) := (others => '0'); 
signal ram_error		:	std_logic := '0';	 
signal ram_comparing	:	std_logic := '0';
signal compare_val 		:	std_logic_vector(15 downto 0) := x"5555"; 
signal refresh_counter 	: integer range 0 to REFRESH_DELAY+30;
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


	--small state machine
	process(clk_100MHz, pll_locked) 

	begin
		if pll_locked = '0' then
			state <= s05_wait_for_lock;
		elsif rising_edge(clk_100MHz) then
			case state is 
				when s05_wait_for_lock =>
					if pll_locked = '1' then
						state <= s0_reset;
					else
						state <= s05_wait_for_lock;
					end if;
					
				when s0_reset =>
					if reset_finished = '1' then
						state <= s06_init_ram;
					else
						state <= s0_reset;
					end if;
					
				when s06_init_ram =>
					if  sdr_ready = '1' then
						state <= s1_fill_ram;
					else
						state <= s06_init_ram;
					end if;
				
				when s1_fill_ram =>
					if ram_filling = '0' then
						state <= s2_compare_ram;
					else
						state <= s1_fill_ram;
					end if;	
					if refresh_counter >= REFRESH_DELAY then
						state <= s3_refresh_ram;  
					end if;
					
				when s2_compare_ram =>
					if ram_comparing = '0' then
						state <= s1_fill_ram;
					else
						state <= s2_compare_ram;
					end if;
					if refresh_counter >= REFRESH_DELAY then
						state <= s3_refresh_ram;  
					end if;

				when s3_refresh_ram =>
				if sdr_done = '1' then	  
					if ram_comparing = '0' then
						state <= s1_fill_ram;
					else
						state <= s2_compare_ram;
					end if;	
					if ram_filling = '0' then
						state <= s2_compare_ram;
					else
						state <= s1_fill_ram;
					end if;					
				else
					state <= s3_refresh_ram;
				end if;
					
				when others =>
					NULL;
			end case;
		end if;
	end process;
	
	process (clk_100MHz,state) 
		variable delay_reset : integer range 0 to 10;
		variable address : integer range 0 to RAM_SIZE := 0;  
	begin
		if rising_edge(clk_100MHz) then
			case state is
				when s0_reset =>
					state_dbg <= "000";
					if delay_reset < 10 then
						delay_reset := delay_reset + 1;
						reset_finished <= '0';
						reset_n <= '0';	  
					else
						reset_finished <= '1';
					end if;
				
				when s05_wait_for_lock =>
					state_dbg <= "001";
					delay_reset := 0;
					reset_finished <= '0';
					reset_n <= '0';	 
					
				when s06_init_ram =>  
					state_dbg <= "010";
					reset_n <= '1';	
					rw_sdr <= '0';
					we_sdr_n <= '1';
					mask_u_sdr <= '0';
					mask_l_sdr <= '0';	
					ram_filling <= '1';
					addr_sdr <= (others => '0');   
					data_to_sdr <= (others => '0');	
					compare_val <= x"5555"; 
					
					
				when s1_fill_ram =>	 
					state_dbg <= "011";
					reset_n	 <= '1';	
					refresh_sdr <= '0';	
					refresh_counter <= refresh_counter + 1 ; 
					if refresh_counter <= REFRESH_DELAY then   
						rw_sdr <= '1';
						we_sdr_n <= '0'; 
						
						addr_sdr <= std_logic_vector(to_unsigned(address, 24 )) ;
						data_to_sdr <= compare_val;
						if sdr_done = '1' then	   
							if address < RAM_SIZE then
								address := address +1;
							else
								address := 0;
								ram_comparing <= '1'; 
								ram_filling <= '0';
							end if;
						end if;
					end if;
					
				when s2_compare_ram =>
					state_dbg <= "100";
					refresh_sdr <= '0';	
					refresh_counter <= refresh_counter + 1 ; 
					if refresh_counter <= REFRESH_DELAY then 
						rw_sdr <= '1';
						we_sdr_n <= '1';
						addr_sdr <= std_logic_vector(to_unsigned(address, 24 )) ;	 
						
						if sdr_done = '1' then 
							if data_from_sdr /= compare_val then
								ram_error <= '1';
							else
								ram_error <= '0';
							end if;
							if address < RAM_SIZE then
								address := address +1;
							else
								address := 0;
								ram_comparing <= '0'; 
								ram_filling <= '1';
								compare_val <= compare_val(14 downto 0) & compare_val(15);
							end if;
						end if;		
					end if;
				
				when s3_refresh_ram =>	 
					refresh_sdr <= '1';	
					refresh_counter	<= 0;
					
				when others	=>
				NULL;
			end case;  
		end if;
	end process;
	
	sdr_CLK 	<= clk_100MHz;
	reset <= not reset_n;
	
end Behavioral1;