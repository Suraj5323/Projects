`timescale 1s / 1ms

module tb_clock_24_12_date;

    // Inputs
    reg clk = 0;
    reg reset = 1;
    reg mode = 0; // Change to 0 for 12-hour mode
    reg start_timer = 0;

    // Outputs
    wire [7:0] hours_out;
    wire [7:0] min;
    wire [7:0] sec;
    wire am_pm;
    wire [7:0] day;
    wire [7:0] month;
    wire [7:0] year;
    wire [7:0] cd_min;
    wire [7:0] cd_sec;
    wire buzzer;

    // Instantiate DUT
    clock_24_12_date uut (
        .clk(clk),
        .reset(reset),
        .mode(mode),
        .start_timer(start_timer),
        .hours_out(hours_out),
        .min(min),
        .sec(sec),
        .am_pm(am_pm),
        .day(day),
        .month(month),
        .year(year),
        .cd_min(cd_min),
        .cd_sec(cd_sec),
        .buzzer(buzzer)
    );

    // Clock generation
    always #0.5 clk = ~clk;

    // Simulation logic
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_clock_24_12_date);

        #1 reset = 1;
        #1 reset = 0;

        // Set initial time to 23:59:50 on 30-04-2025
        uut.hours = 23;
        uut.min = 59;
        uut.sec = 50;
        uut.day = 28;
        uut.month = 02;
        uut.year = 25;

        #1;
        $display("---- %s Clock Mode ----", mode ? "24-Hour" : "12-Hour");

        repeat (20) begin
            #1;
            if (mode == 1) begin
                $display("DATE: %0d-%0d-20%0d, TIME: %02d:%02d:%02d",
                    day, month, year, hours_out, min, sec);
            end else begin
                $display("DATE: %0d-%0d-20%0d, TIME: %02d:%02d:%02d %s",
                    day, month, year, hours_out, min, sec, am_pm ? "PM" : "AM");
            end
        end

        $finish;
    end

endmodule

