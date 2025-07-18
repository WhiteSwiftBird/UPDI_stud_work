`timescale 1ns / 1ps


module CPU_MEM(
// Port 0: RW
    clk0,csb0,web0,addr0,din0,dout0
  );

  parameter DATA_WIDTH = 8 ;
  parameter ADDR_WIDTH = $clog2(256) ;
  parameter RAM_DEPTH = 256 ;


  input  clk0; // clock
  input  csb0; // active low chip select
  input  web0; // active low write control
  input [ADDR_WIDTH-1:0]  addr0;
  input [DATA_WIDTH-1:0]  din0;
  output [DATA_WIDTH-1:0] dout0;

  //memory itself
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
  always @ (posedge clk0)
  begin : MEM_WRITE0
    if ( !csb0_reg && !web0_reg ) begin
        mem[addr0_reg][DATA_WIDTH-1:0] = din0_reg[DATA_WIDTH-1:0];
    end
  end

  // Memory Read Block Port 0
  // Read Operation : When web0 = 1, csb0 = 0
  always @ (posedge clk0)
  begin : MEM_READ0
    if (!csb0_reg && web0_reg)
       dout0 <= mem[addr0_reg];
  end

endmodule
