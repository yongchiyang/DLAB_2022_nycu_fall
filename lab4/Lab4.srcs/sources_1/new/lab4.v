`timescale 1ns / 1ps

/*
module debouncing(input clk, 
                 input reset_n, 
                 input b_in, 
                 output reg b_o);

reg [6:0] cs, ns;

always@(*)begin
if(cs == 7'd8)
    ns = (b_in) ? 7'd8 : 7'd0;
else if(cs < 7'd8 && cs >= 7'd0) // next state 
    ns = (b_in) ? cs + 1 : 7'd0;
else // defualt value
    ns = 7'd0;
end

always@(posedge clk, negedge reset_n)begin
if(!reset_n)
    cs <= 7'd8;
else
    cs <= ns;
end

always@(*)begin
    if(cs == 7'd8)
        b_o = 1'b1;
    else   
        b_o = 1'b0;
end
endmodule

*/

module debouncing_3(input clk, input b_in, output reg b_out);
    
    reg [31:0] count;
    always@(posedge clk) begin
        if(!b_in)begin
            b_out <= 1'b0;
            count = 0;
        end
        else begin
            if(count < 32'd700000)begin
                count = count + 1;
                b_out = 0;
            end
            else begin
                b_out = 1;
            end
        end
    end
endmodule


module lab4(
  input  clk,            // System clock at 100 MHz
  input  reset_n,        // System reset signal, in negative logic
  input  [3:0] usr_btn,  // Four user pushbuttons
  output [3:0] usr_led   // Four yellow LEDs
);
/*********** debouncing***********/

wire [3:0] usr_btn_o;
wire reset_o;
debouncing_3 d1 (clk, usr_btn[0], usr_btn_o[0]);
debouncing_3 d2 (clk, usr_btn[1], usr_btn_o[1]);
debouncing_3 d3 (clk, usr_btn[2], usr_btn_o[2]);
debouncing_3 d4 (clk, usr_btn[3], usr_btn_o[3]);
debouncing_3 d5 (clk, reset_n,  reset_o);


reg [3:0] counter; // for button 0 & 1
reg [3:0] brightness;  // for button 2 & 3
reg out_bri; // for button 2 & 3
integer count; // for brightness
reg [3:0] btn_n;
reg [3:0] btn_old;
reg bbtn_old;
reg bbtn_r;
wire button;
assign button = | usr_btn_o;

always@(posedge clk, negedge reset_o)begin
if(!reset_o)begin
    counter <= 4'b0000;
    //btn_old <= 4'b0000;
    brightness <= 3'b010;
    btn_old <= 1'b0;
end
else begin
/*
//// button 0
    if(btn_old[0] != usr_btn_o[0] && usr_btn_o[0] == 1'b0)
        btn_n[0] <= 1'b1;
    else
        btn_n[0] <= 1'b0;
    
    btn_old[0] <= usr_btn_o[0]; 
    
    if(btn_n[0])begin
        if(counter == 4'b1000)
            counter <= 4'b1000;
        else
            counter <= counter - 4'd1;
    end
//// button 1
    if(btn_old[1] != usr_btn_o[1] && usr_btn_o[1] == 1'b0)
        btn_n[1] <= 1'b1;
    else
        btn_n[1] <= 1'b0;
        
    btn_old[1] <= usr_btn_o[1];
        
    if(btn_n[1])begin
        if(counter == 4'b0111)
            counter <= 4'b0111;
        else    
            counter <= counter + 4'd1;
    end

/// button 2 
    if(btn_old[2] != usr_btn_o[2] && usr_btn_o[2] == 1'b0)
        btn_n[2] <= 1'b1;
    else 
        btn_n[2] <= 1'b0;
   
   btn_old[2] <= usr_btn_o[2];
   
   if(btn_n[2])begin
        if(brightness == 3'b000)
            brightness <= 3'b000;
        else 
            brightness <= brightness - 3'd1;
   end

//// button 3 
    if(btn_old[3] != usr_btn_o[3] && usr_btn_o[3] == 1'b0)
        btn_n[3] <= 1'b1;
    else
        btn_n[3] <= 1'b0;
        
    btn_old[3] <= usr_btn_o[3];
    
    if(btn_n[3])begin
        if(brightness == 3'b100)
            brightness <= 3'b100;
        else
            brightness <= brightness + 3'd1;
    end
    */
///// buttun handler 
    if(bbtn_old != button && button == 1'b1)
        bbtn_r <= 1'b1;
    else
        bbtn_r <= 1'b0;
        
    bbtn_old <= button;
    
    if(bbtn_r)begin
    if(usr_btn_o[0])begin
        if(counter == 4'b1000)
            counter <= 4'b1000;
        else
            counter <= counter - 4'd1;
    end
    
    if(usr_btn_o[1])begin
        if(counter == 4'b0111)
            counter <= 4'b0111;
        else    
            counter <= counter + 4'd1;
    end
    
    if(usr_btn_o[2])begin
        if(brightness == 3'b000)
            brightness <= 3'b000;
        else 
            brightness <= brightness - 3'd1;
    end
    
    if(usr_btn_o[3])begin
         if(brightness == 3'b100)
            brightness <= 3'b100;
        else
            brightness <= brightness + 3'd1;
    end
    end
//// brightness
    if(count == 0)
            count <= 1000000;
            
    if(brightness == 3'b000)begin
        if(count > 50000)
            out_bri <= 1'b0;
         else
            out_bri <= 1'b1;
    end
    else if(brightness == 3'b001)begin
        if(count > 250000)
            out_bri <= 1'b0;
        else
            out_bri <= 1'b1;
    end
    else if(brightness == 3'b010)begin
        if(count > 500000)
            out_bri <= 1'b0;
        else
            out_bri <= 1'b1;
    end
    else if(brightness == 3'b011)begin
        if(count > 750000)
            out_bri <= 1'b0;
        else
            out_bri <= 1'b1;
    end
    else if(brightness == 3'b100)begin 
        out_bri<= 1'b1;
    end
    
    count = count - 1;
    
end
end




assign usr_led = counter & {4{out_bri}};

endmodule