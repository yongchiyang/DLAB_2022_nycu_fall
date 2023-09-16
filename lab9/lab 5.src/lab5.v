`timescale 1ns / 1ps

/////////////////////////////////////////////////////////
module lab5(
  input clk,
  input reset_n,
  input [3:0] usr_btn,
  output [3:0] usr_led,
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

// turn off all the LEDs
assign usr_led = 4'b0000;

wire btn_level, btn_pressed;
reg prev_btn_level;
reg [127:0] row_A = "Press BTN3 to   "; // Initialize the text of the first row. 
reg [127:0] row_B = "show a message.."; // Initialize the text of the second row.
reg start = 0;

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
  .btn_input(usr_btn[3]),
  .btn_output(btn_level)
);
    
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 1;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0);

//reg [127:0] passwd_hash = 128'h68406571d2a81a6d7a2c956e645f131c;
reg [127:0] passwd_hash = 128'hE8_CD_09_53_AB_DF_DE_43_3D_FE_C7_FA_A7_0D_F7_F6;  //53589793
//reg [127:0] test_hash = 128'h2e9ec317e197819358fbc43afca7d837; // 01234567
//ef775988943825d2871e1cfa75473ec0   99999999
// dd4b21e9ef71e1291183a46b913ae6f2   00000000
// 68406571d2a81a6d7a2c956e645f131c    98765674

wire [63:0] pwd[0:7]; 
reg [63:0] pwd_i2[0:7];
wire [63:0] pwd_i3[0:7];
wire [127:0] md5_o[0:7];
wire [0:7]en;
wire [0:7]b_en;
reg done_flag;
reg [63:0] f_pwd;
reg [27:0] b_timer;
wire [63:0] timer;
integer i;
wire md5_en;
assign md5_en = (en[7] && en[6] && en[5] && en[4] && en[3] && en[2] && en[1] && en[0]);

reg [2:0] N;
reg [2:0] N_next;
localparam [2:0] MAIN_START = 0, MAIN_IDLE = 1, MAIN_MD5 = 2, MAIN_CHK = 3, MAIN_NEXT = 4, MAIN_END = 5, MAIN_INCR = 6;

always@(posedge clk)begin
    if(~reset_n) N <= 0;
    else N <= N_next;
end

always@(posedge clk)begin
    if(~reset_n || btn_pressed)begin
        b_timer <= 0;
        i <= 0;
    end
    else begin
        if(done_flag);
        else if(i < 100000) i = i + 1;
        else if(i == 100000)begin
            i = 0;
            b_timer = b_timer + 1;
        end
    end
end


always@(*)begin
    case(N)
        MAIN_START:
            if(btn_pressed) N_next <= MAIN_IDLE;
            else N_next <= MAIN_START;
        MAIN_IDLE:
            N_next <= MAIN_MD5;
        MAIN_MD5:
        begin
            if(md5_en) N_next <= MAIN_CHK;
            else N_next <= MAIN_MD5;
        end       
        MAIN_CHK:
            N_next <= MAIN_NEXT;
            //else N_next <= MAIN_CHK;
        MAIN_NEXT:
        begin
            if(done_flag) N_next <= MAIN_END;
            else N_next <= MAIN_INCR;
        end
        MAIN_INCR:
            N_next <= MAIN_IDLE;
        MAIN_END:
            N_next <= MAIN_END;
    endcase
end

always@(posedge clk)begin
    if(N == MAIN_START)
        done_flag <= 0;
    
    if(N == MAIN_CHK)begin
    
    case(passwd_hash)
    md5_o[0]:begin  done_flag <= 1;  f_pwd <= pwd[0]; end
    md5_o[1]:begin  done_flag <= 1;  f_pwd <= pwd[1]; end
    md5_o[2]:begin  done_flag <= 1;  f_pwd <= pwd[2]; end
    md5_o[3]:begin  done_flag <= 1;  f_pwd <= pwd[3]; end
    md5_o[4]:begin  done_flag <= 1;  f_pwd <= pwd[4]; end
    md5_o[5]:begin  done_flag <= 1;  f_pwd <= pwd[5]; end 
    md5_o[6]:begin  done_flag <= 1;  f_pwd <= pwd[6]; end 
    md5_o[7]:begin  done_flag <= 1;  f_pwd <= pwd[7]; end
    //md5_o[8]:begin  done_flag <= 1;  f_pwd <= pwd[8]; end
    endcase
    /*
    
        case(j)
            0:begin 
                if(passwd_hash == md5_o[0])begin  done_flag <= 1;  f_pwd <= pwd[0]; end
                if(passwd_hash == md5_o[1])begin  done_flag <= 1;  f_pwd <= pwd[1]; end
                j = j + 1; 
            end
            1:begin 
                if(passwd_hash == md5_o[2])begin  done_flag <= 1;  f_pwd <= pwd[2]; end
                if(passwd_hash == md5_o[3])begin  done_flag <= 1;  f_pwd <= pwd[3]; end 
                j = j + 1;
            end
            2:begin 
                if(passwd_hash == md5_o[4])begin  done_flag <= 1;  f_pwd <= pwd[4]; end
                if(passwd_hash == md5_o[5])begin  done_flag <= 1;  f_pwd <= pwd[5]; end 
                j = j + 1;
            end
            3:begin 
                if(passwd_hash == md5_o[6])begin  done_flag <= 1;  f_pwd <= pwd[6]; end 
                if(passwd_hash == md5_o[7])begin  done_flag <= 1;  f_pwd <= pwd[7]; end
                j = j + 1;
            end
            4: begin
                if(passwd_hash == md5_o[8])begin  done_flag <= 1;  f_pwd <= pwd[8]; end
                j =j+1;
            end
            5:j=5;
        endcase
        */
    end
end




always@(posedge clk)begin
    if(~reset_n)begin
        
        pwd_i2[0] <= 64'h303030303030303F;
        pwd_i2[1] <= 65'h313235303030303F;
        pwd_i2[2] <= 65'h323530303030303F;
        pwd_i2[3] <= 65'h333735303030303F;
        pwd_i2[4] <= 65'h353030303030303F;
        pwd_i2[5] <= 65'h363235303030303F;
        pwd_i2[6] <= 65'h373530303030303F;
        pwd_i2[7] <= 65'h383735303030303F; 
       
        
        /*
        pwd_i2[0] <= 64'h303030303030303F;
        pwd_i2[1] <= 64'h313131313131313F;
        pwd_i2[2] <= 64'h323232323232323F;
        pwd_i2[3] <= 64'h333333333333333F;
        pwd_i2[4] <= 64'h343434343434343F;
        pwd_i2[5] <= 64'h353535353535353F;
        pwd_i2[6] <= 64'h363636363636363F;
        pwd_i2[7] <= 64'h373737373737373F;
        pwd_i2[8] <= 65'h3838383838383838; 
        */
    end
    else if(N != MAIN_INCR && N_next == MAIN_INCR) begin 
 
        pwd_i2[0] <= pwd_i3[0];
        pwd_i2[1] <= pwd_i3[1];
        pwd_i2[2] <= pwd_i3[2];
        pwd_i2[3] <= pwd_i3[3];
        pwd_i2[4] <= pwd_i3[4];
        pwd_i2[5] <= pwd_i3[5];
        pwd_i2[6] <= pwd_i3[6];
        pwd_i2[7] <= pwd_i3[7];
        //pwd_i2[8] <= pwd_i3[8];
    end
end


ascii_incr a0(.clk(clk), .ascii_i(pwd_i2[0]), .ascii_o(pwd_i3[0]), .ascii_o2(pwd[0]), .en2(b_en[0]));
ascii_incr a1(.clk(clk), .ascii_i(pwd_i2[1]), .ascii_o(pwd_i3[1]), .ascii_o2(pwd[1]), .en2(b_en[1]));
ascii_incr a2(.clk(clk), .ascii_i(pwd_i2[2]), .ascii_o(pwd_i3[2]), .ascii_o2(pwd[2]), .en2(b_en[2]));
ascii_incr a3(.clk(clk), .ascii_i(pwd_i2[3]), .ascii_o(pwd_i3[3]), .ascii_o2(pwd[3]), .en2(b_en[3]));
ascii_incr a4(.clk(clk), .ascii_i(pwd_i2[4]), .ascii_o(pwd_i3[4]), .ascii_o2(pwd[4]), .en2(b_en[4]));
ascii_incr a5(.clk(clk), .ascii_i(pwd_i2[5]), .ascii_o(pwd_i3[5]), .ascii_o2(pwd[5]), .en2(b_en[5]));
ascii_incr a6(.clk(clk), .ascii_i(pwd_i2[6]), .ascii_o(pwd_i3[6]), .ascii_o2(pwd[6]), .en2(b_en[6]));
ascii_incr a7(.clk(clk), .ascii_i(pwd_i2[7]), .ascii_o(pwd_i3[7]), .ascii_o2(pwd[7]), .en2(b_en[7]));
//ascii_incr a8(.clk(clk), .ascii_i(pwd_i2[8]), .ascii_o(pwd_i3[8]), .ascii_o2(pwd[8]), .en2(b_en[8]));


md5 m0(.clk(clk), .reset_n(reset_n), .done(b_en[0]), .pwd(pwd[0]), .hash_pwd(md5_o[0]), .en(en[0]));
md5 m1(.clk(clk), .reset_n(reset_n), .done(b_en[1]), .pwd(pwd[1]), .hash_pwd(md5_o[1]), .en(en[1]));
md5 m2(.clk(clk), .reset_n(reset_n), .done(b_en[2]), .pwd(pwd[2]), .hash_pwd(md5_o[2]), .en(en[2]));
md5 m3(.clk(clk), .reset_n(reset_n), .done(b_en[3]), .pwd(pwd[3]), .hash_pwd(md5_o[3]), .en(en[3]));
md5 m4(.clk(clk), .reset_n(reset_n), .done(b_en[4]), .pwd(pwd[4]), .hash_pwd(md5_o[4]), .en(en[4]));
md5 m5(.clk(clk), .reset_n(reset_n), .done(b_en[5]), .pwd(pwd[5]), .hash_pwd(md5_o[5]), .en(en[5]));
md5 m6(.clk(clk), .reset_n(reset_n), .done(b_en[6]), .pwd(pwd[6]), .hash_pwd(md5_o[6]), .en(en[6]));
md5 m7(.clk(clk), .reset_n(reset_n), .done(b_en[7]), .pwd(pwd[7]), .hash_pwd(md5_o[7]), .en(en[7]));
//md5 m8(.clk(clk), .reset_n(reset_n), .done(b_en[8]), .pwd(pwd[8]), .hash_pwd(md5_o[8]), .en(en[8]));

bin2ascii_2 bt(.clk(clk), .reset_n(reset_n), .en_begin(done_flag), .bin(b_timer), .bcd1(timer));

always@(posedge clk)begin
    if(N == MAIN_START)begin
       row_A = "Press BTN3 to   ";
       row_B = "start pwd crack ";
    end
    else if(done_flag)begin
        row_A = {"Passwd: ", {f_pwd[39:32], f_pwd[47:40]}, f_pwd[55:48], f_pwd[63:56], f_pwd[7:0], f_pwd[15:8], f_pwd[23:16], f_pwd[31:24]};
        row_B = {"Time: ",timer[55:0]," ms"};
    end
    else begin
        row_A = {"    password    "};
        row_B = {"    cracking    "};
    end
end
endmodule




module md5(
    input clk,
    input reset_n,
    input done,
    input [63:0] pwd,
    output [127:0] hash_pwd,
    output en
);
reg [63:0] passwd;

integer i = 0;
reg [31:0] f;
reg [31:0] w;
reg [31:0] a;
reg [31:0] b;
reg [31:0] c;
reg [31:0] d;
reg [31:0] tmp;

assign en = (i == 66);
assign hash_pwd = {a, b, c, d};


always@(posedge clk)begin
    if(~reset_n)begin
        i = 0;
    end
    else if(!done)
        i <= 0;
    else if(done) begin
        case(i)
            // i = 0 ~ 15
             0:begin   a = 32'h67452301; b = 32'hefcdab89; c = 32'h98badcfe; d = 32'h10325476;
                      f = (b & c) | ((~b) & d);   w = a + f + 32'hd76aa478 + pwd[63:32];  tmp = d; d = c; c = b; b = b + ((w <<  7) | (w >> 25)); a = tmp; i = i + 1; end
             1:begin  f = (b & c) | ((~b) & d);   w = a + f + 32'he8c7b756 + pwd[31:0];   tmp = d; d = c; c = b; b = b + ((w << 12) | (w >> 20)); a = tmp; i = i + 1; end
             2:begin  f = (b & c) | ((~b) & d);   w = a + f + 32'h242070db + 32'h80;      tmp = d; d = c; c = b; b = b + ((w << 17) | (w >> 15)); a = tmp; i = i + 1; end
             3:begin  f = (b & c) | ((~b) & d);   w = a + f + 32'hc1bdceee;               tmp = d; d = c; c = b; b = b + ((w << 22) | (w >> 10)); a = tmp; i = i + 1; end
             4:begin  f = (b & c) | ((~b) & d);   w = a + f + 32'hf57c0faf;               tmp = d; d = c; c = b; b = b + ((w <<  7) | (w >> 25)); a = tmp; i = i + 1; end
             5:begin  f = (b & c) | ((~b) & d);   w = a + f + 32'h4787c62a;               tmp = d; d = c; c = b; b = b + ((w << 12) | (w >> 20)); a = tmp; i = i + 1; end
             6:begin  f = (b & c) | ((~b) & d);   w = a + f + 32'ha8304613;               tmp = d; d = c; c = b; b = b + ((w << 17) | (w >> 15)); a = tmp; i = i + 1; end
             7:begin  f = (b & c) | ((~b) & d);   w = a + f + 32'hfd469501;               tmp = d; d = c; c = b; b = b + ((w << 22) | (w >> 10)); a = tmp; i = i + 1; end
             8:begin  f = (b & c) | ((~b) & d);   w = a + f + 32'h698098d8;               tmp = d; d = c; c = b; b = b + ((w <<  7) | (w >> 25)); a = tmp; i = i + 1; end
             9:begin  f = (b & c) | ((~b) & d);   w = a + f + 32'h8b44f7af;               tmp = d; d = c; c = b; b = b + ((w << 12) | (w >> 20)); a = tmp; i = i + 1; end
            10:begin  f = (b & c) | ((~b) & d);   w = a + f + 32'hffff5bb1;               tmp = d; d = c; c = b; b = b + ((w << 17) | (w >> 15)); a = tmp; i = i + 1; end
            11:begin  f = (b & c) | ((~b) & d);   w = a + f + 32'h895cd7be;               tmp = d; d = c; c = b; b = b + ((w << 22) | (w >> 10)); a = tmp; i = i + 1; end
            12:begin  f = (b & c) | ((~b) & d);   w = a + f + 32'h6b901122;               tmp = d; d = c; c = b; b = b + ((w <<  7) | (w >> 25)); a = tmp; i = i + 1; end
            13:begin  f = (b & c) | ((~b) & d);   w = a + f + 32'hfd987193;               tmp = d; d = c; c = b; b = b + ((w << 12) | (w >> 20)); a = tmp; i = i + 1; end
            14:begin  f = (b & c) | ((~b) & d);   w = a + f + 32'ha679438e + 32'h40;      tmp = d; d = c; c = b; b = b + ((w << 17) | (w >> 15)); a = tmp; i = i + 1; end
            15:begin  f = (b & c) | ((~b) & d);   w = a + f + 32'h49b40821;               tmp = d; d = c; c = b; b = b + ((w << 22) | (w >> 10)); a = tmp; i = i + 1; end 
            // i = 16 ~ 31 , g = (5*i + 1 )%16
         
            16:begin  f = (d & b) | ((~d) & c);  w = a + f + 32'hf61e2562 + pwd[31:0];    tmp = d; d = c; c = b; b = b + ((w <<  5) | (w >> 27)); a = tmp; i = i + 1; end // g = 1
            17:begin  f = (d & b) | ((~d) & c);  w = a + f + 32'hc040b340;                tmp = d; d = c; c = b; b = b + ((w <<  9) | (w >> 23)); a = tmp; i = i + 1; end // g = 6
            18:begin  f = (d & b) | ((~d) & c);  w = a + f + 32'h265e5a51;                tmp = d; d = c; c = b; b = b + ((w << 14) | (w >> 18)); a = tmp; i = i + 1; end // g = 11
            19:begin  f = (d & b) | ((~d) & c);  w = a + f + 32'he9b6c7aa + pwd[63:32];   tmp = d; d = c; c = b; b = b + ((w << 20) | (w >> 12)); a = tmp; i = i + 1; end // g = 0
            20:begin  f = (d & b) | ((~d) & c);  w = a + f + 32'hd62f105d;                tmp = d; d = c; c = b; b = b + ((w <<  5) | (w >> 27)); a = tmp; i = i + 1; end // g = 5
            21:begin  f = (d & b) | ((~d) & c);  w = a + f + 32'h02441453;                tmp = d; d = c; c = b; b = b + ((w <<  9) | (w >> 23)); a = tmp; i = i + 1; end // g = 10
            22:begin  f = (d & b) | ((~d) & c);  w = a + f + 32'hd8a1e681;                tmp = d; d = c; c = b; b = b + ((w << 14) | (w >> 18)); a = tmp; i = i + 1; end // g = 15 
            23:begin  f = (d & b) | ((~d) & c);  w = a + f + 32'he7d3fbc8;                tmp = d; d = c; c = b; b = b + ((w << 20) | (w >> 12)); a = tmp; i = i + 1; end // g = 4
            24:begin  f = (d & b) | ((~d) & c);  w = a + f + 32'h21e1cde6;                tmp = d; d = c; c = b; b = b + ((w <<  5) | (w >> 27)); a = tmp; i = i + 1; end // g = 9
            25:begin  f = (d & b) | ((~d) & c);  w = a + f + 32'hc33707d6 + 32'h40;       tmp = d; d = c; c = b; b = b + ((w <<  9) | (w >> 23)); a = tmp; i = i + 1; end // g = 14
            26:begin  f = (d & b) | ((~d) & c);  w = a + f + 32'hf4d50d87;                tmp = d; d = c; c = b; b = b + ((w << 14) | (w >> 18)); a = tmp; i = i + 1; end // g = 3
            27:begin  f = (d & b) | ((~d) & c);  w = a + f + 32'h455a14ed;                tmp = d; d = c; c = b; b = b + ((w << 20) | (w >> 12)); a = tmp; i = i + 1; end // g = 8
            28:begin  f = (d & b) | ((~d) & c);  w = a + f + 32'ha9e3e905;                tmp = d; d = c; c = b; b = b + ((w <<  5) | (w >> 27)); a = tmp; i = i + 1; end // g = 13
            29:begin  f = (d & b) | ((~d) & c);  w = a + f + 32'hfcefa3f8 + 32'h80;       tmp = d; d = c; c = b; b = b + ((w <<  9) | (w >> 23)); a = tmp; i = i + 1; end // g = 2
            30:begin  f = (d & b) | ((~d) & c);  w = a + f + 32'h676f02d9;                tmp = d; d = c; c = b; b = b + ((w << 14) | (w >> 18)); a = tmp; i = i + 1; end // g = 7
            31:begin  f = (d & b) | ((~d) & c);  w = a + f + 32'h8d2a4c8a;                tmp = d; d = c; c = b; b = b + ((w << 20) | (w >> 12)); a = tmp; i = i + 1; end // g = 12
            // i = 32 ~ 47 g = (3*i+5) % 16
            
            32:begin  f = b ^ c ^ d;             w = a + f + 32'hfffa3942;                tmp = d; d = c; c = b; b = b + ((w <<  4) | (w >> 28)); a = tmp; i = i + 1; end // g = 5
            33:begin  f = b ^ c ^ d;             w = a + f + 32'h8771f681;                tmp = d; d = c; c = b; b = b + ((w << 11) | (w >> 21)); a = tmp; i = i + 1; end //  g = 8
            34:begin  f = b ^ c ^ d;             w = a + f + 32'h6d9d6122;                tmp = d; d = c; c = b; b = b + ((w << 16) | (w >> 16)); a = tmp; i = i + 1; end // g = 11
            35:begin  f = b ^ c ^ d;             w = a + f + 32'hfde5380c + 32'h40;       tmp = d; d = c; c = b; b = b + ((w << 23) | (w >>  9)); a = tmp; i = i + 1; end // g = 14
            36:begin  f = b ^ c ^ d;             w = a + f + 32'ha4beea44 + pwd[31:0];    tmp = d; d = c; c = b; b = b + ((w <<  4) | (w >> 28)); a = tmp; i = i + 1; end // g = 1
            37:begin  f = b ^ c ^ d;             w = a + f + 32'h4bdecfa9;                tmp = d; d = c; c = b; b = b + ((w << 11) | (w >> 21)); a = tmp; i = i + 1; end //  g = 4
            38:begin  f = b ^ c ^ d;             w = a + f + 32'hf6bb4b60;                tmp = d; d = c; c = b; b = b + ((w << 16) | (w >> 16)); a = tmp; i = i + 1; end // g = 7
            39:begin  f = b ^ c ^ d;             w = a + f + 32'hbebfbc70;                tmp = d; d = c; c = b; b = b + ((w << 23) | (w >>  9)); a = tmp; i = i + 1; end // g = 10
            40:begin  f = b ^ c ^ d;             w = a + f + 32'h289b7ec6;                tmp = d; d = c; c = b; b = b + ((w <<  4) | (w >> 28)); a = tmp; i = i + 1; end // g = 13
            41:begin  f = b ^ c ^ d;             w = a + f + 32'heaa127fa + pwd[63:32];   tmp = d; d = c; c = b; b = b + ((w << 11) | (w >> 21)); a = tmp; i = i + 1; end //  g = 0
            42:begin  f = b ^ c ^ d;             w = a + f + 32'hd4ef3085;                tmp = d; d = c; c = b; b = b + ((w << 16) | (w >> 16)); a = tmp; i = i + 1; end // g = 3
            43:begin  f = b ^ c ^ d;             w = a + f + 32'h04881d05;                tmp = d; d = c; c = b; b = b + ((w << 23) | (w >>  9)); a = tmp; i = i + 1; end // g = 6
            44:begin  f = b ^ c ^ d;             w = a + f + 32'hd9d4d039;                tmp = d; d = c; c = b; b = b + ((w <<  4) | (w >> 28)); a = tmp; i = i + 1; end // g = 9
            45:begin  f = b ^ c ^ d;             w = a + f + 32'he6db99e5;                tmp = d; d = c; c = b; b = b + ((w << 11) | (w >> 21)); a = tmp; i = i + 1; end //  g = 12
            46:begin  f = b ^ c ^ d;             w = a + f + 32'h1fa27cf8;                tmp = d; d = c; c = b; b = b + ((w << 16) | (w >> 16)); a = tmp; i = i + 1; end // g = 15
            47:begin  f = b ^ c ^ d;             w = a + f + 32'hc4ac5665 + 32'h80;       tmp = d; d = c; c = b; b = b + ((w << 23) | (w >>  9)); a = tmp; i = i + 1; end // g = 2
            // i = 48 ~ 63  g = (7*i)%16
            
            48:begin  f = c ^ (b | (~d));        w = a + f + 32'hf4292244 + pwd[63:32];   tmp = d; d = c; c = b; b = b + ((w <<  6) | (w >> 26)); a = tmp; i = i + 1; end // g = 0
            49:begin  f = c ^ (b | (~d));        w = a + f + 32'h432aff97;                tmp = d; d = c; c = b; b = b + ((w << 10) | (w >> 22)); a = tmp; i = i + 1; end // g = 7
            50:begin  f = c ^ (b | (~d));        w = a + f + 32'hab9423a7 + 32'h40;       tmp = d; d = c; c = b; b = b + ((w << 15) | (w >> 17)); a = tmp; i = i + 1; end // g = 14
            51:begin  f = c ^ (b | (~d));        w = a + f + 32'hfc93a039;                tmp = d; d = c; c = b; b = b + ((w << 21) | (w >> 11)); a = tmp; i = i + 1; end // g = 5
            52:begin  f = c ^ (b | (~d));        w = a + f +32'h655b59c3;                 tmp = d; d = c; c = b; b = b + ((w <<  6) | (w >> 26)); a = tmp; i = i + 1; end // g = 12
            53:begin  f = c ^ (b | (~d));        w = a + f + 32'h8f0ccc92;                tmp = d; d = c; c = b; b = b + ((w << 10) | (w >> 22)); a = tmp; i = i + 1; end // g = 3
            54:begin  f = c ^ (b | (~d));        w = a + f + 32'hffeff47d;                tmp = d; d = c; c = b; b = b + ((w << 15) | (w >> 17)); a = tmp; i = i + 1; end // g = 10
            55:begin  f = c ^ (b | (~d));        w = a + f + 32'h85845dd1 + pwd[31:0];    tmp = d; d = c; c = b; b = b + ((w << 21) | (w >> 11)); a = tmp; i = i + 1; end // g = 1
            56:begin  f = c ^ (b | (~d));        w = a + f + 32'h6fa87e4f;                tmp = d; d = c; c = b; b = b + ((w <<  6) | (w >> 26)); a = tmp; i = i + 1; end // g = 8
            57:begin  f = c ^ (b | (~d));        w = a + f + 32'hfe2ce6e0;                tmp = d; d = c; c = b; b = b + ((w << 10) | (w >> 22)); a = tmp; i = i + 1; end // g = 15
            58:begin  f = c ^ (b | (~d));        w = a + f + 32'ha3014314;                tmp = d; d = c; c = b; b = b + ((w << 15) | (w >> 17)); a = tmp; i = i + 1; end // g = 6
            59:begin  f = c ^ (b | (~d));        w = a + f + 32'h4e0811a1;                tmp = d; d = c; c = b; b = b + ((w << 21) | (w >> 11)); a = tmp; i = i + 1; end // g = 13
            60:begin  f = c ^ (b | (~d));        w = a + f + 32'hf7537e82;                tmp = d; d = c; c = b; b = b + ((w <<  6) | (w >> 26)); a = tmp; i = i + 1; end // g = 4
            61:begin  f = c ^ (b | (~d));        w = a + f + 32'hbd3af235;                tmp = d; d = c; c = b; b = b + ((w << 10) | (w >> 22)); a = tmp; i = i + 1; end // g = 11
            62:begin  f = c ^ (b | (~d));        w = a + f + 32'h2ad7d2bb + 32'h80;       tmp = d; d = c; c = b; b = b + ((w << 15) | (w >> 17)); a = tmp; i = i + 1; end // g = 2
            63:begin  f = c ^ (b | (~d));        w = a + f + 32'heb86d391;                tmp = d; d = c; c = b; b = b + ((w << 21) | (w >> 11)); a = tmp; i = i + 1; end // g = 9
           
            64:begin  a = a + 32'h67452301; b = b + 32'hefcdab89; c = c + 32'h98badcfe; d = d + 32'h10325476; i = i + 1; end 
            65:begin  a = {a[7:0], a[15:8], a[23:16], a[31:24]}; b = {b[7:0],b[15:8], b[23:16], b[31:24]}; c = {c[7:0], c[15:8], c[23:16], c[31:24]}; d = {d[7:0], d[15:8], d[23:16], d[31:24]};i = i + 1;end
            66:begin i = 66; end
        endcase
    end
    
end
endmodule


module bin2ascii_2(
    input clk,
    input reset_n,
    input [27:0] bin,
    input en_begin,
    output reg [63:0] bcd1);
 
    reg [27:0] pre_bin = 28'hFFFFFFF;
    reg [4:0] i;
    reg [31:0] bcd;
    

    always@(posedge clk)begin
        pre_bin <= bin;
    end
    
    always@(posedge clk)begin
        if(pre_bin != bin || !en_begin || ~reset_n)begin
            bcd = 0;
            i = 0;
            bcd1 = 0;
        end
        else if(en_begin)begin
            if(i < 28)bcd = {bcd[30:0], bin[27-i]};
            
            if(i < 27)begin
                if(bcd[3:0] >= 5)      bcd[3:0] <=   bcd[3:0] + 3;
                if(bcd[7:4] >= 5)      bcd[7:4] <=   bcd[7:4] + 3;
                if(bcd[11:8] >= 5)    bcd[11:8] <=  bcd[11:8] + 3;
                if(bcd[15:12] >= 5)  bcd[15:12] <= bcd[15:12] + 3;
                if(bcd[19:16] >= 5)  bcd[19:16] <= bcd[19:16] + 3;
                if(bcd[23:20] >= 5)  bcd[23:20] <= bcd[23:20] + 3;
                if(bcd[27:24] >= 5)  bcd[27:24] <= bcd[27:24] + 3;
                if(bcd[31:28] >= 5)  bcd[31:28] <= bcd[31:28] + 3;
            end
            else if(i == 28)begin
                bcd1[63:56] <= 8'h30 + bcd[31:28];
                bcd1[55:48] <= 8'h30 + bcd[27:24];
                bcd1[47:40] <= 8'h30 + bcd[23:20];
                bcd1[39:32] <= 8'h30 + bcd[19:16];
                bcd1[31:24] <= 8'h30 + bcd[15:12];
                bcd1[23:16] <= 8'h30 + bcd[11:8];
                bcd1[15:8] <= 8'h30 + bcd[7:4];
                bcd1[7:0] <= 8'h30 + bcd[3:0]; 
            end
            if(i < 29)
                i = i + 1;
        end              
    end
endmodule

module ascii_incr(
    input clk,
    input [63:0] ascii_i,
    output reg [63:0] ascii_o,
    output [63:0] ascii_o2,
    output en2
);

integer i = 0;
assign en2 = (i==3);
reg [63:0] pre_ascii = 64'hFFFFFFFF;

always@(posedge clk)begin
    pre_ascii <= ascii_i;
end

always@(posedge clk)begin  
    if(pre_ascii != ascii_i)begin
        i <= 0;
        ascii_o <= ascii_i;
    end
    else if(i < 1)begin
        if(ascii_i[3:0] ==  4'h9 && ascii_i[11:8] == 4'h9 && ascii_i[19:16] == 4'h9 && ascii_i[27:24] == 4'h9 && ascii_i[35:32] == 4'h9 && ascii_i[43:40] == 4'h9 && ascii_i[51:48] == 4'h9)begin
             ascii_o[59:56] <= ascii_i[59:56] + 1; 
        end
        if(ascii_i[3:0] ==  4'h9 && ascii_i[11:8] == 4'h9 && ascii_i[19:16] == 4'h9 && ascii_i[27:24] == 4'h9 && ascii_i[35:32] == 4'h9 && ascii_i[43:40] == 4'h9)begin
             if(ascii_i[51:48] == 4'h9) ascii_o[51:48] <= 4'h0;
             else ascii_o[51:48] <= ascii_i[51:48] + 1;
        end
        if(ascii_i[3:0] ==  4'h9 && ascii_i[11:8] == 4'h9 && ascii_i[19:16] == 4'h9 && ascii_i[27:24] == 4'h9 && ascii_i[35:32] == 4'h9)begin
             if(ascii_i[43:40] == 4'h9) ascii_o[43:40] <= 4'h0;
             else ascii_o[43:40] <= ascii_i[43:40] + 1;
        end
        if(ascii_i[3:0] ==  4'h9 && ascii_i[11:8] == 4'h9 && ascii_i[19:16] == 4'h9 && ascii_i[27:24] == 4'h9)begin
              if(ascii_i[35:32] == 4'h9)  ascii_o[35:32] <= 4'h0;
              else ascii_o[35:32] <= ascii_i[35:32] + 1;
        end
        if(ascii_i[3:0] ==  4'h9 && ascii_i[11:8] == 4'h9 && ascii_i[19:16] == 4'h9)begin
              if(ascii_i[27:24] == 4'h9)  ascii_o[27:24] <= 4'h0;
              else  ascii_o[27:24] <= ascii_i[27:24] + 1;
        end
        if(ascii_i[3:0] ==  4'h9 && ascii_i[11:8] == 4'h9)begin
              if(ascii_i[19:16] == 4'h9) ascii_o[19:16] <= 4'h0;
              else ascii_o[19:16] <= ascii_i[19:16] + 1;
        end
        if(ascii_i[3:0] ==  4'h9)begin
              if(ascii_o[11:8] == 4'h9) ascii_o[11:8] <= 4'h0;
              else  ascii_o[11:8] <= ascii_i[11:8] + 1;
              ascii_o[3:0] <= 4'h0;
         end
         else ascii_o[3:0] = ascii_i[3:0] + 1;
         i = 3;
    end
    else i = 3;
end

assign ascii_o2 = {ascii_o[39:32], ascii_o[47:40], ascii_o[55:48], ascii_o[63:56], ascii_o[7:0], ascii_o[15:8], ascii_o[23:16], ascii_o[31:24]};
endmodule

module debounce(
    input clk,
    input btn_input,
    output btn_output
    );
    assign btn_output = btn_input;
endmodule