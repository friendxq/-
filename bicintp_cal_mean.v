/*-------------------------------------------------------------------------
This confidential and proprietary software may be only used as authorized
by a licensing agreement from cheerchips.
(C) COPYRIGHT 2013.www.cheerchips.com ALL RIGHTS RESERVED
Filename			:		bicintp_cal.v
Author				:		
Data				:		
Version				:		1.0
Description			:		
Modification History	:
Data			By			Version			Change Description
===========================================================================
13/02/1
--------------------------------------------------------------------------*/

`timescale 1 ns / 1 ns
module bicintp_cal

(
  //global clock
	sys_clk						,				
	sys_rstn					,			
	
	// bicintp_eng io
	w_x,
	w_y_0,
	w_y_1,
	w_y_2,
	w_y_3,
	
	intp_enb,
	
	//bicintp_ram io
	p0,
	p1,
	p2,
	p3,
	
	// ddr_rw io
	cmos_bicintp_data,
	cmos_bicintp_data_vld

);
	//global clock
	input									sys_clk;			//系统时钟125M/105M
	input 								sys_rstn;			//全局复位
	
	// vga_bicintp_cal io
	input  [7:0]					w_x;
	
	input  [7:0]					w_y_0;
	input  [7:0]					w_y_1;
	input  [7:0]					w_y_2;
	input  [7:0]					w_y_3;
	
	input									intp_enb;
	
	//vga_bicintp_cal io
	input  [15:0]					p0;
	input  [15:0]					p1 ;
	input  [15:0]					p2;
	input  [15:0]					p3 ;
	
	
	// vga_pingpong_buf io
	output  [15:0]				cmos_bicintp_data;
	output								cmos_bicintp_data_vld;

	wire  [17:0]					p_wy_r;
	wire  [17:0]					p_wy_g;
	wire  [17:0]					p_wy_b;
	
	wire  [15:0]					p0_wy0_r,  p1_wy1_r,  p2_wy2_r,  p3_wy3_r;
	wire  [15:0]					p0_wy0_g,  p1_wy1_g,  p2_wy2_g,  p3_wy3_g;
	wire  [15:0]					p0_wy0_b,  p1_wy1_b,  p2_wy2_b,  p3_wy3_b;
	
	wire	[24:0]					p_wxy_r;
	wire	[24:0]					p_wxy_g;
	wire	[24:0]					p_wxy_b;
	
	
	reg										intp_enb_d1,		intp_enb_d2,		intp_enb_d3,		intp_enb_d4;
	
	always@(posedge sys_clk or negedge sys_rstn)
	begin
		if(!sys_rstn)	
		begin
			intp_enb_d1 <= 1'b0;
			intp_enb_d2 <= 1'b0;
			intp_enb_d3 <= 1'b0;
			intp_enb_d4 <= 1'b0;
		end
		else
		begin
			intp_enb_d1 <= intp_enb;
			intp_enb_d2 <= intp_enb_d1;
			intp_enb_d3 <= intp_enb_d2;
			intp_enb_d4 <= intp_enb_d3;
		end
	end
	
	reg  [15:0] 					p1_d1, p1_d2, p1_d3, p1_d4, p1_d5, p1_d6, p1_d7;
	
	always@(posedge sys_clk or negedge sys_rstn)
	begin
		if(!sys_rstn)	
		begin
			p1_d1 <= 16'h0000;
			p1_d2 <= 16'h0000;
			p1_d3 <= 16'h0000;
			p1_d4 <= 16'h0000;
			p1_d5 <= 16'h0000;
			p1_d6 <= 16'h0000;
			p1_d7 <= 16'h0000;
			
		end
		else
		begin
			p1_d1 <= p1;
			p1_d2 <= p1_d1;
			p1_d3 <= p1_d2;
			p1_d4 <= p1_d3;
			p1_d5 <= p1_d4;
			p1_d6 <= p1_d5;
			p1_d7 <= p1_d6;
		end
	end
	
	reg  [1:0]						intp_cnt;
	
	always@(posedge sys_clk or negedge sys_rstn)
	begin
		if(!sys_rstn)	
			intp_cnt <= 2'b00;
		else if(intp_enb_d4)
			intp_cnt <= intp_cnt + 1'b1;
	end
	
	
	assign								p_wy_r	=	{p0_wy0_r[15],p0_wy0_r[15],p0_wy0_r[15:0]} + {p1_wy1_r[15],p1_wy1_r[15],p1_wy1_r[15:0]} + {p2_wy2_r[15],p2_wy2_r[15],p2_wy2_r[15:0]} + {p3_wy3_r[15],p3_wy3_r[15],p3_wy3_r[15:0]};
	
	
	reg  [26:0]						p_wxy_reg_r;
	
	always@(posedge sys_clk or negedge sys_rstn)
	begin
		if(!sys_rstn)	
		begin
			p_wxy_reg_r <= 27'h000_0000;
		end
		else if(intp_enb_d4 && (intp_cnt == 2'b00))
		begin
			p_wxy_reg_r <= {p_wxy_r[24],p_wxy_r[24],p_wxy_r[24:0]};
		end
		else 
		begin
			p_wxy_reg_r <= p_wxy_reg_r + {p_wxy_r[24],p_wxy_r[24],p_wxy_r[24:0]};
		end
	end 

// add for test	
	wire  [4:0]					p_wxy_reg_r_adj;
	
	assign								p_wxy_reg_r_adj	=	p_wxy_reg_r[18:14] + p_wxy_reg_r[13]; //结果四舍五入
	
	wire  [4:0]						bicintp_r;
	
	assign								bicintp_r	=	(p_wxy_reg_r[26] || ((~p_wxy_reg_r[26]) && p_wxy_reg_r[19]) )? p1_d7[15:11] : p_wxy_reg_r_adj;
	
	assign								p_wy_g	=	{p0_wy0_g[15],p0_wy0_g[15],p0_wy0_g[15:0]} + {p1_wy1_g[15],p1_wy1_g[15],p1_wy1_g[15:0]} + {p2_wy2_g[15],p2_wy2_g[15],p2_wy2_g[15:0]} + {p3_wy3_g[15],p3_wy3_g[15],p3_wy3_g[15:0]};
	
	
	reg  [26:0]						p_wxy_reg_g;
	
	always@(posedge sys_clk or negedge sys_rstn)
	begin
		if(!sys_rstn)	
		begin
			p_wxy_reg_g <= 27'h000_0000;
		end
		else if(intp_enb_d4 && (intp_cnt == 2'b00))
		begin
			p_wxy_reg_g <= {p_wxy_g[24],p_wxy_g[24],p_wxy_g[24:0]};
		end
		else 
		begin
			p_wxy_reg_g <= p_wxy_reg_g + {p_wxy_g[24],p_wxy_g[24],p_wxy_g[24:0]};
		end
	end 
	
	// add for test	
	wire  [5:0]						p_wxy_reg_g_adj;
	
	assign								p_wxy_reg_g_adj	=	p_wxy_reg_g[19:14] + p_wxy_reg_g[13]; //结果四舍五入
	
	wire  [5:0]						bicintp_g;
		
	assign								bicintp_g	=	(p_wxy_reg_g[26] || ((~p_wxy_reg_g[26]) && p_wxy_reg_g[20]) )? p1_d7[10:5] : p_wxy_reg_g_adj;

	
	assign								p_wy_b	=	{p0_wy0_b[15],p0_wy0_b[15],p0_wy0_b[15:0]} + {p1_wy1_b[15],p1_wy1_b[15],p1_wy1_b[15:0]} + {p2_wy2_b[15],p2_wy2_b[15],p2_wy2_b[15:0]} + {p3_wy3_b[15],p3_wy3_b[15],p3_wy3_b[15:0]};
	
	
	reg  [26:0]						p_wxy_reg_b;
	
	always@(posedge sys_clk or negedge sys_rstn)
	begin
		if(!sys_rstn)	
		begin
			p_wxy_reg_b <= 27'h000_0000;
		end
		else if(intp_enb_d4 && (intp_cnt == 2'b00))
		begin
			p_wxy_reg_b <= {p_wxy_b[24],p_wxy_b[24],p_wxy_b[24:0]};
		end
		else 
		begin
			p_wxy_reg_b <= p_wxy_reg_b + {p_wxy_b[24],p_wxy_b[24],p_wxy_b[24:0]};
		end
	end 
	
	// add for test	
	wire  [4:0]					  p_wxy_reg_b_adj;
	
	assign								p_wxy_reg_b_adj	=	p_wxy_reg_b[18:14] + p_wxy_reg_b[13]; //结果四舍五入
	
	wire  [4:0]						bicintp_b;
	
	assign								bicintp_b	=	(p_wxy_reg_b[26] || ((~p_wxy_reg_b[26]) && p_wxy_reg_b[19]) )? p1_d7[4:0] : p_wxy_reg_b_adj;
	

	
	reg  [7:0]						w_x_d1,		w_x_d2;
	
	always@(posedge sys_clk or negedge sys_rstn)
	begin
		if(!sys_rstn)	
		begin
			w_x_d1 <= 8'h00;
			w_x_d2 <= 8'h00;
		end
		else
		begin
			w_x_d1 <= w_x;
			w_x_d2 <= w_x_d1;
		end
	end 
	
	
	wire  [15:0]					cmos_bicintp_data;
	
	assign								cmos_bicintp_data	=	{bicintp_r[4:0],bicintp_g[5:0],bicintp_b[4:0]};
	
	reg 									cmos_bicintp_data_vld;
	
	always@(posedge sys_clk or negedge sys_rstn)
	begin
		if(!sys_rstn)	
		begin
			cmos_bicintp_data_vld <= 1'b0;
		end
		else if(intp_enb_d4 && (intp_cnt == 2'b11))
		begin
			cmos_bicintp_data_vld <= 1'b1;
		end
		else
		begin
			cmos_bicintp_data_vld <= 1'b0;
		end		
	end
	
//5T delay
// red intp
	//表示 p0*w__wy_0
	dsp_mult_8x8 	dsp_mult_p0_wy0_r(
	.clk								(sys_clk),
	.a								({3'b000,p0[15:11]}),
	//.b								(w_y_0),
	.b								(8'h20),
	.p								(p0_wy0_r)
	); 
	
	//表示 p1*w_y_1
	dsp_mult_8x8 	dsp_mult_p1_wy1_r(
	.clk								(sys_clk),
	.a								({3'b000,p1[15:11]}),
	//.b								(w_y_1),
	.b								(8'h20),
	.p								(p1_wy1_r)
	);
	
	//表示 p2*w_y_2
	dsp_mult_8x8 	dsp_mult_p2_wy2_r(
	.clk								(sys_clk),
	.a								({3'b000,p2[15:11]}),
	//.b								(w_y_2),
	.b								(8'h20),
	.p								(p2_wy2_r)
	); 
	
	//表示 p3*w_y_3
	dsp_mult_8x8 	dsp_mult_p3_wy3_r(
	.clk								(sys_clk),
	.a								({3'b000,p3[15:11]}),
	//.b								(w_y_3),
	.b								(8'h20),
	.p								(p3_wy3_r)
	);
	
	//7T delay
	//表示 p_wy_r * w_x
	dsp_mult_18x8 	dsp_mult_p_wxy_r(
	.clk								(sys_clk),
	.a								(p_wy_r),
	//.b								(w_x_d2),
	.b								(8'h20),
	.p								(p_wxy_r)
	);
	
// green intp
	//表示 p0*w__wy_0
	dsp_mult_8x8 	dsp_mult_p0_wy0_g(
	.clk								(sys_clk),
	.a								({2'b00,p0[10:5]}),
	//.b								(w_y_0),
	.b								(8'h20),
	.p								(p0_wy0_g)
	); 
	
	//表示 p1*w_y_1
	dsp_mult_8x8 	dsp_mult_p1_wy1_g(
	.clk								(sys_clk),
	.a								({2'b00,p1[10:5]}),
	//.b								(w_y_1),
	.b								(8'h20),
	.p								(p1_wy1_g)
	);
	
	//表示 p2*w_y_2
	dsp_mult_8x8 	dsp_mult_p2_wy2_g(
	.clk								(sys_clk),
	.a								({2'b00,p2[10:5]}),
	//.b								(w_y_2),
	.b								(8'h20),
	.p								(p2_wy2_g)
	); 
	
	//表示 p3*w_y_3
	dsp_mult_8x8 	dsp_mult_p3_wy3_g(
	.clk								(sys_clk),
	.a								({2'b00,p3[10:5]}),
	//.b								(w_y_3),
	.b								(8'h20),
	.p								(p3_wy3_g)
	);
	
	//7T delay
	//表示 p_wy_r * w_x
	dsp_mult_18x8 	dsp_mult_p_wxy_g(
	.clk								(sys_clk),
	.a								(p_wy_g),
	//.b								(w_x_d2),
	.b								(8'h20),
	.p								(p_wxy_g)
	);
	
	
	// blue intp
	//表示 p0*w_y_0
	dsp_mult_8x8 	dsp_mult_p0_wy0_b(
	.clk								(sys_clk),
	.a								({3'b000,p0[4:0]}),
	//.b								(w_y_0),
	.b								(8'h20),
	.p								(p0_wy0_b)
	); 
	
	//表示 p1*w_y_1
	dsp_mult_8x8 	dsp_mult_p1_wy1_b(
	.clk								(sys_clk),
	.a								({3'b000,p1[4:0]}),
	//.b								(w_y_1),
	.b								(8'h20),
	.p								(p1_wy1_b)
	);
	
	//表示 p2*w_y_2
	dsp_mult_8x8 	dsp_mult_p2_wy2_b(
	.clk								(sys_clk),
	.a								({3'b000,p2[4:0]}),
	//.b								(w_y_2),
	.b								(8'h20),
	.p								(p2_wy2_b)
	); 
	
	//表示 p3*w_y_3
	dsp_mult_8x8 	dsp_mult_p3_wy3_b(
	.clk								(sys_clk),
	.a								({3'b000,p3[4:0]}),
	//.b								(w_y_3),
	.b								(8'h20),
	.p								(p3_wy3_b)
	);
	
	//7T delay
	//表示 p_wy_r * w_x
	dsp_mult_18x8 	dsp_mult_p_wxy_b(
	.clk								(sys_clk),
	.a								(p_wy_b),
	//.b								(w_x_d2),
	.b								(8'h20),
	.p								(p_wxy_b)
	);
	
	

	

endmodule
