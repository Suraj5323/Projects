// ============================================================
// tb_fir_optimized.v  -  Testbench for Optimized FIR Filter
//
// Note: Optimized form uses only HALF (50) coefficients
//       Reads from coeffs_half.txt (first 50 values)
//       Output scaling same as direct form: divide by 2^28 in MATLAB
// ============================================================

`timescale 1ns/1ps

module tb_fir_optimized;

    // ---- Parameters ----
    parameter N        = 100;
    parameter HALF     = 50;
    parameter NSAMPLES = 1000;
    parameter WIDTH    = 16;
    parameter OUTW     = 40;

    // ---- DUT Signals ----
    reg                     clk;
    reg                     rst;
    reg  signed [WIDTH-1:0] x_in;
    wire signed [OUTW-1:0]  y_out;

    // ---- DUT Instantiation ----
    fir_optimized #(
        .N    (N),
        .HALF (HALF),
        .WIDTH(WIDTH),
        .OUTW (OUTW)
    ) DUT (
        .clk  (clk),
        .rst  (rst),
        .x_in (x_in),
        .y_out(y_out)
    );

    // ---- Clock: 10ns period ----
    initial clk = 0;
    always  #5 clk = ~clk;

    integer coeff_mem  [0:HALF-1];
    integer signal_mem [0:NSAMPLES-1];
    integer fid_r, fid_w, ret, i;

    initial begin
        $display("=== TB_FIR_OPTIMIZED Starting ===");

        // --------------------------------------------------
        // Load HALF coefficients from coeffs_half.txt
        // (Only h[0]..h[49] since h[k] = h[99-k])
        // --------------------------------------------------
        fid_r = $fopen("coeffs_half.txt", "r");
        if (fid_r == 0) begin
            $display("ERROR: Cannot open coeffs_half.txt"); $finish;
        end
        for (i = 0; i < HALF; i = i+1) begin
            ret = $fscanf(fid_r, "%d\n", coeff_mem[i]);
            DUT.h[i] = coeff_mem[i];
        end
        $fclose(fid_r);
        $display("Half-coefficients loaded: %0d values", HALF);

        // --------------------------------------------------
        // Signal 1: 950 Hz
        // --------------------------------------------------
        fid_r = $fopen("signal1.txt", "r");
        if (fid_r == 0) begin $display("ERROR: Cannot open signal1.txt"); $finish; end
        for (i = 0; i < NSAMPLES; i = i+1)
            ret = $fscanf(fid_r, "%d\n", signal_mem[i]);
        $fclose(fid_r);

        rst = 1; x_in = 0;
        repeat(3) @(posedge clk); #1;
        rst = 0;

        fid_w = $fopen("output_optimized_s1.txt", "w");
        for (i = 0; i < NSAMPLES; i = i+1) begin
            x_in = signal_mem[i];
            @(posedge clk); #1;
            $fwrite(fid_w, "%0d\n", $signed(y_out));
        end
        $fclose(fid_w);
        $display("Done: output_optimized_s1.txt");

        // --------------------------------------------------
        // Signal 2: 1100 Hz
        // --------------------------------------------------
        fid_r = $fopen("signal2.txt", "r");
        if (fid_r == 0) begin $display("ERROR: Cannot open signal2.txt"); $finish; end
        for (i = 0; i < NSAMPLES; i = i+1)
            ret = $fscanf(fid_r, "%d\n", signal_mem[i]);
        $fclose(fid_r);

        rst = 1; x_in = 0;
        repeat(3) @(posedge clk); #1;
        rst = 0;

        fid_w = $fopen("output_optimized_s2.txt", "w");
        for (i = 0; i < NSAMPLES; i = i+1) begin
            x_in = signal_mem[i];
            @(posedge clk); #1;
            $fwrite(fid_w, "%0d\n", $signed(y_out));
        end
        $fclose(fid_w);
        $display("Done: output_optimized_s2.txt");

        // --------------------------------------------------
        // Signal 3: 2000 Hz
        // --------------------------------------------------
        fid_r = $fopen("signal3.txt", "r");
        if (fid_r == 0) begin $display("ERROR: Cannot open signal3.txt"); $finish; end
        for (i = 0; i < NSAMPLES; i = i+1)
            ret = $fscanf(fid_r, "%d\n", signal_mem[i]);
        $fclose(fid_r);

        rst = 1; x_in = 0;
        repeat(3) @(posedge clk); #1;
        rst = 0;

        fid_w = $fopen("output_optimized_s3.txt", "w");
        for (i = 0; i < NSAMPLES; i = i+1) begin
            x_in = signal_mem[i];
            @(posedge clk); #1;
            $fwrite(fid_w, "%0d\n", $signed(y_out));
        end
        $fclose(fid_w);
        $display("Done: output_optimized_s3.txt");

        $display("=== TB_FIR_OPTIMIZED Complete ===");
        $finish;
    end

endmodule
