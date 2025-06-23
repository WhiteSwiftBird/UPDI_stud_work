module top_DL (
	input clk,
	input logic [7:0] cmd,
	input logic [32:0]  i_data,  // data by PHY in case of STS, ST, STCS, REP
   output logic [32:0] o_data // output send data to PHY
);
	
	DL_ComandDecoder dl_dec (.cmd(cmd), .clk(clk) );
	
	REGISTERS registers( .clk0(clk), .din0(i_data [7:0]), .dout0(o_data[7:0]) );

endmodule