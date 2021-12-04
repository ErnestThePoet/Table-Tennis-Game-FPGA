`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/04 00:25:17
// Design Name: 
// Module Name: ihsim
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


module ihsim();
    reg hwClock=0;
    reg gamePauseSignal=0;
    reg [2:0] tennisSpeedControls={0,0,0};
    reg lHitSignal=0;
    reg rHitSignal=0;
    wire [7:0] tennisLeds;
    wire lServeLed;
    wire rServeLed;
    wire [7:0] digitSelectors;
    wire [7:0] digitSegmentsL;
    wire [7:0] digitSegmentsR;
    
    InteractionHandlerForSim ih(hwClock,gamePauseSignal,tennisSpeedControls,lHitSignal,rHitSignal,
    tennisLeds,lServeLed,rServeLed,digitSelectors,digitSegmentsL,digitSegmentsR);
    
    always begin
        #1;
        hwClock=~hwClock;
    end
    
    always begin
            
        #100;
        lHitSignal=1;
        #30;
        lHitSignal=0;
    end
endmodule
