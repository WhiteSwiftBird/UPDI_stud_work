module CG_FSM(
  input         i_clk,
                i_rst,

  input  [7:0]  i_data,
                i_valid,

  output        o_ready,
  input         i_write,
  
  output        o_trans_en,
  output [11:0] o_data,
  output        o_valid
)


logic       parity;
logic [7:0] data_q, data_next;
logic [9:0] frame_counter_q, frame_counter_next;
logic [7:0] repeat_number_q, repeat_number_next;
logic       valid_next, valid_q;
logic       ready_next, ready_q;

enum logic [2:0] {
    SYNCH         = 3'b000,
    REPEAT        = 3'b001,
    RPT_0         = 3'b010,
    INSTRUCTION   = 3'b011,
    DATA          = 3'b100
}
state, new_state;

always_comb
begin
    o_ready    = 0;
    o_trans_en = 0;
    o_valid    = 0;

    frame_counter_next = frame_counter_q;
    new_state          = state;
    repeat_number_next = repeat_number_q;
    data_next          = data_q;
    valid_next         = valid_q;
    ready_next         = ready_q;
    

    case (state)
    SYNCH:
    begin
        data_next = 0;
        repeat_number_next = 0;
        o_ready = 1;
        valid_next = 0;

        if(i_valid) 
        begin
            data_next = 8'h55;
            valid_next = 1;

            if(i_data == 0)
            begin
                new_state = INSTRUCTION;
            end
            else
            begin
                repeat_number_next = i_data;
                new_state     = REPEAT;
            end
        end
    end



    REPEAT:
    begin
        data_next = 8'b10100000;
        new_state = RPT_0;
        valid_next = 1;
        o_ready = 0;
    end


    RPT_0:
    begin
        data_next  = repeat_number_q;
        valid_next = 1;
        o_ready    = 0;

        new_state = INSTRUCTION;
    end


    INSTRUCTION:
    begin
        data_next  = 8'b00100100;
        valid_next = 1;
        o_ready    = 1;

        new_state = DATA;
    end


    DATA:
    begin
        o_ready    = 1;
        valid_next = 1;
        data_next  = i_data;

        if(frame_counter_q == 1)
        begin
            new_state = SYNCH;
            o_trans_en = 1;
        end
        else
        begin
            new_state = DATA;
            frame_counter_next = frame_counter_q - 1;
        end
    end
    endcase
end


assign parity = ^data_q;
assign o_data = {1'h0, data, parity, 2'h3};


endmodule