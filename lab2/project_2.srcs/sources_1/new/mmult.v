
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/10/02 15:53:08
// Design Name: 
// Module Name: mmult
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





module mmult(
    input clk,
    input reset_n,
    input enable,
    
    input [0:9*8-1] A_mat,
    input [0:9*8-1] B_mat,
    
    output valid,
    
    output reg [0:9*17-1] C_mat
    );
    reg [0:9*17-1] C;
    reg valid_t;
    integer i;
    
    assign valid = valid_t;
    
    always @(posedge clk, negedge reset_n)begin
        if(!reset_n)begin
            C_mat[0:152] <= 153'b0;
            i <= 0;
            valid_t <= 0;
        end
        
        if(enable) begin
            if(i == 3) begin
                valid_t <= 1'b1;
            end
            else begin
                //  A row1
                C[0:16] = A_mat[0:7] * B_mat[i*8 +:8];
                C[17:33] = A_mat[8:15] * B_mat[i*8+24 +:8];
                C[34:50] = A_mat[16:23] * B_mat[i*8+48 +:8];
                C_mat[i*17+ :17] = C[0:16] + C[17:33] + C[34:50];
                // A row 2
                C[51:67] = A_mat[24:31] * B_mat[i*8 +:8];
                C[68:84] = A_mat[32:39] * B_mat[i*8+24 +:8];
                C[85:101] = A_mat[40:47] * B_mat[i*8+48 +:8];
                C_mat[i*17+51 +: 17] = C[51:67] + C[68:84] + C[85:101];
                // A row3
                C[102:118] = A_mat[48:55] * B_mat[i*8 +:8];
                C[119:135] = A_mat[56:63] * B_mat[i*8+24 +:8];
                C[136:152] = A_mat[63:71] * B_mat[i*8+48 +:8];
                C_mat[i*17+102 +: 17] = C[102:118] + C[119:135] + C[136:152];
                i = i + 1;
                if(i == 3)
                valid_t = 1'b1;
            end
        end
    end
    
    
    
   
    
endmodule
