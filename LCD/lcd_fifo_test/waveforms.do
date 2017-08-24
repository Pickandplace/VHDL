onerror { resume }
transcript off
add wave -noreg -hexadecimal -literal {/top/red_io}
add wave -noreg -hexadecimal -literal {/top/green_io}
add wave -noreg -hexadecimal -literal {/top/blue_io}
add wave -noreg -logic {/top/hsync_io}
add wave -noreg -logic {/top/vsync_io}
add wave -noreg -logic {/top/de_io}
add wave -noreg -logic {/top/clk_io}
add wave -noreg -decimal -literal {/top/lcd_0/h_pixel_vector}
add wave -noreg -decimal -literal {/top/lcd_0/v_pixel_vector}
add wave -noreg -decimal -literal {/top/pixel_vector}
add wave -noreg -decimal -literal {/top/fifo_d}
add wave -noreg -logic {/top/fifo_wr}
add wave -noreg -logic {/top/fifo_rd}
add wave -noreg -logic {/top/fifo_Reset}
add wave -noreg -decimal -literal {/top/fifo_Q}
add wave -noreg -logic {/top/fifo_Empty}
add wave -noreg -logic {/top/fifo_Full}
add wave -noreg -logic {/top/lcd_0/hsync}
add wave -noreg -logic {/top/lcd_0/vsync}
add wave -noreg -logic {/top/lcd_0/de}
cursor "Cursor 1" 658229898ps  
transcript on
