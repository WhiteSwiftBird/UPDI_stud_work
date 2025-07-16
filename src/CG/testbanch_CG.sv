module testbench;

logic [7:0]  repeat_number;
localparam seed = 12345;
logic clk, rstn;

logic i_write, i_valid;

logic o_write, o_trans_en, o_ready, o_valid;
logic [7:0]  sent_data_next, i_data, sent_data_q;
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

 logic [7 :0] repeat_num;



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
 end


//APP part (generation of input signals)
task APP_generation(logic [7:0] repeat_number_1);
  wait (o_write);
  i_valid <= 1;
  i_data  <= repeat_number_1;
  wait (o_ready);

  for (int i = 1; i < (repeat_number_1 * 4) + 1; i++)
  begin
    sent_data_next = i_data;
    @ (posedge clk)
    i_valid <= 1;
    i_data  <= $urandom;
    sent_data_q = sent_data_next;

    if (!o_ready)
    begin
    // $display("Valid wait");
      while(!o_ready)
      begin
      @ (posedge clk);
      end
    end
    end
    
  i_valid <= 0;
endtask

initial begin
  $urandom(seed);
  wait(~rstn)
  i_valid <= 0;
  repeat_number = 8'd10;
  APP_generation(repeat_number);
  wait(o_trans_en);
  $finish;
end

//Checking of start, parity and stop bits
task check_frame(logic [11:0] data);
  if (data [11] != 0)
  begin
    $display("Start bit error! Start bit: %b", data[0]);
    $finish;
  end
  if (data [1:0] != 2'b11)
  begin
    $display("Stop bit error! Get: %b_%b_%b", o_data[11:8], o_data[7:4], o_data[3:0]);
    $finish;
  end
  if (^data[10:3] != data[2])
  begin
    $display("Parity bit error! Get: %b_%b_%b", o_data[11:8], o_data[7:4], o_data[3:0]);
    $finish;
  end
endtask



//test of outputs to PHY mem part
initial 
begin
  wait (~rstn);
  @ (posedge rstn);
  repeat_num <= 8'd10;

// -------------SYNCH character----------------------------------------------------------------------
  if (!o_valid)
  begin
  $display("Valid wait");
  while(!o_valid)
  begin
  @ (posedge clk);
  end
  end

  $display("repeat_number: %d", repeat_num);
  $display("SYNCH char: %b_%b_%b", o_data[11:8], o_data[7:4], o_data[3:0]);
  if (o_data != 12'b0_01010101_011)
  begin
    $display ("SYNCH character error. Was expected: 0101_0101_0011 get: %b_%b_%b", o_data[11:8], o_data[7:4], o_data[3:0]);
    $finish;
  end
  else
  begin
    $display("SYNCH character was CORRECT");
  end
  

// ------------REPEAT character-----------------------------------------------------------------
  @ (posedge clk);
  if (!o_valid)
  begin
  $display("Valid wait");
  while(!o_valid)
  begin
  @ (posedge clk);
  end
  end

  //---------Instr----------------------
  if(repeat_num > 0)
  begin
    
    $display("REPEAT frame check");
    check_frame(o_data);
    if (o_data [10:3] != 8'b10100000)
    begin
        $display ("REPEAT instruction character error. Was expected: 1010_0000 get: %b_%b", o_data[8:5], o_data[4:1]);
        $finish;
    end
    else
    begin
       $display("REPEAT instruction was CORRECT");
    end
    //-----Number----------------------
    @ (posedge clk);
    if (!o_valid)
    begin
      while(!o_valid)
      begin
      @ (posedge clk);
      end
    end

    check_frame(o_data);
    if (o_data [10:3] != repeat_num)
    begin
        $display ("REPEAT number character error. Was expected: %d get: %d", repeat_num, o_data[8:1]);
        $finish;
    end
    else
    begin
        $display("REPEAT number was CORRECT");
    end
    //----SYNCH character-------------
    @ (posedge clk);
    if (!o_valid)
    begin
      while(!o_valid)
      begin
      @ (posedge clk);
      end
    end
    
    check_frame(o_data);
    if (o_data[10:3] != 8'b01010101)
    begin
        $display ("SYNCH character error. Was expected: 0010_1010_1011 get: %b_%b_%b", o_data[11:8], o_data[7:4], o_data[3:0]);
        $finish;
    end
    else
    begin
        $display("SYNCH character was CORRECT");
    end
  end

//---------------INSTRUCTION------------------------------------------------------------------------------------------
  @ (posedge clk);
  if (!o_valid)
  begin
  while(!o_valid)
  begin
  @ (posedge clk);
  end
  end
  
  $display("INSTR frame check");
  check_frame(o_data);
  if (o_data [10:3] != 8'b01100100)
  begin
    $display ("ST INSTRUCTION error. Was expected: 0110_0110 get: %b_%b", o_data[8:5], o_data[4:1]);
    $finish;
  end
  else
  begin
    $display("INSTRUCTION character was CORRECT");
  end

//---------------DATA check------------------------------------------------------------------------------------------
  for (int i = repeat_num * 4 + 1; i > 0; i--)
  begin
    @ (posedge clk);
    if (!o_valid)
    begin
      while(!o_valid)
      begin
      @ (posedge clk);
      end
    end

    check_frame(o_data);
    if (o_data [10:3] != sent_data_q)
    begin
      $display ("DATA error. Sent: %b_%b get: %b_%b", sent_data_q[7:4], sent_data_q[3:0], o_data[10:7], o_data[6:3]);
      $finish;
    end
    else
    begin
      $display ("DATA correct. Sent: %b_%b get: %b_%b", sent_data_q[7:4], sent_data_q[3:0], o_data[10:7], o_data[6:3]);
    end
    if (o_trans_en == 1)
    begin
      $display("Mismatch counter: expected: %d Real: %d", repeat_num * 4, repeat_num * 4 - i);
    end
  end
end
//---------------END of OUTPUT check----------------------------------------------------------------------------------


//---------------Setting timeout against hangs------------------------------------------------------------------------
initial
begin
    repeat (100000) @ (posedge clk);
    $display ("FAIL: timeout!");
    $finish;
end

endmodule