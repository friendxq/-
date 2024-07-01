/*-------------------------------------------------------------------------
This confidential and proprietary software may be only used as authorized
by a licensing agreement from cheerchips.
(C) COPYRIGHT 2013.www.cheerchips.com ALL RIGHTS RESERVED
Filename			:		bicintp_ram.v
Author				:		maggie
Data				:		2021-02-1
Version				:		1.0
Description			:		
Modification History	:
Data			By			Version			Change Description
===========================================================================
21/02/1
--------------------------------------------------------------------------*/

`timescale 1 ns / 1 ns
module bicintp_ram
	( 
	//global clock
	sys_clk						,				
	sys_rstn					,				
	
	//cmos_top io
	clk_cmos	,
	cmos_data					,
	cmos_vld			,
	cmos_hsync					,  
	cmos_vsync			,
	
	
	//bicintp_eng  io
	cmos_ram_ready		,   //sdram_vga_ram ini done
	cmos_ram_rd_enb	,
	cmos_ram_rd_addr,	
	cmos_ram_rd_sel,
	
	// bicintp_cal io
	p0,
	p1,
	p2,
	p3

	);
	//global clock
	input											sys_clk   ;		//系统时钟，125M
	input 										sys_rstn  ;		//全局复位
	
	//cmos_top io
	input											clk_cmos   ;  //cmos时钟 78.125M
	input  [15:0]							cmos_data  ;
	input											cmos_vld   ;
	input											cmos_hsync ;  
	input											cmos_vsync ;
		
	//bicintp_eng io
	output										cmos_ram_ready;   //bicintp_ram内4行原始数据已准备好供新的一行插值放大
	input											cmos_ram_rd_enb	;
	input  [9:0]							cmos_ram_rd_addr;	
	input  										cmos_ram_rd_sel;  //即将插值放大的某行数据需要新的4行原始数据，1T高电平有效。
	
		
	// bicintp_cal io，
	output  [15:0]						p0	; 
	output  [15:0]						p1	;
	output  [15:0]						p2	;
	output  [15:0]						p3	;
	
	reg  [15:0]								p0	;
	reg  [15:0]								p1	;
	reg  [15:0]								p2	;
	reg  [15:0]								p3	;
	
	//clk_cmos domain
	//block ram写电路
	//bram写地址
	reg  [9:0]								ram_wr_addr;
	
	always@(posedge clk_cmos or negedge sys_rstn)
	begin
		if(!sys_rstn)
		begin	
			ram_wr_addr <= 10'h000;
		end
		else if(cmos_vsync)
		begin
			ram_wr_addr <= 10'h000; 
		end
		else if(cmos_vld)
		begin
			if(ram_wr_addr == 10'd639)
				ram_wr_addr <= 10'h000; 
			else
				ram_wr_addr <= ram_wr_addr + 1'b1; 
		end
	end
	
	//原始图像行数
	reg  [8:0]								cmos_vcnt;
	
	always@(posedge clk_cmos or negedge sys_rstn)
	begin
		if(!sys_rstn)
			cmos_vcnt <= 9'h000;
		else if(cmos_vld && (ram_wr_addr == 10'd639))
		begin
			if(cmos_vcnt < 9'd479)
				cmos_vcnt <= cmos_vcnt + 1'b1;
			else
				cmos_vcnt <= 9'h000;
		end
	end
	
	//bram写使能
	wire					ram_wr_enb_0,	ram_wr_enb_1,	ram_wr_enb_2,	ram_wr_enb_3,	ram_wr_enb_4,	ram_wr_enb_5,	ram_wr_enb_6,	ram_wr_enb_7;	
	
	assign				ram_wr_enb_0	=		cmos_vld && ((cmos_vcnt[2:0] == 3'b000) || (cmos_vcnt[8:0] == 9'd479));;
	assign				ram_wr_enb_1	=		cmos_vld && ((cmos_vcnt[2:0] == 3'b001) || (cmos_vcnt[8:0] == 9'd479));;
	assign				ram_wr_enb_2	=		cmos_vld && (cmos_vcnt[2:0] == 3'b010);
	assign				ram_wr_enb_3	=		cmos_vld && (cmos_vcnt[2:0] == 3'b011);
	assign				ram_wr_enb_4	=		cmos_vld && (cmos_vcnt[2:0] == 3'b100);
	assign				ram_wr_enb_5	=		cmos_vld && (cmos_vcnt[2:0] == 3'b101);
	assign				ram_wr_enb_6	=		cmos_vld && (cmos_vcnt[2:0] == 3'b110);
	assign				ram_wr_enb_7	=		cmos_vld && ((cmos_vcnt[2:0] == 3'b111) || (cmos_vcnt[8:0] == 9'h000));
	

	reg						ram_wr_sel;
	
	always@(posedge clk_cmos or negedge sys_rstn)
	begin
		if(!sys_rstn)
			ram_wr_sel <= 1'b0;
		else if(cmos_vld && (ram_wr_addr == 10'd639) )
			ram_wr_sel <= 1'b1;
		else
			ram_wr_sel <= 1'b0;
	end
	
	// sys_clk domain
	reg						ram_wr_sel_d1,	ram_wr_sel_d2, ram_wr_sel_d3;
	
	always@(posedge sys_clk or negedge sys_rstn)
	begin
		if(!sys_rstn)
		begin
			ram_wr_sel_d1 <= 1'b0;
			ram_wr_sel_d2 <= 1'b0;
			ram_wr_sel_d3 <= 1'b0;
		end
		else
		begin
			ram_wr_sel_d1 <= ram_wr_sel;
			ram_wr_sel_d2 <= ram_wr_sel_d1;
			ram_wr_sel_d3 <= ram_wr_sel_d2;
		end
	end
	
	wire							cmos_ram_wr_sel;
	
	assign						cmos_ram_wr_sel	=	ram_wr_sel_d2 && (~ram_wr_sel_d3);
	
	reg								cmos_vsync_d1,			cmos_vsync_d2;
	
	always@(posedge sys_clk or negedge sys_rstn)
	begin
		if(!sys_rstn)
		begin
			cmos_vsync_d1 <= 1'b0;
			cmos_vsync_d2 <= 1'b0;
		end
		else
		begin
			cmos_vsync_d1 <= cmos_vsync;
			cmos_vsync_d2 <= cmos_vsync_d1;
		end
	end
	
	reg  [3:0]				cmos_ram_rw_cnt;
	
	always@(posedge sys_clk or negedge sys_rstn)
	begin
		if(!sys_rstn)
		begin
			cmos_ram_rw_cnt <= 4'b0000;
		end
	/*	else if(cmos_vsync)
		begin
			cmos_ram_rw_cnt <= 4'b1110;
		end */
		else if(cmos_vsync_d2) 
		begin
			cmos_ram_rw_cnt <= 4'b1110;
		end
		else if(cmos_ram_wr_sel && (~cmos_ram_rd_sel))
		begin
			if(cmos_vcnt != 9'h000)
				cmos_ram_rw_cnt <= cmos_ram_rw_cnt + 1'b1;
			else
				cmos_ram_rw_cnt <= cmos_ram_rw_cnt + 2'b11;
		end
		else if ((~cmos_ram_wr_sel) && cmos_ram_rd_sel)
		begin	
			cmos_ram_rw_cnt <= cmos_ram_rw_cnt + 4'b1111;
		end
	end
	
	wire									cmos_ram_ready;
	
	assign								cmos_ram_ready	=	((cmos_ram_rw_cnt[3] == 1'b0) && (cmos_ram_rw_cnt[2:0] != 3'b000))? 1'b1 : 1'b0;
	
	reg		[2:0]						cmos_ram_mux;
	
	always@(posedge sys_clk or negedge sys_rstn)
	begin
		if(!sys_rstn)
			cmos_ram_mux <= 3'b111;
		else if(cmos_ram_rd_sel)
			cmos_ram_mux <= cmos_ram_mux + 1'b1;
	end
	
	
	//3T delay
	wire  [15:0]				ram_rd_data_0, 	ram_rd_data_1,	ram_rd_data_2,	ram_rd_data_3,	ram_rd_data_4,	ram_rd_data_5,	ram_rd_data_6,	ram_rd_data_7;
	                                                   
	always@(*)                                        
	begin                                           
		case (cmos_ram_mux)
			3'b000:begin
				p0 <= ram_rd_data_7;
				p1 <= ram_rd_data_0;
				p2 <= ram_rd_data_1;
				p3 <= ram_rd_data_2;
			end
			3'b001:begin
				p0 <= ram_rd_data_0;
				p1 <= ram_rd_data_1;
				p2 <= ram_rd_data_2;
				p3 <= ram_rd_data_3;
			end
			3'b010:begin
				p0 <= ram_rd_data_1;
				p1 <= ram_rd_data_2;
				p2 <= ram_rd_data_3;
				p3 <= ram_rd_data_4;
			end
			3'b011:begin
				p0 <= ram_rd_data_2;
				p1 <= ram_rd_data_3;
				p2 <= ram_rd_data_4;
				p3 <= ram_rd_data_5;
			end
			3'b100:begin
				p0 <= ram_rd_data_3;
				p1 <= ram_rd_data_4;
				p2 <= ram_rd_data_5;
				p3 <= ram_rd_data_6;
			end
			3'b101:begin
				p0 <= ram_rd_data_4;
				p1 <= ram_rd_data_5;
				p2 <= ram_rd_data_6;
				p3 <= ram_rd_data_7;
			end
			3'b110:begin
				p0 <= ram_rd_data_5;
				p1 <= ram_rd_data_6;
				p2 <= ram_rd_data_7;
				p3 <= ram_rd_data_0;
			end
			3'b111:begin
				p0 <= ram_rd_data_6;
				p1 <= ram_rd_data_7;
				p2 <= ram_rd_data_0;
				p3 <= ram_rd_data_1;
			end
		endcase
	end
	
	
	
  //8x1024x16bits ram
  bram_1024x16  bram_1024x16_0 (
	.clka						(clk_cmos),
	.clkb						(sys_clk),
	.dina						(cmos_data),
	.addrb					(cmos_ram_rd_addr),
	.addra					(ram_wr_addr ),
	.wea						(ram_wr_enb_0),
	.doutb					(ram_rd_data_0)
	);
	
	bram_1024x16  bram_1024x16_1 (
	.clka						(clk_cmos),
	.clkb						(sys_clk),
	.dina						(cmos_data),
	.addrb					(cmos_ram_rd_addr),
	.addra					(ram_wr_addr ),
	.wea						(ram_wr_enb_1),
	.doutb					(ram_rd_data_1)
	);
	
	bram_1024x16  bram_1024x16_2 (
	.clka						(clk_cmos),
	.clkb						(sys_clk),
	.dina						(cmos_data),
	.addrb					(cmos_ram_rd_addr),
	.addra					(ram_wr_addr ),
	.wea						(ram_wr_enb_2),
	.doutb					(ram_rd_data_2)
	);
	
	bram_1024x16  bram_1024x16_3 (
	.clka						(clk_cmos),
	.clkb						(sys_clk),
	.dina						(cmos_data),
	.addrb					(cmos_ram_rd_addr),
	.addra					(ram_wr_addr ),
	.wea						(ram_wr_enb_3),
	.doutb					(ram_rd_data_3)
	);
	
	bram_1024x16  bram_1024x16_4 (
	.clka						(clk_cmos),
	.clkb						(sys_clk),
	.dina						(cmos_data),
	.addrb					(cmos_ram_rd_addr),
	.addra					(ram_wr_addr ),
	.wea						(ram_wr_enb_4),
	.doutb					(ram_rd_data_4)
	);
	
	bram_1024x16  bram_1024x16_5 (
	.clka						(clk_cmos),
	.clkb						(sys_clk),
	.dina						(cmos_data),
	.addrb					(cmos_ram_rd_addr),
	.addra					(ram_wr_addr ),
	.wea						(ram_wr_enb_5),
	.doutb					(ram_rd_data_5)
	);
	
	bram_1024x16  bram_1024x16_6 (
	.clka						(clk_cmos),
	.clkb						(sys_clk),
	.dina						(cmos_data),
	.addrb					(cmos_ram_rd_addr),
	.addra					(ram_wr_addr ),
	.wea						(ram_wr_enb_6),
	.doutb					(ram_rd_data_6)
	);
	
	bram_1024x16  bram_1024x16_7 (
	.clka						(clk_cmos),
	.clkb						(sys_clk),
	.dina						(cmos_data),
	.addrb					(cmos_ram_rd_addr),
	.addra					(ram_wr_addr ),
	.wea						(ram_wr_enb_7),
	.doutb					(ram_rd_data_7)
	);
	


endmodule
