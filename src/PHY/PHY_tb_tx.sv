//////////////////////////////////////////////////////////////////////////////////
// Company: POLYTHEC
// Engineer: ARTEM
// 
// Create Date: 26.06.2025 00:17:38
// Design Name: PHY testbench
// Module Name: PHY_tb
// Project Name: 
// Target Devices: UPDI
// Tool Versions: 
// Description: testbench of PHY level of UPDI
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Пока не подключен полноценный UART внутренние сигналы PHY нужно выводить наружу для проверки правильности отправки данных
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 10ps / 1ps

module PHY_tb_tx ;

    logic clk;
    logic rst;
    logic ten; 
    logic ren;
    logic csb0;
    logic web0;
    logic [6:0]  addr0;
    logic [11:0] i_data;
    logic [11:0] o_data;	 
    logic tend; 
    logic rend;  
    logic pwdata; 
    logic prdata; 
	
    int iterator, error, cnt, one_delay; //variables cnt is a immitation of getting data from mem
	 
	 logic [13:0] tv [1000:0]; //testvector

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
				
				
				
				
    initial 
      begin
		  
		  //variables init
		  $readmemb("D:/UPDI Project RADAR/UPDI_stud_work/src/PHY/PHY_tb_tx.tv", tv);
		  iterator = 0;
		  cnt = 0;
		  error = 0;
		  one_delay = 0;
		  
		  //uut signals init
		  { ten, ren, i_data } = tv [0];
		  rst = 0;
		  clk = 1;
		  #5;
		  rst = 1;
		  
      end
		
		
    always 
      begin
		  
        #5;
        clk = ~clk;
		
      end
		
		
    always @(posedge clk)
      begin
		  
        if (cnt < 12)
          begin
			 
			 //added delay for simulation cnt var, due to faster simulation execution than real module execution
				if (one_delay > 1)
		        begin
				  
		          cnt += 1;
					 
			     end
				  
				  
		      one_delay += 1;
				
				
			   if ( pwdata != i_data [cnt-1])
			     begin
				
				  $error ("Error detected in %d position, in %d line", cnt, iterator);
				  error += 1;
				
				  end
				
            end
			 
			 
		  if ( tv [iterator] === 'x )
		    begin
				
				  $display ("Test ended in %d iterations and handle %d errors", iterator + 1, error);
				  $stop;
				  
			 end
	     
	   end
		
		always @(negedge clk)
		    if (cnt == 11)
		    begin
			 
				cnt = -1;
				iterator += 1;
				{ ten, ren, i_data } = tv [iterator];
				
			 end
		
		
endmodule