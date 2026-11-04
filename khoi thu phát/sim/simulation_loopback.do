cd [file dirname [file normalize [info script]]]
if {![file isdirectory work]} {
    vlib work
}
vmap work work
vlog -work work i2s_rx.v
vlog -work work i2s_tx.v
vlog -work work tb_i2s_loopback.v
vsim work.tb_i2s_loopback
add wave sim:/tb_i2s_loopback/clk
add wave sim:/tb_i2s_loopback/rst_n
add wave sim:/tb_i2s_loopback/bclk
add wave sim:/tb_i2s_loopback/ws
add wave sim:/tb_i2s_loopback/mic_sd
add wave -radix hexadecimal sim:/tb_i2s_loopback/rx_data
add wave sim:/tb_i2s_loopback/rx_valid
add wave sim:/tb_i2s_loopback/speaker_sd
run -all
wave zoomrange 20000ns 65000ns
