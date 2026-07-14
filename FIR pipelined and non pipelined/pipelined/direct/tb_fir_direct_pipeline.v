// ============================================================
// Testbench: fir_direct_pipeline
// Tests with impulse input → output should match h[] values
// ============================================================

`timescale 1ns/1ps

module tb_fir_direct_pipeline;

    reg         clk = 0;
    reg         rst = 1;
    reg  signed [15:0] x_in = 0;
    wire signed [31:0] y_out;

    // Instantiate DUT
    fir_direct_pipeline uut (
        .clk   (clk),
        .rst   (rst),
        .x_in  (x_in),
        .y_out (y_out)
    );

    // 10 ns clock period (100 MHz)
    always #5 clk = ~clk;

    // File handles
    integer fin_950, fin_1100, fin_2000;
    integer fout_950, fout_1100, fout_2000;
    integer sample;
    integer scan_ret;

    initial begin
        // ---- Reset ----
        rst = 1;
        repeat(5) @(posedge clk);
        rst = 0;

        // ============================================================
        // TEST 1: Impulse response
        // Feed x = 1 then zeros. Output should be coefficients h[].
        // ============================================================
        $display("=== Impulse Response Test ===");
        @(posedge clk);
        x_in = 16'sd16384; // Q(2,14) representation of 1.0
        @(posedge clk);
        x_in = 16'sd0;

        repeat(110) @(posedge clk);

        // ============================================================
        // TEST 2: Process 3 sinewaves from files
        // Files must be in same directory as simulation
        // ============================================================
        fin_950 = $fopen("C:/Users/kollu/dspquartus/ass5/signal_950.txt", "r");
        fin_1100 = $fopen("C:/Users/kollu/dspquartus/ass5/signal_1100.txt", "r");
        fin_2000 = $fopen("C:/Users/kollu/dspquartus/ass5/signal_2000.txt", "r");
        fout_950  = $fopen("vout_direct_950.txt",  "w");
        fout_1100 = $fopen("vout_direct_1100.txt", "w");
        fout_2000 = $fopen("vout_direct_2000.txt", "w");

        // Reset before each signal
        rst = 1; repeat(5) @(posedge clk); rst = 0;

        // -- 950 Hz signal --
        $display("Processing 950 Hz signal...");
        while (!$feof(fin_950)) begin
            scan_ret = $fscanf(fin_950, "%d\n", sample);
            x_in = sample[15:0];
            @(posedge clk);
            $fdisplay(fout_950, "%0d", $signed(y_out));
        end

        // Reset between signals
        rst = 1; repeat(5) @(posedge clk); rst = 0;

        // -- 1100 Hz signal --
        $display("Processing 1100 Hz signal...");
        while (!$feof(fin_1100)) begin
            scan_ret = $fscanf(fin_1100, "%d\n", sample);
            x_in = sample[15:0];
            @(posedge clk);
            $fdisplay(fout_1100, "%0d", $signed(y_out));
        end

        // Reset between signals
        rst = 1; repeat(5) @(posedge clk); rst = 0;

        // -- 2000 Hz signal --
        $display("Processing 2000 Hz signal...");
        while (!$feof(fin_2000)) begin
            scan_ret = $fscanf(fin_2000, "%d\n", sample);
            x_in = sample[15:0];
            @(posedge clk);
            $fdisplay(fout_2000, "%0d", $signed(y_out));
        end

        $fclose(fin_950);  $fclose(fin_1100);  $fclose(fin_2000);
        $fclose(fout_950); $fclose(fout_1100); $fclose(fout_2000);

        $display("Simulation complete. Output files written.");
        $finish;
    end

    // Monitor key output values
    initial begin
        $monitor("Time=%0t | x_in=%0d | y_out=%0d", $time, x_in, y_out);
    end

endmodule
