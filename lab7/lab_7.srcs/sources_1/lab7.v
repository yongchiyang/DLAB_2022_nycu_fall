`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2018/11/01 11:16:50
// Design Name: 
// Module Name: lab6
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This is a sample circuit to show you how to initialize an SRAM
//              with a pre-defined data file. Hit BTN0/BTN1 let you browse
//              through the data.
// 
// Dependencies: LCD_module, debounce
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab6(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,

  // 1602 LCD Module Interface
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D,
  
  // usrt module
  input  uart_rx,
  output uart_tx
);

reg [7:0] matrixA [0:15];
reg [7:0] matrixB [0:15];
reg [17:0] matrixC [0:15];

//  read 32 nums
reg [3:0] N = MAIN_ADDR, N_next;
localparam [3:0] MAIN_ADDR = 0, MAIN_READ = 1, MAIN_STORE = 2, MAIN_CHECK = 3, MAIN_INCR = 4, MAIN_END = 5;

// declare system variables
wire [1:0]  btn_level, btn_pressed;
reg  [1:0]  prev_btn_level;
reg  [11:0] user_addr;
reg  [7:0]  user_data;

reg  [127:0] row_A, row_B;

// declare SRAM control signals
wire [10:0] sram_addr;
wire [7:0]  data_in;
wire [7:0]  data_out;
wire        sram_we, sram_en;

// idx for read sram
integer i = 0;

assign usr_led = 4'h0;

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
  
debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[0]),
  .btn_output(btn_level[0])
);

debounce btn_db1(
  .clk(clk),
  .btn_input(usr_btn[1]),
  .btn_output(btn_level[1])
);

// ======================== read 32 numbers =========================================== //

/*
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 2'b00;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level & ~prev_btn_level);
*/

always@(posedge clk) begin
    if(~reset_n)
        N <= MAIN_ADDR;
    else 
        N <= N_next;
end

always@(*)begin
    case(N)
        MAIN_ADDR:
            N_next = MAIN_READ;
        MAIN_READ:
            N_next = MAIN_STORE;
        MAIN_STORE:
            N_next = MAIN_CHECK;
        MAIN_CHECK:
        if(i == 31) N_next = MAIN_END;
        else N_next = MAIN_INCR;
        MAIN_INCR:
            N_next = MAIN_ADDR;
        MAIN_END:
            N_next = MAIN_END;
    endcase
end

always@(posedge clk)begin
    if(~reset_n)begin
        user_addr <= 12'h00;
    end
    else if(N == MAIN_CHECK) begin
        user_addr = (i == 31) ? user_addr: user_addr + 1;
    end
end

always@(posedge clk)begin
    if(~reset_n)
        i <= 0;
    else if(N == MAIN_INCR)
        i = i + 1;
end

always@(posedge clk)begin
    if(N == MAIN_STORE && reset_n)
    begin
        if (i < 16)
            matrixA[i] = user_data;
        else
            matrixB[i-16] = user_data;
    end
end

sram ram0(.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr), .data_i(data_in), .data_o(data_out));
 
assign sram_we = usr_btn[3];         
assign sram_en = (N == MAIN_ADDR || N_next == MAIN_READ);  
assign sram_addr = user_addr[11:0];
assign data_in = 8'b0; // SRAM is read-only so we tie inputs to zeros.

always @(posedge clk) begin
  if (~reset_n) user_data <= 8'b0;
  else if (sram_en && !sram_we) user_data <= data_out;
end

// ================== end of read 32 nums ============================= //

// =================== matrix multiplication =========================== //


localparam [2:0] S_MM_INIT = 0, S_MM_MUL = 1, S_MM_ADD = 2, S_MM_CHK = 3, S_MM_INCR = 4, S_MM_END = 5;
reg [2:0] M, M_Next;
reg [17:0] sum [0:15];
integer idx_m = 0;
integer idx_2 = 0;

always@(posedge clk)begin
    if(~reset_n)
        M <= S_MM_INIT;
    else
        M <= M_Next;
end


always@(posedge clk)begin
    if(~reset_n)
        idx_m <= 0;
    else if(M == S_MM_INCR)
        idx_m <= idx_m + 1;
end 

always@(*) begin
    case(M)
        S_MM_INIT:
            if(N != MAIN_END) M_Next <= S_MM_INIT;
            else M_Next <= S_MM_MUL;
        S_MM_MUL:
            M_Next = S_MM_ADD;
        S_MM_ADD:
            M_Next = S_MM_CHK;
        S_MM_CHK:
        if(idx_m == 3) M_Next = S_MM_END;
        else M_Next = S_MM_INCR;
        S_MM_INCR:
            M_Next = S_MM_INIT;
        S_MM_END:
            M_Next = S_MM_END;
        
    endcase
end


always@(posedge clk)begin
    if(~reset_n)begin
        for(idx_2 = 0; idx_2 < 16; idx_2 = idx_2  + 1) sum[idx_2] <= 18'b0;
    end
    else begin
        if(M == S_MM_MUL)begin
            //  row 1
            sum[0] <= matrixA[0] * matrixB[idx_m*4];
            sum[1] <= matrixA[4] * matrixB[idx_m*4 + 1];
            sum[2] <= matrixA[8] * matrixB[idx_m*4 + 2];
            sum[3] <= matrixA[12] * matrixB[idx_m*4 + 3];
            // row 2
            sum[4] <= matrixA[1] * matrixB[idx_m*4];
            sum[5] <= matrixA[5] * matrixB[idx_m*4 + 1];
            sum[6] <= matrixA[9] * matrixB[idx_m*4 + 2];
            sum[7] <= matrixA[13] * matrixB[idx_m*4 + 3];
            //  row 3
            
            sum[8] <= matrixA[2] * matrixB[idx_m*4];
            sum[9] <= matrixA[6] * matrixB[idx_m*4 + 1];
            sum[10] <= matrixA[10] * matrixB[idx_m*4 + 2];
            sum[11] <= matrixA[14] * matrixB[idx_m*4 + 3];
            // row 4
            sum[12] <= matrixA[3] * matrixB[idx_m*4];
            sum[13] <= matrixA[7] * matrixB[idx_m*4 + 1];
            sum[14] <= matrixA[11] * matrixB[idx_m*4 + 2];
            sum[15] <= matrixA[15] * matrixB[idx_m*4 + 3];
            
        end
    end
end

always@(posedge clk)begin
    if(~reset_n)begin
        for (idx_2 = 0; idx_2 < 32; idx_2 = idx_2 + 1) matrixC[idx_2] = 18'b0;
    end
    else if(M == S_MM_ADD)begin
        matrixC[idx_m*4] <= sum[0] + sum[1] + sum[2] + sum[3];
        matrixC[idx_m*4 + 1] <= sum[4] + sum[5] + sum[6] + sum[7];
        matrixC[idx_m*4 + 2] <= sum[8] + sum[9] + sum[10] + sum[11];
        matrixC[idx_m*4 + 3] <= sum[12] + sum[13] + sum[14] + sum[15];
    end
end


// ================== end of matrix multiplication ======================= //

// =================== print the outcome ============================= //
           
// uart params

localparam [1:0] S_UART_IDLE = 0, S_UART_WAIT = 1,
                 S_UART_SEND = 2, S_UART_INCR = 3;
localparam INIT_DELAY = 100_000; // 1 msec @ 100 MHz
localparam PROMPT_STR = 0;  // starting index of the prompt message
localparam PROMPT_LEN2 = 40;
localparam ROW_LEN = 34;
localparam ROW1_STR = 40;
localparam ROW2_STR = 74;
localparam ROW3_STR = 108;
localparam ROW4_STR = 142;


localparam MEM_SIZE = PROMPT_LEN2 + ROW_LEN*4 + 1;

// declare system variables
wire print_enable, print_done;
reg [$clog2(MEM_SIZE):0] send_counter;
reg [1:0] Q, Q_next;
reg [$clog2(INIT_DELAY):0] init_counter;
reg [7:0] data[0:MEM_SIZE-1];
reg [0:PROMPT_LEN2*8-1] msg2 = {"\015\012The matrix multiplication result is:\015\012"};
reg [0:ROW_LEN*8-1] row1 = {"\015\012[ -----, -----, -----, ----- ]\015\012"};
reg [0:ROW_LEN*8-1] row2 = {"\015\012[ -----, -----, -----, ----- ]\015\012"};
reg [0:ROW_LEN*8-1] row3 = {"\015\012[ -----, -----, -----, ----- ]\015\012"};
reg [0:(ROW_LEN + 1)*8-1] row4 = {"\015\012[ -----, -----, -----, ----- ]\015\012", 8'h00};


// declare UART signals
wire transmit;
wire received;
wire [7:0] rx_byte;
reg  [7:0] rx_temp;  // if recevied is true, rx_temp latches rx_byte for ONLY ONE CLOCK CYCLE!
wire [7:0] tx_byte;


wire is_receiving;
wire is_transmitting;
wire recv_error;

// local variable
integer idx = 0;

/* The UART device takes a 100MHz clock to handle I/O at 9600 baudrate */
uart uart(
  .clk(clk),
  .rst(~reset_n),
  .rx(uart_rx),
  .tx(uart_tx),
  .transmit(transmit),
  .tx_byte(tx_byte),
  .received(received),
  .rx_byte(rx_byte),
  .is_receiving(is_receiving),
  .is_transmitting(is_transmitting),
  .recv_error(recv_error)
);




// ----------------------- FSM for print the outcome ---------------------
localparam [1:0] S_P_INIT = 0, S_P_PROMPT = 1, S_P_END = 6;
reg [1:0] P, P_Next;
integer idx_n = 0;
always@(posedge clk)begin
    if(!reset_n)begin
        for(idx = 0; idx < PROMPT_LEN2; idx = idx + 1) data[idx] <= msg2[idx*8 +: 8];
        for(idx = 0; idx < ROW_LEN; idx = idx + 1) data[ROW1_STR + idx] <= row1[idx*8 +: 8];
        for(idx = 0; idx < ROW_LEN; idx = idx + 1) data[ROW2_STR + idx] <= row2[idx*8 +: 8];
        for(idx = 0; idx < ROW_LEN; idx = idx + 1) data[ROW3_STR + idx] <= row3[idx*8 +: 8];
        for(idx = 0; idx < ROW_LEN + 1; idx = idx + 1) data[ROW4_STR + idx] <= row4[idx*8 +: 8];
    end
    else if(M_Next == S_MM_END)begin
        for(idx = 0; idx < 4; idx = idx + 1)begin
            for(idx_n = 0; idx_n <4; idx_n = idx_n+1)begin
                data[ROW1_STR + idx*ROW_LEN + (idx_n*7) + 4] <= (matrixC[idx_n*4 + idx][17:16]) + "0";
                data[ROW1_STR + idx*ROW_LEN + (idx_n*7) + 5] <= ((matrixC[idx_n*4 + idx][15:12]) > 9 ? "7" : "0") + matrixC[idx_n*4 + idx][15:12];
                data[ROW1_STR + idx*ROW_LEN + (idx_n*7) + 6] <= ((matrixC[idx_n*4 + idx][11:8]) > 9 ? "7" : "0") + matrixC[idx_n*4 + idx][11:8];
                data[ROW1_STR + idx*ROW_LEN + (idx_n*7) + 7] <= ((matrixC[idx_n*4 + idx][7:4]) > 9 ? "7" : "0") + matrixC[idx_n*4 + idx][7:4];
                data[ROW1_STR + idx*ROW_LEN + (idx_n*7) + 8] <= ((matrixC[idx_n*4 + idx][3:0]) > 9 ? "7" : "0") + matrixC[idx_n*4 + idx][3:0];
            end
        end
    end  
end

always @(posedge clk) begin
  if (P == S_P_INIT) init_counter <= init_counter + 1;
  else init_counter <= 0;
end

always@(posedge clk)begin
    if(~reset_n)
        P <= S_P_INIT;
    else
        P <= P_Next;
end

always@(*)begin
    case(P)
        S_P_INIT:
        if (init_counter < INIT_DELAY && M!= S_MM_END) P_Next = S_P_INIT;
        else P_Next <= S_P_PROMPT;
        S_P_PROMPT:
        if(print_done) P_Next <= S_P_END;
        else P_Next <= S_P_PROMPT;
        S_P_END:
            P_Next <= S_P_END;
    endcase
end



assign print_done = (tx_byte == 8'h00);
assign print_enable = (P_Next == S_P_PROMPT && P != S_P_PROMPT) ;


// ------------------------------------------------------------------------
// FSM of the controller that sends a string to the UART.
always @(posedge clk) begin
  if (~reset_n) Q <= S_UART_IDLE;
  else Q <= Q_next;
end

always @(*) begin // FSM next-state logic
  case (Q)
    S_UART_IDLE: // wait for the print_string flag
      if (print_enable) Q_next = S_UART_WAIT;
      else Q_next = S_UART_IDLE;
    S_UART_WAIT: // wait for the transmission of current data byte begins
      if (is_transmitting == 1) Q_next = S_UART_SEND;
      else Q_next = S_UART_WAIT;
    S_UART_SEND: // wait for the transmission of current data byte finishes
      if (is_transmitting == 0) Q_next = S_UART_INCR; // transmit next character
      else Q_next = S_UART_SEND;
    S_UART_INCR:
      if (tx_byte == 8'h0) Q_next = S_UART_IDLE; // string transmission ends
      else Q_next = S_UART_WAIT;
  endcase
end

// FSM output logics: UART transmission control signals
assign transmit = (Q_next == S_UART_WAIT || print_enable);
assign tx_byte  = data[send_counter];


always @(posedge clk) begin
  case (P_Next)
    S_P_INIT: send_counter <= PROMPT_STR;
    default: send_counter <= send_counter + (Q_next == S_UART_INCR);
  endcase
end 

always @(posedge clk) begin
  rx_temp <= (received)? rx_byte : 8'h0;
end
// =================== end of printing outcome ========================= //

endmodule
