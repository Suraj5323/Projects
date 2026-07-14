// ============================================================
// Testbench: fir_genvar_pipeline
// NOTE: Genvar (systolic) pipeline has latency of N=100 cycles
//       so output appears 100 cycles after input
// ============================================================

`timescale 1ns/1ps

module tb_fir_genvar_pipeline;

    reg         clk = 0;
    reg         rst = 1;
    reg  signed [15:0] x_in = 0;
    wire signed [31:0] y_out;

    fir_genvar_pipeline uut (
        .clk   (clk),
        .rst   (rst),
        .x_in  (x_in),
        .y_out (y_out)
    );

    always #5 clk = ~clk;

    integer fin_950, fin_1100, fin_2000;
    integer fout_950, fout_1100, fout_2000;
    integer sample;
    integer scan_ret;

    initial begin
        rst = 1;
        repeat(5) @(posedge clk);
        rst = 0;

        // Impulse test - need extra cycles for pipeline to drain (N=100)
        $display("=== Impulse Response Test (Genvar Systolic Pipeline) ===");
        $display("Note: Pipeline latency = 100 cycles");
        @(posedge clk); x_in = 16'sd16384;
        @(posedge clk); x_in = 16'sd0;
        repeat(210) @(posedge clk);  // extra 100 for pipeline drain

        // Signal files
        fin_950   = $fopen("signal_950.txt",  "r");
        fin_1100  = $fopen("signal_1100.txt", "r");
        fin_2000  = $fopen("signal_2000.txt", "r");
        fout_950  = $fopen("vout_genvar_950.txt",  "w");
        fout_1100 = $fopen("vout_genvar_1100.txt", "w");
        fout_2000 = $fopen("vout_genvar_2000.txt", "w");

        // 950 Hz
        rst = 1; repeat(5) @(posedge clk); rst = 0;
        while (!$feof(fin_950)) begin
            scan_ret = $fscanf(fin_950, "%d\n", sample);
            x_in = sample[15:0];
            @(posedge clk);
            $fdisplay(fout_950, "%0d", $signed(y_out));
        end
        // Drain remaining pipeline samples
        x_in = 16'sd0;
        repeat(105) begin
            @(posedge clk);
            $fdisplay(fout_950, "%0d", $signed(y_out));
        end

        // 1100 Hz
        rst = 1; repeat(5) @(posedge clk); rst = 0;
        while (!$feof(fin_1100)) begin
            scan_ret = $fscanf(fin_1100, "%d\n", sample);
            x_in = sample[15:0];
            @(posedge clk);
            $fdisplay(fout_1100, "%0d", $signed(y_out));
        end
        x_in = 16'sd0;
        repeat(105) begin
            @(posedge clk);
            $fdisplay(fout_1100, "%0d", $signed(y_out));
        end

        // 2000 Hz
        rst = 1; repeat(5) @(posedge clk); rst = 0;
        while (!$feof(fin_2000)) begin
            scan_ret = $fscanf(fin_2000, "%d\n", sample);
            x_in = sample[15:0];
            @(posedge clk);
            $fdisplay(fout_2000, "%0d", $signed(y_out));
        end
        x_in = 16'sd0;
        repeat(105) begin
            @(posedge clk);
            $fdisplay(fout_2000, "%0d", $signed(y_out));
        end

        $fclose(fin_950);  $fclose(fin_1100);  $fclose(fin_2000);
        $fclose(fout_950); $fclose(fout_1100); $fclose(fout_2000);

        $display("Simulation complete.");
        $finish;
    end

endmodule
