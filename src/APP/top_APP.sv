




// module top_APP (
//     input wire        i_clk,
//     input wire        i_resetn,
//     input wire        i_ready,
//     input wire        i_write,
//     output wire       o_done,
//     output wire       o_valid,
//     output wire [7:0] o_data
// );

//     wire [7:0]   addr_mem;
//     wire [7:0]   dout_mem;
//     wire csb_mem, web_mem;

//     CPU_MEM mem_inst (
//         .clk0(i_clk),
//         .csb0(csb_mem),
//         .web0(web_mem),
//         .addr0(addr_mem),
//         .din0(8'b0),  
//         .dout0(dout_mem)
//     );


//     Memory_Reader reader_inst (
//         .i_clk(i_clk),
//         .i_resetn(i_resetn),
//         .o_done(o_done),
//         .o_data(o_data),
//         .o_valid(o_valid),
//         .i_ready(i_ready),
//         .i_write(i_write),
//         .csb0(csb_mem),
//         .web0(web_mem),
//         .addr0(addr_mem),
//         .dout0(dout_mem)
//     );

// endmodule

