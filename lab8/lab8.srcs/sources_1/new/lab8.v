`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2017/05/08 15:29:41
// Design Name: 
// Module Name: lab6
// Project Name: 
// Target Devices: 
// Tool Versions:
// Description: The sample top module of lab 6: sd card reader. The behavior of
//              this module is as follows
//              1. When the SD card is initialized, display a message on the LCD.
//                 If the initialization fails, an error message will be shown.
//              2. The user can then press usr_btn[2] to trigger the sd card
//                 controller to read the super block of the sd card (located at
//                 block # 8192) into the SRAM memory.
//              3. During SD card reading time, the four LED lights will be turned on.
//                 They will be turned off when the reading is done.
//              4. The LCD will then displayer the sector just been read, and the
//                 first byte of the sector.
//              5. Everytime you press usr_btn[2], the next byte will be displayed.
// 
// Dependencies: clk_divider, LCD_module, debounce, sd_card
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab8(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,

  // SD card specific I/O ports
  output spi_ss,
  output spi_sck,
  output spi_mosi,
  input  spi_miso,

  // 1602 LCD Module Interface
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);



// Declare system variables
wire btn_level, btn_pressed;
reg  prev_btn_level;
reg  [5:0] send_counter;
reg  [9:0] sd_counter;
reg  [7:0] data_byte;
reg  [31:0] blk_addr;

reg  [127:0] row_A = "SD card cannot  ";
reg  [127:0] row_B = "be initialized! ";
reg  done_flag; // Signals the completion of reading one SD sector.

// Declare SD card interface signals
wire clk_sel;
wire clk_500k;
reg  rd_req;
reg  [31:0] rd_addr;
wire init_finished;
wire [7:0] sd_dout;
wire sd_valid;

// Declare the control/data signals of an SRAM memory block
wire [7:0] data_in;
wire [7:0] data_out;
wire [8:0] sram_addr;
wire       sram_we, sram_en;

assign clk_sel = (init_finished)? clk : clk_500k; // clock for the SD controller
assign usr_led = 4'h00;

clk_divider#(200) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(clk_500k)
);

debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[2]),
  .btn_output(btn_level)
);

LCD_module lcd0( 
  .clk(clk),
  .reset(~reset_n),
  .row_A(row_A),
  .row_B(row_B),
  .LCD_E(LCD_E),
  .LCD_RS(LCD_RS),
  .LCD_RW(LCD_RW),
  .LCD_D(LCD_D)
);

sd_card sd_card0(
  .cs(spi_ss),
  .sclk(spi_sck),
  .mosi(spi_mosi),
  .miso(spi_miso),

  .clk(clk_sel),
  .rst(~reset_n),
  .rd_req(rd_req),
  .block_addr(rd_addr),
  .init_finished(init_finished),
  .dout(sd_dout),
  .sd_valid(sd_valid)
);

sram ram0(
  .clk(clk),
  .we(sram_we),
  .en(sram_en),
  .addr(sram_addr),
  .data_i(data_in),
  .data_o(data_out)
);


// ---------------------------- new vars -----------------------------------
reg [63:0] TAG = "DLAB_TAG";
reg [63:0] END_TAG = "DLAB_END";
reg [63:0] data_in_reg = "        ";
reg [39:0] word;
//reg [55:0] test = "LAB_END";
//reg [55:0] test2 = "DLAB_EN";
//reg [55:0] input_test;
reg chk = 0;
reg chk_end = 0;
reg [15:0] num = 0;
reg done_chk;
reg word_chk;
localparam [3:0] MAIN_INIT = 0, MAIN_READ = 1, MAIN_DONE = 2, MAIN_CHK = 3, MAIN_NEXT = 4, MAIN_END = 5, MAIN_WAIT = 6, MAIN_INCR = 7, MAIN_CHK2 = 8, MAIN_IDLE = 9;
reg [3:0] N, N_next;

always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 0;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0)? 1 : 0;

always@(*)begin
    case(N)
        MAIN_INIT:
            if(init_finished == 1) N_next = MAIN_IDLE;
            else N_next = MAIN_INIT;
        MAIN_IDLE:
            if(btn_pressed) N_next = MAIN_WAIT;
            else N_next = MAIN_IDLE;
        MAIN_WAIT:
            N_next = MAIN_READ;
        MAIN_READ:
            if(sd_counter == 512) N_next = MAIN_DONE;
            else N_next = MAIN_READ;
        MAIN_DONE:
            N_next = MAIN_CHK;
        MAIN_CHK:
            N_next = MAIN_CHK2;
        MAIN_CHK2:
            if(chk_end) N_next = MAIN_END;
            else N_next = MAIN_INCR;
        MAIN_INCR:
            if(sd_counter < 512)N_next = MAIN_DONE;
            else N_next = MAIN_NEXT;
        MAIN_NEXT:
            N_next = MAIN_WAIT;
        MAIN_END:
            N_next = MAIN_END;
    endcase
end

always @(*) begin
  rd_req = (N == MAIN_WAIT);
  rd_addr = blk_addr;
end

always@(posedge clk)begin
    if(!reset_n)begin
        N <= MAIN_INIT;
        done_chk <= 0;
    end
    else begin
        N <= N_next;
        if(N == MAIN_DONE || N == MAIN_CHK) done_chk <= 1;
        else if(N == MAIN_READ && N == MAIN_WAIT) done_chk <= 0;
        else done_chk <= done_chk;
    end
end

always@(posedge clk)begin
    if(!reset_n)begin
        chk <= 0;
        chk_end <= 0;
    end
    else begin
        if((!chk) && (N == MAIN_CHK)) chk <= (TAG == data_in_reg);
        else chk <= chk;
        
        if((!chk_end) && (N == MAIN_CHK)) chk_end <= (END_TAG == data_in_reg);
        else chk_end <= chk_end;
    end
end

always@(posedge clk)begin
    if(!reset_n)begin
        num <= 0;
    end
    else begin
        if(chk && N == MAIN_CHK2 && (!chk_end))begin
            word_chk = (word[31:24] <= "Z" && word[31:24] >= "A") || (word[31:24] <= "z" && word[31:24] >= "a" );
            word_chk = word_chk && ((word[23:16] <= "Z" && word[23:16] >= "A") || (word[23:16] <= "z" && word[23:16] >= "a"));
            word_chk = word_chk && ((word[15:8] <= "Z" && word[15:8] >= "A") || (word[15:8] <= "z" && word[15:8] >= "a"));
            word_chk = word_chk && (word[39:32] <= 8'h40 || (word[39:32] >= 8'h5B && word[39:32] <= 8'h60) || word[39:32] >= 8'h7B);
            word_chk = word_chk && (word[7:0] <= 8'h40 || (word[7:0] >= 8'h5B && word[7:0] <= 8'h60) || word[7:0] >= 8'h7B);
            num = num + word_chk;
        end
    end
end

always @(posedge clk) begin
  if (~reset_n) blk_addr <= 32'h2000;
  else if(N == MAIN_NEXT)  blk_addr <= blk_addr + 1;
  else blk_addr <= blk_addr; // In lab 6, change this line to scan all blocks
end

always @(posedge clk) begin
  if (~reset_n || (N == MAIN_READ && N_next == MAIN_DONE) ||(N == MAIN_WAIT && N_next == MAIN_READ))
    sd_counter <= 0;
  else if ((N == MAIN_READ && sd_valid) ||N == MAIN_CHK2)
    sd_counter <= sd_counter + 1;
end


always @(posedge clk) begin
  if (~reset_n)begin
   data_in_reg <= 0;
   word <= 0;
  end
  else if (sram_en && N == MAIN_DONE)begin // done -> idle
    data_in_reg = data_in_reg << 8;
    data_in_reg[7:0] = data_out;
    //input_test = input_test << 8;
    //input_test[7:0] = data_out;
    
    if(chk)begin
        word = word << 8;
        word[7:0] = data_out;
    end
    
  end
  
end

assign sram_we = sd_valid;          // Write data into SRAM when sd_valid is high.
assign sram_en = 1;                 // Always enable the SRAM block.
assign data_in = sd_dout;           // Input data always comes from the SD controller.
assign sram_addr = sd_counter[8:0]; // Set the driver of the SRAM address signal.


// LCD Display function.
always @(posedge clk) begin
  if (~reset_n) begin
    row_A = "SD card cannot  ";
    row_B = "be initialized! ";
  end else if (N == MAIN_END) begin
    row_A <= {"found ", ((num[15:12] > 9) ? "7" : "0") + num[15:12],
                       ((num[11:8] > 9) ? "7" : "0") + num[11:8],
                       ((num[7:4] > 9) ? "7" : "0") + num[7:4],
                       ((num[3:0] > 9) ? "7" : "0") + num[3:0]," words"};
    row_B <= "in the text file";

  end
  else if(done_chk && N != MAIN_END)begin
    row_A <= "Searching in blk";
    row_B <= {"address ", ((blk_addr[31:28] > 9) ? "7" : "0") +blk_addr[31:28],
                        ((blk_addr[27:24] > 9) ? "7" : "0") +blk_addr[27:24],
                        ((blk_addr[23:20] > 9) ? "7" : "0") +blk_addr[23:20],
                        ((blk_addr[19:16] > 9) ? "7" : "0") +blk_addr[19:16],
                        ((blk_addr[15:12] > 9) ? "7" : "0") +blk_addr[15:12],
                        ((blk_addr[11:8] > 9) ? "7" : "0") +blk_addr[11:8],
                        ((blk_addr[7:4] > 9) ? "7" : "0") +blk_addr[7:4],
                        ((blk_addr[3:0] > 9) ? "7" : "0") +blk_addr[3:0]};
  end
  else if(N == MAIN_IDLE)begin
    row_A <= "Hit BTN2 to read";
    row_B <= "the SD card ... ";
  end
end


endmodule
