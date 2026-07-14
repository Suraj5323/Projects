module clock_24_12_date (
    input wire clk,          // 1Hz clock
    input wire reset,        // Synchronous reset
    input wire mode,         // 1 = 24-hour, 0 = 12-hour
    input wire start_timer,  // Start the countdown

    // Alarm inputs
    input wire [7:0] alarm_hour,
    input wire [7:0] alarm_min,
    input wire [7:0] alarm_sec,
    input wire alarm_enable,

    // Time setting inputs
    input wire [7:0] set_hours,
    input wire [7:0] set_min,
    input wire [7:0] set_sec,
    input wire set_time, // High to set the time

    // Outputs
    output reg [7:0] hours_out = 0,
    output reg [7:0] min = 0,
    output reg [7:0] sec = 0,
    output reg am_pm = 0,
    output reg [7:0] day = 1,
    output reg [7:0] month = 1,
    output reg [7:0] year = 20,

    output reg [7:0] cd_min = 10,
    output reg [7:0] cd_sec = 0,
    output reg buzzer = 0,
    output reg alarm_buzzer = 0
);

    reg [7:0] hours = 0;
    reg timer_running = 0;
    reg alarm_pulse = 0;
    reg start_timer_prev = 0;
    reg buzzer_pulse = 0;

    // Helper function: Get number of days in month
    function [7:0] days_in_month;
        input [7:0] m;
        input [7:0] y;
        begin
            case (m)
                1,3,5,7,8,10,12: days_in_month = 31;
                4,6,9,11:        days_in_month = 30;
                2: days_in_month = (y % 4 == 0) ? 29 : 28;
                default: days_in_month = 31;
            endcase
        end
    endfunction

    always @(posedge clk) begin
        // Track start_timer edge
        start_timer_prev <= start_timer;

        if (reset) begin
            sec   <= 0;
            min   <= 0;
            hours <= 0;
            day   <= 1;
            month <= 1;
            year  <= 20;
            cd_min <= 10;
            cd_sec <= 50;
            timer_running <= 0;
            buzzer <= 0;
            alarm_buzzer <= 0;
            alarm_pulse <= 0;
            buzzer_pulse <= 0;

        end else if (set_time) begin
            sec   <= set_sec;
            min   <= set_min;
            hours <= set_hours;

        end else begin
            // Clock increment
            if (sec == 59) begin
                sec <= 0;
                if (min == 59) begin
                    min <= 0;
                    if (hours == 23) begin
                        hours <= 0;
                        if (day == days_in_month(month, year)) begin
                            day <= 1;
                            if (month == 12) begin
                                month <= 1;
                                year <= year + 1;
                            end else begin
                                month <= month + 1;
                            end
                        end else begin
                            day <= day + 1;
                        end
                    end else begin
                        hours <= hours + 1;
                    end
                end else begin
                    min <= min + 1;
                end
            end else begin
                sec <= sec + 1;
            end

            // Countdown logic with edge detection
            if (start_timer && !start_timer_prev) begin
                if (!timer_running && cd_min <= 10) begin
                    timer_running <= 1;
                    buzzer <= 0;
                    buzzer_pulse <= 0;
                end
            end

            if (timer_running) begin
                if (cd_min == 0 && cd_sec == 0) begin
                    if (!buzzer_pulse) begin
                        buzzer <= 1;
                        buzzer_pulse <= 1;
                    end else begin
                        buzzer <= 0;
                        buzzer_pulse <= 0;
                        timer_running <= 0;
                    end
                end else begin
                    if (cd_sec == 0) begin
                        cd_sec <= 59;
                        cd_min <= cd_min - 1;
                    end else begin
                        cd_sec <= cd_sec - 1;
                    end
                end
            end else begin
                buzzer <= 0;
            end

            // Alarm logic with 1-second pulse
            if (alarm_enable) begin
                if (hours == alarm_hour && min == alarm_min && sec == alarm_sec && !alarm_pulse) begin
                    alarm_buzzer <= 1;
                    alarm_pulse <= 1;
                end else begin
                    alarm_buzzer <= 0;
                end
            end else begin
                alarm_buzzer <= 0;
                alarm_pulse <= 0;
            end

            // Clear alarm_pulse when time moves forward
            if (alarm_pulse && (hours != alarm_hour || min != alarm_min || sec != alarm_sec)) begin
                alarm_pulse <= 0;
            end
        end
    end

    // Format for 12/24 hour output
    always @(*) begin
        if (mode) begin  // 24-hour
            hours_out = hours;
            am_pm = 0;
        end else begin  // 12-hour
            if (hours == 0) begin
                hours_out = 12;
                am_pm = 0;
            end else if (hours < 12) begin
                hours_out = hours;
                am_pm = 0;
            end else if (hours == 12) begin
                hours_out = 12;
                am_pm = 1;
            end else begin
                hours_out = hours - 12;
                am_pm = 1;
            end
        end
    end

endmodule

