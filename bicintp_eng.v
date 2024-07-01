/*-------------------------------------------------------------------------
This confidential and proprietary software may be only used as authorized
by a licensing agreement from cheerchips.
(C) COPYRIGHT 2013.www.cheerchips.com ALL RIGHTS RESERVED
Filename			:		bicintp_eng.v
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
module bicintp_eng
	( 
	//global clock
	sys_clk						,				
	sys_rstn					,				
	
	//bicintp_ram  io
	cmos_ram_ready		,   
	cmos_ram_rd_enb	,
	cmos_ram_rd_addr,	
	cmos_ram_rd_sel ,
	
	// bicintp_rom io
	rom_h_rd_addr,
	rom_v_rd_addr,
	rom_v_rd_enb,
	
	//bicintp_cal io
	intp_enb
	

	);
	//global clock
	input											sys_clk;		//系统时钟125M/105M
	input 										sys_rstn;		//全局复位
		
	//bicintp_ram  io
	input											cmos_ram_ready;  
	output										cmos_ram_rd_enb	;
	output  [9:0]							cmos_ram_rd_addr;	
	//output  [2:0]							cmos_ram_rd_sel;
	output  									cmos_ram_rd_sel;
	
	// bicintp_rom io
	output   [4:0]						rom_h_rd_addr;
	output   [4:0]						rom_v_rd_addr;
	output										rom_v_rd_enb;
	
	//bicintp_cal io
	output										intp_enb;

	
	reg  											para_h_flag;
	reg												para_v_flag;
	
	//fsm 主控状态机
	reg   [1:0]								FSM;
	
	parameter									IDLE				= 3'b000;
	parameter									PRE					= 3'b001;
	parameter									INTP				= 3'b010;
	parameter									BLANK				= 3'b011;
	
	reg  [1:0]								sub_cnt;
	reg  [11:0]								h_cnt;
	reg  [11:0]								v_cnt;
	
	always@(posedge sys_clk or negedge sys_rstn)
	begin
		if(!sys_rstn)	
		begin
			FSM <= IDLE;
			sub_cnt <= 2'b00;	
			h_cnt <= 12'h000;
			v_cnt <= 12'h000;
		end
		else 
		begin
			case (FSM)
				IDLE: begin
					if(cmos_ram_ready)
					begin
						FSM <= PRE;
					end
					sub_cnt <= 2'b00;	
					h_cnt <= 12'h000;
					v_cnt <= 12'h000;
				end
				PRE: begin
					if(sub_cnt == 2'b11)
					begin
						FSM <= INTP;
					end
					sub_cnt <= sub_cnt + 1'b1;	
				end
				INTP: begin
					if(sub_cnt[1:0] == 2'b11)
					begin
						if(h_cnt[11:0] == 12'd1023) 
						begin
							if(v_cnt[11:0] == 12'd767)
							begin
								FSM <= IDLE;
								v_cnt <= 12'h000;
							end
							else
							begin
								FSM <= BLANK;
								v_cnt <= v_cnt + 1'b1;
							end
							h_cnt <= 12'h000;
						end
						else
						begin
							h_cnt <= h_cnt + 1'b1;
						end
					end
					sub_cnt <= sub_cnt + 1'b1;
					
				end
				BLANK: begin
					if(cmos_ram_ready || (~para_v_flag) )
					begin
						FSM <=	PRE;
					end
				end
				default: begin
					FSM <= IDLE;
				end
	    endcase
	  end
	end
	
	
	
	always@(*)
	begin
		case(h_cnt[2:0])
			3'b000:begin
				para_h_flag <= 1'b1;
			end
			3'b001:begin
				para_h_flag <= 1'b0;
			end
			3'b010:begin
				para_h_flag <= 1'b1;
			end
			3'b011:begin
				para_h_flag <= 1'b0;
			end
			3'b100:begin
				para_h_flag <= 1'b1;
			end
			3'b101:begin
				para_h_flag <= 1'b1;
			end
			3'b110:begin
				para_h_flag <= 1'b0;
			end
			3'b111:begin
				para_h_flag <= 1'b1;
			end
			
		endcase
	end
	
	always@(*)
	begin
		case(v_cnt[2:0])
			3'b000:begin
				para_v_flag <= 1'b1;
			end
			3'b001:begin
				para_v_flag <= 1'b0;
			end
			3'b010:begin
				para_v_flag <= 1'b1;
			end
			3'b011:begin
				para_v_flag <= 1'b0;
			end
			3'b100:begin
				para_v_flag <= 1'b1;
			end
			3'b101:begin
				para_v_flag <= 1'b1;
			end
			3'b110:begin
				para_v_flag <= 1'b0;
			end
			3'b111:begin
				para_v_flag <= 1'b1;
			end
			
		endcase
	end
	
	wire						para_h_enb;
	wire						para_v_enb;
	
	wire						idle_flag;
	wire						intp_flag;
	wire						pre_flag;
	wire						blank_flag;
	
	assign					idle_flag					=	(FSM == IDLE)?     1'b1 : 1'b0;
	assign					intp_flag					=	(FSM == INTP)?     1'b1 : 1'b0;
	assign					pre_flag					=	(FSM == PRE)? 1'b1 : 1'b0;
	assign					blank_flag				=	(FSM == BLANK)?    1'b1 : 1'b0;
	
	reg							blank_flag_d;
	
	always@(posedge sys_clk or negedge sys_rstn)
	begin
		if(!sys_rstn)	
			blank_flag_d <= 1'b0;
		else
			blank_flag_d <= blank_flag;
	end
	
	reg							idle_flag_d;
	
	always@(posedge sys_clk or negedge sys_rstn)
	begin
		if(!sys_rstn)	
			idle_flag_d <= 1'b0;
		else
			idle_flag_d <= idle_flag;
	end
	
	assign					para_h_enb		=	intp_flag && (sub_cnt == 2'b00) && para_h_flag;
	assign					para_v_enb		=	((idle_flag_d && (~idle_flag)) || (blank_flag_d && (~blank_flag))) && para_v_flag;						
	
	//3T delay
	reg							para_v_enb_d1;
	
	always@(posedge sys_clk or negedge sys_rstn)
	begin
		if(!sys_rstn)	
			para_v_enb_d1 <= 1'b0;
		else 
			para_v_enb_d1 <= para_v_enb;
	end
	

	//3T delay (intp flag)
	wire  				cmos_ram_rd_sel;
	
	assign				cmos_ram_rd_sel	=	para_v_enb_d1;  
	
	
	//1T delay
	reg  [10:0]						ram_base_addr;
	
	always@(posedge sys_clk or negedge sys_rstn)
	begin
		if(!sys_rstn)	
		begin
			ram_base_addr <= 11'h7FE;
		end
		else if(pre_flag)
		begin
			ram_base_addr <= 11'h7FE;
		end
		else if(para_h_enb)
		begin
			ram_base_addr <= ram_base_addr + 1'b1;
		end	
	end
	
	//1T delay
	reg  [1:0]				sub_cnt_d;
	
	always@(posedge sys_clk or negedge sys_rstn)
	begin
		if(!sys_rstn)	
			sub_cnt_d <= 2'b00;
		else
			sub_cnt_d <= sub_cnt;
	end
	
	wire  [10:0]					ram_addr_r;
	
	assign								ram_addr_r	=	ram_base_addr + sub_cnt_d;
	
	reg	  [9:0]						cmos_ram_rd_addr;
	
	//1T delay
	always@(*)
	begin
		if(ram_addr_r[10])
		begin
			cmos_ram_rd_addr	=	10'h000;
		end
		else if(ram_addr_r[9:0] > 10'd639)
		begin
			cmos_ram_rd_addr	=	10'd639;
		end
		else
		begin
			cmos_ram_rd_addr	=	ram_addr_r[9:0];
		end
	end
	
	
	wire  [5:0]								rom_v_rd_addr;
	wire  [5:0]								rom_h_rd_addr;
	wire											rom_v_rd_enb	;
	
	assign										rom_v_rd_addr	=	{v_cnt[2:0],sub_cnt[1:0]};
	
	assign										rom_h_rd_addr	= {h_cnt[2:0],sub_cnt[1:0]};
	
	assign										rom_v_rd_enb	=	pre_flag;
	
	//3T delay
	reg												intp_flag_d1,			intp_flag_d2,				intp_flag_d3;
	
	always@(posedge sys_clk or negedge sys_rstn)
	begin
		if(!sys_rstn)
		begin	
			intp_flag_d1 <= 1'b0;
			intp_flag_d2 <= 1'b0;
			intp_flag_d3 <= 1'b0;
		end
		else
		begin	
			intp_flag_d1 <= intp_flag;
			intp_flag_d2 <= intp_flag_d1;
			intp_flag_d3 <= intp_flag_d2;
		end
	end
	
	wire											intp_enb;
	
	assign										intp_enb	= intp_flag_d3;
	

endmodule
