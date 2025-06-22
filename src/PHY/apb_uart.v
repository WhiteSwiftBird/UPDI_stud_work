// ---------------------------------------------------------------------
// File :                       apb_uart.v
//
// Abstract     :               UART Top Level
//
//                                                           (optional)
//                                          (optional)        _________
// _                          _______         _______        |         |
//  \          ______        |       |       |       | /|_|\ | Timeout |
// A \        |      |       |       |       |       |<  _  >| Detector|
// P  | /|_|\ | Bus  | /|_|\ |       |       |       | \| |/ |         |
// B  |<  _  >| I/F  |<  _  >| Reg   | /|_|\ |       |       |_________|
//    | \| |/ | Unit | \| |/ | Block |<  _  >| Sync  |        _______
// I  |       |______|       |       | \| |/ | Block |       |       |
// F  |                      |       |       |       | /|_|\ | Baud  |
//   /        _______  /|_|\ |       |       |       |<  _  >| clock |
// _/        |       |<  _  >|       |       |       | \| |/ | Gen   |
//           | Reset | \| |/ |_______|       |       |       |_______|
//           | Block |        ^     ^        |       |        ________
//           |_______|       / \   / \       |       | /|_|\ |        |
//                           | |   | |       |       |<  _  >| Serial |
//                           \ /   \ /       |_______| \| |/ | TX     |
//                            v     v            ^           | Block  |
//                      |-------|  |-------|    / \          |________|
//                      |       |  |       |    | |
//                      | FIFO  |  | Modem |    \ /
//                      | Block |  | Ctrl  |     v
//                      |       |  | Sync  | |--------|
//                      |_______|  |_______| |        |
//                     (optional)            | Serial |
//                                           | RX     |
//                                           | Block  |
//                                           |________|
//
// Hierarchy of the apb_uart:
//                           Reset Block           (apb_uart_rst)
//                           Bus I/F Unit          (apb_uart_biu)
//                           Register Block        (apb_uart_regfile)
//                           FIFO Block            (apb_uart_fifo)
//                             DW FIFO Controllers (fifoctl_s1_df)
//                             DW RAMs             (ram_r_w_s_dff)
//                           Modem Control Sync    (apb_uart_mc_sync)
//                           Sync Block            (apb_uart_sync)
//                             Level Sync          (apb_uart_bcm21)
//                             Data Sync           (apb_uart_bcm25)
//                             Async Reset Gen     (apb_async_rst_gen)
//                           Baud Clock Gen        (apb_uart_bclk_gen)
//                           Timeout Detector      (apb_uart_to_det)
//                             Async Reset Gen     (apb_async_rst_gen)
//                           Serial TX Block       (apb_uart_tx)
//                           Serial RX Block       (apb_uart_rx)
//
//

`include "apb_uart_cc_constants.v"

module apb_uart
  (
   // Inputs
   pclk,
   presetn,
   penable,
   pwrite,
   pwdata,
   paddr,
   psel,
   scan_mode,
   cts_n,
   dsr_n,
   dcd_n,
   ri_n,
   sin,
   // Outputs
   prdata,
   dtr_n,
   rts_n,
   out2_n,
   out1_n,
   dma_tx_req_n,
   dma_rx_req_n,
   txrdy_n,
   rxrdy_n,
   sout,
   baudout_n,
   intr,
   tx_enable
   );

   input                              pclk;                   // APB Clock
   input                              presetn;                // APB active low
                                                              // async reset
   input                              penable;                // strobe signal
   input                              pwrite;                 // write enable
   input  [`APB_DATA_WIDTH-1:0]       pwdata;                 // write data bus
   input  [`UART_ADDR_SLICE_LHS-1:0]  paddr;                  // address bus
   input                              psel;                   // APB peripheral
                                                              // select
                                                              // low async reset
   input                              scan_mode;              // scan mode signal
                                                              // RAM
                                                              // RAM
   input                              cts_n;                  // clear to send,
                                                              // active low
   input                              dsr_n;                  // data set ready,
                                                              // active low
   input                              dcd_n;                  // data carrier detect,
                                                              // active low
   input                              ri_n;                   // ring indicator,
                                                              // active low
                                                              // active high
                                                              // active low
                                                              // active high
                                                              // active low
   input                              sin;                    // serial in

   output [`APB_DATA_WIDTH-1:0]       prdata;                 // read data bus
                                                              // RAM
                                                              // for TX FIFO RAM
                                                              // for TX FIFO RAM
                                                              // TX FIFO RAM,
                                                              // active low
                                                              // TX FIFO RAM,
                                                              // active low
                                                              // chip enable for
                                                              // external ram,
                                                              // active low
                                                              // RAM
                                                              // for RX FIFO RAM
                                                              // for RX FIFO RAM
                                                              // RX FIFO RAM,
                                                              // active low
                                                              // RX FIFO RAM,
                                                              // active low
                                                              // chip enable for
                                                              // external ram,
                                                              // active low
   output                             dtr_n;                  // data terminal ready,
                                                              // active low
   output                             rts_n;                  // request to send,
                                                              // active low
   output                             out2_n;                 // programmable output2,
                                                              // active low
   output                             out1_n;                 // programmable output1,
                                                              // active low
                                                              // active high
   output                             dma_tx_req_n;           // TX buffer ready,
                                                              // active low
                                                              // active high
                                                              // active low
                                                              // active high
   output                             dma_rx_req_n;           // RX buffer ready,
                                                              // active low
                                                              // active high
                                                              // active low
   output                             txrdy_n;                // legacy DMA TX
                                                              // buffer ready,
                                                              // active low
   output                             rxrdy_n;                // legacy DMA rx
                                                              // buffer ready,
                                                              // active low
   output                             sout;                   // serial out
                                                              // active low
   output                             baudout_n;              // baud clock reference,
                                                              // active low
   output                             intr;                   // interrupt
   output                             tx_enable;                   // interrupt

   wire                               int_uart_lp_req;        // Internal uart low power request
   wire                               wr_en;                  // write enable
   wire                               wr_enx;                 // write enable extra
   wire                               rd_en;                  // read enable
   wire                               dtr_n;                  // data terminal ready,
                                                              // active low
   wire                               rts_n;                  // request to send,
                                                              // active low
   wire                               out2_n;                 // programmable output2,
                                                              // active low
   wire                               out1_n;                 // programmable output1,
   wire                               sclk;                   // serial I/F clock
   wire                               s_rst_n;                // serial I/F active
                                                              // low async reset
   wire                               int_sclk;               // internal sclk
   wire                               int_s_rst_n;            // internal s_rst_n
   wire                               new_presetn;            // generated presetn,
                                                              // may include SW reset
   wire                               new_s_rst_n;            // generated s_rst_n,
                                                              // may include SW reset
   wire                               sync_cts_n;             // synd'ed clear to send,
                                                              // active low
   wire                               sync_dsr_n;             // synd'ed data set ready,
                                                              // active low
   wire                               sync_dcd_n;             // synd'ed data carrier detect,
                                                              // active low
   wire                               sync_ri_n;              // synd'ed ring indicator,
                                                              // active low
   wire                               dma_tx_ack;             // DMA TX burst end,
                                                              // active high
   wire                               dma_tx_ack_n;           // DMA TX burst end,
                                                              // active low
   wire                               dma_rx_ack;             // DMA RX burst end,
                                                              // active high
   wire                               dma_rx_ack_n;           // DMA RX burst end,
                                                              // active low
   wire                               dma_tx_req;             // TX buffer ready,
                                                              // active high
   wire                               dma_tx_req_n;           // TX buffer ready,
                                                              // active low
   wire                               dma_tx_single;          // DMA TX FIFO single,
                                                              // active high
   wire                               dma_tx_single_n;        // DMA TX FIFO single,
                                                              // active low
   wire                               dma_rx_req;             // RX buffer ready,
                                                              // active high
   wire                               dma_rx_req_n;           // RX buffer ready,
                                                              // active low
   wire                               dma_rx_single;          // DMA RX FIFO single,
                                                              // active high
   wire                               dma_rx_single_n;        // DMA RX FIFO single,
                                                              // active low
   wire                               int_dma_tx_ack;         // internal dma_tx_ack
   wire                               int_dma_rx_ack;         // internal dma_rx_ack
   wire                               ser_out_lb;             // serial tx data out
                                                              // for loopback
   wire                               sout;                   // serial out
   wire                               sir_out_n;              // serial IR out,
                                                              // active low
   wire                               tx_start;               // start serial
                                                              // transmission
   wire                               int_tx_start;           // internal tx_start
   wire                               sync_tx_start;          // synd'ed start serial
                                                              // transmission
   wire                               tx_finish;              // serial transmission
                                                              // of current character
                                                              // finished
   wire                               int_tx_finish;          // internal tx_finish
   wire                               sync_tx_finish;         // synd'ed serial transmission
                                                              // of current character
                                                              // finished
   wire                               sir_en;                 // serial infrared enable
   wire                               int_sir_en;             // internal sir_en
   wire                               sync_sir_en;            // synd'ed serial infrared enable
   wire                               lb_en;                  // loopback enable
   wire                               int_lb_en;              // internal lb_en
   wire                               sync_lb_en;             // synd'ed loopback enable
   wire                               xbreak;                  // break control
   wire                               int_break;              // internal break
   wire                               sync_break;             // synd'ed break control
   wire                               divsr_wd;               // baud clock divisor
                                                              // write detect
   wire                               int_divsr_wd;           // internal divsr_wd
   wire                               sync_divsr_wd;          // synd'ed divsr_wd
                                                              // divisor write detect
   wire                               lp_divsr_wd;            // low power baud clock divisor
                                                              // write detect
   wire                               int_lp_divsr_wd;        // internal lp_divsr_wd
   wire                               sync_lp_divsr_wd;       // synd'ed lp_divsr_wd
                                                              // divisor write detect
   wire                               bclk;                   // baud clock
   wire                               baudout_n;              // baud clock reference,
                                                              // active low
   wire                               lp_bclk;                // low power baud clock
   wire                               int_lp_bclk;            // internal lp_bclk
   wire                               rx_in_prog;             // serial reception
                                                              // in progress
   wire                               int_rx_in_prog;         // internal rx_in_prog
   wire                               sync_rx_in_prog;        // synd'ed serial reception
                                                              // in progress
   wire                               rx_finish;              // serial reception of
                                                              // current character
                                                              // finished
   wire                               int_rx_finish;          // internal rx_finish
   wire                               sync_rx_finish;         // synd'ed serial reception of
                                                              // current character
                                                              // finished
   wire                               tx_push;                // tx fifo pop
   wire                               tx_pop;                 // tx fifo pop
   wire                               rx_push;                // rx fifo push
   wire                               rx_pop;                 // rx fifo pop
   wire                               tx_fifo_rst;            // tx fifo reset
   wire                               rx_fifo_rst;            // rx fifo reset
   wire                               tx_full;                // tx fifo full status
   wire                               tx_empty;               // tx fifo empty status
   wire                               tx_ram_we_n;            // tx fifo write
                                                              // enable for external
                                                              // ram, active low
   wire                               tx_ram_re_n;            // tx fifo read
                                                              // enable for external
                                                              // ram, active low
   wire                               tx_ram_rd_ce_n;         // tx fifo read port chip
                                                              // enable for external
                                                              // ram, active low
   wire                               rx_full;                // rx fifo full status
   wire                               rx_almost_full;         // rx fifo almost full status
   wire                               rx_empty;               // rx fifo empty status
   wire                               rx_overflow;            // rx fifo overflow status
   wire                               rx_ram_we_n;            // rx fifo write
                                                              // enable for external
                                                              // ram, active low
   wire                               rx_ram_re_n;            // rx fifo read
                                                              // enable for external
                                                              // ram, active low
   wire                               rx_ram_rd_ce_n;         // rx fifo read port chip
                                                              // enable for external
                                                              // ram, active low
   wire                               char_to;                // character timeout
   wire                               int_char_to;            // internal char_to
   wire                               sync_char_to;           // synd'ed character timeout
   wire                               rx_pop_ack;             // rx_pop acknowledge signal
   wire                               rx_pop_ack_ed;          // rx_pop acknowledge edge detection
   wire                               sync_rx_pop_ack;        // sync'ed rx_pop_ack
   // jduarte 20110316 begin
   // each signal sent to the timeout detector will now be individually
   // synchronized to avoid any signal change being masked by the synchronizers
   // wire                               cnt_ens_ed;             // counter enables
   //                                                            // edge detect
   wire   [  `TO_DET_CNT_ENS_WIDTH-1:0] cnt_ens_ed;             // counter enables
                                                              // edge detect
   // jduarte 20110316 end
   wire                               char_info_wd;           // char_info
                                                              // write detect
   wire                               final_rx_in;            // rx in seen by receiver
   wire                               uart_lp_req;            // uart low power request
   wire                               sync_uart_lp_req;       // synd'ed uart low power request
   wire                               uart_lp_req_pclk;       // pclk domain uart_lp_req
   wire                               uart_lp_req_sclk;       // sclk domain uart_lp_req
   wire                               clear_lp_req_pclk;      // clear for UART low
                                                              // power request from
                                                              // the pclk domain
   wire                               clear_lp_req_sclk;      // clear for UART low
                                                              // power request from
                                                              // the sclk domain
   wire                               rx_err_check_oe;        // rx error check
                                                              // output enable
   wire                               sw_rst_dec;             // SW reset decode
   wire                               ser_in;                 // serial in
   wire                               sir_in;                 // serial IR in
   wire                               int_sir_in;             // internal sir_in
   wire                               txrdy_n;                // legacy DMA tx
                                                              // buffer ready,
                                                              // active low
   wire                               rxrdy_n;                // legacy DMA rx
                                                              // buffer ready,
                                                              // active low
   wire 			      ext_clear_bclk;         // external clear for bclk gen
   wire 			      ext_clear_lp_bclk;      // external clear for
                                                              // lp_bclk gen
   wire   [3:0]                       byte_en;                // active byte lane
   wire   [  `UART_ADDR_SLICE_LHS-3:0]  reg_addr;               // register offset
                                                              // address
   wire   [  `MAX_APB_DATA_WIDTH-1:0]   ipwdata;                // internal pwdata bus
   wire   [  `MAX_APB_DATA_WIDTH-1:0]   iprdata;                // internal prdata bus
   wire   [7:0]                       tx_data;                // data to be
                                                              // transmitted
   wire   [7:0]                       int_tx_data;            // internal tx_data
   wire   [7:0]                       sync_tx_data;           // synd'ed data to be
                                                              // transmitted
   wire   [9:0]                       rx_data;                // received data
   wire   [9:0]                       int_rx_data;            // internal rx_data
   wire   [9:0]                       sync_rx_data;           // synd'ed received data
   wire   [15:0]                      divsr;                  // baud clock divisor
   wire   [15:0]                      int_divsr;              // internal divsr
   wire   [15:0]                      sync_divsr;             // synd'ed baud clock divisor
   wire   [15:0]                      lp_divsr;               // low power baud
                                                              // clock divisor
   wire   [15:0]                      int_lp_divsr;           // internal lp_divsr
   wire   [15:0]                      sync_lp_divsr;          // synd'ed low power baud
                                                              // clock divisor

   // aaraujo @ 17/05/2011 : CRM_9000431453
   // Updated width of *char_info signals to include
   // stick parity feature
   wire   [5:0]                       char_info;              // serial character
   wire   [5:0]                       int_char_info;          // internal char_info
   wire   [5:0]                       sync_char_info;         // synd'ed serial character
                                                              // information
   wire   [7:0]                       tx_ram_in;              // tx fifo read data
                                                              // from external ram
   wire   [7:0]                       tx_push_data;           // data to the tx fifo
   wire   [9:0]                       rx_ram_in;              // rx fifo read data
                                                              // from external ram
   wire   [9:0]                       rx_push_data;           // data to the tx fifo
   wire   [7:0]                       tx_ram_out;             // tx fifo write data
                                                              // to external ram
   wire   [  `FIFO_ADDR_WIDTH-1:0]      tx_ram_wr_addr;         // tx fifo write address
                                                              // for external ram
   wire   [  `FIFO_ADDR_WIDTH-1:0]      tx_ram_rd_addr;         // tx fifo read address
                                                              // for external ram
   wire   [7:0]                       tx_pop_data;            // data from the tx fifo
   wire   [9:0]                       rx_ram_out;             // rx fifo write data
                                                              // to external ram
   wire   [  `FIFO_ADDR_WIDTH-1:0]      rx_ram_wr_addr;         // rx fifo write address
                                                              // for external ram
   wire   [  `FIFO_ADDR_WIDTH-1:0]      rx_ram_rd_addr;         // rx fifo read address
                                                              // for external ram
   wire   [9:0]                       rx_pop_data;            // data from the rx fifo
   wire   [31:0]                      debug;                  // on-chip debug
   wire                               allow_lp_req;           // allow low power request
   wire   [  `TO_DET_CNT_ENS_WIDTH-1:0] to_det_cnt_ens;         // timeout detect
                                                              // count enables
   wire   [  `TO_DET_CNT_ENS_WIDTH-1:0] sync_to_det_cnt_ens;    // synd'ed timeout
                                                              // detect count enables
   wire   [  `TO_DET_CNT_ENS_WIDTH-1:0] int_to_det_cnt_ens;     // internal
                                                              // to_det_cnt_ens
   wire                               int_rx_pop_ack;         // internal
                                                              // int_rx_pop_ack
   wire                               rx_pop_hld;
   wire                               rx_pop_hld_ed;
   wire                               sync_rx_pop_hld;
   wire                               int_rx_pop_hld;


// Dummy wires - used to suppress unconnected ports warnings by Leda tool - BR - 2/12/2010
   wire alr_unconn, bn_unconn, sm_unconn;

   // APB Interface
   apb_uart_biu
    #(  `UART_ADDR_SLICE_LHS) U_apb_uart_biu
     (
      // Inputs
      .pclk              (pclk),
      .presetn           (new_presetn),
      .psel              (psel),
      .penable           (penable),
      .pwrite            (pwrite),
      .paddr             (paddr),
      .pwdata            (pwdata),
      .prdata            (prdata),

      // Outputs
      .wr_en             (wr_en),
      .wr_enx            (wr_enx),
      .rd_en             (rd_en),
      .byte_en           (byte_en),
      .reg_addr          (reg_addr),
      .ipwdata           (ipwdata),
      .iprdata           (iprdata)
      );

   // UART Reset Block
   apb_uart_rst
    U_apb_uart_rst
     (
     // Inputs
      .pclk(pclk),
      .presetn(presetn),
      .sw_rst_dec(sw_rst_dec),
      .scan_mode(scan_mode),
      // Outputs
      .new_presetn(new_presetn),
      .new_s_rst_n(new_s_rst_n)
      );

   // UART Register Block
   apb_uart_regfile
    U_apb_uart_regfile
     (
      // Inputs
      .pclk(pclk),
      .presetn(new_presetn),
      .scan_mode(scan_mode),
      .wr_en(wr_en),
      .wr_enx(wr_enx),
      .rd_en(rd_en),
      .byte_en(byte_en),
      .reg_addr(reg_addr),
      .ipwdata(ipwdata),
      .tx_full(tx_full),
      .tx_empty(tx_empty),
      .rx_full(rx_full),
      // CRM 9000533265
      .rx_empty(rx_empty),
      .rx_overflow(rx_overflow),
      .tx_pop_data(tx_pop_data),
      .rx_pop_data(rx_pop_data),
      .tx_finish(int_tx_finish),
      .rx_finish(int_rx_finish),
      .rx_in_prog(int_rx_in_prog),
      .rx_data(int_rx_data),
      .char_to(int_char_to),
      .rx_pop_ack(int_rx_pop_ack),
      .cts_n(sync_cts_n),
      .dsr_n(sync_dsr_n),
      .dcd_n(sync_dcd_n),
      .ri_n(sync_ri_n),
      .dma_tx_ack(int_dma_tx_ack),
      .dma_rx_ack(int_dma_rx_ack),
      .uart_lp_req_pclk(uart_lp_req_pclk),
      // Outputs
      .iprdata(iprdata),
      .tx_push(tx_push),
      .tx_pop(tx_pop),
      .rx_push(rx_push),
      .rx_pop(rx_pop),
      .tx_fifo_rst(tx_fifo_rst),
      .rx_fifo_rst(rx_fifo_rst),
      .rx_err_check_oe(rx_err_check_oe),
      .tx_push_data(tx_push_data),
      .rx_push_data(rx_push_data),
      .tx_start(tx_start),
      .tx_data(tx_data),
      .sir_en(sir_en),
      // jduarte 20110309 begin
      // CRM_9000442021
      // .lb_en             (lb_en),
      // .xbreak            (xbreak),
      .lb_en_o(lb_en),
      .xbreak_o(xbreak),
      // jduarte 20110309 end
      .cnt_ens_ed(cnt_ens_ed),
      .to_det_cnt_ens(to_det_cnt_ens),
      // jduarte 20110309 begin
      // CRM_9000445419 && CRM_9000445469
      .rx_pop_hld(rx_pop_hld),
      .rx_pop_hld_ed(rx_pop_hld_ed),
      // jduarte 20110309 end
      .divsr(divsr),
      .divsr_wd(divsr_wd),
      .lp_divsr(lp_divsr),
      .lp_divsr_wd(lp_divsr_wd),
      .char_info(char_info),
      .dtr_n(dtr_n),
      .rts_n(rts_n),
      .out1_n(out1_n),
      .out2_n(out2_n),
      .dma_tx_req(dma_tx_req),
      .dma_tx_req_n(dma_tx_req_n),
      .dma_tx_single(dma_tx_single),
      .dma_tx_single_n(dma_tx_single_n),
      .dma_rx_req(dma_rx_req),
      .dma_rx_req_n(dma_rx_req_n),
      .dma_rx_single(dma_rx_single),
      .dma_rx_single_n(dma_rx_single_n),
      .sw_rst_dec(sw_rst_dec),
      .debug(debug),
      .char_info_wd(char_info_wd),
      .clear_lp_req_pclk(clear_lp_req_pclk),
      .intr(intr),
      .tx_enable(tx_enable)
      );

   apb_uart_fifo
    U_apb_uart_fifo
     (
      .pclk(pclk),
      .presetn(new_presetn),
      .tx_push(tx_push),
      .tx_pop(tx_pop),
      .rx_push(rx_push),
      .rx_pop(rx_pop),
      .tx_fifo_rst(tx_fifo_rst),
      .rx_fifo_rst(rx_fifo_rst),
      .rx_err_check_oe(rx_err_check_oe),
      .tx_ram_out(tx_ram_out),
      .tx_push_data(tx_push_data),
      .rx_ram_out(rx_ram_out),
      .rx_push_data(rx_push_data),
      .tx_full(tx_full),
      .tx_empty(tx_empty),
      .rx_full(rx_full),
      // CRM 9000533265
      .rx_empty(rx_empty),
      .rx_overflow(rx_overflow),
      .tx_ram_we_n(tx_ram_we_n),
      .tx_ram_re_n(tx_ram_re_n),
      .tx_ram_rd_ce_n(tx_ram_rd_ce_n),
      .rx_ram_we_n(rx_ram_we_n),
      .rx_ram_re_n(rx_ram_re_n),
      .rx_ram_rd_ce_n(rx_ram_rd_ce_n),
      .tx_ram_in(tx_ram_in),
      .tx_ram_wr_addr(tx_ram_wr_addr),
      .tx_ram_rd_addr(tx_ram_rd_addr),
      .tx_pop_data(tx_pop_data),
      .rx_ram_in(rx_ram_in),
      .rx_ram_wr_addr(rx_ram_wr_addr),
      .rx_ram_rd_addr(rx_ram_rd_addr),
      .rx_pop_data(rx_pop_data)
      );




   // Modem Control Synchronization
   apb_uart_mc_sync
    U_apb_uart_mc_sync
     (
      .clk                 (pclk),
      .resetn              (new_presetn),
      .cts_n               (cts_n),
      .dsr_n               (dsr_n),
      .dcd_n               (dcd_n),
      .ri_n                (ri_n),
      .sync_cts_n          (sync_cts_n),
      .sync_dsr_n          (sync_dsr_n),
      .sync_dcd_n          (sync_dcd_n),
      .sync_ri_n           (sync_ri_n)
      );

   // Baud Clock Generator
   apb_uart_bclk_gen
    U_apb_uart_bclk_gen
     (
      // Inputs
      .sclk                (int_sclk),
      .s_rst_n             (int_s_rst_n),
      .divisor             (int_divsr),
      .divisor_wd          (int_divsr_wd),
      .scan_mode           (scan_mode),
      .uart_lp_req         (int_uart_lp_req),
      .ext_clear           (ext_clear_bclk),

      // Outputs
      .allow_lp_req        (allow_lp_req),
      .bclk                (bclk),
      .baudout_n           (baudout_n)
      );



   // Serial Transmitter
   apb_uart_tx
    U_apb_uart_tx
     (
      // Inputs
      .sclk                (int_sclk),
      .s_rst_n             (int_s_rst_n),
      .bclk                (bclk),
      .tx_start            (int_tx_start),
      .tx_data             (int_tx_data),
      .char_info           (int_char_info),
      .xbreak               (int_break),
      .lb_en               (int_lb_en),
      .sir_en              (int_sir_en),

      // Outputs
      .tx_finish           (tx_finish),
      .ser_out_lb          (ser_out_lb),
      .sout                (sout),
      .sir_out_n           (sir_out_n)
      );

   // Serial Receiver
   apb_uart_rx
    U_apb_uart_rx
     (
      // Inputs
      .sclk                (int_sclk),
      .s_rst_n             (int_s_rst_n),
      .bclk                (bclk),
      .lp_bclk             (int_lp_bclk),
      .sin                 (sin),
      .sir_in              (int_sir_in),
      .char_info           (int_char_info),
      .sir_en              (int_sir_en),
      .lb_en               (int_lb_en),
      .ser_out_lb          (ser_out_lb),
      .divisor             (int_divsr),
      .lp_divisor          (int_lp_divsr),

      // Outputs
      .rx_in_prog          (rx_in_prog),
      .ser_in              (ser_in),
      .rx_finish           (rx_finish),
      .final_rx_in         (final_rx_in),
      .ext_clear_bclk      (ext_clear_bclk),
      .ext_clear_lp_bclk   (ext_clear_lp_bclk),
      .rx_data             (rx_data)
      );

   apb_uart_to_det
    U_apb_uart_to_det
     (
      // Inputs
      .sclk                (int_sclk),
      .s_rst_n             (int_s_rst_n),
      .bclk                (bclk),
      .clear_lp_req_pclk   (clear_lp_req_pclk),
      .ser_in              (ser_in),
      .final_rx_in         (final_rx_in),
      .allow_lp_req        (allow_lp_req),
      .rx_in_prog          (rx_in_prog),
      .cts_n               (cts_n),
      .dsr_n               (dsr_n),
      .dcd_n               (dcd_n),
      .ri_n                (ri_n),
      .scan_mode           (scan_mode),
      .char_info           (int_char_info[3:0]),
      .to_det_cnt_ens      (int_to_det_cnt_ens),
      // jduarte 20110309 begin
      // CRM_9000445419 && CRM_9000445469
      .rx_pop_hld          (int_rx_pop_hld),
      // jduarte 20110309 end
      // jduarte 20110311 begin
      // CRM_9000452270
      .rx_finish           (rx_finish),
      // jduarte 20110311 end

      // Outputs
      .clear_lp_req_sclk   (clear_lp_req_sclk),
      .uart_lp_req         (uart_lp_req),
      .char_to             (char_to),
      .rx_pop_ack          (rx_pop_ack),
      .rx_pop_ack_ed       (rx_pop_ack_ed)
      );


   assign int_uart_lp_req = ((      `FIFO_MODE > 0) || (      `CLK_GATE_EN == 1)) ? uart_lp_req : 1'b0;

   assign int_sclk           = (      `CLOCK_MODE == 2) ? sclk                : pclk;
   assign int_s_rst_n        = new_s_rst_n;

   assign int_divsr          = (      `CLOCK_MODE == 2) ? sync_divsr          : divsr;
   assign int_divsr_wd       = (      `CLOCK_MODE == 2) ? sync_divsr_wd       : divsr_wd;
   assign int_lp_divsr       = (      `CLOCK_MODE == 2) ? sync_lp_divsr       : lp_divsr;
   assign int_lp_divsr_wd    = (      `CLOCK_MODE == 2) ? sync_lp_divsr_wd    : lp_divsr_wd;
   assign int_char_info      = (      `CLOCK_MODE == 2) ? sync_char_info      : char_info;
   assign int_break          = (      `CLOCK_MODE == 2) ? sync_break          : xbreak;
   assign int_lb_en          = (      `CLOCK_MODE == 2) ? sync_lb_en          : lb_en;
   assign int_sir_en         = (      `CLOCK_MODE == 2) ? sync_sir_en         : sir_en;
   assign int_tx_start       = (      `CLOCK_MODE == 2) ? sync_tx_start       : tx_start;
   assign int_tx_data        = (      `CLOCK_MODE == 2) ? sync_tx_data        : tx_data;
   assign int_tx_finish      = (      `CLOCK_MODE == 2) ? sync_tx_finish      : tx_finish;
   assign int_rx_in_prog     = (      `CLOCK_MODE == 2) ? sync_rx_in_prog     : rx_in_prog;
   assign int_rx_finish      = (      `CLOCK_MODE == 2) ? sync_rx_finish      : rx_finish;
   assign int_rx_data        = (      `CLOCK_MODE == 2) ? sync_rx_data        : rx_data;
   assign int_char_to        = (      `CLOCK_MODE == 2) ? sync_char_to        : char_to;
   assign int_rx_pop_ack     = (      `CLOCK_MODE == 2) ? sync_rx_pop_ack     : rx_pop_ack;
   assign int_to_det_cnt_ens = (      `CLOCK_MODE == 2) ? sync_to_det_cnt_ens : to_det_cnt_ens;
   // jduarte 20110309 begin
   // CRM_9000445419 && CRM_9000445469
   assign int_rx_pop_hld     = (      `CLOCK_MODE == 2) ? sync_rx_pop_hld     : rx_pop_hld;
   // jduarte 20110309 end


   // internal serial IR input selection
   assign int_sir_in         = (      `SIR_MODE == 1)   ? sir_in              : 1'b0;

   // low power request selection
   assign uart_lp_req_pclk   = (      `CLOCK_MODE == 2) ? sync_uart_lp_req    : uart_lp_req;
   assign uart_lp_req_sclk   = (      `CLOCK_MODE == 2) ? uart_lp_req         : 1'b0;

   // DMA signaling - polarity selection
   assign int_dma_tx_ack     = (      `DMA_EXTRA == 1) ? ((      `DMA_POL == 1) ? dma_tx_ack_n : dma_tx_ack) : 1'b0;
   assign int_dma_rx_ack     = (      `DMA_EXTRA == 1) ? ((      `DMA_POL == 1) ? dma_rx_ack_n : dma_rx_ack) : 1'b0;

   assign txrdy_n            = (      `DMA_EXTRA == 0) ? dma_tx_req_n : 1'b1;
   assign rxrdy_n            = (      `DMA_EXTRA == 0) ? dma_rx_req_n : 1'b1;

   // Internal low power bclk selection
   assign int_lp_bclk        = (      `SIR_LP_RX == 1) ? lp_bclk : 1'b0;


endmodule // apb_uart

