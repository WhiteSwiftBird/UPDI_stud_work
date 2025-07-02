`timescale 1ns / 1ps

module tb_top;

    reg i_clk;
    reg i_resetn;
    reg i_ready;
    wire o_done;
    wire o_valid;
    wire o_repeats_valid;
    wire [7:0] o_data;
    wire [7:0] o_repeats;

    // ??????????? top-??????
    top_APP dut (
        .i_clk(i_clk),
        .i_resetn(i_resetn),
        .o_done(o_done),
        .o_valid(o_valid),
        .i_ready(i_ready),
        .o_repeats_valid(o_repeats_valid),
        .o_data(o_data),
        .o_repeats(o_repeats)
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

        i_ready = 1;
        #10;


        
        wait (o_done);
        #20;
        
    end

    // ?????????? ?????
    always @(posedge i_clk) begin
        if (o_repeats_valid)
            $display("Time %t: o_repeats = %0d", $time, o_repeats);
        if (o_valid)
            $display("Time %t: DATA OUT = %0d", $time, o_data);
    end

endmodule