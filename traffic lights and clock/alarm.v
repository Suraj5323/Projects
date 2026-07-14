`timescale 1s / 1ms

module clock_24_12_date_tb();

    reg clk = 0;
    reg reset = 1;
    reg mode = 1; // 24-hour mode
    reg start_timer = 0;
    reg [7:0] alarm_hour = 17;
    reg [7:0] alarm_min = 30;
    reg [7:0] alarm_sec = 0;
    reg alarm_enable = 0;
    reg [7:0] set_hours = 6;
    reg [7:0] set_min = 29;
    reg [7:0] set_sec = 58;
    reg set_time = 0;

    wire [7:0] hours_out;
    wire [7:0] min;
    wire [7:0] sec;
    wire am_pm;
    wire [7:0] day, month, year;
    wire [7:0] cd_min, cd_sec;
    wire buzzer, alarm_buzzer;

    clock_24_12_date uut (
        .clk(clk),
        .reset(reset),
        .mode(mode),
        .start_timer(start_timer),
        .alarm_hour(alarm_hour),
        .alarm_min(alarm_min),
        .alarm_sec(alarm_sec),
        .alarm_enable(alarm_enable),
        .set_hours(set_hours),
        .set_min(set_min),
        .set_sec(set_sec),
        .set_time(set_time),
        .hours_out(hours_out),
        .min(min),
        .sec(sec),
        .am_pm(am_pm),
        .day(day),
        .month(month),
        .year(year),
        .cd_min(cd_min),
        .cd_sec(cd_sec),
        .buzzer(buzzer),
        .alarm_buzzer(alarm_buzzer)
    );

    // Clock generation: 1Hz
    always #0.5 clk = ~clk;

    initial begin
        // === GTKWave dump setup ===
        $dumpfile("alarm.vcd");
        $dumpvars(0, clock_24_12_date_tb);

        $display("=== Starting Alarm Pulse Test ===");

        #1;
        reset = 0;

        // Set initial time to 06:29:58
        set_time = 1;
        #1;
        set_time = 0;

        // Enable the alarm
        alarm_enable = 1;

        // Wait for alarm to trigger
        wait (alarm_buzzer == 1);
        $display("Alarm triggered at %0d:%0d:%0d", hours_out, min, sec);

        #1;
        if (alarm_buzzer == 0)
            $display("Alarm correctly deactivated after 1 second ✅");

        // End simulation
        #2;
        $finish;
    end

    // Time monitor
    always @(posedge clk) begin
        $display("Time = %0d:%0d:%0d | Alarm Buzzer = %b", hours_out, min, sec, alarm_buzzer);
    end

endmodule