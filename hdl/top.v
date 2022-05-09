// =====================================================================
//  ____         _                 ____                      
// | __ )  _ __ (_)  __ _  _ __   / ___|  _   _  _ __    ___ 
// |  _ \ | '__|| | / _` || '_ \  \___ \ | | | || '_ \  / _ \
// | |_) || |   | || (_| || | | |  ___) || |_| || | | ||  __/
// |____/ |_|   |_| \__,_||_| |_| |____/  \__,_||_| |_| \___|
// 
// =====================================================================


`timescale 1ns / 1ps

module top(
	input		sys_clk,
	input		sys_nrst,
	// ===================================
	output		CS42xx8_DAC_SDOUT0,
	output		CS42xx8_DAC_SCLK,
	output		CS42xx8_DAC_LRCK,
	// ===================================
	input		CS42xx8_ADC_SDIN0,
	output		CS42xx8_ADC_SCLK,
	output		CS42xx8_ADC_LRCK,
	// ===================================
	// Global Clock
	output		CS42xx8_MCLK,
	// ===================================
	// Physical Layer Interface
	output		CS42xx8_SCL,
	inout		CS42xx8_SDA,
	output		CS42xx8_nRST
);
	
	wire		glb_clk;
	
	sys_pll pll_u0(
		.clk_out1	(glb_clk),
		.resetn		(sys_nrst),
		.clk_in1	(sys_clk)
	);
	
	cs42448 cs42448_u0(
		.sys_clk				(glb_clk),
		.sys_nrst				(sys_nrst),
		
		.CS42xx8_nRST			(CS42xx8_nRST),
		.CS42xx8_SDA			(CS42xx8_SDA),
		.CS42xx8_SCL			(CS42xx8_SCL),
		
		.CS42xx8_MCLK			(CS42xx8_MCLK),
		
		.CS42xx8_ADC_SDIN0		(CS42xx8_ADC_SDIN0),
		.CS42xx8_ADC_LRCK		(CS42xx8_ADC_LRCK),
		.CS42xx8_ADC_SCLK		(CS42xx8_ADC_SCLK),
		
		.CS42xx8_DAC_SDOUT0		(CS42xx8_DAC_SDOUT0),
		.CS42xx8_DAC_LRCK		(CS42xx8_DAC_LRCK),
		.CS42xx8_DAC_SCLK		(CS42xx8_DAC_SCLK)
	);
	
endmodule
