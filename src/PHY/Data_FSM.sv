module Data_FSM(
    input             clk,
    input             rst,


    input             i_valid,             //valid of i_next_state_TopFSM
    input   [1:0]     i_next_state_TopFSM, //the next state of FSM (from DL)
    output  [1:0]     o_next_state_TopFSM,

    output [7:0]     o_data,               //instructions and data transmitted to DL
    input  [7:0]     i_data,               //instructions and data that must be transmitted to DL

    output           o_valid,              //valid of transmitted data
)

//FSM states
enum logic
{
    GIVE_DATA              = 1'b0,
    WAITING_FOR_NEXT_STATE = 1'b1
} state, next_state;



//FSM
always_comb 
begin
    next_state = GIVE_DATA;
    o_valid = 0;

    case (state)
    GIVE_DATA: 
    begin
        o_valid = 1;
        o_data = i_data;
        next_state = WAITING_FOR_NEXT_STATE;
    end

    WAITING_FOR_NEXT_STATE:
    begin
        if(i_valid)
        begin
            next_state = GIVE_DATA; 
            o_next_state_TopFSM = i_next_state_TopFSM;
        end 
        else
            next_state = WAITING_FOR_NEXT_STATE;
    end

    endcase
end

always_ff @(posedge clk)
begin
    if(rst)
    begin
        state <= GIVE_DATA;
    end
    else
    begin
        state <= next_state;
    end
end

endmodule