`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Polytech
// Engineer: Artem
// 
// Create Date: 20.06.2025 18:52:05
// Design Name: 
// Module Name: DL_ComandDecoder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module DL_ComandDecoder(
  input logic [7:0] cmd, // UPDI comand
  input clk, // clock 
  input logic [32:0] data_in, // data by PHY in case of STS, ST, STCS, REP
  output logic [32:0] data_out, // output send data to PHY
  output csb0, // active low chip select
  output web0, // active low write control
  output [3:0] reg_addr // output choose register adress to read/write info,
    );
	 

    
    // UPDI comands set
    typedef enum logic [2:0] 
    {
     LDS = 3'b000,  STS = 3'b010, 
     LD = 3'b001,   ST = 3'b011, 
     LDCS = 3'b100, STCS = 3'b110, 
     REP = 3'b101,  KEY = 3'b111
    } comands;
    
    
    comands state, next_state;
    
	 // state changing
    always_ff @(posedge clk)
	 
			 case (cmd [7:5]):
			 
			      // switch state of FSM by opcode
					LDS:  next_state = LDS;
					STS:  next_state = STS;
					LD:   next_state = LD;
					ST:   next_state = ST;
					LDCS: next_state = LDCS;
					STCS: next_state = STCS;
					REP:  next_state = REP;
					KEY:  next_state = KEY;
					
					// there is no free number for states to make IDLE state, use high-impedance value
					default: next_state <= 3'bzzz;
    
	 always_comb
			
			 case (state):
			 
			      LDCS: 
							begin
							csb0 = 1'b0;
							web0 = 1'b1;
							reg_addr = cmd [3:0];
							end
			
			
						
    
endmodule
