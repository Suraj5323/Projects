`timescale 1ns / 1ps

module tb_fir_optimized;

reg clk;
reg rst;
reg signed [15:0] x_in;
wire signed [39:0] y_out;

fir_optimized_pipe uut (
    .clk(clk),
    .rst(rst),
    .x_in(x_in),
    .y_out(y_out)
);

// ─── Clock: 100 MHz ───────────────────────────────────────────────────────────
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// ─── Signal Memory ────────────────────────────────────────────────────────────
reg signed [15:0] x_signal1 [0:999];
reg signed [15:0] x_signal2 [0:999];
reg signed [15:0] x_signal3 [0:999];

integer i, f1, f2, f3, dummy;

// ─── Load all input files (separate initial block) ────────────────────────────
initial begin
    f1 = $fopen("signal_950.txt",  "r");
    f2 = $fopen("signal_1100.txt", "r");
    f3 = $fopen("signal_2000.txt", "r");

    if (f1 == 0) begin $display("ERROR: Cannot open signal_950.txt");  $finish; end
    if (f2 == 0) begin $display("ERROR: Cannot open signal_1100.txt"); $finish; end
    if (f3 == 0) begin $display("ERROR: Cannot open signal_2000.txt"); $finish; end

    for (i = 0; i < 1000; i = i + 1) dummy = $fscanf(f1, "%d", x_signal1[i]);
    for (i = 0; i < 1000; i = i + 1) dummy = $fscanf(f2, "%d", x_signal2[i]);
    for (i = 0; i < 1000; i = i + 1) dummy = $fscanf(f3, "%d", x_signal3[i]);

    $fclose(f1);
    $fclose(f2);
    $fclose(f3);
    $display("INFO: All signal files loaded.");
end

// ─── Main Stimulus ────────────────────────────────────────────────────────────
initial begin

    // FIX 1: Initialise all inputs at time 0
    rst  = 1'b1;
    x_in = 16'sd0;

    // FIX 2: Wait for file-loading initial block to finish
    #1;

    // =========================================================================
    //  RUN 1 — 950 Hz
    // =========================================================================
    f1 = $fopen("verilog_optimized_pipe_s1.txt", "w");
    if (f1 == 0) begin $display("ERROR: Cannot open verilog_optimized_pipe_s1.txt"); $finish; end

    // FIX 3: De-assert reset at negedge — prevents x from race condition
    rst = 1'b1; x_in = 16'sd0;
    repeat(10) @(posedge clk);
    @(negedge clk); rst = 1'b0;

    for (i = 0; i < 1000; i = i + 1) begin
        x_in = x_signal1[i];
        @(posedge clk);
        #1;
        $fwrite(f1, "%d\n", y_out);
    end
        for (i = 0; i < 99; i = i + 1) begin
        x_in = 0;
        @(posedge clk);
        #1;
        $fwrite(f1, "%d\n", y_out);
    end

    $fclose(f1);
    $display("INFO: Run 1 (950 Hz) done.");

    // =========================================================================
    //  RUN 2 — 1100 Hz
    // =========================================================================
    f2 = $fopen("verilog_optimized_pipe_s2.txt", "w");
    if (f2 == 0) begin $display("ERROR: Cannot open verilog_optimized_pipe_s2.txt"); $finish; end

    rst = 1'b1; x_in = 16'sd0;
    repeat(10) @(posedge clk);
    @(negedge clk); rst = 1'b0;

    for (i = 0; i < 1000; i = i + 1) begin
        x_in = x_signal2[i];
        @(posedge clk);
        #1;
        $fwrite(f2, "%d\n", y_out);
    end
    for (i = 0; i < 99; i = i + 1) begin
        x_in = 0;
        @(posedge clk);
        #1;
        $fwrite(f2, "%d\n", y_out);
    end
    $fclose(f2);
    $display("INFO: Run 2 (1100 Hz) done.");

    // =========================================================================
    //  RUN 3 — 2000 Hz
    // =========================================================================
    f3 = $fopen("verilog_optimized_pipe_s3.txt", "w");
    if (f3 == 0) begin $display("ERROR: Cannot open verilog_optimized_pipe_s3.txt"); $finish; end

    rst = 1'b1; x_in = 16'sd0;
    repeat(10) @(posedge clk);
    @(negedge clk); rst = 1'b0;

    for (i = 0; i < 1000; i = i + 1) begin
        x_in = x_signal3[i];
        @(posedge clk);
        #1;
        $fwrite(f3, "%d\n", y_out);
    end
    for (i = 0; i < 99; i = i + 1) begin
        x_in = 0;
        @(posedge clk);
        #1;
        $fwrite(f1, "%d\n", y_out);
    end
    $fclose(f3);
    $display("INFO: Run 3 (2000 Hz) done.");

    $display("TB_FIR_OPTIMIZED: All done.");
    $finish;
end

endmodule