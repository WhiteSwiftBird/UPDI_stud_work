`timescale 1ns / 1ps

module tb_top;

    reg i_clk;
    reg i_resetn;
    reg i_ready;
    reg i_write;
    wire o_done;
    wire o_valid;
    wire [7:0] o_data;


    // ??????????? top-??????
    top_APP dut (
        .i_clk(i_clk),
        .i_resetn(i_resetn),
        .o_done(o_done),
        .o_valid(o_valid),
        .i_ready(i_ready),
	.i_write(i_write),
        .o_data(o_data)
    );
    integer i;
    // ???????? ?????????
    always #5 i_clk = ~i_clk;
    always #10 i_ready = ~i_ready;
    initial begin
        i_clk = 1;
        i_resetn = 0;
	

        // ?????
        #20;
        i_resetn = 1;

    
	
        force dut.mem_inst.mem[0] = 8'd120;
	
        for (i = 1; i <= 120; i = i + 1) begin
            force dut.mem_inst.mem[i] = i[7:0]; 
        end

        #20;

        // ?????? ??????
	i_write = 1;
        i_ready = 1;
        #10;
	i_write = 0;


        
        wait (o_done);
        #20;
        
    end



endmodule