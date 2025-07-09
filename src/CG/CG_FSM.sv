module CG_FSM(
  input         i_clk,
                i_rstn,

  input  [7:0]  i_data,
  input         i_valid,

  output        o_ready,
  input         i_write,
  
  output        o_trans_en,
  output [11:0] o_data,
  output        o_valid,
  output        o_write
);


logic       parity;
logic [7:0] data_q, data_next;
logic [9:0] frame_counter_q, frame_counter_next;
logic [7:0] repeat_number_q, repeat_number_next;
logic       valid_next, valid_q;
logic       ready_next, ready_q;
logic       trans_en_next, trans_en_q;


enum logic [2:0] {
    SYNCH         = 3'b000,
    REPEAT        = 3'b001,
    RPT_0         = 3'b010,
    SYNCH_REP     = 3'b011,
    INSTRUCTION   = 3'b100,
    DATA          = 3'b101
}
state, new_state;

always_comb
begin
    trans_en_next      = trans_en_q;
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
        ready_next = 1;
        valid_next = 0;

        if(i_valid) 
        begin
            data_next = 8'h55;
            valid_next = 0;

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
        ready_next = 0;
    end


    RPT_0:
    begin
        data_next  = repeat_number_q;
        valid_next = 1;
        ready_next = 0;

        new_state = INSTRUCTION;
    end

    SYNCH_REP:
    begin
        data_next = 8'h55;
        new_state = INSTRUCTION;
        valid_next = 1;
        ready_next = 0;
    end


    INSTRUCTION:
    begin
        data_next  = 8'b01100100;
        valid_next = 1;
        ready_next = 1;

        new_state = DATA;
    end


    DATA:
    begin
        if(i_valid) 
        begin
            ready_next = 1;
            valid_next = 1;
            data_next  = i_data;

            if(frame_counter_q == 1)
            begin
                new_state     = SYNCH;
                trans_en_next = 1;
            end
            else
            begin
                new_state = DATA;
                frame_counter_next = frame_counter_q - 1;
            end
        end
    end
    endcase
end


assign parity = ^data_q;
assign o_data = {1'b0, data_q, parity, 2'b11};
assign o_write    = i_write;
assign o_ready    = ready_q;
assign o_trans_en = trans_en_q;
assign o_valid    = valid_q;

always_ff @( posedge i_clk ) begin
    if (~i_rstn)
    begin
        state <= SYNCH;
        data_q <= '0;
        frame_counter_q <= '0;
        ready_q <= '0;
        valid_q <= '0;
        trans_en_q <= '0;
    end
    else
    begin
        state <= new_state;
        data_q <= data_next;
        frame_counter_q <= frame_counter_next;
        ready_q <= ready_next;
        valid_q <= valid_next;
        trans_en_q <= trans_en_next;
    end
end

endmodule