----Copyright (C) 2017 Jean Wlodarski

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

entity acq_interface is
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
end acq_interface ;

architecture acq_interface_behav of acq_interface is 


begin
	sample_X			<= 	sample_X_acq; 		
	sample_signed_X		<=	sample_signed_X_acq; 	
	sample_Y			<=	sample_Y_acq; 		
	sample_signed_Y		<=	sample_signed_Y_acq; 	
	sample_Z			<=	sample_Z_acq; 		
	sample_signed_Z		<=	sample_signed_Z_acq; 	
	new_sample 			<= 	new_sample_acq;  		
	pen					<=	pen_acq; 					

end acq_interface_behav;
