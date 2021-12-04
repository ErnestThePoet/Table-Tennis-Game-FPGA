`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/04 00:19:39
// Design Name: 
// Module Name: cgsim
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


module cgsim();
    reg sysClk=0;
    wire newClk;
    
    ClockGenerator #(0.0001,100) cg(sysClk,newClk);
    
    always begin
        #1;
        sysClk=~sysClk;
    end
endmodule
