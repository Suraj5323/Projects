
module FFB #(
    parameter WIDTH = 16,
    parameter OUTW  = 40
)(
    input  wire                    clk,
    input  wire                    rst,
    input  wire signed [WIDTH-1:0] a_in,   // signal input
    input  wire signed [OUTW-1:0]  b_in,   // accumulator input
    input  wire signed [WIDTH-1:0] h_i,    // coefficient for this tap
    output reg  signed [WIDTH-1:0] a_out,  // registered signal (delay)
    output wire signed [OUTW-1:0]  b_out   // combinational accumulator out
);

    // Internal product: 32-bit signed
    wire signed [2*WIDTH:0] prod;
    assign prod  = a_in * h_i;

    // b_out: combinational - accumulate product into running sum
   
    assign b_out = b_in +  prod;

    // a_out: registered - creates the delay element (D flip-flop)
    always @(posedge clk or posedge rst) begin
        if (rst) a_out <= {WIDTH{1'b0}};
        else     a_out <= a_in;
    end

endmodule


// ============================================================
// fir_genvar - Top-Level FIR using generate/genvar
// ============================================================
module fir_genvar #(
    parameter N     = 100,
    parameter WIDTH = 16,
    parameter OUTW  = 40
)(
    input  wire                     clk,
    input  wire                     rst,
    input  wire signed [WIDTH-1:0]  x_in,
    output reg  signed [OUTW-1:0]   y_out
);

    // Coefficient memory (loaded by testbench via DUT.h[i])
    reg signed [WIDTH-1:0] h [0:N-1];

    // Signal chain: a_chain[0]=x_in, a_chain[1..N] = delayed versions
    wire signed [WIDTH-1:0] a_chain [0:N];
    // Accumulator chain: b_chain[0]=0, b_chain[N]=final sum
    wire signed [OUTW-1:0]  b_chain [0:N];

    // Feed input into the chain
    assign a_chain[0] = x_in;
    assign b_chain[0] = {OUTW{1'b0}};

    // ---- generate / genvar: instantiate N FFB blocks ----
    genvar i;
    generate
        for (i = 0; i < N; i = i+1) begin : tap_gen
            FFB #(
                .WIDTH(WIDTH),
                .OUTW (OUTW)
            ) ffb_inst (
                .clk  (clk),
                .rst  (rst),
                .a_in (a_chain[i]),      // current delayed signal
                .b_in (b_chain[i]),      // running accumulator
                .h_i  (h[i]),            // tap coefficient
                .a_out(a_chain[i+1]),    // pass delayed signal to next FFB
                .b_out(b_chain[i+1])     // pass updated accumulator to next FFB
            );
        end
    endgenerate

    // Register final accumulator output
    always @(posedge clk or posedge rst) begin
        if (rst) y_out <= {OUTW{1'b0}};
        else     y_out <= b_chain[N];
    end

endmodule
