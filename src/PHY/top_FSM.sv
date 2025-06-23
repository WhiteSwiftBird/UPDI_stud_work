module top_FSM(
    input            clk,
    input            rst,

    input  [7:0]     i_data_to_write, //data to be output to the serial port
    input            i_valid,         //validity of data output to the serial port
    input  [1:0]     i_next_state,    //the next state of FSM (from DL)

    output [7:0]     o_data,          //instructions and data transmitted to DL

    input  [11:0]    i_prdata,        //apb_uart read data
    output [11:0]    o_pwdata,        //apd_uart write data

    output           o_valid_DataFSM,
    input            i_valid_DataFSM

)

//FSM states
enum logic [1:0]
{
    IDLE  = 2'b00,
    SYNCH = 2'b01,
    DATA  = 2'b10,
    SERIAL_WRITE = 2'b11
} state, next_state;


//FSM
always_comb 
begin
    next_state = IDLE;

    case (state)
    IDLE: 
    begin
        //как-то понять что пришел SYNCH сигнал
        next_state = SYNCH;
    end

    SYNCH:
    begin
        //добавить логику для получения сигнала синхронизации
        next_state = DATA; 
    end

    DATA:
    begin
        Data_FSM (clk, rst, 
                  i_valid_DataFSM, //i_valid
                  i_next_state,    //i_next_state_TopFSM
                  next_state,      //o_next_state_TopFSM
                  o_data,          //o_data
                  i_prdata[8:1],   //i_data
                  o_valid_DataFSM  //o_valid
                  );
    end

    SERIAL_WRITE:
    begin
        if (i_valid)
        begin
            //start bit, data, parity bit, 2 stop bits
            o_pwdata = {0, i_data_to_write, ^i_data_to_write, 2'b11}; 
            next_state = i_next_state;
        end
        else
        begin
            next_state = i_next_state;
        end
    end
    endcase
end

always_ff @(posedge clk)
begin
    if(rst)
    begin
        state <= IDLE;
    end
    else
    begin
        state <= next_state;
    end
end


endmodule