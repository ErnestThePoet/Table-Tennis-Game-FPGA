`timescale 1ns / 1ps

// Module: InteractionHandlerForSim
// Implementation of the game, FOR SIMULATION ONLY. Manages game state, handles hardware input and updates display.
// @port hwClock : Hardware clock input.
// @port gamePauseSignal : Signal indicating whether the game is paused.
// @port tennisSpeedControls : A pack of three tennis speed control signals. {FAST, DEFAULT, SLOW}
// @port lHitSignal : Left player hitting signal.
// @port rHitSignal : Right player hitting signal.
//
// @port tennisLeds : An 8-bit vector representing tennis LEDs.
// @port lServeLed : Left player serve indication LED.
// @port rServeLed : Right player serve indication LED.
// @port digitSelectors : An 8-bit nixie tube selector vector.
// @port digitSegmentsL : An 8-bit segment selector vector for the left 4 nixie tubes.
// @port digitSegmentsR : An 8-bit segment selector vector for the right 4 nixie tubes.

module InteractionHandlerForSim(
    input hwClock,
    input gamePauseSignal,
    input [2:0] tennisSpeedControls,
    input lHitSignal,
    input rHitSignal,
    output reg [7:0] tennisLeds,
    output reg lServeLed,
    output reg rServeLed,
    output reg [7:0] digitSelectors,
    output reg [7:0] digitSegmentsL,
    output reg [7:0] digitSegmentsR);

    /////////////////////////////////// Marco definitions /////////////////////////////////////////
    // FSM States
    parameter STATE_INITIAL = -1;
    parameter STATE_SERVE_LEFT_PLAYER=0;
    parameter STATE_SERVE_RIGHT_PLAYER=1;
    parameter STATE_TENNIS_MOVE_RIGHT = 2;
    parameter STATE_TENNIS_MOVE_LEFT = 3;
    parameter STATE_FOULED_LEFT_PLAYER = 4;
    parameter STATE_FOULED_RIGHT_PLAYER = 5;
    parameter STATE_WON_LEFT_PLAYER = 6;
    parameter STATE_WON_RIGHT_PLAYER = 7;
    ///////////////////////////////////////////////////////////////////////////////////////////////
    
    /////////////////////////////// Customizable constants ////////////////////////////////////////
    // Min, max, and change step for tennis LED move interval in millisecond.
    parameter MAX_SPEED_TENNIS_MOVE_INTERVAL_MS = 100;
    parameter MIN_SPEED_TENNIS_MOVE_INTERVAL_MS = 250;
    parameter DEFAULT_TENNIS_MOVE_INTERVAL_MS = 175;
    // LED Refresh interval in millisecond.
    parameter LED_REFRESH_INTERVAL_MS=5;
    // Text display duration in millisecond.
    parameter TEXT_DISPLAY_DURATION_MS = 1500;
    // Winning scores.
    parameter WINNING_SCORES=11;
    // Minimum score diffenence required to win.
    parameter MIN_WINNING_SCORE_DIFFERENCE = 2;
    // The score at which serve needs to be exchanged.
    parameter XSERVE_SCORES_BASE=5;
    ///////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////// Nixie tube character bitsets /////////////////////////////////////
    // Single character bitfields for nixie tubes
    parameter DIGIT_EMPTY=8'b00000000;
    reg[7:0] DIGIT_NUMS[0:9];

    parameter DIGIT_t = 8'b01111000;
    parameter DIGIT_E = 8'b01111001;
    parameter DIGIT_N = 8'b00110111;
    parameter DIGIT_I = 8'b00000110;

    parameter DIGIT_S=8'b01101101;
    parameter DIGIT_e=8'b01111011;
    parameter DIGIT_r=8'b01010000;

    parameter DIGIT_o=8'b01011100;
    parameter DIGIT_F=8'b01110001;
    parameter DIGIT_u=8'b00011100;
    parameter DIGIT_L=8'b00111000;
    parameter DIGIT_d = 8'b01011110;

    parameter DIGIT_C = 8'b00111001;
    parameter DIGIT_n = 8'b01010100;
    parameter DIGIT_g = 8'b01101111;
    parameter DIGIT_a = 8'b01011111;
    parameter DIGIT_t_DOT = 8'b11111000;

    parameter DIGIT_v_DOT=8'b10011100;
    parameter DIGIT_V_DOT=8'b10111110;
    parameter DIGIT_S_DOT=8'b11101101;
    parameter DIGIT_L_DOT=8'b10111000;
    parameter DIGIT_r_DOT=8'b11010000;
    parameter DIGIT_DASH = 8'b01000000;
    ///////////////////////////////////////////////////////////////////////////////////////////////

    /////////////////////////////// Local ports and variables /////////////////////////////////////
    // Local clock signal, cycle=1ms, 10ms.
    wire clockMs;
    // Current used LED move time interval.
    integer currentTennisLedMoveIntervalMs=DEFAULT_TENNIS_MOVE_INTERVAL_MS;
    // Timer counter for tennis LED.
    integer tennisLedTimerCycleCounter=0;
    // Timer counter for led refreshing.
    integer ledRefreshTimerCounter=0;
    // Timer counter for text display.
    integer textDisplayTimerCounter=0;
    // Current game state.
    integer currentState=STATE_INITIAL;
    // Scores:left, right
    integer scores[1:0];  // TO BE MANAGED
    // Serves:left, right
    integer serves[1:0];  // TO BE MANAGED
    // Character display buffer and position pointer for left side.
    reg[7:0] ledBuffer[0:7];  // TO BE MANAGED
    integer ledBufferPosL=0;
    ///////////////////////////////////////////////////////////////////////////////////////////////

    ClockGenerator #(0.001,100) clock_generator_ms(hwClock,clockMs);

    initial begin
        digitSelectors=8'b1000_1000;
        tennisLeds=8'b1111_1111;
        DIGIT_NUMS[0]=8'b00111111;
        DIGIT_NUMS[1]=8'b00000110;
        DIGIT_NUMS[2]=8'b01011011;
        DIGIT_NUMS[3]=8'b01001111;
        DIGIT_NUMS[4]=8'b01100110;
        DIGIT_NUMS[5]=8'b01101101;
        DIGIT_NUMS[6]=8'b01111101;
        DIGIT_NUMS[7]=8'b00000111;
        DIGIT_NUMS[8]=8'b01111111;
        DIGIT_NUMS[9]=8'b01101111;
    end

    always @(posedge clockMs) begin: clock_loop
        // Always update LED Refresh counter
        ledRefreshTimerCounter=ledRefreshTimerCounter+1;
        if(ledRefreshTimerCounter>=LED_REFRESH_INTERVAL_MS) begin
            if(digitSelectors>>1==8'b0000_1000) begin
                digitSelectors=8'b1000_1000;
                ledBufferPosL=0;
            end
            else begin
                digitSelectors=digitSelectors>>1;
                ledBufferPosL=ledBufferPosL+1;
            end

            digitSegmentsL<=ledBuffer[ledBufferPosL];
            digitSegmentsR<=ledBuffer[ledBufferPosL+4];

            ledRefreshTimerCounter<=0;
        end

        // Handle speed control inputs
        case(tennisSpeedControls)
            // up
            3'b100: begin
                currentTennisLedMoveIntervalMs=MAX_SPEED_TENNIS_MOVE_INTERVAL_MS;     
            end
            // reset
            3'b010: begin
                currentTennisLedMoveIntervalMs=DEFAULT_TENNIS_MOVE_INTERVAL_MS;
            end
            // down
            3'b001: begin
                currentTennisLedMoveIntervalMs=MIN_SPEED_TENNIS_MOVE_INTERVAL_MS;
            end
        endcase

        // Skip all remaining statements if game is paused.
        if(gamePauseSignal) begin
            disable clock_loop;
        end

        // Handle hit signals
        if(lHitSignal) begin
            if(currentState==STATE_TENNIS_MOVE_LEFT) begin
                // If the tennis is at valid position, just bounce right.
                if(tennisLeds==8'b1000_0000) begin
                    currentState=STATE_TENNIS_MOVE_RIGHT;
                end
                // Otherwise, left player fouls.
                else begin
                    currentState=STATE_FOULED_LEFT_PLAYER;
                end
            end
            // If hit to serve
            else if(currentState==STATE_SERVE_LEFT_PLAYER) begin
                currentState=STATE_TENNIS_MOVE_RIGHT;
                // Increase serve count
                serves[0]=serves[0]+1;
            end
            // If hit after right player's win or at initial state.
            else if(currentState==STATE_WON_RIGHT_PLAYER||currentState==STATE_INITIAL) begin
                currentState=STATE_SERVE_LEFT_PLAYER;

                // Clear serves and scores.
                serves[0]<=0;
                serves[1]<=0;
                scores[0]<=0;
                scores[1]<=0;
            end
        end
        else if(rHitSignal) begin
            if(currentState==STATE_TENNIS_MOVE_RIGHT) begin
                if(tennisLeds==8'b0000_0001) begin
                    currentState=STATE_TENNIS_MOVE_LEFT;
                end
                else begin
                    currentState=STATE_FOULED_RIGHT_PLAYER;
                end
            end
            else if(currentState==STATE_SERVE_RIGHT_PLAYER) begin
                currentState=STATE_TENNIS_MOVE_LEFT;
                
                serves[1]=serves[1]+1;
            end
            else if(currentState==STATE_WON_LEFT_PLAYER||currentState==STATE_INITIAL) begin
                currentState=STATE_SERVE_RIGHT_PLAYER;

                serves[0]<=0;
                serves[1]<=0;
                scores[0]<=0;
                scores[1]<=0;
            end
        end

        // Handle states.
        case(currentState)
            STATE_SERVE_LEFT_PLAYER: begin
                DisplayServeLeftPlayer;
            end

            STATE_SERVE_RIGHT_PLAYER: begin
                DisplayServeRightPlayer;
            end

            STATE_TENNIS_MOVE_RIGHT: begin
                DisplayTennisMoveNoTennisLed;

                tennisLedTimerCycleCounter=tennisLedTimerCycleCounter+1;

                if(tennisLedTimerCycleCounter>=currentTennisLedMoveIntervalMs) begin
                    // If the tennis goes out, the right player fouls.
                    if(tennisLeds==8'b0000_0001) begin
                        currentState=STATE_FOULED_RIGHT_PLAYER;
                    end
                    // Otherwise move the tennis by one bit right.
                    else begin
                        tennisLeds=tennisLeds>>1;
                    end

                    tennisLedTimerCycleCounter=0;
                end
            end

            STATE_TENNIS_MOVE_LEFT: begin
                DisplayTennisMoveNoTennisLed;

                tennisLedTimerCycleCounter=tennisLedTimerCycleCounter+1;

                if(tennisLedTimerCycleCounter>=currentTennisLedMoveIntervalMs) begin
                    if(tennisLeds==8'b1000_0000) begin
                        currentState=STATE_FOULED_LEFT_PLAYER;
                    end
                    else begin
                        tennisLeds=tennisLeds<<1;
                    end

                    tennisLedTimerCycleCounter=0;
                end
            end

            STATE_FOULED_LEFT_PLAYER: begin
                DisplayFouledLeftPlayerNoTennisLed;

                textDisplayTimerCounter=textDisplayTimerCounter+1;

                if(textDisplayTimerCounter>=TEXT_DISPLAY_DURATION_MS) begin
                    scores[1]=scores[1]+1;

                    // Two conditions must be met if a player wants to win:
                    // 1). The player has to have got at least WINNING_SCORES scores.
                    // 2). The player has to have at least MIN_WINNING_SCORE_DIFFERENCE scores ahead of the other player.
                    if(scores[1]>=WINNING_SCORES
                        &&(scores[1]-scores[0]>=MIN_WINNING_SCORE_DIFFERENCE)) begin
                        currentState=STATE_WON_RIGHT_PLAYER;
                    end
                    // Exchange the serve if the other player's scores reaches a multiple of XSERVE_SCORES.
                    else if(scores[1]%XSERVE_SCORES_BASE==0) begin
                        currentState=STATE_SERVE_LEFT_PLAYER;
                    end
                    // Otherwise let the other player serve who didn't foul this time.
                    else begin
                        currentState=STATE_SERVE_RIGHT_PLAYER;
                    end

                    textDisplayTimerCounter=0;
                end
            end

            STATE_FOULED_RIGHT_PLAYER: begin
                DisplayFouledRightPlayerNoTennisLed;

                textDisplayTimerCounter=textDisplayTimerCounter+1;

                if(textDisplayTimerCounter>=TEXT_DISPLAY_DURATION_MS) begin
                    scores[0]=scores[0]+1;

                    if(scores[0]>=WINNING_SCORES
                        &&(scores[0]-scores[1]>=MIN_WINNING_SCORE_DIFFERENCE)) begin
                        currentState=STATE_WON_LEFT_PLAYER;
                    end
                    else if(scores[0]%XSERVE_SCORES_BASE==0) begin
                        currentState=STATE_SERVE_RIGHT_PLAYER;
                    end
                    else begin
                        currentState=STATE_SERVE_LEFT_PLAYER;
                    end

                    textDisplayTimerCounter=0;
                end
            end

            STATE_WON_LEFT_PLAYER: begin
                DisplayWonLeftPlayer;
            end

            STATE_WON_RIGHT_PLAYER: begin
                DisplayWonRightPlayer;
            end
        endcase
    end

    task DisplayServeLeftPlayer; begin
            lServeLed<=1;
            rServeLed<=0;

            ledBuffer[0]<=DIGIT_DASH;
            ledBuffer[1]<=DIGIT_L_DOT;
            ledBuffer[2]<=DIGIT_S;
            ledBuffer[3]<=DIGIT_r;
            ledBuffer[4]<=DIGIT_v_DOT;
            ledBuffer[5]<=DIGIT_NUMS[(serves[0]+1)/10];
            ledBuffer[6]<=DIGIT_NUMS[(serves[0]+1)%10];
            ledBuffer[7]<=DIGIT_DASH;

            tennisLeds<=8'b1000_0000;
        end
    endtask

    task DisplayServeRightPlayer; begin
            lServeLed<=0;
            rServeLed<=1;

            ledBuffer[0]<=DIGIT_DASH;
            ledBuffer[1]<=DIGIT_r_DOT;
            ledBuffer[2]<=DIGIT_S;
            ledBuffer[3]<=DIGIT_r;
            ledBuffer[4]<=DIGIT_v_DOT;
            ledBuffer[5]<=DIGIT_NUMS[(serves[1]+1)/10];
            ledBuffer[6]<=DIGIT_NUMS[(serves[1]+1)%10];
            ledBuffer[7]<=DIGIT_DASH;

            tennisLeds<=8'b0000_0001;
        end
    endtask

    task DisplayTennisMoveNoTennisLed; begin
            lServeLed<=0;
            rServeLed<=0;

            ledBuffer[0]<=DIGIT_NUMS[scores[0]/10];
            ledBuffer[1]<=DIGIT_NUMS[scores[0]%10];
            ledBuffer[2]<=DIGIT_EMPTY;
            ledBuffer[3]<=DIGIT_V_DOT;
            ledBuffer[4]<=DIGIT_S_DOT;
            ledBuffer[5]<=DIGIT_EMPTY;
            ledBuffer[6]<=DIGIT_NUMS[scores[1]/10];
            ledBuffer[7]<=DIGIT_NUMS[scores[1]%10];
        end
    endtask

    task DisplayFouledLeftPlayerNoTennisLed; begin
            lServeLed<=0;
            rServeLed<=0;

            ledBuffer[0]<=DIGIT_DASH;
            ledBuffer[1]<=DIGIT_L_DOT;
            ledBuffer[2]<=DIGIT_F;
            ledBuffer[3]<=DIGIT_o;
            ledBuffer[4]<=DIGIT_u;
            ledBuffer[5]<=DIGIT_L;
            ledBuffer[6]<=DIGIT_e;
            ledBuffer[7]<=DIGIT_d;
        end
    endtask

    task DisplayFouledRightPlayerNoTennisLed; begin
            lServeLed<=0;
            rServeLed<=0;

            ledBuffer[0]<=DIGIT_DASH;
            ledBuffer[1]<=DIGIT_r_DOT;
            ledBuffer[2]<=DIGIT_F;
            ledBuffer[3]<=DIGIT_o;
            ledBuffer[4]<=DIGIT_u;
            ledBuffer[5]<=DIGIT_L;
            ledBuffer[6]<=DIGIT_e;
            ledBuffer[7]<=DIGIT_d;
        end
    endtask

    task DisplayWonLeftPlayer; begin
            lServeLed<=1;
            rServeLed<=0;

            ledBuffer[0]<=DIGIT_C;
            ledBuffer[1]<=DIGIT_o;
            ledBuffer[2]<=DIGIT_n;
            ledBuffer[3]<=DIGIT_g;
            ledBuffer[4]<=DIGIT_r;
            ledBuffer[5]<=DIGIT_a;
            ledBuffer[6]<=DIGIT_t_DOT;
            ledBuffer[7]<=DIGIT_L_DOT;

            tennisLeds<=8'b1111_0000;
        end
    endtask

    task DisplayWonRightPlayer; begin
            lServeLed<=0;
            rServeLed<=1;

            ledBuffer[0]<=DIGIT_C;
            ledBuffer[1]<=DIGIT_o;
            ledBuffer[2]<=DIGIT_n;
            ledBuffer[3]<=DIGIT_g;
            ledBuffer[4]<=DIGIT_r;
            ledBuffer[5]<=DIGIT_a;
            ledBuffer[6]<=DIGIT_t_DOT;
            ledBuffer[7]<=DIGIT_r_DOT;

            tennisLeds<=8'b0000_1111;
        end
    endtask
endmodule