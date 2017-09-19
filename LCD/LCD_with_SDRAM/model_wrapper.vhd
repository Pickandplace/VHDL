
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity model_wrapper is
   port(
	  clk_100m0    : in std_logic;            -- Master clock
      reset        : in std_logic ;     -- Reset, active high
      refresh      : in std_logic ;     -- Initiate a refresh cycle, active high
      rw           : in std_logic ;     -- Initiate a read or write operation, active high
      we           : in std_logic ;     -- Write enable, active low
      addr         : in std_logic_vector(23 downto 0) := (others => '0');   -- Address from host to SDRAM
      data_to      : in std_logic_vector(15 downto 0) := (others => '0');   -- Data from host to SDRAM
      ub           : in std_logic;            -- Data upper byte enable, active low
      lb           : in std_logic;            -- Data lower byte enable, active low
      ready        : out std_logic := '0';    -- Set to '1' when the memory is ready
      done         : out std_logic := '0';    -- Read, write, or refresh, operation is done
	  data_from    : out std_logic_vector(15 downto 0)   -- Data from SDRAM to host
);
end entity;

architecture rtl1 of model_wrapper is
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

signal clk_133MHz		:	std_logic := '0'; 

signal	s_Dq :   std_logic_vector (16-1 downto 0);
signal  s_Addr:  std_logic_vector(12 downto 0);
signal  s_Ba:  std_logic_vector(1 downto 0);
signal  s_Cke: std_logic; 
signal  s_Cs_n: std_logic; 
signal  s_Ras_n: std_logic; 
signal  s_Cas_n: std_logic; 
signal  s_We_n: std_logic; 
signal  s_Dqm: std_logic_vector(1 downto 0);

begin
sdram_simple_c:sdram_simple
   port map(
      -- Host side
      clk_100m0_i    => clk_100m0,
      reset_i        => reset,
      refresh_i      => refresh,
      rw_i           => rw,
      we_i           => we,
      addr_i         => addr,
      data_i         => data_to,
      ub_i           => ub,
      lb_i           => lb,
      ready_o        => ready,
      done_o         => done,
      data_o         => data_from,

      -- SDRAM side
      sdCke_o        => s_Cke,
      sdCe_bo        => s_Cs_n,
      sdRas_bo       => s_Ras_n,
      sdCas_bo       => s_Cas_n,
      sdWe_bo        => s_We_n,
      sdBs_o         => s_Ba,
      sdAddr_o       => s_Addr, 
      sdData_io      => s_Dq,
      sdDqmh_o       => s_Dqm(1),
      sdDqml_o       => s_Dqm(0)

);

sdr_module_c:mt48lc16m16a2
port map(
	Dq => s_Dq,
    Addr => s_Addr,
    Ba => s_Ba,
    Clk => clk_100m0,
    Cke => s_Cke,
    Cs_n => s_Cs_n,
    Ras_n => s_Ras_n,
    Cas_n => s_Cas_n,
    We_n => s_We_n,
    Dqm => s_Dqm
);

end architecture;