module Memory_Reader #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = $clog2(256)
)(
    input                       i_clk,
    input                       i_resetn,
    output reg                  o_done,

    output reg [DATA_WIDTH-1:0] o_data,
    output reg                  o_valid,
    input                       i_ready, 

    output reg                  o_repeats_valid,
    output reg [DATA_WIDTH-1:0] o_repeats,

    // memory interface
    output reg                  csb0,
    output reg                  web0,
    output reg [ADDR_WIDTH-1:0] addr0,
    input      [DATA_WIDTH-1:0] dout0
);

    reg [2:0] state;
    localparam IDLE             = 0,
               WAIT_READ_COUNT  = 1,
               READ_COUNT       = 2,
               WAIT_DATA        = 3,
               OUTPUT_DATA      = 4,
               DONE             = 5;

    reg [ADDR_WIDTH-1:0] counter;
    reg [7:0] total_count;
    reg [7:0] dout_reg;

    always @(posedge i_clk) begin
        if (!i_resetn) begin
            state <= IDLE;
            o_done <= 0;
            o_valid <= 0;
            csb0 <= 1;
            web0 <= 1;
            addr0 <= 0;
            counter <= 0;
            total_count <= 0;
            o_repeats_valid <= 0;
        end else begin
            case (state)
                IDLE: begin
                    o_done <= 0;
                    o_valid <= 0;
                    o_repeats_valid <= 0;
                    if (i_ready) begin
                        csb0 <= 0;
                        web0 <= 1;
                        addr0 <= 0;
                        state <= WAIT_READ_COUNT;
                    end
                end

                WAIT_READ_COUNT: begin
                    state <= READ_COUNT;
                end

                READ_COUNT: begin
                    total_count <= dout0;
                    o_repeats <= (dout0 > 4) ? (dout0 - 4) : 0;
                    o_repeats_valid <= 1;
                    counter <= 1;
                    addr0 <= 1;
                    state <= WAIT_DATA;
                end

                WAIT_DATA: begin
                    state <= OUTPUT_DATA;
                end

                OUTPUT_DATA: begin
                    o_valid <= 0;
                    if (i_ready) begin
                        o_valid <= 1;
                        o_data <= dout0;
                        counter <= counter + 1;
                        addr0 <= counter + 1;
                        if (counter == total_count) begin
                            o_repeats_valid <= 0;
                            o_done <= 1;
                            state <= o_done;
                        end else begin
                            state <= WAIT_DATA;
                        end
                    end
                end

                DONE: begin
                    if (!i_ready) begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end



endmodule
