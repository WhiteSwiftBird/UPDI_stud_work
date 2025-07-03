//////////////////////////////////////////////////////////////////////////////////
// Company: POLYTHEC
// Engineer: ARTEM
// 
// Create Date: 26.06.2025 00:17:38
// Design Name: PHY tx testbench 2ed
// Module Name: PHY_tb_tx
// Project Name: 
// Target Devices: UPDI
// Tool Versions: 
// Description: testbench of PHY level transmission of UPDI
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Пока не подключен полноценный UART внутренние сигналы PHY нужно выводить наружу для проверки правильности отправки данных
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 10ps / 1ps

module PHY_TX_tb ;

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
	
    int iterator, error, cnt;             //variables cnt is a immitation of getting data from mem
	 
    logic [13:0] tv [1000:0];             //testvector
	 
    typedef struct {
        
        logic idt;
         
    } pack;                                //structures mailboxed in inital blocks to carry prev iteration
    
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
        $readmemb("D:/UPDI Project RADAR/UPDI_stud_work/src/PHY/PHY_tb_tx.tv", tv);
        iterator = 0;
        cnt = 0;
        error = 0;
		  
		  //uut signals init
        { ten , ren , i_data } = tv [0];
        clk = 1;
        rst = 0;
        #10;
        rst = 1;
        
        forever begin
          @(negedge clk)
                      
          pkt.idt = i_data[cnt];
          monitor.put(pkt);
          
          if (cnt == 11) begin
            iterator += 1;
            cnt = 0;
            { ten , ren , i_data } <= tv [iterator];
            if ( tv [iterator] === 'x ) begin
              $display ("Test ended in %d iterations and handle %d errors", iterator + 1, error);
              $stop;
              end
            continue;
            end
            
          cnt++;
          
          end
          
        end  

    initial begin
      
        pack pkt_prev, pkt_cur;
      
        wait(rst);
        monitor.get(pkt_prev);
        forever begin
        
          monitor.get(pkt_cur);
          if (pwdata != pkt_prev.idt) begin
            $error ("error detected in %d position, in %d testvector line", cnt, iterator );
            error += 1;
          end
          
          pkt_prev.idt = pkt_cur.idt;
          end
          
        end
		
endmodule