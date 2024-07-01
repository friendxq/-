/*-------------------------------------------------------------------------
This confidential and proprietary software may be only used as authorized
by a licensing agreement from cheerchips.
(C) COPYRIGHT 2013.www.cheerchips.com ALL RIGHTS RESERVED
Filename			:		biciintp_top.v
Author				:		maggie
Data				:		2021-02-1
Version				:		1.0
Description			:		
Modification History	:
Data			By			Version			Change Description
===========================================================================
13/02/1
--------------------------------------------------------------------------*/

`timescale 1 ns / 1 ns
module bicintp_top
	( 
	//global clock
	sys_clk						,				
	clk_cmos 					,    		
	sys_rstn					,				
	
	//cmos inf
	cmos_hsync					,  
	cmos_vsync			,
	cmos_wr_enb				,			
	cmos_data					,			
	
	//ddr inf
	cmos_bicintp_data_vld	,			
	cmos_bicintp_data			

	);
	//global clock
	input								sys_clk;		//ddr用户 时钟，125M/105M
	input 							clk_cmos;		//fifo写数据时钟，cmos随路时钟，25M
	input 							sys_rstn;		//全局复位
	
	  
	//cmos 接口
	input								cmos_hsync ;  
	input								cmos_vsync ;
	input 							cmos_wr_enb;		//cmos 写fifo写使能
	input		[15:0] 			cmos_data;		//cmos 写fifo数据，16bits
	
	//ddr接口
	output  						cmos_bicintp_data_vld	;
	output  [15:0]			cmos_bicintp_data			;
	
	
	wire								sys_clk		;				
	wire 								sys_rstn	;				
	
	//cmos_top io
	wire 								clk_cmos	;
	wire  [15:0]				cmos_data	;
	wire 								cmos_wr_enb	;
	wire 								cmos_hsync ;  
	wire 								cmos_vsync ;
	
	
	//bicintp_eng  io
	wire 								cmos_ram_ready	;  
	wire 								cmos_ram_rd_enb	;
	wire 	[9:0]					cmos_ram_rd_addr ;
	wire 								cmos_ram_rd_sel  ;
	
	
	
	
	// bicintp_cal io
	wire 	[15:0]				p0	;
	wire 	[15:0]				p1		;
	wire 	[15:0]				p2	;
	wire 	[15:0]				p3	;
	
	wire	[4:0]					rom_v_rd_addr ;
	wire	[4:0]					rom_h_rd_addr ;
	
	wire 	[7:0]							w_x           ;
	wire 	[7:0]							w_y_0          ;
	wire 	[7:0]							w_y_1         ;
	wire 	[7:0]							w_y_2         ;
	wire 	[7:0]							w_y_3         ;
	
	wire 										intp_enb      ;
	
	
	// ddr_rw io
	wire 	[15:0]							cmos_bicintp_data			;
	wire 											cmos_bicintp_data_vld 	;

	
 	bicintp_ram      U_bicintp_ram ( 
	//global clock
	.sys_clk					(sys_clk)	,				
	.sys_rstn					(sys_rstn),				
	
	//cmos_top io
	.clk_cmos					(clk_cmos),
	.cmos_data				(cmos_data)	,
	.cmos_vld					(cmos_wr_enb),
	.cmos_hsync				(cmos_hsync)	,  
	.cmos_vsync				(cmos_vsync),
	
	
	//bicintp_eng  io
	.cmos_ram_ready		(cmos_ram_ready),   
	.cmos_ram_rd_enb	(cmos_ram_rd_enb),
	.cmos_ram_rd_addr (cmos_ram_rd_addr),	
	.cmos_ram_rd_sel  (cmos_ram_rd_sel),
	
	// bicintp_cal io
	.p0								(p0),
	.p1								(p1),
	.p2								(p2),
	.p3								(p3)

	);
	
	
	bicintp_eng				U_bicintp_eng ( 
	//global clock
	.sys_clk					(sys_clk)	,				
	.sys_rstn					(sys_rstn),				
	
	//bicintp_ram  io
	.cmos_ram_ready		(cmos_ram_ready),   
	.cmos_ram_rd_enb	(cmos_ram_rd_enb),
	.cmos_ram_rd_addr (cmos_ram_rd_addr),	
	.cmos_ram_rd_sel  (cmos_ram_rd_sel),
	
	// bicintp_rom io
	.rom_h_rd_addr    (rom_h_rd_addr),
	.rom_v_rd_addr    (rom_v_rd_addr),
	.rom_v_rd_enb			(rom_v_rd_enb),
	
	//bicintp_cal io
	.intp_enb					(intp_enb)
	
	);
	
	
	bicintp_rom					U_bicintp_rom  ( 
	//global clock
	.sys_clk						(sys_clk),				
	.sys_rstn						(sys_rstn),				
	
	// bicintp_eng io
	.rom_h_rd_addr			(rom_h_rd_addr),
	.rom_v_rd_addr			(rom_v_rd_addr),
	.rom_v_rd_enb				(rom_v_rd_enb),

  // bicintp_eng io
	.w_x								(w_x),
	.w_y_0							(w_y_0),
	.w_y_1							(w_y_1),
	.w_y_2							(w_y_2),
	.w_y_3							(w_y_3)	
	
	);
	
	bicintp_cal		U_bicintp_cal (
  //global clock
	.sys_clk					(sys_clk)	,				
	.sys_rstn					(sys_rstn),			
	
	// bicintp_rom io
	.w_x              (w_x),
	.w_y_0            (w_y_0),
	.w_y_1            (w_y_1),
	.w_y_2            (w_y_2),
	.w_y_3            (w_y_3),
	
	// bicintp_eng io
	.intp_enb         (intp_enb), 
	
	//bicintp_ram io
	.p0               (p0),
	.p1               (p1),
	.p2               (p2),
	.p3               (p3),
	
	// ddr_rw io
	.cmos_bicintp_data			(cmos_bicintp_data), 
	.cmos_bicintp_data_vld 	(cmos_bicintp_data_vld)

);

endmodule
