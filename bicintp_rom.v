/*-------------------------------------------------------------------------
This confidential and proprietary software may be only used as authorized
by a licensing agreement from cheerchips.
(C) COPYRIGHT 2013.www.cheerchips.com ALL RIGHTS RESERVED
Filename			:		biciintp_rom.v
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
module bicintp_rom
	( 
	//global clock
	sys_clk						,				
	sys_rstn					,				
	
	// bicintp_eng io
	rom_v_rd_addr,
	rom_h_rd_addr,
	rom_v_rd_enb,

  // bicintp_eng io
	w_x,
	w_y_0,
	w_y_1,
	w_y_2,
	w_y_3
	
	
	);
	//global clock
	input											sys_clk;		//系统时钟，125M/105M
	input 										sys_rstn;		//全局复位
		
	// bicintp_eng io
	input   [4:0]						rom_v_rd_addr;
	input   [4:0]						rom_h_rd_addr;
	input										rom_v_rd_enb;


	// vga_bilintp_cal io
	output  [7:0]						w_x;
	
	output  [7:0]						w_y_0;
	output  [7:0]						w_y_1;
	output  [7:0]						w_y_2;
	output  [7:0]						w_y_3;
	
	reg	  [7:0]							w_x;
	
	reg	  [7:0]						w_y_0;
	reg	  [7:0]						w_y_1;
	reg	  [7:0]						w_y_2;
	reg	  [7:0]						w_y_3;
	
	wire  [7:0]						rom_h_rd_data;
	wire  [7:0]						rom_v_rd_data;
	
	//2T delay
	reg										rom_v_rd_enb_d1,   rom_v_rd_enb_d2;
	
	always@(posedge sys_clk or negedge sys_rstn)
	begin
		if(!sys_rstn)	
		begin
			rom_v_rd_enb_d1 <= 1'b0;
			rom_v_rd_enb_d2 <= 1'b0;
		end
		else
		begin
			rom_v_rd_enb_d1 <= rom_v_rd_enb;
			rom_v_rd_enb_d2 <= rom_v_rd_enb_d1;
		end
	end
	
	//3T delay
	reg  [31:0]       wy_sf_reg;
	
	always@(posedge sys_clk or negedge sys_rstn)
	begin
		if(!sys_rstn)	
		begin
			wy_sf_reg <= 32'h0000_0000;
		end
		else if(rom_v_rd_enb_d2)
		begin
			wy_sf_reg <= {wy_sf_reg[23:0],rom_v_rd_data};
		end
	end
	
	always@(posedge sys_clk or negedge sys_rstn)
	begin
		if(!sys_rstn)	
		begin
			{w_y_0,w_y_1,w_y_2,w_y_3} <= 32'h0000_0000;
		end
		else 
		begin
			{w_y_0,w_y_1,w_y_2,w_y_3} <= wy_sf_reg;
			//{w_y_0,w_y_1,w_y_2,w_y_3} <= {w_y_1,w_y_2,w_y_3,8'h20};
		end
	end
	
	
	//3T delay
	always@(posedge sys_clk or negedge sys_rstn)
	begin
		if(!sys_rstn)	
		begin
			w_x	<= 8'h00;
		end
		else 
		begin
			//w_x	<= 8'h20;
			w_x	<= rom_h_rd_data;
		end
	end
	
	
	//rom read data 2T delay
	rom_h     U_rom_h(
	
	.a					(rom_h_rd_addr),
  .clk				(sys_clk),
  .qspo				(rom_h_rd_data)
  
	);
	
	rom_v     U_rom_v(
	
	.a					(rom_v_rd_addr),
  .clk				(sys_clk),
  .qspo				(rom_v_rd_data)
  
	);


endmodule
