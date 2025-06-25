`timescale 1ns / 1ps

module tb_top;

    reg clk;
    reg resetn;
    reg start;
    wire done;
    wire valid;
    wire repeats_valid;
    wire [7:0] data_out;
    wire [7:0] repeats;

    // ??????????? top-??????
    top dut (
        .clk(clk),
        .resetn(resetn),
        .start(start),
        .done(done),
        .valid(valid),
        .repeats_valid(repeats_valid),
        .data_out(data_out),
        .repeats(repeats)
    );
    integer i;
    // ???????? ?????????
    always #5 clk = ~clk;
    
    initial begin
        clk = 1;
        resetn = 0;
        start = 0;

        // ?????
        #20;
        resetn = 1;

    
	
        force dut.mem_inst.mem[0] = 8'd120;
	
        for (i = 1; i <= 120; i = i + 1) begin
            force dut.mem_inst.mem[i] = i[7:0]; 
        end

        #20;

        // ?????? ??????
        start = 1;
        #10;
        start = 0;

        
        wait (done);
        #20;
        
    end

    // ?????????? ?????
    always @(posedge clk) begin
        if (repeats_valid)
            $display("Time %t: REPEATS = %0d", $time, repeats);
        if (valid)
            $display("Time %t: DATA OUT = %0d", $time, data_out);
    end

endmodule
