// =====================================================================
//  ____         _                 ____                      
// | __ )  _ __ (_)  __ _  _ __   / ___|  _   _  _ __    ___ 
// |  _ \ | '__|| | / _` || '_ \  \___ \ | | | || '_ \  / _ \
// | |_) || |   | || (_| || | | |  ___) || |_| || | | ||  __/
// |____/ |_|   |_| \__,_||_| |_| |____/  \__,_||_| |_| \___|
// 
// =====================================================================


`timescale 1ns / 1ps

module cs42448_adc (
	
	// 12MHz
	input					sys_clk,
	input					sys_nrst,
	
	input					init_done,
	
	output		[15 : 0]	adc_dout_l0,
	output		[15 : 0]	adc_dout_r0,
	output		[15 : 0]	adc_dout_l1,
	output		[15 : 0]	adc_dout_r1,
	output		[15 : 0]	adc_dout_l2,
	output		[15 : 0]	adc_dout_r2,
	
	// Physical Layer - CS42448
	input					ADC_SDIN_CH0,
	input					ADC_SDIN_CH1,
	input					ADC_SDIN_CH2,
	output					ADC_SCLK,
	output					ADC_LRCK
);
	
	reg		[5 : 0]			adc_divider;
	wire	[3 : 0]			shift_bit;
	
	reg						sclk_r;
	reg						lrck_r;
	
	reg		[19 : 0]	startup_delay;
	reg		[15 : 0]	startup_delay2;
	reg					all_ready;
	reg					all_ready2;
	
	always@(posedge sys_clk)begin
		if(!sys_nrst)begin
			startup_delay <= 'd0;
			all_ready <= 1'b0;
		end else if(init_done)begin
			if(adc_divider == 'd63 && startup_delay < 'd76800)
				startup_delay <= startup_delay + 'd1;
			if(startup_delay >= 'd76800)
				all_ready <= 1'b1;
		end
	end
	
	always@(posedge sys_clk)begin
		if(!sys_nrst)begin
			startup_delay2 <= 'd0;
			all_ready2 <= 1'b0;
		end else if(all_ready)begin
			if(adc_divider == 'd63 && startup_delay2 < 'd2000)
				startup_delay2 <= startup_delay2 + 'd1;
			if(startup_delay2 >= 'd2000)
				all_ready2 <= 1'b1;
		end
	end
	
	always@(posedge sys_clk)begin
		if(!sys_nrst)begin
			adc_divider <= 'd0;
		end else begin
			adc_divider <= adc_divider + 'd1;
		end
	end
	
	always@(posedge sys_clk)begin
		if(!sys_nrst)begin
			lrck_r <= 1'b0;
		end else begin
			if(adc_divider == 'd29)
				lrck_r <= 1'b1;
			else if(adc_divider == 'd61)
				lrck_r <= 1'b0;
		end
	end
	
	
	always@(posedge sys_clk)begin
		if(!sys_nrst)begin
			sclk_r <= 1'b0;
		end else begin
			if(!adc_divider[0])
				sclk_r <= 1'b1;
			else
				sclk_r <= 1'b0;
		end
	end
	
	assign shift_bit = 'd15 - adc_divider[4 : 1];
	
	reg		[15 : 0]	adc_l_d0;
	reg		[15 : 0]	adc_r_d0;
	reg		[15 : 0]	adc_l_d1;
	reg		[15 : 0]	adc_r_d1;
	reg		[15 : 0]	adc_l_d2;
	reg		[15 : 0]	adc_r_d2;
	
	always@(posedge sys_clk)begin
		if(!sys_nrst)begin
			
			adc_l_d0 <= 'd0;
			adc_r_d0 <= 'd0;
			adc_l_d1 <= 'd0;
			adc_r_d1 <= 'd0;
			adc_l_d2 <= 'd0;
			adc_r_d2 <= 'd0;
			
		end else if(!adc_divider[0])begin
			if(adc_divider[5])begin
				adc_r_d0[shift_bit] <= ADC_SDIN_CH0;
				adc_r_d1[shift_bit] <= ADC_SDIN_CH1;
				adc_r_d2[shift_bit] <= ADC_SDIN_CH2;
			end else begin
				adc_l_d0[shift_bit] <= ADC_SDIN_CH0;
				adc_l_d1[shift_bit] <= ADC_SDIN_CH1;
				adc_l_d2[shift_bit] <= ADC_SDIN_CH2;
			end
		end
	end
	
	assign ADC_SCLK = (all_ready) ? sclk_r : 1'b0;
	assign ADC_LRCK = (all_ready) ? lrck_r : 1'b0;
	
	assign adc_dout_l0 = adc_l_d0;
	assign adc_dout_r0 = adc_r_d0;
	assign adc_dout_l1 = adc_l_d1;
	assign adc_dout_r1 = adc_r_d1;
	assign adc_dout_l2 = adc_l_d2;
	assign adc_dout_r2 = adc_r_d2;
	
endmodule
