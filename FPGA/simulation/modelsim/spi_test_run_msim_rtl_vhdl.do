transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+C:/GitHub/ELEC241-P1-2022/FPGA {C:/GitHub/ELEC241-P1-2022/FPGA/registerN.sv}
vlog -sv -work work +incdir+C:/GitHub/ELEC241-P1-2022/FPGA {C:/GitHub/ELEC241-P1-2022/FPGA/led_reg_controller.sv}
vlog -sv -work work +incdir+C:/GitHub/ELEC241-P1-2022/FPGA {C:/GitHub/ELEC241-P1-2022/FPGA/display_controller.sv}
vcom -93 -work work {C:/GitHub/ELEC241-P1-2022/lib/spi_bhm.vhd}

