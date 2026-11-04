
# Xac dinh thu muc du an
if {[file exists RX/i2s_rx.v]} {
    # Dang o thu muc goc
} elseif {[file exists ../RX/i2s_rx.v]} {
    # Dang o thu muc sim
    cd ..
} else {
    error "Khong tim thay du an. Hay cd vao thu muc goc hoac sim."
}

# Tao thu vien ModelSim
if {![file isdirectory work]} {
    vlib work
}
vmap work work

# Bien dich
vlog -work work RX/i2s_rx.v
vlog -work work TX/i2s_tx.v
vlog -work work sim/tb_i2s_loopback.v

# Khoi dong mo phong
vsim work.tb_i2s_loopback

# Hien thi tin hieu
add wave -r sim:/tb_i2s_loopback/*

# Chay mo phong
run -all
wave zoomrange 20000ns 65000ns
