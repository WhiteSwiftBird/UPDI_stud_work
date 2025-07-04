//////////////////////////////////////////////////////////////////////////////////
// Company: POLYTHEC
// Engineer: ARTEM, MARIA, DENIS
// 
// Create Date: 04.07.2025 00:00:00
// Design Name: UPDI TOP MODULE testbench
// Module Name: top_UPDI
// Project Name: 
// Target Devices: UPDI
// Tool Versions: 
// Description: testbench for transmision
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 10ps / 1ps

module CPU_MEM_tb;

    //signals
    logic          clk;        // clock (??same for every part of UPDI??)
    //logic          i_resetn;
    //logic          i_write;
    logic        csb0; // active low chip select
    logic        web0; // active low write control
    logic [7:0]  addr0;
    logic [7:0]  din0;
    logic [7:0] dout0;
    logic [7:0] i_data_fill;
    logic [7:0] o_data_check;
    
    //non-signal var
    int cnt, error, ready;
    logic [7:0] tv [1000:0];
    
    CPU_MEM UUT (
    
        .clk0(clk),
        .csb0(csb0),
        .web0(web0),
        .addr0(addr0),
        .din0(din0),
        .dout0(dout0)
    
    );
    
    task automatic mem_filling (ref logic clk, inout logic [7:0] addr, inout logic [7:0] i_data_fill, output csb0, output web0, inout int cnt);
      @(posedge clk)
      csb0 = 0;
      web0 = 0;
      addr = addr + 1;
      din0 = i_data_fill;
      
      cnt++;
    endtask
   
    task automatic mem_checking (ref logic clk, inout logic [7:0] addr, output csb0, output web0, inout int cnt);
      @(posedge clk)
      csb0 = 0;
      web0 = 1;
      addr = addr + 1;
      
      cnt++;
    endtask
   
    always begin
    #5; clk = ~clk;
    end
   
   
    //fill
    initial begin
      $readmemb ("D:/UPDI Project RADAR/UPDI_stud_work/src/CPU_MEM_tb_tx.tv", tv);
      cnt = 0;
      ready = 0;
      i_data_fill = tv[cnt];
      
      clk = 0;
      addr0 = '1;
      csb0 = 1;
      web0 = 1;
      din0 = '0;
      
      //@(posedge clk)
      repeat (255) begin
      
        if (tv[cnt] === 'x)
          break;
        
        mem_filling (clk, addr0, i_data_fill, csb0, web0, cnt);
        i_data_fill = tv[cnt];

        end
        
      @(posedge clk)
        ready = 1;
        
      end
    
    //check filling for later top_module check
    initial begin
      
        wait (ready);
        cnt = 0;
      
        addr0 = '1;
        csb0 = 1;
        web0 = 0;
        din0 = '0;
        
        @(posedge clk)
        repeat (258) begin
        
          mem_checking (clk, addr0, csb0, web0, cnt);
          if (dout0 != tv [cnt-3]) begin
          
              $error ("Error occured in %d word, expected %b", cnt, tv [cnt] );
              error++ ;
          
              end
          end
        
        $display ("Test completed, found %d errors", error);
        $stop;
          
        end
    
endmodule
    
    
    