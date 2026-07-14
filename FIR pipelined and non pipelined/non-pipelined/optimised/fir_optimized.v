
module fir_optimized #(
    parameter N     = 100,         // total taps (must be even)
    parameter HALF  = 50,          // N/2
    parameter WIDTH = 16,          // input / coefficient bit width  (Q2.14)
    parameter OUTW  = 40           // accumulator width
)(
    input  wire                      clk,
    input  wire                      rst,
    input  wire signed [WIDTH-1:0]   x_in,
    output reg  signed [OUTW-1:0]    y_out
);

    // Only HALF coefficients needed (symmetric: h[k] = h[N-1-k])
    // Testbench loads h[0]..h[49] from coeffs_half.txt
    reg signed [WIDTH-1:0] h [0:HALF-1];

    // Full delay line still needed to hold all N past samples
    reg signed [WIDTH-1:0] shift_reg [0:N-1];

    // Internal signals
    reg signed [WIDTH:0]     sym_sum;    // 17-bit: sum of two Q(2,14) values
    reg signed [2*WIDTH:0]   prod;       // 33-bit: 17-bit * 16-bit
    reg signed [OUTW-1:0]    acc;
    integer k;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            y_out <= {OUTW{1'b0}};
            for (k = 0; k < N; k = k+1)
                shift_reg[k] <= {WIDTH{1'b0}};
        end else begin

            // --- Step 1: Shift register update ---
            for (k = N-1; k > 0; k = k-1)
                shift_reg[k] <= shift_reg[k-1];
            shift_reg[0] <= x_in;

            // --- Step 2: Symmetric MAC ---
            // y[n] = sum_{k=0}^{49} h[k] * (shift_reg[k] + shift_reg[99-k])
            acc = {OUTW{1'b0}};
            for (k = 0; k < HALF; k = k+1) begin
                // 1. Add symmetric pair (1-bit wider to avoid overflow)
                sym_sum = shift_reg[k]
                        + shift_reg[N-1-k];
                // 2. Multiply pair-sum by coefficient
                prod    = sym_sum * h[k];
                // 3. Sign-extend and accumulate
                acc     = acc +  prod;
            end
            y_out <= acc;

        end
    end

endmodule
