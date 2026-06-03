## Basys 3 constraints for elevator_top.
## Target FPGA: Xilinx Artix-7 xc7a35tcpg236-1.
## ---------------------------------------------------------------------------

## 100 MHz system clock.
set_property -dict { PACKAGE_PIN W5  IOSTANDARD LVCMOS33 } [get_ports clk100mhz]
create_clock -add -name sys_clk_pin -waveform {0 5} -period 10.00 [get_ports clk100mhz]

## Slide switches assigned to floor request inputs.
##   sw[3:0]  = cab requests
##   sw[7:4]  = hall up requests
##   sw[11:8] = hall down requests
set_property -dict { PACKAGE_PIN V17 IOSTANDARD LVCMOS33 } [get_ports {sw[0]}]
set_property -dict { PACKAGE_PIN V16 IOSTANDARD LVCMOS33 } [get_ports {sw[1]}]
set_property -dict { PACKAGE_PIN W16 IOSTANDARD LVCMOS33 } [get_ports {sw[2]}]
set_property -dict { PACKAGE_PIN W17 IOSTANDARD LVCMOS33 } [get_ports {sw[3]}]
set_property -dict { PACKAGE_PIN W15 IOSTANDARD LVCMOS33 } [get_ports {sw[4]}]
set_property -dict { PACKAGE_PIN V15 IOSTANDARD LVCMOS33 } [get_ports {sw[5]}]
set_property -dict { PACKAGE_PIN W14 IOSTANDARD LVCMOS33 } [get_ports {sw[6]}]
set_property -dict { PACKAGE_PIN W13 IOSTANDARD LVCMOS33 } [get_ports {sw[7]}]
set_property -dict { PACKAGE_PIN V2  IOSTANDARD LVCMOS33 } [get_ports {sw[8]}]
set_property -dict { PACKAGE_PIN T3  IOSTANDARD LVCMOS33 } [get_ports {sw[9]}]
set_property -dict { PACKAGE_PIN T2  IOSTANDARD LVCMOS33 } [get_ports {sw[10]}]
set_property -dict { PACKAGE_PIN R3  IOSTANDARD LVCMOS33 } [get_ports {sw[11]}]

## Push buttons assigned to reset, emergency, and door controls.
set_property -dict { PACKAGE_PIN U17 IOSTANDARD LVCMOS33 } [get_ports btnD] ;# system reset
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports btnC] ;# emergency stop
set_property -dict { PACKAGE_PIN T18 IOSTANDARD LVCMOS33 } [get_ports btnU] ;# emergency reset
set_property -dict { PACKAGE_PIN W19 IOSTANDARD LVCMOS33 } [get_ports btnL] ;# manual door open
set_property -dict { PACKAGE_PIN T17 IOSTANDARD LVCMOS33 } [get_ports btnR] ;# manual door close

## LEDs assigned to movement and door status outputs.
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports {led[0]}] ;# move_up
set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } [get_ports {led[1]}] ;# move_down
set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 } [get_ports {led[2]}] ;# door_open
set_property -dict { PACKAGE_PIN V19 IOSTANDARD LVCMOS33 } [get_ports {led[3]}] ;# door_close

# VGA RGB output pins.
set_property -dict {PACKAGE_PIN N19 IOSTANDARD LVCMOS33 } [get_ports {rgb[11]}]
set_property -dict {PACKAGE_PIN J19 IOSTANDARD LVCMOS33 } [get_ports {rgb[10]}]
set_property -dict {PACKAGE_PIN H19 IOSTANDARD LVCMOS33 } [get_ports {rgb[9]}]

set_property -dict {PACKAGE_PIN G19 IOSTANDARD LVCMOS33 } [get_ports {rgb[8]}]
set_property -dict {PACKAGE_PIN D17 IOSTANDARD LVCMOS33 } [get_ports {rgb[7]}]
set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS33 } [get_ports {rgb[6]}]

set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33 } [get_ports {rgb[5]}]
set_property -dict {PACKAGE_PIN J17 IOSTANDARD LVCMOS33 } [get_ports {rgb[4]}]
set_property -dict {PACKAGE_PIN J18 IOSTANDARD LVCMOS33 } [get_ports {rgb[3]}]

set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33 } [get_ports {rgb[2]}]
set_property -dict {PACKAGE_PIN L18 IOSTANDARD LVCMOS33 } [get_ports {rgb[1]}]
set_property -dict {PACKAGE_PIN N18 IOSTANDARD LVCMOS33 } [get_ports {rgb[0]}]


# VGA synchronization output pins.
set_property -dict {PACKAGE_PIN P19 IOSTANDARD LVCMOS33 } [get_ports {hsync}]
set_property -dict {PACKAGE_PIN R19 IOSTANDARD LVCMOS33 } [get_ports {vsync}]
