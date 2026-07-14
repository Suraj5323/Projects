
module fir_direct #(
    parameter N     = 100,          // number of taps
    parameter WIDTH = 16,           // input / coefficient bit width
    parameter OUTW  = 40            // accumulator width (prevents overflow)
)(
    input  wire                      clk,
    input  wire                      rst,
    input  wire signed [WIDTH-1:0]   x_in,
    output reg  signed [OUTW-1:0]    y_out
);

    // ---- Coefficient memory (loaded by testbench) ----
    reg signed [WIDTH-1:0] h [0:N-1];

    // ---- Delay line (shift register) ----
    reg signed [WIDTH-1:0] shift_reg [0:N-1];

    // ---- Internal computation signals ----
    reg signed [OUTW-1:0]      acc;
    reg signed [2*WIDTH:0]   prod;
    integer k;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            y_out <= {OUTW{1'b0}};
            for (k = 0; k < N; k = k+1)
                shift_reg[k] <= {WIDTH{1'b0}};
        end else begin

            // --- Step 1: Update shift register ---
            // Shift all samples one position right
            for (k = N-1; k > 0; k = k-1)
                shift_reg[k] <= shift_reg[k-1];
            shift_reg[0] <= x_in;      // Insert new sample at position 0

            // --- Step 2: Multiply-Accumulate (MAC) ---
            // Compute y[n] = sum of h[k] * shift_reg[k]
            acc = {OUTW{1'b0}};
            for (k = 0; k < N; k = k+1) begin
                prod = shift_reg[k] * h[k];
                
                acc  = acc +  prod;
            end
            y_out <= acc;

        end
    end

endmodule
