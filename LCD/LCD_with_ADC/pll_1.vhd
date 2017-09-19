-- VHDL netlist generated by SCUBA Diamond Version 3.9.1.119
-- Module  Version: 5.7
--C:\lscc\diamond\3.9\ispfpga\bin\nt\scuba.exe -w -n pll_1 -lang vhdl -synth lse -arch xo2c00 -type pll -fin 133 -fclkop 5 -fclkop_tol 5.0 -fclkos 80 -fclkos_tol 5.0 -fclkos2 1.6 -fclkos2_tol 0.5 -trimp 0 -phasep 0 -trimp_r -trims 0 -phases 0 -trims_r -phases2 0 -phase_cntl STATIC -enable_ports -fb_mode 6 -lock 

-- Fri Sep 15 15:45:49 2017

library IEEE;
use IEEE.std_logic_1164.all;
-- synopsys translate_off
library MACHXO2;
use MACHXO2.components.all;
-- synopsys translate_on

entity pll_1 is
    port (
        CLKI: in  std_logic; 
        ENCLKOP: in  std_logic; 
        ENCLKOS: in  std_logic; 
        ENCLKOS2: in  std_logic; 
        CLKOP: out  std_logic; 
        CLKOS: out  std_logic; 
        CLKOS2: out  std_logic; 
        LOCK: out  std_logic);
end pll_1;

architecture Structure of pll_1 is

    -- internal signal declarations
    signal CLKOS2_t: std_logic;
    signal CLKOS_t: std_logic;
    signal CLKOP_t: std_logic;
    signal CLKFB_t: std_logic;
    signal scuba_vlo: std_logic;

    -- local component declarations
    component VLO
        port (Z: out  std_logic);
    end component;
    component EHXPLLJ
        generic (INTFB_WAKE : in String; DDRST_ENA : in String; 
                DCRST_ENA : in String; MRST_ENA : in String; 
                PLLRST_ENA : in String; DPHASE_SOURCE : in String; 
                STDBY_ENABLE : in String; OUTDIVIDER_MUXD2 : in String; 
                OUTDIVIDER_MUXC2 : in String; 
                OUTDIVIDER_MUXB2 : in String; 
                OUTDIVIDER_MUXA2 : in String; 
                PREDIVIDER_MUXD1 : in Integer; 
                PREDIVIDER_MUXC1 : in Integer; 
                PREDIVIDER_MUXB1 : in Integer; 
                PREDIVIDER_MUXA1 : in Integer; PLL_USE_WB : in String; 
                PLL_LOCK_MODE : in Integer; 
                CLKOS_TRIM_DELAY : in Integer; 
                CLKOS_TRIM_POL : in String; 
                CLKOP_TRIM_DELAY : in Integer; 
                CLKOP_TRIM_POL : in String; FRACN_DIV : in Integer; 
                FRACN_ENABLE : in String; FEEDBK_PATH : in String; 
                CLKOS3_FPHASE : in Integer; CLKOS2_FPHASE : in Integer; 
                CLKOS_FPHASE : in Integer; CLKOP_FPHASE : in Integer; 
                CLKOS3_CPHASE : in Integer; CLKOS2_CPHASE : in Integer; 
                CLKOS_CPHASE : in Integer; CLKOP_CPHASE : in Integer; 
                VCO_BYPASS_D0 : in String; VCO_BYPASS_C0 : in String; 
                VCO_BYPASS_B0 : in String; VCO_BYPASS_A0 : in String; 
                CLKOS3_ENABLE : in String; CLKOS2_ENABLE : in String; 
                CLKOS_ENABLE : in String; CLKOP_ENABLE : in String; 
                CLKOS3_DIV : in Integer; CLKOS2_DIV : in Integer; 
                CLKOS_DIV : in Integer; CLKOP_DIV : in Integer; 
                CLKFB_DIV : in Integer; CLKI_DIV : in Integer);
        port (CLKI: in  std_logic; CLKFB: in  std_logic; 
            PHASESEL1: in  std_logic; PHASESEL0: in  std_logic; 
            PHASEDIR: in  std_logic; PHASESTEP: in  std_logic; 
            LOADREG: in  std_logic; STDBY: in  std_logic; 
            PLLWAKESYNC: in  std_logic; RST: in  std_logic; 
            RESETM: in  std_logic; RESETC: in  std_logic; 
            RESETD: in  std_logic; ENCLKOP: in  std_logic; 
            ENCLKOS: in  std_logic; ENCLKOS2: in  std_logic; 
            ENCLKOS3: in  std_logic; PLLCLK: in  std_logic; 
            PLLRST: in  std_logic; PLLSTB: in  std_logic; 
            PLLWE: in  std_logic; PLLADDR4: in  std_logic; 
            PLLADDR3: in  std_logic; PLLADDR2: in  std_logic; 
            PLLADDR1: in  std_logic; PLLADDR0: in  std_logic; 
            PLLDATI7: in  std_logic; PLLDATI6: in  std_logic; 
            PLLDATI5: in  std_logic; PLLDATI4: in  std_logic; 
            PLLDATI3: in  std_logic; PLLDATI2: in  std_logic; 
            PLLDATI1: in  std_logic; PLLDATI0: in  std_logic; 
            CLKOP: out  std_logic; CLKOS: out  std_logic; 
            CLKOS2: out  std_logic; CLKOS3: out  std_logic; 
            LOCK: out  std_logic; INTLOCK: out  std_logic; 
            REFCLK: out  std_logic; CLKINTFB: out  std_logic; 
            DPHSRC: out  std_logic; PLLACK: out  std_logic; 
            PLLDATO7: out  std_logic; PLLDATO6: out  std_logic; 
            PLLDATO5: out  std_logic; PLLDATO4: out  std_logic; 
            PLLDATO3: out  std_logic; PLLDATO2: out  std_logic; 
            PLLDATO1: out  std_logic; PLLDATO0: out  std_logic);
    end component;
    attribute FREQUENCY_PIN_CLKOS2 : string; 
    attribute FREQUENCY_PIN_CLKOS : string; 
    attribute FREQUENCY_PIN_CLKOP : string; 
    attribute FREQUENCY_PIN_CLKI : string; 
    attribute ICP_CURRENT : string; 
    attribute LPF_RESISTOR : string; 
    attribute FREQUENCY_PIN_CLKOS2 of PLLInst_0 : label is "1.596000";
    attribute FREQUENCY_PIN_CLKOS of PLLInst_0 : label is "79.800000";
    attribute FREQUENCY_PIN_CLKOP of PLLInst_0 : label is "5.204348";
    attribute FREQUENCY_PIN_CLKI of PLLInst_0 : label is "133.000000";
    attribute ICP_CURRENT of PLLInst_0 : label is "7";
    attribute LPF_RESISTOR of PLLInst_0 : label is "8";
    attribute syn_keep : boolean;
    attribute NGD_DRC_MASK : integer;
    attribute NGD_DRC_MASK of Structure : architecture is 1;

begin
    -- component instantiation statements
    scuba_vlo_inst: VLO
        port map (Z=>scuba_vlo);

    PLLInst_0: EHXPLLJ
        generic map (DDRST_ENA=> "DISABLED", DCRST_ENA=> "DISABLED", 
        MRST_ENA=> "DISABLED", PLLRST_ENA=> "DISABLED", INTFB_WAKE=> "DISABLED", 
        STDBY_ENABLE=> "DISABLED", DPHASE_SOURCE=> "DISABLED", 
        PLL_USE_WB=> "DISABLED", CLKOS3_FPHASE=>  0, CLKOS3_CPHASE=>  0, 
        CLKOS2_FPHASE=>  0, CLKOS2_CPHASE=>  49, CLKOS_FPHASE=>  0, 
        CLKOS_CPHASE=>  5, CLKOP_FPHASE=>  0, CLKOP_CPHASE=>  91, 
        PLL_LOCK_MODE=>  0, CLKOS_TRIM_DELAY=>  0, CLKOS_TRIM_POL=> "RISING", 
        CLKOP_TRIM_DELAY=>  0, CLKOP_TRIM_POL=> "RISING", FRACN_DIV=>  0, 
        FRACN_ENABLE=> "DISABLED", OUTDIVIDER_MUXD2=> "DIVD", 
        PREDIVIDER_MUXD1=>  0, VCO_BYPASS_D0=> "DISABLED", CLKOS3_ENABLE=> "DISABLED", 
        OUTDIVIDER_MUXC2=> "DIVC", PREDIVIDER_MUXC1=>  2, VCO_BYPASS_C0=> "DISABLED", 
        CLKOS2_ENABLE=> "DISABLED", OUTDIVIDER_MUXB2=> "DIVB", 
        PREDIVIDER_MUXB1=>  0, VCO_BYPASS_B0=> "DISABLED", CLKOS_ENABLE=> "DISABLED", 
        OUTDIVIDER_MUXA2=> "DIVA", PREDIVIDER_MUXA1=>  0, VCO_BYPASS_A0=> "DISABLED", 
        CLKOP_ENABLE=> "DISABLED", CLKOS3_DIV=>  1, CLKOS2_DIV=>  50, 
        CLKOS_DIV=>  6, CLKOP_DIV=>  92, CLKFB_DIV=>  3, CLKI_DIV=>  5, 
        FEEDBK_PATH=> "INT_DIVB")
        port map (CLKI=>CLKI, CLKFB=>CLKFB_t, PHASESEL1=>scuba_vlo, 
            PHASESEL0=>scuba_vlo, PHASEDIR=>scuba_vlo, 
            PHASESTEP=>scuba_vlo, LOADREG=>scuba_vlo, STDBY=>scuba_vlo, 
            PLLWAKESYNC=>scuba_vlo, RST=>scuba_vlo, RESETM=>scuba_vlo, 
            RESETC=>scuba_vlo, RESETD=>scuba_vlo, ENCLKOP=>ENCLKOP, 
            ENCLKOS=>ENCLKOS, ENCLKOS2=>ENCLKOS2, ENCLKOS3=>scuba_vlo, 
            PLLCLK=>scuba_vlo, PLLRST=>scuba_vlo, PLLSTB=>scuba_vlo, 
            PLLWE=>scuba_vlo, PLLADDR4=>scuba_vlo, PLLADDR3=>scuba_vlo, 
            PLLADDR2=>scuba_vlo, PLLADDR1=>scuba_vlo, 
            PLLADDR0=>scuba_vlo, PLLDATI7=>scuba_vlo, 
            PLLDATI6=>scuba_vlo, PLLDATI5=>scuba_vlo, 
            PLLDATI4=>scuba_vlo, PLLDATI3=>scuba_vlo, 
            PLLDATI2=>scuba_vlo, PLLDATI1=>scuba_vlo, 
            PLLDATI0=>scuba_vlo, CLKOP=>CLKOP_t, CLKOS=>CLKOS_t, 
            CLKOS2=>CLKOS2_t, CLKOS3=>open, LOCK=>LOCK, INTLOCK=>open, 
            REFCLK=>open, CLKINTFB=>CLKFB_t, DPHSRC=>open, PLLACK=>open, 
            PLLDATO7=>open, PLLDATO6=>open, PLLDATO5=>open, 
            PLLDATO4=>open, PLLDATO3=>open, PLLDATO2=>open, 
            PLLDATO1=>open, PLLDATO0=>open);

    CLKOS2 <= CLKOS2_t;
    CLKOS <= CLKOS_t;
    CLKOP <= CLKOP_t;
end Structure;

-- synopsys translate_off
library MACHXO2;
configuration Structure_CON of pll_1 is
    for Structure
        for all:VLO use entity MACHXO2.VLO(V); end for;
        for all:EHXPLLJ use entity MACHXO2.EHXPLLJ(V); end for;
    end for;
end Structure_CON;

-- synopsys translate_on
