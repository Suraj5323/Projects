// ============================================================
// FIR Filter - Optimized (Symmetric) Form - PIPELINED
// Taps      : 100
// Data width: 16-bit signed Q(2,14)
//
// Uses symmetry: h[k] = h[99-k]
// -> 50 additions + 50 multiplications instead of 100
//
// Pipeline stages:
//   Stage 1 - Add symmetric pairs  -> register
//   Stage 2 - Multiply by coeff    -> register
//   Stage 3 - Accumulate products  -> output
// Latency: 3 clock cycles
// ============================================================

module fir_optimized_pipeline (
    input  wire               clk,
    input  wire               rst,
    input  wire signed [15:0] x_in,
    output reg  signed [31:0] y_out
);

    parameter N    = 100;
    parameter HALF = 50;

    // --------------------------------------------------------
    // Coefficients - first half only (h[0]..h[49])
    // --------------------------------------------------------
    wire signed [15:0] h [0:HALF-1];
    assign h[0]  = -16'sd3;    assign h[1]  = -16'sd7;
    assign h[2]  = -16'sd9;    assign h[3]  = -16'sd8;
    assign h[4]  = -16'sd3;    assign h[5]  =  16'sd4;
    assign h[6]  =  16'sd11;   assign h[7]  =  16'sd15;
    assign h[8]  =  16'sd14;   assign h[9]  =  16'sd6;
    assign h[10] = -16'sd7;    assign h[11] = -16'sd21;
    assign h[12] = -16'sd29;   assign h[13] = -16'sd26;
    assign h[14] = -16'sd11;   assign h[15] =  16'sd13;
    assign h[16] =  16'sd38;   assign h[17] =  16'sd52;
    assign h[18] =  16'sd47;   assign h[19] =  16'sd20;
    assign h[20] = -16'sd22;   assign h[21] = -16'sd64;
    assign h[22] = -16'sd87;   assign h[23] = -16'sd78;
    assign h[24] = -16'sd33;   assign h[25] =  16'sd36;
    assign h[26] =  16'sd104;  assign h[27] =  16'sd141;
    assign h[28] =  16'sd125;  assign h[29] =  16'sd52;
    assign h[30] = -16'sd57;   assign h[31] = -16'sd164;
    assign h[32] = -16'sd222;  assign h[33] = -16'sd197;
    assign h[34] = -16'sd83;   assign h[35] =  16'sd91;
    assign h[36] =  16'sd263;  assign h[37] =  16'sd360;
    assign h[38] =  16'sd324;  assign h[39] =  16'sd139;
    assign h[40] = -16'sd156;  assign h[41] = -16'sd465;
    assign h[42] = -16'sd661;  assign h[43] = -16'sd625;
    assign h[44] = -16'sd285;  assign h[45] =  16'sd352;
    assign h[46] =  16'sd1194; assign h[47] =  16'sd2077;
    assign h[48] =  16'sd2811; assign h[49] =  16'sd3227;

    // --------------------------------------------------------
    // Delay line - full N samples needed
    // --------------------------------------------------------
    reg signed [15:0] x_delay [0:N-1];
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1)
                x_delay[i] <= 16'sd0;
        end else begin
            x_delay[0] <= x_in;
            for (i = 1; i < N; i = i + 1)
                x_delay[i] <= x_delay[i-1];
        end
    end

    // --------------------------------------------------------
    // PIPELINE STAGE 1: Add symmetric pairs
    // x_delay[k] + x_delay[99-k]
    // 17-bit to avoid overflow on addition
    // --------------------------------------------------------
    reg signed [16:0] sym_sum [0:HALF-1];

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < HALF; i = i + 1)
                sym_sum[i] <= 17'sd0;
        end else begin
            for (i = 0; i < HALF; i = i + 1)
                sym_sum[i] <= x_delay[i] + x_delay[N-1-i];
        end
    end

    // --------------------------------------------------------
    // PIPELINE STAGE 2: Multiply each sum by its coefficient
    // --------------------------------------------------------
    reg signed [31:0] products [0:HALF-1];

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < HALF; i = i + 1)
                products[i] <= 32'sd0;
        end else begin
            for (i = 0; i < HALF; i = i + 1)
                products[i] <= sym_sum[i] * h[i];
        end
    end

    // --------------------------------------------------------
    // PIPELINE STAGE 3: Accumulate all products
    // --------------------------------------------------------
    reg signed [31:0] acc;

    always @(posedge clk) begin
        if (rst) begin
            acc   <= 32'sd0;
            y_out <= 32'sd0;
        end else begin
            acc = 32'sd0;
            for (i = 0; i < HALF; i = i + 1)
                acc = acc + products[i];
            y_out <= acc;
        end
    end

endmodule
