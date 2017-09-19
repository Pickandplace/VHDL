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

entity fifo_acq is
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
	AlmostFull: out  std_logic
		);
end fifo_acq;

architecture Behavioral4 of fifo_acq is
COMPONENT fifo_acq_x
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(24 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(24 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    prog_full : OUT STD_LOGIC;
    prog_empty : OUT STD_LOGIC
  );
END COMPONENT;
begin
fifo_c : fifo_acq_x
  PORT MAP (
    rst => Reset,
    wr_clk => WrClock,
    rd_clk => RdClock,
    din => Data,
    wr_en => WrEn,
    rd_en => RdEn,
    dout => Q,
    full => Full,
    empty => empty,
    prog_full => AlmostFull,
    prog_empty => AlmostEmpty
  );

end Behavioral4;