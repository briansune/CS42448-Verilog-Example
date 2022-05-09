# ======================================================================
# 
#  ____         _                 ____                      
# | __ )  _ __ (_)  __ _  _ __   / ___|  _   _  _ __    ___ 
# |  _ \ | '__|| | / _` || '_ \  \___ \ | | | || '_ \  / _ \
# | |_) || |   | || (_| || | | |  ___) || |_| || | | ||  __/
# |____/ |_|   |_| \__,_||_| |_| |____/  \__,_||_| |_| \___|
#
# ======================================================================

# ======================================================================
set_property IOSTANDARD LVCMOS33 [get_ports sys_nrst]
set_property IOSTANDARD LVCMOS33 [get_ports sys_clk]
set_property PACKAGE_PIN H11 [get_ports sys_clk]
set_property PACKAGE_PIN C5 [get_ports sys_nrst]
# ======================================================================
set_property SLEW SLOW [get_ports CS42xx8_SDA]
set_property IOSTANDARD LVCMOS33 [get_ports CS42xx8_SDA]
set_property DRIVE 4 [get_ports CS42xx8_SDA]
set_property PACKAGE_PIN B5 [get_ports CS42xx8_SDA]
# ======================================================================
set_property SLEW SLOW [get_ports CS42xx8_SCL]
set_property IOSTANDARD LVCMOS33 [get_ports CS42xx8_SCL]
set_property DRIVE 4 [get_ports CS42xx8_SCL]
set_property PACKAGE_PIN A5 [get_ports CS42xx8_SCL]
# ======================================================================
set_property IOSTANDARD LVCMOS33 [get_ports CS42xx8_nRST]
set_property DRIVE 4 [get_ports CS42xx8_nRST]
set_property PACKAGE_PIN D3 [get_ports CS42xx8_nRST]
# ======================================================================
set_property IOSTANDARD LVCMOS33 [get_ports CS42xx8_MCLK]
set_property DRIVE 4 [get_ports CS42xx8_MCLK]
set_property PACKAGE_PIN C3 [get_ports CS42xx8_MCLK]
# ======================================================================
set_property IOSTANDARD LVCMOS33 [get_ports CS42xx8_DAC_SCLK]
set_property DRIVE 4 [get_ports CS42xx8_DAC_SCLK]
set_property PACKAGE_PIN A4 [get_ports CS42xx8_DAC_SCLK]
# ======================================================================
set_property IOSTANDARD LVCMOS33 [get_ports CS42xx8_DAC_LRCK]
set_property DRIVE 4 [get_ports CS42xx8_DAC_LRCK]
set_property PACKAGE_PIN A3 [get_ports CS42xx8_DAC_LRCK]
# ======================================================================
set_property IOSTANDARD LVCMOS33 [get_ports CS42xx8_DAC_SDOUT0]
set_property DRIVE 4 [get_ports CS42xx8_DAC_SDOUT0]
set_property PACKAGE_PIN A2 [get_ports CS42xx8_DAC_SDOUT0]
# ======================================================================



set_property IOSTANDARD LVCMOS33 [get_ports CS42xx8_ADC_LRCK]
set_property DRIVE 4 [get_ports CS42xx8_ADC_LRCK]
set_property PACKAGE_PIN B3 [get_ports CS42xx8_ADC_LRCK]
# ======================================================================
set_property IOSTANDARD LVCMOS33 [get_ports CS42xx8_ADC_SCLK]
set_property DRIVE 4 [get_ports CS42xx8_ADC_SCLK]
set_property PACKAGE_PIN E4 [get_ports CS42xx8_ADC_SCLK]
# ======================================================================
set_property IOSTANDARD LVCMOS33 [get_ports CS42xx8_ADC_SDIN0]
set_property PACKAGE_PIN D4 [get_ports CS42xx8_ADC_SDIN0]
# ======================================================================
