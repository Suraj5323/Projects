// ============================================================
// FIR Filter - Direct Form - PIPELINED
// Taps      : 100
// Data width: 16-bit signed Q(2,14)
// Pipeline  : 2 stages
//   Stage 1 - All 100 multiplications (parallel) -> register
//   Stage 2 - Accumulate all products            -> output
// Latency   : 2 clock cycles
// ============================================================

module fir_direct_pipeline (
    input  wire               clk,
    input  wire               rst,
    input  wire signed [15:0] x_in,
    output reg  signed [31:0] y_out
);

    parameter N = 100;

    // --------------------------------------------------------
    // Coefficients - Q(2,14) format
    // --------------------------------------------------------
    wire signed [15:0] h [0:N-1];
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
    assign h[50] =  16'sd3227; assign h[51] =  16'sd2811;
    assign h[52] =  16'sd2077; assign h[53] =  16'sd1194;
    assign h[54] =  16'sd352;  assign h[55] = -16'sd285;
    assign h[56] = -16'sd625;  assign h[57] = -16'sd661;
    assign h[58] = -16'sd465;  assign h[59] = -16'sd156;
    assign h[60] =  16'sd139;  assign h[61] =  16'sd324;
    assign h[62] =  16'sd360;  assign h[63] =  16'sd263;
    assign h[64] =  16'sd91;   assign h[65] = -16'sd83;
    assign h[66] = -16'sd197;  assign h[67] = -16'sd222;
    assign h[68] = -16'sd164;  assign h[69] = -16'sd57;
    assign h[70] =  16'sd52;   assign h[71] =  16'sd125;
    assign h[72] =  16'sd141;  assign h[73] =  16'sd104;
    assign h[74] =  16'sd36;   assign h[75] = -16'sd33;
    assign h[76] = -16'sd78;   assign h[77] = -16'sd87;
    assign h[78] = -16'sd64;   assign h[79] = -16'sd22;
    assign h[80] =  16'sd20;   assign h[81] =  16'sd47;
    assign h[82] =  16'sd52;   assign h[83] =  16'sd38;
    assign h[84] =  16'sd13;   assign h[85] = -16'sd11;
    assign h[86] = -16'sd26;   assign h[87] = -16'sd29;
    assign h[88] = -16'sd21;   assign h[89] = -16'sd7;
    assign h[90] =  16'sd6;    assign h[91] =  16'sd14;
    assign h[92] =  16'sd15;   assign h[93] =  16'sd11;
    assign h[94] =  16'sd4;    assign h[95] = -16'sd3;
    assign h[96] = -16'sd8;    assign h[97] = -16'sd9;
    assign h[98] = -16'sd7;    assign h[99] = -16'sd3;

    // --------------------------------------------------------
    // Delay line
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
    // PIPELINE STAGE 1: Multiply all taps in parallel -> reg
    // --------------------------------------------------------
    reg signed [31:0] products [0:N-1];

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1)
                products[i] <= 32'sd0;
        end else begin
            for (i = 0; i < N; i = i + 1)
                products[i] <= x_delay[i] * h[i];
        end
    end

    // --------------------------------------------------------
    // PIPELINE STAGE 2: Accumulate registered products
    // --------------------------------------------------------
    reg signed [31:0] acc;

    always @(posedge clk) begin
        if (rst) begin
            acc   <= 32'sd0;
            y_out <= 32'sd0;
        end else begin
            acc = 32'sd0;
            for (i = 0; i < N; i = i + 1)
                acc = acc + products[i];
            y_out <= acc;
        end
    end

endmodule
