`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: POLYTHEC
// Engineer: ARTEM
// 
// Create Date: 25.06.2025 00:17:38
// Design Name: UPDI CPU_MEM
// Module Name: CPU_MEM
// Project Name: 
// Target Devices: UPDI
// Tool Versions: 
// Description: CPU Memory for loading packets by CPU, that must be converted into comand frames
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CPU_MEM(
// Port 0: RW
    clk0,csb0,web0,addr0,din0,dout0
  );

  parameter DATA_WIDTH = 8 ;
  parameter ADDR_WIDTH = $clog2(128) ;
  parameter RAM_DEPTH = 128 ;


  input  clk0; // clock
  input  csb0; // active low chip select
  input  web0; // active low write control
  input [ADDR_WIDTH-1:0]  addr0;
  input [DATA_WIDTH-1:0]  din0;
  output [DATA_WIDTH-1:0] dout0;

  //вот это по сути и есть память, вот этот вот массив регистров
  reg [DATA_WIDTH-1:0]  mem [0:RAM_DEPTH-1];
  
  reg  csb0_reg;
  reg  web0_reg;
  reg [ADDR_WIDTH-1:0]  addr0_reg;
  reg [DATA_WIDTH-1:0]  din0_reg;
  reg [DATA_WIDTH-1:0]  dout0;

  // All inputs are registers
  always @(posedge clk0)
  begin
    csb0_reg = csb0;
    web0_reg = web0;
    addr0_reg = addr0;
    din0_reg = din0;
  end


  // Memory Write Block Port 0
  // Write Operation : When web0 = 0, csb0 = 0
  always @ (negedge clk0)
  begin : MEM_WRITE0
    if ( !csb0_reg && !web0_reg ) begin
        mem[addr0_reg][7:0] = din0_reg[7:0];
    end
  end

  // Memory Read Block Port 0
  // Read Operation : When web0 = 1, csb0 = 0
  always @ (negedge clk0)
  begin : MEM_READ0
    if (!csb0_reg && web0_reg)
       dout0 <= mem[addr0_reg];
  end

endmodule