`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/10/07 15:18:45
// Design Name: 
// Module Name: alu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module alu(
    output reg [7:0] alu_out,
    output zero,
    
    input [2:0] opcode,
    input [7:0] data, accum,
    input clk,
    input reset
    );
  
 `define passA 3'b000
 `define add 3'b001
 `define sub 3'b010
 `define And 3'b011
 `define Xor 3'b100
 `define abs 3'b101
 `define mul 3'b110
 `define passD 3'b111
 
 reg chk;
 reg [3:0] absA, absD;
 reg [7:0] mult;
 
 assign zero = ~|accum;
 
  always@(posedge clk, posedge reset) begin
    if(reset == 1)
        alu_out <= 8'b00000000;
    else begin
        if(opcode == `passA)
            assign alu_out = accum;
         else if(opcode == `add)
            assign alu_out = accum + data;
         else if(opcode == `sub)
            assign alu_out = accum - data;
        else if(opcode == `And)
            assign alu_out = accum & data;
        else if(opcode == `Xor)
            assign alu_out = accum ^ data;
        else if(opcode == `abs)
            assign alu_out = accum[7] ? ~accum + 1 : accum;
        else if(opcode == `mul) begin
            assign chk = accum[3] ^ data[3];
            assign absA = accum[3] ? ~accum[3:0] + 1 : accum[3:0];
            assign absD = data[3] ? ~data[3:0] + 1 : data[3:0];
            assign mult = absA * absD;
            assign alu_out = chk ? ~mult + 1 : mult;
        end
        else if(opcode == `passD)
            assign alu_out = data;
    end
 
  end
 
endmodule

