module updi_error_handler #(
    parameter DATA_WIDTH = 12 
)(
    input                   clk,
    input  [DATA_WIDTH-1:0] data_in,
    input                   valid_in,
    input                   resetn,
    output reg [DATA_WIDTH-1:0] error_code,
    output reg                error_valid 
);

    localparam ERROR_NONE      = 3'b000;
    localparam ERROR_PARITY    = 3'b001;
    localparam ERROR_STOP_BIT  = 3'b010;
    localparam ERROR_START_BIT = 3'b100;
    
    wire       parity_bit      = data_in[DATA_WIDTH - 3];
    wire [1:0] stop_bits       = data_in[11:10];
    wire       start_bit       = data_in[0];
 
    assign     stop_bit_err    = (stop_bits != 2'b11);
    assign     start_bit_err   = (start_bit != 1'b0);
    assign     parity_err      = (^data_in[DATA_WIDTH-4: 1] != parity_bit);

    always @(posedge clk) begin 
        if (!resetn) begin
            error_code  <= ERROR_NONE;
            error_valid <= 1'b0;
        end
        else begin
            if (valid_in) begin
                if (parity_err) begin
                    error_code  <= ERROR_PARITY;
                    error_valid <= 1'b1;
                end
                else if (stop_bit_err) begin
                    error_code  <= ERROR_STOP_BIT;
                    error_valid <= 1'b1;
                end     
                else if (start_bit_err) begin
                    error_code  <= ERROR_START_BIT;
                    error_valid <= 1'b1;
                end 
                
                else begin
                    error_code  <= ERROR_NONE;
                    error_valid <= 1'b1;  
                end
            end
            else begin
                error_code  <= ERROR_NONE;
                error_valid <= 1'b0;  
            end
        end
    end
endmodule
