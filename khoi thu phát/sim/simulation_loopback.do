
cd [file dirname [file normalize [info script]]]

if {![file isdirectory work]} {
    vlib work
}
vmap work work

vlog -work work ../thu/i2s_rx.v
vlog -work work ../phát/i2s_tx.v
vlog -work work tb_i2s_loopback.v

vsim work.tb_i2s_loopback

add wave -r sim:/tb_i2s_loopback/*

run -all
wave zoomrange 20000ns 65000ns
