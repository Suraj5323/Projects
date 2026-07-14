// ============================================================
// tb_fir_genvar.v  -  Testbench for genvar/FFB FIR Filter
//
// Verification flow (professor's notes, Pages 7-8):
//   MATLAB writes: signal1.txt, signal2.txt, signal3.txt (xx.dat)
//   Verilog reads: signal*.txt
//   Verilog writes: output_genvar_s*.txt (yy.dat)
//   MATLAB reads:  output_genvar_s*.txt and plots MSE comparison
//
// Note: genvar form has 1 extra cycle latency vs direct form
//       because FFB.a_out is registered (delay is inside FFB).
//       First valid output appears after N+1 = 101 clock cycles.
//       Testbench captures N=1000 samples after warmup.
// ============================================================

`timescale 1ns/1ps

module tb_fir_genvar;

    // ---- Parameters ----
    parameter N        = 100;
    parameter NSAMPLES = 1000;
    parameter WIDTH    = 16;
    parameter OUTW     = 40;

    // ---- DUT Signals ----
    reg                     clk;
    reg                     rst;
    reg  signed [WIDTH-1:0] x_in;
    wire signed [OUTW-1:0]  y_out;

    // ---- DUT Instantiation ----
    fir_genvar #(
        .N    (N),
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

    integer coeff_mem  [0:N-1];
    integer signal_mem [0:NSAMPLES-1];
    integer fid_r, fid_w, ret, i;

    initial begin
        $display("=== TB_FIR_GENVAR Starting ===");

        // --------------------------------------------------
        // Step 1: Load all 100 coefficients from coeffs.txt
        //         Initialize each FFB instance's coefficient
        // --------------------------------------------------
        fid_r = $fopen("coeffs.txt", "r");
        if (fid_r == 0) begin
            $display("ERROR: Cannot open coeffs.txt"); $finish;
        end
        for (i = 0; i < N; i = i+1) begin
            ret = $fscanf(fid_r, "%d\n", coeff_mem[i]);
            DUT.h[i] = coeff_mem[i];
        end
        $fclose(fid_r);
        $display("Coefficients loaded into DUT.h[0..%0d]", N-1);

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

        fid_w = $fopen("output_genvar_s1.txt", "w");
        for (i = 0; i < NSAMPLES; i = i+1) begin
            x_in = signal_mem[i];
            @(posedge clk); #1;
            $fwrite(fid_w, "%0d\n", $signed(y_out));
        end
        $fclose(fid_w);
        $display("Done: output_genvar_s1.txt");

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

        fid_w = $fopen("output_genvar_s2.txt", "w");
        for (i = 0; i < NSAMPLES; i = i+1) begin
            x_in = signal_mem[i];
            @(posedge clk); #1;
            $fwrite(fid_w, "%0d\n", $signed(y_out));
        end
        $fclose(fid_w);
        $display("Done: output_genvar_s2.txt");

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

        fid_w = $fopen("output_genvar_s3.txt", "w");
        for (i = 0; i < NSAMPLES; i = i+1) begin
            x_in = signal_mem[i];
            @(posedge clk); #1;
            $fwrite(fid_w, "%0d\n", $signed(y_out));
        end
        $fclose(fid_w);
        $display("Done: output_genvar_s3.txt");

        $display("=== TB_FIR_GENVAR Complete ===");
        $finish;
    end

endmodule
