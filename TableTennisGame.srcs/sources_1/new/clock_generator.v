`timescale 1ns / 1ps

// Module: ClockGenerator
// Generates a new clock signal based on the given hardware clock signal.
// The two parameters specify your target clock cycle in ms and the
// hardware clock frequency in MHz.
// @param TARGET_CYCLE_MS : Target clock cycle in ms. Defaults to 200. 0<TARGET_CYCLE_MS<2^32
// @param HW_CLOCK_FREQ_MHZ : Hardware clock frequency in MHz. Defaults to 100.
// @port hw_clock : Hardware clock input.
// @port clock_output : generated clock signal.

module ClockGenerator
    #(parameter TARGET_CYCLE_MS=200,
      parameter HW_CLOCK_FREQ_MHZ=100)

    (input hw_clock,
    output reg clock_output);

    reg local_clock=0;
    reg [32-1:0] cycle_counter=0;
    parameter [32-1:0] HALF_TARGET_CYCLE_COUNT=HW_CLOCK_FREQ_MHZ*TARGET_CYCLE_MS*500;
    
    // Initialize output signal
    initial begin
        clock_output=local_clock;
    end

    // increase the counter at each positive edge of the hardware clock
    always @(posedge hw_clock) begin
        if(cycle_counter==HALF_TARGET_CYCLE_COUNT) begin
            local_clock=~local_clock;
            clock_output=local_clock;
            cycle_counter=0;
        end
        else
            cycle_counter=cycle_counter+1;
    end

endmodule