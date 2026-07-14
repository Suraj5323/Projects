
`timescale 1ns/1ps

module tb_fir_direct;

    // ---- Parameters ----
    parameter N        = 100;
    parameter NSAMPLES = 1000;
    parameter WIDTH    = 16;
    parameter OUTW     = 40;

    // ---- DUT Signals ----
    reg                    clk;
    reg                    rst;
    reg  signed [WIDTH-1:0] x_in;
    wire signed [OUTW-1:0]  y_out;

    // ---- DUT Instantiation ----
    fir_direct #(
        .N    (N),
        .WIDTH(WIDTH),
        .OUTW (OUTW)
    ) DUT (
        .clk  (clk),
        .rst  (rst),
        .x_in (x_in),
        .y_out(y_out)
    );

    // ---- Clock Generation: 10ns period (100 MHz) ----
    initial clk = 0;
    always  #5 clk = ~clk;

    // ---- Memory for file data ----
    integer coeff_mem  [0:N-1];
    integer signal_mem [0:NSAMPLES-1];

    integer fid_r, fid_w, ret, i, s;

    // ---- Main Stimulus ----
    initial begin
        $display("=== TB_FIR_DIRECT Starting ===");

        // --------------------------------------------------
        // Step 1: Load filter coefficients from coeffs.txt
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
        $display("Coefficients loaded: %0d taps", N);

        // --------------------------------------------------
        // Step 2: Process each of the 3 input signals
        // --------------------------------------------------

        // ---- Signal 1: 950 Hz ----
        s = 1;
        fid_r = $fopen("signal1.txt", "r");
        if (fid_r == 0) begin $display("ERROR: Cannot open signal1.txt"); $finish; end
        for (i = 0; i < NSAMPLES; i = i+1)
            ret = $fscanf(fid_r, "%d\n", signal_mem[i]);
        $fclose(fid_r);

        rst = 1; x_in = 0;
        repeat(3) @(posedge clk); #1;
        rst = 0;

        fid_w = $fopen("output_direct_s1.txt", "w");
        for (i = 0; i < NSAMPLES; i = i+1) begin
            x_in = signal_mem[i];
            @(posedge clk); #1;
            $fwrite(fid_w, "%0d\n", $signed(y_out));
        end
        $fclose(fid_w);
        $display("Done: output_direct_s1.txt");

        // ---- Signal 2: 1100 Hz ----
        fid_r = $fopen("signal2.txt", "r");
        if (fid_r == 0) begin $display("ERROR: Cannot open signal2.txt"); $finish; end
        for (i = 0; i < NSAMPLES; i = i+1)
            ret = $fscanf(fid_r, "%d\n", signal_mem[i]);
        $fclose(fid_r);

        rst = 1; x_in = 0;
        repeat(3) @(posedge clk); #1;
        rst = 0;

        fid_w = $fopen("output_direct_s2.txt", "w");
        for (i = 0; i < NSAMPLES; i = i+1) begin
            x_in = signal_mem[i];
            @(posedge clk); #1;
            $fwrite(fid_w, "%0d\n", $signed(y_out));
        end
        $fclose(fid_w);
        $display("Done: output_direct_s2.txt");

        // ---- Signal 3: 2000 Hz ----
        fid_r = $fopen("signal3.txt", "r");
        if (fid_r == 0) begin $display("ERROR: Cannot open signal3.txt"); $finish; end
        for (i = 0; i < NSAMPLES; i = i+1)
            ret = $fscanf(fid_r, "%d\n", signal_mem[i]);
        $fclose(fid_r);

        rst = 1; x_in = 0;
        repeat(3) @(posedge clk); #1;
        rst = 0;

        fid_w = $fopen("output_direct_s3.txt", "w");
        for (i = 0; i < NSAMPLES; i = i+1) begin
            x_in = signal_mem[i];
            @(posedge clk); #1;
            $fwrite(fid_w, "%0d\n", $signed(y_out));
        end
        $fclose(fid_w);
        $display("Done: output_direct_s3.txt");

        $display("=== TB_FIR_DIRECT Complete ===");
        $finish;
    end

endmodule
