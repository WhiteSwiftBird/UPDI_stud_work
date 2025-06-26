//////////////////////////////////////////////////////////////////////////////////
// Company: POLYTHEC
// Engineer: ARTEM
// 
// Create Date: 25.06.2025 00:17:38
// Design Name: UPDI Physical level loader
// Module Name: PHY_LOADER
// Project Name: 
// Target Devices: UPDI
// Tool Versions: 
// Description: Loader of prepared in CG data, use UART to t/r data to AVR
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module PHY_LOADER (
	
    input clk,
	 input rst,   //reset while start UPDI
    input ten,  //transmission enable
    input ren, //receive enable
	 //input ACK, //acknowledge bit, unnecessary
    output csb0,
    output web0,
    output [6:0]  addr0,
	 inout [11:0] io_data, //не забыть положить сюда данные, в самом топовом модуле соединить соответсвующий выход с память BUFF_MEM
	 input prdata, //RX UART
	 output pwdata,  //TX UART
	 output tend,  //end-transmission signal
	 output rend  //end-receiving signal	 
	
    );
	
	logic [11:0] io_data_reg;
	logic [4:0]  counter;
	
	enum logic [1:0] {IDLE = 2'b00, TR = 2'b01, RC = 2'b10} state, next_state;
	
	
	
	always_ff @(posedge clk)
	  if (!rst)
	    state <= IDLE;
	  else
	    state <= next_state;
	
	
   always_comb
	  begin
		
		 next_state = state;
		
		 case (state)
		    
			 IDLE:      if (!ten)
			            next_state = TR;
						  
					      else if (!ren)
					      next_state = RC;
						  
			 TR:        if (!tend && !ren)
			            next_state = RC;
							
						   else if (!tend && ren)
						   next_state = IDLE;
						  
			 RC:        if (!rend)
			            next_state = IDLE;
						  
			 default:   next_state = IDLE;
		
		 endcase 
		
	  end
	
   always_ff @(posedge clk)
      begin
		  
		  case (state)
		  
            IDLE: begin
				
				        csb0 <= 1'b1;
				        counter <= '0;
						  addr0 <= '0;
						  tend <= 1'b0;
						  rend <= 1'b0;
		              io_data_reg <= '0;
						  
			         end
			   //transmission
            TR:   begin
				        if (counter == 0)
						    begin
							 
							   csb0 <= 1'b0;
							   web0 <= 1'b1;
						      io_data_reg <= io_data;
								
							 end
						  
	                 if (counter < 12)
				          begin
				
				            pwdata <= io_data_reg[0];
					         io_data_reg <= io_data_reg >> 1;
					         counter <= counter + 1;
					 
					       end
					 
				        else
				          begin
					  
					         counter <= 1'b0;
                        addr0 <= addr0 + 1;
					  
					       end
					  
				        //end of transmission
				        if ( (&addr0) && (counter == 11) )
				          begin 
					  
					         addr0 <= '0;
					         tend <= 1'b0;
					  
					       end
				        else
				            tend <= 1'b1;	
					
			
	               end 
						
				//receiving	
            RC:   begin
				        if (counter < 12)
						    begin
							 
							   io_data_reg [counter] <= prdata;
								counter <= counter + 1;
								
							 end
							 
				        else
				          begin
					         
								csb0 <= 1'b0;
								web0 <= 1'b0;
								io_data <= io_data_reg;
					         counter <= 1'b0;
                        addr0 <= addr0 + 1;
					  
					       end
							 
				        if ( (&addr0) && (counter == 11) )
				          begin 
					  
					         addr0 <= '0;
					         rend <= 1'b0;
					  
					       end
				        else
				            rend <= 1'b1;	
						  
						  
						end
				
            default: begin
				
				           csb0 = 1'b1;
				           counter = '0;
						     addr0 = '0;
						     tend = 1'b0;
						     rend = 1'b0;
		                 io_data_reg = '0;
							  
			            end
			endcase
		
		  
        end
			     
		  
endmodule