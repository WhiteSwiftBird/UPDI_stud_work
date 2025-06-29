module Memory_Reader #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = $clog2(256)
)(
    input                       clk,
    input                       resetn,
    input                       start,
    output reg                  done,

    output reg [DATA_WIDTH-1:0] data_out,
    output reg                  valid,
    input                       ready, 

    output reg                  repeats_valid,
    output reg [DATA_WIDTH-1:0] repeats,

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

    always @(posedge clk) begin
        if (!resetn) begin
            state <= IDLE;
            done <= 0;
            valid <= 0;
            csb0 <= 1;
            web0 <= 1;
            addr0 <= 0;
            counter <= 0;
            total_count <= 0;
            repeats_valid <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    valid <= 0;
                    repeats_valid <= 0;
                    if (start) begin
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
                    repeats <= (dout0 > 4) ? (dout0 - 4) : 0;
                    repeats_valid <= 1;
                    counter <= 1;
                    addr0 <= 1;
                    state <= WAIT_DATA;
                end

                WAIT_DATA: begin
                    state <= OUTPUT_DATA;
                end

                OUTPUT_DATA: begin
                    valid <= 0;
                    if (ready) begin
                        valid <= 1;
                        data_out <= dout0;
                        counter <= counter + 1;
                        addr0 <= counter + 1;
                        if (counter == total_count) begin
                            repeats_valid <= 0;
                            done <= 1;
                            state <= DONE;
                        end else begin
                            state <= WAIT_DATA;
                        end
                    end
                end

                DONE: begin
                    if (!start) begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end



endmodule
