-- VHDL module instantiation generated by SCUBA Diamond Version 3.9.1.119
-- Module  Version: 5.8
-- Sun Sep 17 18:21:30 2017

-- parameterized module component declaration
component fifo_acq
    port (Data: in  std_logic_vector(24 downto 0); 
        WrClock: in  std_logic; RdClock: in  std_logic; 
        WrEn: in  std_logic; RdEn: in  std_logic; Reset: in  std_logic; 
        RPReset: in  std_logic; Q: out  std_logic_vector(24 downto 0); 
        Empty: out  std_logic; Full: out  std_logic; 
        AlmostEmpty: out  std_logic; AlmostFull: out  std_logic);
end component;

-- parameterized module component instance
__ : fifo_acq
    port map (Data(24 downto 0)=>__, WrClock=>__, RdClock=>__, WrEn=>__, 
        RdEn=>__, Reset=>__, RPReset=>__, Q(24 downto 0)=>__, Empty=>__, 
        Full=>__, AlmostEmpty=>__, AlmostFull=>__);
