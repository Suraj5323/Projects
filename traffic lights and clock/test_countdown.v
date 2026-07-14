`timescale 1s / 1ms

module tb_countdown_timer;

    // Declarations must be inside the module
    reg clk;
    reg reset;
    reg mode;
    reg start_timer;

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

    integer counter;
    reg done;

    // Instantiate your design
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

    // Clock generation: 1Hz clock
    always #0.5 clk = ~clk;

    initial begin
        // Initialization
        clk = 0;
        reset = 1;
        mode = 1;
        start_timer = 0;
        done = 0;
        counter = 0;

        $dumpfile("countdown_timer.vcd");
        $dumpvars(0, tb_countdown_timer);

        #2;
        reset = 0;
        start_timer = 1;
        #1;
        start_timer = 0;

        // Wait until buzzer goes high or timeout
        while (!done) begin
            #1;
            counter = counter + 1;

            if (buzzer) begin
                $display("Buzzer activated at countdown 00:00 at time = %0d s", counter);
                done = 1;
            end else if (counter > 620) begin
                $display(" Timeout: Buzzer not triggered within 620 seconds.");
                done = 1;
            end
        end

        $finish;
    end

endmodule

