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
	
     input              clk,     //clock
     input              rst,    //reset while start UPDI
     input logic        ten,   //transmission enable
     input logic        ren,  //receive enable
     input logic [11:0] i_data,    //data frrom mem
     input logic        prdata,   //RX UART
    output logic        csb0,    //chip select mem
    output logic        web0,   //write enable mem
    output logic [6:0]  addr0, //word addr in mem
    output logic [11:0] o_data,  //data to mem
    output logic        pwdata, //TX UART
    output logic        tend,  //end-transmission signal
    output logic        rend  //end-receiving signal	 
	
    );
	
    //logic [11:0] o_data_reg;
    logic [3:0]  counter;
	
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
	
    always_ff @(negedge clk)
      begin
		  
        case (state)
		  
            IDLE: begin
				
                        csb0 <= 1'b1;
                        counter <= '0;
                        addr0 <= '0;
                        tend <= 1'b0;
                        rend <= 1'b0;
                        //o_data_reg <= '0;
						  
                   end
						
			   //transmission
            TR:   begin
                    if (counter == 0)
                      begin
							 
                        csb0 <= 1'b0;
                        web0 <= 1'b1;
								
                      end
						  
                    if (counter < 12)
                      begin
				
                        pwdata <= i_data[counter];
                        counter <= counter + 1;
					 
                      end
					 
                    if (counter == 11)
                      begin
					  
                        counter <= '0;
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
				
                    if (counter == 0)
                      begin
							 
                        csb0 <= 1'b0;
                        web0 <= 1'b0;
								
                      end
							 
                    if (counter < 12)
                      begin
							 
                        o_data [counter] <= prdata;
                        counter <= counter + 1;
								
                      end
							 
                    if (counter == 12)
                      begin
					         
                        counter <= '0;
                        addr0 <= addr0 + 1;
					  
                      end
						  
						  //end of receiving 
                    if ( (&addr0) && (counter == 11) )
                      begin 
					  
                        addr0 <= '0;
                        rend <= 1'b0;
					  
                      end
                     else
                        rend <= 1'b1;	
						  
						  
                   end
				
            default: begin
				
                        csb0 <= 1'b1;
                        counter <= '0;
                        addr0 <= '0;
                        tend <= 1'b0;
                        rend <= 1'b0;
                        //o_data_reg = '0;
							  
                     end
          endcase
		
		  
        end
			     
		  
endmodule