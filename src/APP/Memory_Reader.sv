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

    // memory interface
    input                       i_write,

    output reg                  csb0,
    output reg                  web0,
    output reg [ADDR_WIDTH-1:0] addr0,
    input      [DATA_WIDTH-1:0] dout0
);

    reg [2:0] state;
    localparam IDLE             = 0,
               WAIT_REPEAT      = 1,
               READ_REPEAT        = 2,
               OUTPUT_DATA      = 3,
               DONE             = 4;

    reg [ADDR_WIDTH-1:0] counter;
    reg [7:0] total_count;

    always @(posedge i_clk) begin
        if (!i_resetn) begin
            state       <= IDLE;
            o_done      <= 0;
            o_valid     <= 0;
            csb0        <= 1;
            web0        <= 1;
            addr0       <= 0;
            counter     <= 0;
            total_count <= 0;
        end else begin
            case (state)
                IDLE: begin
                    o_done  <= 0;
                    o_valid <= 0;
                    csb0    <= 0;
                    web0    <= 1;
                    addr0   <= 0;
                    counter <= 0;
                    if (i_write) begin
                        state   <= WAIT_REPEAT;
                    end
                end

                WAIT_REPEAT: begin
                    state <= READ_REPEAT;
                end

                READ_REPEAT: begin
                    if (i_ready) begin
                        o_data  <= (dout0 > 4) ? (dout0 - 4) : 0;;
                        o_valid <= 1;
                        total_count <= dout0;
                        counter <= 1;
                        addr0   <= 1;
                        state   <= OUTPUT_DATA;
                    end
                end

                OUTPUT_DATA: begin
                    if (i_ready) begin
                        o_data  <= dout0;
                        o_valid <= 1;
                        counter <= counter + 1;
                        addr0   <= counter + 1;

                        if (counter == total_count) begin
                            o_done <= 1;
                            state  <= DONE;
                        end
                    end else begin
                        o_valid <= 1;  
                    end
                end

                DONE: begin
                    o_valid <= 0;
                    if (!i_ready) begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule