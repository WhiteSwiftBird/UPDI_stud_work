module Memory_Reader #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = $clog2(256)
)(
    input                       clk,
    input                       resetn,  
    input                       start,
    output reg                  done, // reading done
    output reg [DATA_WIDTH-1:0] data_out,
    output reg                  valid,
    output reg                  repeats_valid,
    output reg [DATA_WIDTH-1:0] repeats, 

    // memory interface
    output reg                  csb0,
    output reg                  web0,
    output reg [ADDR_WIDTH-1:0] addr0,
    input      [DATA_WIDTH-1:0] dout0
);

    reg [1:0] state;
    localparam IDLE = 0, SET_ADDR = 1, READ_COUNT = 2, READ_DATA = 3, DONE = 4;

    reg [DATA_WIDTH-1:0] counter;
    reg [DATA_WIDTH-1:0] total_count;

    always @(posedge clk) begin
        if (!resetn) begin
            state <= IDLE;
            total_count <= '0;
            counter <= '0;
            csb0 <= 1;
            web0 <= 1;
            addr0 <= 0;
            valid <= 0;
            done <= 0;
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
                        state <= SET_ADDR;
                    end
                end
                SET_ADDR: begin
                    counter <= 1;
                    addr0 <= 1;
                    state <= READ_COUNT;
                end
                READ_COUNT: begin
                    total_count <= dout0;
                    repeats     <= (dout0 > 4) ? (dout0 - 4) : 0;
                    repeats_valid <= 1;
                    addr0 <= counter + 1;
                    counter <= counter + 1;
                    state <= READ_DATA;
                end

                READ_DATA: begin
                    if (counter <= total_count + 1) begin
                        data_out <= dout0;
                        valid <= 1;
                        repeats_valid <= 0;
                        addr0 <= counter + 1;
                        counter <= counter + 1;
                    end else begin
                        valid <= 0;
			            repeats_valid <= 0;
                        done <= 1;
                        state <= DONE;
                    end
                end

                DONE: begin
                    if (!start) state <= IDLE;
                end
            endcase
        end
    end
endmodule
