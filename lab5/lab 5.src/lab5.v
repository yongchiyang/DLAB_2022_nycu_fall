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
//reg [127:0] row_A = "Press BTN3 to   "; // Initialize the text of the first row. 
//reg [127:0] row_B = "show a message.."; // Initialize the text of the second row.
reg [127:0] row_A = 128'b0;
reg [127:0] row_B = 128'b0;
wire [127:0] C = 128'h44656D6F206F66204C61332020202020;
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

reg [15:0] fib [0:24];
reg [31:0] a, a_1;
reg [23:0] b, b_1;
reg [15:0] c, c_1;
reg [7:0] d, d_1; // four hex value
integer i; // for fibonacci loop
integer j, k; // for current fib#
reg [7:0] counter, counter_1; // for the output
reg fwrd; 
integer time_q; // 0.7s
reg [7:0] counter_d, counter_d1; // counter_decimal output

// fibonacci loop
always @(posedge clk) begin
    if(~reset_n)begin
        fib[0] <= 16'd0;
        fib[1] <= 16'd1;
        i <= 2;
    end
    else begin
        if(i <= 24)begin
            fib[i] <= fib[i - 1] + fib[i - 2];
            i = i + 1;
        end
    end
end

// fwrd & bwrd control
always@(posedge clk)begin
    if(~reset_n)begin
        time_q <= 70000000;
        fwrd <= 1'b1;
        j = 0;
        k = 1;
    end
    else begin
        if(btn_pressed)
            fwrd = !fwrd;
            
        if(time_q == 0)begin
            if(fwrd)begin
                if(j == 24)begin
                    j = 0;
                end
                else
                    j = j + 1;
                    
                if(k == 24)begin
                    k = 0;
                end
                else
                    k = k + 1;
            end
            else begin
                if(j == 0)begin
                    j = 24;
                 end
                 else
                    j = j - 1;
                    
                 if(k == 0)
                    k = 24;
                 else 
                    k = k - 1;
            end
            time_q = 90000000;
        end
        else
            time_q = time_q - 1;
    end
end

// counter assignment
always@(posedge clk)begin
    if(~reset_n)begin
        counter <= 8'd0;
    end
    else
        counter = j + 1;
        counter_1 = k + 1;
end



// assign counter decimal value
always@(posedge clk)begin
    if(~reset_n)begin
        counter_d <= 8'd0;
        counter_d <= 8'd0;
    end
    else begin
        // for counter_d : row_A
        if(counter >= 10 && counter <20)begin
            counter_d[7:4] = 4'b0001;
            counter_d[3:0] = counter - 4'd10;
        end
        else if(counter >= 20)begin
            counter_d[7:4] = 4'b0010;
            counter_d[3:0] = counter - 8'd20;
        end
        else
            counter_d = counter;
            
       // for counter_d1 : row_B
       if(counter_1 >= 10 && counter_1 <20)begin
            counter_d1[7:4] = 4'b0001;
            counter_d1[3:0] = counter_1 - 4'd10;
        end
        else if(counter_1 >= 20)begin
            counter_d1[7:4] = 4'b0010;
            counter_d1[3:0] = counter_1 - 8'd20;
        end
        else
            counter_d1 = counter_1;
    end
end

// assign fibo hexadecimal value
always@(posedge clk)begin
    if(~reset_n)begin
        a <= 0;
        b <= 0;
        c <= 0;
        d <= 0;
        
        a_1 <= 0;
        b_1 <= 0;
        c_1 <= 0;
        d_1 <= 0;
    end
    else begin
        // row_A
        if(fib[j][15:12] > 4'b1001)
            a = (fib[j][15:12] - 4'd10 + 8'h41);
        else
            a = (fib[j][15:12] + 8'h30);
           
        if(fib[j][11:8] > 4'b1001)
            b = (fib[j][11:8] - 4'd10 + 8'h41);
        else
            b = (fib[j][11:8] + 8'h30);
            
        if(fib[j][7:4] > 4'b1001)
            c = (fib[j][7:4] - 4'd10 +8'h41);
        else
            c = (fib[j][7:4] + 8'h30);
            
        if(fib[j][3:0] > 4'b1001)
            d = (fib[j][3:0] - 4'd10 + 8'h41);
        else
            d = fib[j][3:0] + 8'h30;
            
        // row_B  
        if(fib[k][15:12] > 4'b1001)
            a_1 = (fib[k][15:12] - 4'd10 + 8'h41);
        else
            a_1 = (fib[k][15:12] + 8'h30);
           
        if(fib[k][11:8] > 4'b1001)
            b_1 = (fib[k][11:8] - 4'd10 + 8'h41);
        else
            b_1 = (fib[k][11:8] + 8'h30);
            
        if(fib[k][7:4] > 4'b1001)
            c_1 = (fib[k][7:4] - 4'd10 +8'h41);
        else
            c_1 = (fib[k][7:4] + 8'h30);
            
        if(fib[k][3:0] > 4'b1001)
            d_1 = (fib[k][3:0] - 4'd10 + 8'h41);
        else
            d_1 = fib[k][3:0] + 8'h30;
    end
end


// assign output
always@(posedge clk)begin
    if(~reset_n)begin
        row_A = "Press BTN3 to   ";
        row_B = "show a message..";
    end
    else begin
        //row_A <= 128'h20202020202020202020202000000000 + (a << 24) + (b << 16) + (c << 8) + d;
        //row_B = 128'h20202020202020202020202020200000 + ((counter_d[7:4] + 8'h30) << 8) + (counter_d[3:0] + 8'h30);
        row_A <= 128'h46_69_62_6F_20_23_00_00_20_69_73_20_00_00_00_00 + (a << 24) + (b << 16) + (c << 8) + d +  ((counter_d[7:4] + 8'h30) << 72) + ((counter_d[3:0] + 8'h30) << 64);
        row_B <= 128'h46_69_62_6F_20_23_00_00_20_69_73_20_00_00_00_00 + (a_1 << 24) + (b_1 << 16) + (c_1 << 8) + d_1 +  ((counter_d1[7:4] + 8'h30) << 72) + ((counter_d1[3:0] + 8'h30) << 64);
    end
    
end
// 128'h46_69_62_6F_20_23_cc_cc_20_69_73_20_ff_ff_ff_ff
//row_B  = 

endmodule

module debounce(
    input clk,
    input btn_input,
    output btn_output
    );
    assign btn_output = btn_input;
endmodule