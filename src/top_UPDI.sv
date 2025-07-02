//////////////////////////////////////////////////////////////////////////////////
// Company: POLYTHEC
// Engineer: ARTEM, MARIA, DENIS
// 
// Create Date: 30.06.2025 00:00:00
// Design Name: UPDI TOP MODULE
// Module Name: top_UPDI
// Project Name: 
// Target Devices: UPDI
// Tool Versions: 
// Description: UPDI module for AVR programming
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top_UPDI (

   input          clk,        // clock (??same for every part of UPDI??)
   input          i_resetn,
   input          i_write
   
   
);

                  
	//APP + CG
   wire       ready_from_CG;
   wire       valid_to_CG;
   wire [7:0] data_to_CG;

   top_APP top_APP_inst(
      .i_clk(clk),
      .i_resetn(i_resetn),
      .i_ready(ready_from_CG),
      .i_write(i_write),
      .o_done(),
      .o_valid(valid_to_CG),
      .o_data(data_to_CG)
   );

   CG_FSM CG_FSM_inst(
      .i_clk(clk),
      .i_rstn(i_resetn),
      .i_data(data_to_CG),
      .i_valid(valid_to_CG),
      .o_ready(ready_from_CG),
      .i_write(),
      .o_trans_en(),
      .o_data(),
      .o_valid(),
      .o_write()
   );

	//PHY (without apb_uart connection) + BUFF_MEM connection
   wire           csb0;                   // active low chip select
   wire           web0;                   // active low write control
   wire    [6:0]  addr0;                  // adress in mem
   wire    [11:0] din0;                   // input data mem
   wire    [11:0] dout0;                  // ouptup data mem
	wire           rst;                    // PHY reset signal
	wire           ten;                    // transmission enable
	wire           ren;                    // receiving enable
	wire           tend;                   // end-transmission signal
	wire           rend;                   // end-receiving signal
	

	
	//Physical layer responsible for transmission and receiving data to/from external source
   PHY
   physical_layer
   (
      
      //inputs
      .clk(clk),
      .rst(rst),
      .ten(ten),
      .ren(ren),
      .i_data(dout0),
      
      //outputs
      .csb0(csb0),
      .web0(web0),
      .addr0(addr0),
      .o_data(din0),
      .tend(tend),
      .rend(rend)
      
	);
	
   //UPDI internal buffer memory
   BUFF_MEM 
   buffer_memory 
   (
      
      //inputs
      .clk0(clk), 
      .csb0(csb0), 
      .web0(web0), 
      .addr0(addr0), 
      .din0(din0),
      
      //outputs
      .dout0(dout0)
      
   );

endmodule