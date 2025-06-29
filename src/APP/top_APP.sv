module top (
    input wire        clk,
    input wire        resetn,
    input wire        start,
    input wire        ready,
    output wire       done,
    output wire       valid,
    output wire       repeats_valid,
    output wire [7:0] data_out,
    output wire [7:0] repeats
);

    wire [7:0]   addr_mem;
    wire [7:0]   dout_mem;
    wire csb_mem, web_mem;

    CPU_MEM mem_inst (
        .clk0(clk),
        .csb0(csb_mem),
        .web0(web_mem),
        .addr0(addr_mem),
        .din0(8'b0),  
        .dout0(dout_mem)
    );


    Memory_Reader reader_inst (
        .clk(clk),
        .resetn(resetn),
        .start(start),
        .done(done),
        .data_out(data_out),
        .valid(valid),
        .ready(ready),
        .repeats(repeats),
        .repeats_valid(repeats_valid),
        .csb0(csb_mem),
        .web0(web_mem),
        .addr0(addr_mem),
        .dout0(dout_mem)
    );

endmodule

