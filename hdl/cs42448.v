// =====================================================================
//  ____         _                 ____                      
// | __ )  _ __ (_)  __ _  _ __   / ___|  _   _  _ __    ___ 
// |  _ \ | '__|| | / _` || '_ \  \___ \ | | | || '_ \  / _ \
// | |_) || |   | || (_| || | | |  ___) || |_| || | | ||  __/
// |____/ |_|   |_| \__,_||_| |_| |____/  \__,_||_| |_| \___|
// 
// =====================================================================


`timescale 1ns / 1ps

module cs42448 #(
	parameter clk_freq = 12288
)(
	input				sys_clk,
	input				sys_nrst,
	// ===================================
	output				CS42xx8_DAC_SDOUT0,
	output				CS42xx8_DAC_SDOUT1,
	output				CS42xx8_DAC_SDOUT2,
	output				CS42xx8_DAC_SDOUT3,
	output				CS42xx8_DAC_SCLK,
	output				CS42xx8_DAC_LRCK,
	// ===================================
	input				CS42xx8_ADC_SDIN0,
	input				CS42xx8_ADC_SDIN1,
	input				CS42xx8_ADC_SDIN2,
	output				CS42xx8_ADC_SCLK,
	output				CS42xx8_ADC_LRCK,
	// ===================================
	// Global Clock
	output				CS42xx8_MCLK,
	// ===================================
	// Physical Layer Interface
	output				CS42xx8_SCL,
	inout				CS42xx8_SDA,
	output				CS42xx8_nRST
);
	
	wire	[15 : 0]	forward_w	[5 : 0];
	
	wire	init_done;
	wire	cs_mclk_rdy;
	
	assign CS42xx8_MCLK = (cs_mclk_rdy) ? sys_clk : 1'b0;
	
	cs42448_dac cs42448_dac_u0(
		.sys_clk		(sys_clk),
		.sys_nrst		(sys_nrst),
		
		.init_done		(init_done),
		
		.dac_din_l0		(forward_w[0]),
		.dac_din_r0		(forward_w[1]),
		.dac_din_l1		(forward_w[2]),
		.dac_din_r1		(forward_w[3]),
		.dac_din_l2		(forward_w[4]),
		.dac_din_r2		(forward_w[5]),
		.dac_din_l3		(forward_w[0]),
		.dac_din_r3		(forward_w[1]),
		
		.DAC_SDOUT_CH0	(CS42xx8_DAC_SDOUT0),
		.DAC_SDOUT_CH1	(CS42xx8_DAC_SDOUT1),
		.DAC_SDOUT_CH2	(CS42xx8_DAC_SDOUT2),
		.DAC_SDOUT_CH3	(CS42xx8_DAC_SDOUT3),
		
		.DAC_LRCK		(CS42xx8_DAC_LRCK),
		.DAC_SCLK		(CS42xx8_DAC_SCLK)
	);
	
	cs42448_adc cs42448_adc_u0(
		.sys_clk		(sys_clk),
		.sys_nrst		(sys_nrst),
		
		.init_done		(init_done),
		
		.adc_dout_l0	(forward_w[0]),
		.adc_dout_r0	(forward_w[1]),
		.adc_dout_l1	(forward_w[2]),
		.adc_dout_r1	(forward_w[3]),
		.adc_dout_l2	(forward_w[4]),
		.adc_dout_r2	(forward_w[5]),
		
		.ADC_SDIN_CH0	(CS42xx8_ADC_SDIN0),
		.ADC_SDIN_CH1	(CS42xx8_ADC_SDIN1),
		.ADC_SDIN_CH2	(CS42xx8_ADC_SDIN2),
		
		.ADC_LRCK		(CS42xx8_ADC_LRCK),
		.ADC_SCLK		(CS42xx8_ADC_SCLK)
	);
	
	cs42448_iic #(
		.system_clk_freq	(clk_freq),
		// I2C bps
		.i2c_clk_bps		(1000),
		// slave address
		.cs42448_a0			(1'b1),
		.cs42448_a1			(1'b1)
	)cs42448_u0(
		
		.sys_clk			(sys_clk),
		.sys_nrst			(sys_nrst),
		
		.i2c_rw				(1'b0),
		.i2c_start			(1'b0),
		.ready				(),
		.done				(),
		.init_done			(init_done),
		
		.i2c_ptr			('d0),
		.i2c_wr_byte		('d0),
		.i2c_rd_byte		(),
		
		.cs_mclk_rdy		(cs_mclk_rdy),
		
		.cs_nrst			(CS42xx8_nRST),
		.scl				(CS42xx8_SCL),
		.sda				(CS42xx8_SDA)
	);
	
endmodule
