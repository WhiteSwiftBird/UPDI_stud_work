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

                  
	//APP + CG + CPU_MEM connetction
   wire            ready_from_CG;
   wire            valid_to_CG;
   wire [7:0]      data_to_CG;

   wire [7:0]      addr_mem;
   wire [7:0]      dout_mem;
   wire            csb_mem; 
   wire            web_mem;


	//PHY (without apb_uart connection) + BUFF_MEM connection
   wire            csb0;                   // active low chip select
   wire            web0;                   // active low write control
   wire    [6:0]   addr0;                  // adress in mem
   wire    [11:0]  din0;                   // input data mem
   wire    [11:0]  dout0;                  // ouptup data mem
	wire            rst;                    // PHY reset signal
	wire            ten;                    // transmission enable
	wire            ren;                    // receiving enable
	wire            tend;                   // end-transmission signal
	wire            rend;                   // end-receiving signal


   // Connection between CPU memory and CG
    CPU_MEM mem_inst (
        .clk0(clk),
        .csb0(csb_mem),
        .web0(web_mem),
        .addr0(addr_mem),
        .din0(8'b0),  
        .dout0(dout_mem)
    );

    Memory_Reader reader_inst (
        .i_clk(clk),
        .i_resetn(i_resetn),
        .o_done(),
        .o_data(data_to_CG),
        .o_valid(valid_to_CG),
        .i_ready(ready_from_CG),
        .i_write(i_write),
        .csb0(csb_mem),
        .web0(web_mem),
        .addr0(addr_mem),
        .dout0(dout_mem)
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
  
	//Physical layer responsible for transmission and receiving data to/from external source
   PHY
   physical_layer_inst
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
   buffer_memory_inst 
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