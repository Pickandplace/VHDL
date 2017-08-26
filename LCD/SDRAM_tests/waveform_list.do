onerror { resume }
transcript off
add wave -noreg -literal {/testbench/top_comp/state}
add wave -noreg -decimal -literal -signed2 {/testbench/top_comp/refresh_counter}
add wave -noreg -hexadecimal -literal {/testbench/top_comp/addr_sdr}
add wave -noreg -hexadecimal -literal {/testbench/top_comp/data_to_sdr}
add wave -noreg -logic {/testbench/top_comp/sdr_ready}
add wave -noreg -logic {/testbench/top_comp/sdr_done}
add wave -noreg -hexadecimal -literal {/testbench/top_comp/data_from_sdr}
add wave -noreg -hexadecimal -literal {/testbench/top_comp/compare_val}
add wave -noreg -logic {/testbench/top_comp/rw_sdr}
add wave -noreg -logic {/testbench/top_comp/we_sdr_n}
add wave -noreg -logic {/testbench/top_comp/refresh_sdr}
cursor "Cursor 1" 0ps  
transcript on
