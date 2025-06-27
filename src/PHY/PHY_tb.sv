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

module PHY_tb ;

    logic clk;
    logic rst;
    logic ten; //transmission enable
    logic ren;
    logic csb0;
    logic web0;
    logic [6:0]  addr0;
    logic [11:0] i_data;
    logic [11:0] o_data;	 
    logic tend;  //end-transmission signal
    logic rend;  //end-receiving signal
    logic pwdata; 
    logic prdata; 
	
    int iterator, error, cnt, one_delay;
	 
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
		  
		  $readmemb("D:/UPDI Project RADAR/UPDI_stud_work/src/PHY/PHY_tb_tv.tv", tv);
		  iterator = 0;
		  cnt = 0;
		  { ten, ren, i_data } = tv [0];
		  error = 0;
		  one_delay = 0;
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
		
    always @(negedge clk)
	   begin
		  
		  
		  if (cnt == 0)
		    begin
			 
		      //#1;
            { ten, ren, i_data } = tv [iterator];
				
			 end
		  
		  if (one_delay > 2)
		    begin
		    cnt += 1;
			 end
			 
		  one_delay += 1;
		  
		  if (cnt < 12)
		    begin
			 
			 
			   if ( pwdata != i_data [cnt])
			     begin
				
				  $error ("Error detected in %d position, in %d line", cnt, iterator);
				  error += 1;
				
				  end
				
			 
		    end
			 
		  if (cnt == 12)
		    begin
			 
		      cnt = 0;
				iterator += 1;
				{ ten, ren, i_data } = tv [iterator];
				
			 end
			 
		  if ( tv [iterator] === 'x )
		    begin
				
				  $display ("Test ended in %d iterations and handle %d errors", iterator + 1, error);
				  $stop;
				  
			 end
	     
	   end
		
		
		
		
endmodule