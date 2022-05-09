// =====================================================================
//  ____         _                 ____                      
// | __ )  _ __ (_)  __ _  _ __   / ___|  _   _  _ __    ___ 
// |  _ \ | '__|| | / _` || '_ \  \___ \ | | | || '_ \  / _ \
// | |_) || |   | || (_| || | | |  ___) || |_| || | | ||  __/
// |____/ |_|   |_| \__,_||_| |_| |____/  \__,_||_| |_| \___|
// 
// =====================================================================


`timescale 1ns / 1ps

module cs42448_dac (
	
	input				sys_clk,
	input				sys_nrst,
	
	input				init_done,
	
	input	[15 : 0]	dac_din_l0,
	input	[15 : 0]	dac_din_r0,
	input	[15 : 0]	dac_din_l1,
	input	[15 : 0]	dac_din_r1,
	input	[15 : 0]	dac_din_l2,
	input	[15 : 0]	dac_din_r2,
	input	[15 : 0]	dac_din_l3,
	input	[15 : 0]	dac_din_r3,
	
	// Output to CS4344
	output				DAC_SDOUT_CH0,
	output				DAC_SDOUT_CH1,
	output				DAC_SDOUT_CH2,
	output				DAC_SDOUT_CH3,
	
	output				DAC_SCLK,
	output				DAC_LRCK
);
	
	// Register used internally
	reg		[5 : 0]			dac_divider;
	wire	[3 : 0]			shift_bit;
	
	reg						sclk_r;
	reg						lrck_r;
	
	reg						sdin_r0;
	reg						sdin_r1;
	reg						sdin_r2;
	reg						sdin_r3;
	
	reg		[19 : 0]	startup_delay;
	reg		[15 : 0]	startup_delay2;
	reg					all_ready;
	reg					all_ready2;
	
	always@(posedge sys_clk)begin
		if(!sys_nrst)begin
			startup_delay <= 'd0;
			all_ready <= 1'b0;
		end else if(init_done)begin
			if(dac_divider == 'd63 && startup_delay < 'd76800)
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
			if(dac_divider == 'd63 && startup_delay2 < 'd2000)
				startup_delay2 <= startup_delay2 + 'd1;
			if(startup_delay2 >= 'd2000)
				all_ready2 <= 1'b1;
		end
	end
	
	always@(posedge sys_clk)begin
		if(!sys_nrst)begin
			dac_divider <= 'd0;
		end else begin
			dac_divider <= dac_divider + 'd1;
		end
	end
	
	always@(posedge sys_clk)begin
		if(!sys_nrst)begin
			lrck_r <= 1'b0;
		end else begin
			if(dac_divider == 'd29)
				lrck_r <= 1'b1;
			else if(dac_divider == 'd61)
				lrck_r <= 1'b0;
		end
	end
	
	
	always@(posedge sys_clk)begin
		if(!sys_nrst)begin
			sclk_r <= 1'b0;
		end else begin
			if(!dac_divider[0])
				sclk_r <= 1'b1;
			else
				sclk_r <= 1'b0;
		end
	end
	
	reg		[15 : 0]	dac_din_l0_r;
	reg		[15 : 0]	dac_din_r0_r;
	reg		[15 : 0]	dac_din_l1_r;
	reg		[15 : 0]	dac_din_r1_r;
	reg		[15 : 0]	dac_din_l2_r;
	reg		[15 : 0]	dac_din_r2_r;
	reg		[15 : 0]	dac_din_l3_r;
	reg		[15 : 0]	dac_din_r3_r;
	
	always@(posedge sys_clk)begin
		if(!sys_nrst)begin
			dac_din_l0_r <= 'd0;
			dac_din_r0_r <= 'd0;
			dac_din_l1_r <= 'd0;
			dac_din_r1_r <= 'd0;
			dac_din_l2_r <= 'd0;
			dac_din_r2_r <= 'd0;
			dac_din_l3_r <= 'd0;
			dac_din_r3_r <= 'd0;
		end else if(dac_divider == 'd61)begin
			dac_din_l0_r <= dac_din_l0;
			dac_din_r0_r <= dac_din_r0;
			dac_din_l1_r <= dac_din_l1;
			dac_din_r1_r <= dac_din_r1;
			dac_din_l2_r <= dac_din_l2;
			dac_din_r2_r <= dac_din_r2;
			dac_din_l3_r <= dac_din_l3;
			dac_din_r3_r <= dac_din_r3;
		end
	end
	
	assign shift_bit = 'd14 - dac_divider[4 : 1];
	
	always@(posedge sys_clk)begin
		if(!sys_nrst)begin
			sdin_r0 <= 1'b0;
			sdin_r1 <= 1'b0;
			sdin_r2 <= 1'b0;
			sdin_r3 <= 1'b0;
		end else if(dac_divider[0])begin
			if(dac_divider[5 : 1] >= 'd15 && dac_divider[5 : 1] < 'd31)begin
				sdin_r0 <= dac_din_r0_r[shift_bit];
				sdin_r1 <= dac_din_r1_r[shift_bit];
				sdin_r2 <= dac_din_r2_r[shift_bit];
				sdin_r3 <= dac_din_r3_r[shift_bit];
			end else begin
				sdin_r0 <= dac_din_l0_r[shift_bit];
				sdin_r1 <= dac_din_l1_r[shift_bit];
				sdin_r2 <= dac_din_l2_r[shift_bit];
				sdin_r3 <= dac_din_l3_r[shift_bit];
			end
		end
	end
	
	assign DAC_SCLK = (all_ready) ? sclk_r : 1'b0;
	assign DAC_LRCK = (all_ready) ? lrck_r : 1'b0;
	
	assign DAC_SDOUT_CH0 = (all_ready2) ? sdin_r0 : 1'b0;
	assign DAC_SDOUT_CH1 = (all_ready2) ? sdin_r1 : 1'b0;
	assign DAC_SDOUT_CH2 = (all_ready2) ? sdin_r2 : 1'b0;
	assign DAC_SDOUT_CH3 = (all_ready2) ? sdin_r3 : 1'b0;
	
endmodule
