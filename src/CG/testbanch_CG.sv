module testbench;

logic [7:0]  repeat_number;
localparam seed = 12345;
logic clk, rstn;

logic i_write, i_valid;

logic o_write, o_trans_en, o_ready, o_valid;
logic [7:0]  sent_data, i_data;
logic [11:0] o_data;

CG_FSM DUT(
  .i_clk(clk),
  .i_rstn(rstn),

  .i_data(i_data),
  .i_valid(i_valid),

  .o_ready(o_ready),
  .i_write(i_write),
  
  .o_trans_en(o_trans_en),
  .o_data(o_data),
  .o_valid(o_valid),
  .o_write(o_write)
);

typedef struct{
  bit [7 :0] repeat_num_frame;
  bit [11:0] SYNCH_char_frame;
  bit [11:0] REPEAT_instr_frame;
  bit [11:0] REPEAT_num_frame;
  bit [11:0] INSTR_frame;
} packet;

packet pckt_put, pckt_get_1, pckt_get_2;

mailbox#(packet) mbx1 = new();
mailbox#(packet) mbx2 = new();

//clock generation
  initial
  begin
    clk = '0;

    forever
      # 500 clk = ~ clk;
  end

// resetn generator
  initial
  begin
    rstn <= 'x;
    repeat (2) @ (posedge clk);
    rstn <= '0;
    repeat (2) @ (posedge clk);
    rstn <= '1;
  end


//external coamnd part (write input activation)
 initial 
 begin
    i_write <= 'x;
    wait (~rstn);
    i_write <= '1;
    @ (posedge clk);
    i_write <= '0;
    wait (o_trans_en);
    i_write <= '1;
    @ (posedge clk);
    i_write <= '0;
 end


//APP part (generation of input signals)
task APP_generation();
  wait (o_write);
  i_valid <= 1;
  i_data  <= repeat_number;
  pckt_put.repeat_num_frame <= repeat_number;
  mbx1.put(pckt_put);
  wait (o_ready);

  for (int i = 1; i < (repeat_number * 4) + 1; i++)
  begin
    @ (posedge clk)
    i_valid <= 1;
    i_data  <= $urandom;
    sent_data <= i_data;
    wait (o_ready);
    end
  i_valid <= 0;
endtask

initial begin
  $urandom(seed);
  wait(~rstn)
  i_valid <= 0;
  repeat_number = 10;
  APP_generation();
  repeat_number = 0;
  APP_generation();
end

//Checking of start, parity and stop bits
task check_frame(logic [11:0] data);
  if (data [0] != 0)
  begin
    $display("Start bit error!");
    $finish;
  end
  if (data [11:10] != 2'b11)
  begin
    $display("Stop bit error!");
    $finish;
  end
  if (^data[8:1] != data[9])
  begin
    $display("Parity bit error!");
    $finish;
  end
endtask


task check_all_frames();
  mbx2.get(pckt_get_2);
  //SYNCH character
  if (pckt_get_2.SYNCH_char_frame != 12'b010101010011)
  begin
    $display ("SYNCH character error. Was expected: 0101_0101_0011 get: %b_%b_%b", o_data[11:8], o_data[7:4], o_data[3:0]);
    $finish;
  end
  else
  begin
    $display("SYNCH character was CORRECT");
  end

//REPEAT character
 if (repeat_number != 0)
  begin
    check_frame(pckt_get_2.REPEAT_instr_frame);
    if (pckt_get_2.REPEAT_instr_frame [8:1] != 8'b10100000)
    begin
      $display ("REPEAT instruction character error. Was expected: 1010_0000 get: %b_%b", o_data[8:5], o_data[4:1]);
      $finish;
    end
    else
    begin
      $display("REPEAT instruction was CORRECT");
    end

    check_frame(pckt_get_2.REPEAT_num_frame);
    if (pckt_get_2.REPEAT_num_frame [8:1] != repeat_number)
    begin
      $display ("REPEAT number character error. Was expected: %d get: %d", repeat_number, o_data[8:1]);
      $finish;
    end
    else
    begin
      $display("REPEAT number was CORRECT");
    end
  end

//INSTRUCTION
  check_frame(pckt_get_2.INSTR_frame);
  if (pckt_get_2.INSTR_frame [8:1] != 8'b01100110)
  begin
    $display ("ST INSTRUCTION error. Was expected: 0110_0110 get: %b_%b", o_data[8:5], o_data[4:1]);
    $finish;
  end
endtask


//test of outputs to PHY mem part
initial 
begin
  wait (~rstn);

  mbx1.get(pckt_get_1);

  wait(o_valid);
  pckt_get_1.SYNCH_char_frame <= o_data;
  if(pckt_get_1.repeat_num_frame > 0)
  begin
    wait(o_valid);
    pckt_get_1.REPEAT_instr_frame <= o_data;
    wait(o_valid);
    pckt_get_1.REPEAT_num_frame <= o_data;
  end
  wait(o_valid);
  pckt_get_1.INSTR_frame <= o_data;

  mbx2.put(pckt_get_1);

  //DATA check
  for (int i = repeat_number * 4 + 1; i > 0; i--)
  begin
    wait (o_valid);
    check_frame(o_data);
    if (o_data [8:1] != sent_data)
    begin
      $display ("DATA error. Sent: %b_%b get: %b_%b", sent_data[7:4], sent_data[3:0], o_data[8:5], o_data[4:1]);
      $finish;
    end
    if (o_trans_en == 1)
    begin
      $display("Mismatch counter: expected: %d Real: %d", repeat_number * 4, repeat_number * 4 - i);
    end
  end
  check_all_frames();



  mbx1.get(pckt_get_1);

  wait(o_valid);
  pckt_get_1.SYNCH_char_frame <= o_data;
  if(pckt_get_1.repeat_num_frame > 0)
  begin
    wait(o_valid);
    pckt_get_1.REPEAT_instr_frame <= o_data;
    wait(o_valid);
    pckt_get_1.REPEAT_num_frame <= o_data;
  end
  wait(o_valid);
  pckt_get_1.INSTR_frame <= o_data;

  mbx2.put(pckt_get_1);


//DATA check
  for (int i = repeat_number * 4 + 1; i > 0; i--)
  begin
    wait (o_valid);
    check_frame(o_data);
    if (o_data [8:1] != sent_data)
    begin
      $display ("DATA error. Sent: %b_%b get: %b_%b", sent_data[7:4], sent_data[3:0], o_data[8:5], o_data[4:1]);
      $finish;
    end
    if (o_trans_en == 1)
    begin
      $display("Mismatch counter: expected: %d Real: %d", repeat_number * 4, repeat_number * 4 - i);
    end
  end

  check_all_frames();
end

// Setting timeout against hangs
initial
begin
    repeat (100000) @ (posedge clk);
    $display ("FAIL: timeout!");
    $finish;
end

endmodule