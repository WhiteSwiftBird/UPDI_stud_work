//////////////////////////////////////////////////////////////////////////////////
// Company: POLYTHEC
// Engineer: ARTEM
// 
// Create Date: 26.06.2025 00:17:38
// Design Name: UPDI Physical level
// Module Name: PHY
// Project Name: 
// Target Devices: UPDI
// Tool Versions: 
// Description: PHY level of UPDI, w/r info in AVR
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module PHY (

   input clk,
   input rst,
   input ten, //transmission enable
   input ren,
   input logic [11:0] i_data,
   output csb0,
   output web0,
   output [6:0]  addr0,
   output logic [11:0] o_data,
   output tend,  //end-transmission signal
   output rend,  //end-receiving signal
   output pwdata, //убрать и включать только для тестбенчей
   output prdata  //убрать и включать только для тестбенчей
	
   );
	
   //logic pwdata, prdata;
	
   PHY_LOADER loader_from_mem ( 
	
	                             .clk(clk),
	                             .rst(rst), 
	                             .ten(ten), 
	                             .ren(ren), 
	                             .csb0(csb0), 
	                             .web0(web0), 
	                             .addr0(addr0), 
	                             .i_data(i_data),
	                             .o_data(o_data),  
	                             .pwdata(pwdata), 
	                             .prdata(prdata),
	                             .tend(tend),
	                             .rend(rend) 
										  
										);
	
   /*apb_uart UART              ( 
	
	                             .pwdata(pwdata), 
	                             .prdata(prdata) 
										  
	                             );*/
										
endmodule
										