//=============================================================
// 	Engineer:				Brian Sune
//	File:					cs42448.v
//	
//=============================================================

module cs42448_iic #(
	// System clock frequency in kHz
	parameter system_clk_freq = 200000,
	// I2C bps
	parameter i2c_clk_bps = 100000,
	// slave address
	parameter	[0 : 0]	cs42448_a0 = 1'b1,
	parameter	[0 : 0]	cs42448_a1 = 1'b1,
	
	parameter	[0 : 0]	cs42448_dac0 = 1'b0,
	parameter	[0 : 0]	cs42448_dac1 = 1'b0,
	parameter	[0 : 0]	cs42448_dac2 = 1'b0,
	parameter	[0 : 0]	cs42448_dac3 = 1'b0,
	
	parameter	[0 : 0]	cs42448_adc0 = 1'b0,
	parameter	[0 : 0]	cs42448_adc1 = 1'b0,
	parameter	[0 : 0]	cs42448_adc2 = 1'b0
)(
	
	input			sys_clk,
	input 			sys_nrst,
	
	// read / write = 1 / 0
	input			i2c_rw,
	input			i2c_start,
	output			ready,
	output			done,
	
	output			init_done,
	
	input	[6 : 0]		i2c_ptr,
	input	[7 : 0]		i2c_wr_byte,
	output	[7 : 0]		i2c_rd_byte,
	
	// Physical Layer Interface
	output			scl,
	inout			sda,
	output			cs_nrst,
	output			cs_mclk_rdy
);
	
	
	// =========================================================
	//	Write Explain
	// =========================================================
	//
	//        Address           Pointer          DATA
	// 	 |S|1 0 0 1 0 A A 0|I P P P P P P P|D D D D D D D D|
	// 	 | |          1 0  |N 6 5 4 3 2 1 0|7 6 5 4 3 2 1 0|
	// 	 | |               |C              |               |
	// 	
	// =========================================================
	
	// =========================================================
	//	Read Explain
	// =========================================================
	//
	//        Address           Pointer          Address    		DATA
	// 	 |S|1 0 0 1 0 A A 0|I P P P P P P P|S|1 0 0 1 0 A A 1|D D D D D D D D|
	// 	 | |          1 0  |N 6 5 4 3 2 1 0| |            1 0|7 6 5 4 3 2 1 0|
	// 	 | |               |C              | |               |               |
	// 	
	// =========================================================
	
	// =========================================================
	// local parameter
	// =========================================================
	localparam clock_cnt_setup = (system_clk_freq * 1000) / i2c_clk_bps / 5;
	localparam limit_setup1 = clock_cnt_setup;
	localparam limit_setup2 = clock_cnt_setup*2;
	localparam limit_setup3 = clock_cnt_setup*3;
	localparam limit_setup4 = clock_cnt_setup*4;
	localparam limit_setup5 = (clock_cnt_setup*5) - 1;
	
	// 7 bit slave address
	localparam cs42448_saddr = {5'b1001_0, cs42448_a1, cs42448_a0};
	
	localparam	wr_start			= 0,
				rd_restart			= wr_start + 1,
				wr_slave_addr		= rd_restart + 1,
				// --------------------------------------------
				wr_pointer			= wr_slave_addr + 1,
				w_byte				= wr_pointer + 1,
				// --------------------------------------------
				r_byte				= w_byte + 1,
				r_latch				= r_byte + 1,
				// --------------------------------------------
				wr_stop_bit			= r_latch + 1,
				wr_end_pulse		= wr_stop_bit + 1,
				wr_end_return		= wr_end_pulse + 1,
				// --------------------------------------------
				wr_data_bit0		= wr_end_return + 1,
				wr_data_bit1		= wr_data_bit0 + 1,
				wr_data_bit2		= wr_data_bit1 + 1,
				wr_data_bit3		= wr_data_bit2 + 1,
				wr_data_bit4		= wr_data_bit3 + 1,
				wr_data_bit5		= wr_data_bit4 + 1,
				wr_data_bit6		= wr_data_bit5 + 1,
				wr_data_bit7		= wr_data_bit6 + 1,
				// --------------------------------------------
				r_ack_set			= wr_data_bit7 + 1,
				// --------------------------------------------
				w_ack_get			= r_ack_set + 1,
				w_ack_check			= w_ack_get + 1;
	// =========================================================
	
	reg		[5 : 0]		next_stage;
	reg		[5 : 0]		store_stage;
	
	reg		[19 : 0]	sclk_cnt;
	
	reg		[19 : 0]	sclk_limit1;
	reg		[19 : 0]	sclk_limit2;
	reg		[19 : 0]	sclk_limit3;
	reg		[19 : 0]	sclk_limit4;
	reg		[19 : 0]	sclk_limit5;
	
	reg		[7 : 0]		tmp_r;
	
	reg					scl_r;
	reg					sda_r;
	wire				sda_in;
	
	reg					ack_r;
	reg					done_r;
	reg					io_sel_r;
	
	reg					ready_r;
	
	reg					wr_latch;
	reg					rd_latch;
	
	reg					addr_w;
	
	// =========================================================
	// Memory Map
	// =========================================================
	reg		[7 : 0]		mem_load	[21 : 0];
	
	initial begin
		// start at 02H
		mem_load[0] = {	cs42448_adc2, cs42448_adc1, cs42448_adc0, 
						cs42448_dac3, cs42448_dac2, cs42448_dac1, cs42448_dac0 ,1'b1};
		// -----------------------------------------------------
		// ADC and DAC sample rate, clock input rate - 03H
		mem_load[1] = 8'b11_11_000_0;
		// interface, freeze, aux format, adc, dac format - 04H
		mem_load[2] = 8'b0_1_001_001;
		// 05H
		mem_load[3] = 8'b0_0_0_000_0_0;
		// 06H, volume. change
		mem_load[4] = 8'b0_00_0_0_0_00;
		// 07H, mute
		mem_load[5] = 8'h00;
		// 07H, volume
		mem_load[6] = 8'h00;
		mem_load[7] = 8'h00;
		mem_load[8] = 8'h00;
		mem_load[9] = 8'h00;
		mem_load[10] = 8'h00;
		mem_load[11] = 8'h00;
		mem_load[12] = 8'h00;
		mem_load[13] = 8'h00;
		// 10H DAC inv
		mem_load[14] = 8'h00;
		// 11H ADC volume
		mem_load[15] = 8'h00;
		mem_load[16] = 8'h00;
		mem_load[17] = 8'h00;
		mem_load[18] = 8'h00;
		mem_load[19] = 8'h00;
		mem_load[20] = 8'h00;
		// 17H ADC inv
		mem_load[21] = 8'h00;
	end
	
	
	IOBUF #(
		.DRIVE			(4),
		.IBUF_LOW_PWR	("FALSE"),
		.IOSTANDARD		("LVCMOS33"),
		.SLEW			("SLOW")
	)IOBUF_IIC_SDA(
		.O	(sda_in),	// Buffer output
		.IO	(sda),		// Buffer inout port (connect directly to top-level port)
		.I	(sda_r),	// Buffer input
		.T	(io_sel_r)	// 3-state enable input, high=input, low=output
	);
	
	OBUF #(
		.DRIVE		(4),
		.IOSTANDARD	("LVCMOS33"),
		.SLEW		("SLOW")
	)IOBUF_IIC_SCL(
		.O	(scl),	// Buffer output (connect directly to top-level port)
		.I	(scl_r)	// Buffer input
	);
	
	reg		[3 : 0]		startup_fsm;
	reg					startup_ld;
	reg					startup_rw;
	
	reg					cs_nrst_r;
	reg					cs_mclk_r;
	
	assign cs_nrst = cs_nrst_r;
	assign cs_mclk_rdy = cs_mclk_r;
	
	reg		[6 : 0]		ptr_ld;
	reg		[7 : 0]		byte_ld;
	reg		[4 : 0]		mem_ptr;
	
	reg		[11 : 0]	stable_cnt;
	
	always@(posedge sys_clk or negedge sys_nrst)begin
		if(!sys_nrst)begin
			
			cs_nrst_r <= 1'b0;
			cs_mclk_r <= 1'b0;
			stable_cnt <= 'd0;
			
			startup_ld <= 1'b0;
			startup_rw <= 1'b0;
			startup_fsm <= 'd0;
			
			ptr_ld <= 7'd0;
			byte_ld <= 8'd0;
			mem_ptr <= 5'd0;
		end else begin
			case(startup_fsm)
				
				0: begin
					cs_nrst_r <= 1'b0;
					stable_cnt <= stable_cnt + 'd1;
					if(stable_cnt == {12{1'b1}})begin
						cs_nrst_r <= 1'b1;
						stable_cnt <= 'd0;
						startup_fsm <= startup_fsm + 'd1;
					end
				end
				
				1: begin
					startup_rw <= 1'b1;
					ptr_ld <= 7'd1;
					startup_ld <= 1'b1;
					if(!ready_r)
						startup_fsm <= startup_fsm + 'd1;
				end
				
				2: begin
					startup_ld <= 1'b0;
					if(ready_r)begin
						ptr_ld <= ptr_ld + 'd1;
						startup_fsm <= startup_fsm + 'd1;
					end
				end
				
				3: begin
					byte_ld <= mem_load[mem_ptr];
					startup_ld <= 1'b1;
					startup_rw <= 1'b0;
					if(!ready_r)
						startup_fsm <= startup_fsm + 'd1;
				end
				
				4: begin
					startup_ld <= 1'b0;
					if(ready_r)begin
						if(mem_ptr == 'd21)begin
							startup_fsm <= startup_fsm + 'd1;
							startup_rw <= 1'b0;
							ptr_ld <= 7'd1;
						end else begin
							mem_ptr <= mem_ptr + 'd1;
							ptr_ld <= ptr_ld + 'd1;
							startup_fsm <= startup_fsm - 'd1;
						end
					end
				end
				
				5: begin
					startup_rw <= 1'b1;
					startup_ld <= 1'b1;
					if(!ready_r)
						startup_fsm <= startup_fsm + 'd1;
				end
				
				6: begin
					startup_ld <= 1'b0;
					if(ready_r)begin
						if(ptr_ld == 'd21)begin
							startup_fsm <= startup_fsm + 'd1;
						end else begin
							ptr_ld <= ptr_ld + 'd1;
							startup_fsm <= startup_fsm - 'd1;
						end
					end
				end
				
				7: begin
					ptr_ld <= 7'd2;
					// PDN = 1
					byte_ld <= {cs42448_adc2, cs42448_adc1, cs42448_adc0, 
								cs42448_dac3, cs42448_dac2, cs42448_dac1, cs42448_dac0 ,1'b0};
					// -----------------------------------------------------
					
					stable_cnt <= stable_cnt + 'd1;
					if(stable_cnt == {6{1'b1}})begin
						startup_ld <= 1'b1;
						cs_mclk_r <= 1'b1;
					end
					
					startup_rw <= 1'b0;
					if(!ready_r)
						startup_fsm <= startup_fsm + 'd1;
				end
				
				8: begin
					startup_ld <= 1'b0;
					if(ready_r)begin
						startup_fsm <= startup_fsm + 'd1;
					end
				end
				
				// normal opeartion
				9: begin
					mem_ptr <= i2c_ptr;
					byte_ld <= i2c_wr_byte;
				end
				
			endcase
		end
	end
	
	assign init_done = (startup_fsm == 'd9);
	
	reg		[7 : 0]		byte_latch;
	
	// =========================================================
	// Signal feed out
	// =========================================================
	assign done			= done_r & init_done;
	assign ready		= ready_r & init_done;
	assign i2c_rd_byte	= byte_latch;
	
	reg		rd_flag;
	reg		rd_last;
	
	always@(posedge sys_clk or negedge sys_nrst)begin
		
		if(!sys_nrst)begin
			
			next_stage <= 'd0;
			store_stage <= 'd0;
			sclk_cnt <= 'd0;
			
			sclk_limit1 <= limit_setup1;
			sclk_limit2 <= limit_setup2;
			sclk_limit3 <= limit_setup3;
			sclk_limit4 <= limit_setup4;
			sclk_limit5 <= limit_setup5;
			
			tmp_r <= 8'd0;
			byte_latch <= 8'd0;
			
			rd_flag <= 1'b0;
			
			scl_r <= 1'b1;
			sda_r <= 1'b1;
			
			ack_r <= 1'b1;
			done_r <= 1'b0;
			io_sel_r <= 1'b0;
			
			ready_r <= 1'b1;
			
			wr_latch <= 1'b0;
			rd_latch <= 1'b0;
			
			addr_w <= 1'b0;
			rd_last <= 1'b0;
			
		end else begin
			
			//I2C data write 
			if(i2c_start | startup_ld | (wr_latch ^ rd_latch))begin
				case(next_stage)
					//send IIC start signal
					wr_start: begin
						
						if(sclk_cnt == 0)
							
							if(!(wr_latch | rd_latch))begin
								
								rd_flag <= 1'b0;
								
								if(startup_ld)begin
									wr_latch <= !startup_rw;
									rd_latch <= startup_rw;
								end else begin
									wr_latch <= !i2c_rw;
									rd_latch <= i2c_rw;
								end
							end
							ready_r <= 1'b0;
						
						io_sel_r <= 1'b0;
						
						if(sclk_cnt == 0)
							scl_r <= 1'b1;
						if(sclk_cnt == sclk_limit4)
							scl_r <= 1'b0;
						
						if(sclk_cnt == 0)
							sda_r <= 1'b1;
						if(sclk_cnt == sclk_limit1)
							sda_r <= 1'b0;
						
						if(sclk_cnt == sclk_limit5)begin
							sclk_cnt <= 'd0;
							
							next_stage <= wr_slave_addr;
						end else begin
							sclk_cnt <= sclk_cnt + 1'b1;
						end
					end
					
					wr_slave_addr: begin
						if(rd_latch & rd_flag)
							tmp_r <= {cs42448_saddr, 1'b1};
						else
							tmp_r <= {cs42448_saddr, 1'b0};
						
						if(sclk_cnt == sclk_limit1)begin
							sclk_cnt <= 'd0;
							next_stage <= wr_data_bit0;
						end else begin
							sclk_cnt <= sclk_cnt + 1'b1;
						end
						
						if(rd_flag)begin
							store_stage <= r_byte;
						end else begin
							store_stage <= wr_pointer;
						end
						
						addr_w <= 1'b1;
						io_sel_r <= 1'b0;
					end
					
					wr_pointer: begin
						tmp_r <= {1'b0, ptr_ld};
						next_stage <= wr_data_bit0;
						
						if(rd_latch)
							store_stage <= wr_stop_bit;
						else
							store_stage <= w_byte;
						
						io_sel_r <= 1'b0;
					end
					
					w_byte: begin
						tmp_r <= byte_ld;
						next_stage <= wr_data_bit0;
						store_stage <= wr_stop_bit;
						
						io_sel_r <= 1'b0;
					end
					
					r_byte: begin
						next_stage <= wr_data_bit0;
						store_stage <= r_latch;
						rd_last <= 1'b1;
						
						io_sel_r <= 1'b1;
					end
					
					r_latch: begin
						byte_latch <= tmp_r;
						next_stage <= wr_stop_bit;
					end
					
					wr_stop_bit: begin
						io_sel_r <= 1'b0;
						
						if(sclk_cnt == 0)
							scl_r <= 1'b0;
						//scl first change from low to high 
						if(sclk_cnt == sclk_limit1)
							scl_r <= 1'b1;
						
						if(sclk_cnt == 0)
							sda_r <= 1'b0;
						//sda low to high 
						if(sclk_cnt == sclk_limit4)
							sda_r <= 1'b1;
						
						if(sclk_cnt == sclk_limit5)begin
							sclk_cnt <= 'd0;
							
							sclk_limit1 <= limit_setup1;
							sclk_limit2 <= clock_cnt_setup << 1;
							sclk_limit3 <= (clock_cnt_setup << 1) + clock_cnt_setup;
							sclk_limit4 <= clock_cnt_setup << 2;
							sclk_limit5 <= (clock_cnt_setup << 2) + clock_cnt_setup;
							
							next_stage <= wr_end_pulse;
						end else
							sclk_cnt <= sclk_cnt + 1'b1;
					end
					
					wr_end_pulse: begin
						if(sclk_cnt == sclk_limit1)begin
							sclk_cnt <= 'd0;
							
							if(rd_latch & !rd_flag)begin
								next_stage <= wr_start;
								rd_flag <= 1'b1;
							end else begin
								done_r <= 1'b1;
								next_stage <= wr_end_return;
							end
						end else begin
							sclk_cnt <= sclk_cnt + 1'b1;
						end
					end
					
					wr_end_return: begin
						rd_flag <= 1'b0;
						done_r <= 1'b0;
						ready_r <= 1'b1;
						next_stage <= 'd0;
						wr_latch <= 1'b0;
						rd_latch <= 1'b0;
					end
					
					//send Device Addr/Word Addr/Write Data
					wr_data_bit0, wr_data_bit1,
					wr_data_bit2, wr_data_bit3,
					wr_data_bit4, wr_data_bit5,
					wr_data_bit6, wr_data_bit7: begin
						
						if(wr_latch | addr_w | (rd_latch & !rd_flag))
							sda_r <= tmp_r[wr_data_bit7-next_stage];
						else
							sda_r <= 1'b1;
						
						if( (sclk_cnt == sclk_limit2) && (rd_latch & rd_flag))begin
							tmp_r[wr_data_bit7-next_stage] <= sda_in;
						end
						
						if(sclk_cnt == 0)
							scl_r <= 1'b0;
						if(sclk_cnt == sclk_limit1)
							scl_r <= 1'b1;
						if(sclk_cnt == sclk_limit3)
							scl_r <= 1'b0;
						
						if(sclk_cnt == sclk_limit5)begin
							sclk_cnt <= 'd0;
							
							if(next_stage == wr_data_bit7)
								if(wr_latch | addr_w | (rd_latch & !rd_flag))
									next_stage <= w_ack_get;
								else
									next_stage <= r_ack_set;
							else
								next_stage <= next_stage + 1;
							
						end else begin
							sclk_cnt <= sclk_cnt + 1'b1;
						end
					end
					
					r_ack_set: begin
						io_sel_r <= 1'b0;
						sda_r <= rd_last;
						
						if(sclk_cnt == 0)
							scl_r <= 1'b0;
						if(sclk_cnt == sclk_limit1)
							scl_r <= 1'b1;
						if(sclk_cnt == sclk_limit3)
							scl_r <= 1'b0;
						
						if(sclk_cnt == sclk_limit5)begin
							sclk_cnt <= 'd0;
							rd_last <= 1'b0;
							next_stage <= store_stage;
						end else begin
							sclk_cnt <= sclk_cnt + 1'b1;
						end
					end
					
					w_ack_get: begin
						io_sel_r <= 1'b1;
						addr_w <= 1'b0;
						
						if(sclk_cnt == sclk_limit2)begin
							ack_r <= sda_in;
						end
						
						if(sclk_cnt == 0)
							scl_r <= 1'b0;
						if(sclk_cnt == sclk_limit1)
							scl_r <= 1'b1;
						if(sclk_cnt == sclk_limit3)
							scl_r <= 1'b0;
						
						if(sclk_cnt == sclk_limit5)begin
							sclk_cnt <= 'd0;
							next_stage <= w_ack_check;
						end else begin
							sclk_cnt <= sclk_cnt + 1'b1;
						end
					end
					
					w_ack_check: begin
						if(ack_r != 0)begin
							next_stage <= 'd0;
							ready_r <= 1'b1;
						end else begin
							next_stage <= store_stage;
						end
					end
				endcase
				
			end
		end
	end
	
endmodule
