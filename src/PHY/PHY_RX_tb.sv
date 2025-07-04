//////////////////////////////////////////////////////////////////////////////////
// Company: POLYTHEC
// Engineer: ARTEM
// 
// Create Date: 26.06.2025 00:17:38
// Design Name: PHY rx testbench 
// Module Name: PHY_tb_rx
// Project Name: 
// Target Devices: UPDI
// Tool Versions: 
// Description: testbench of PHY level receiving of UPDI
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Пока не подключен полноценный UART внутренние сигналы PHY нужно выводить наружу для проверки правильности отправки данных
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 10ps / 1ps

module PHY_RX_tb ;

    logic        clk;
    logic        rst;
    logic        ten; 
    logic        ren;
    logic        csb0;
    logic        web0;
    logic [6:0]  addr0;
    logic [11:0] i_data;
    logic [11:0] o_data;	 
    logic        tend; 
    logic        rend;  
    logic        pwdata; 
    logic        prdata; 
	
    int error, cnt;             //variables cnt is a immitation of getting data from mem
	  logic [2:0] tv [1000:0];    //testvector
    //logic [11:0] o_data_reg;
    
    typedef struct {
    
        logic prdt;
    
    } pack;
    
    mailbox#(pack) monitor = new();
    
    PHY_LOADER uut (
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
				
				
    always begin
        #5; clk = ~clk;	
      end	
				
				
    initial begin
		  
		  //variables init
        pack pkt;
		    $readmemb("D:/UPDI Project RADAR/UPDI_stud_work/src/PHY/PHY_tb_rx.tv", tv);
		    cnt = 0;
		    error = 0;
		  
		  //uut signals init
		    { ten, ren, prdata } = tv [0];
        clk = 1;
        rst = 0;
        #10;
        rst = 1;
        
        forever begin
          @(negedge clk)
          
          pkt.prdt = prdata;
          monitor.put(pkt);
          
          { ten, ren, prdata } = tv [cnt];
        
          if ( tv [cnt] === 'x ) begin
              $display ("Test ended in %d iterations and handle %d errors", cnt, error);
              $stop;
              end
          
          cnt++;
          
          end
		  
      end
		
		initial begin
    
        pack pkt_prev, pkt_cur;
      
        wait (rst);
        monitor.get(pkt_prev);
        forever begin
    
          monitor.get(pkt_cur);
          if ( pkt_prev.prdt != o_data[(cnt-2) % 12] ) begin
              $error ("error detected in %d vector", cnt );
              error += 1;
              end
          
          pkt_prev.prdt = pkt_cur.prdt;
          end

        end

        
endmodule