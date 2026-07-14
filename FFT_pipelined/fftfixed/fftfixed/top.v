
module top #(
    parameter WIDTH1 = 8,   
    parameter WIDTH2 = 11   
)(
    input  clk,
    input  reset,

    input  [WIDTH1-1:0] serial_in_real,   
    input  [WIDTH1-1:0] serial_in_imag,   
    input  in_valid,

    output [WIDTH2-1:0] serial_out_real,  
    output [WIDTH2-1:0] serial_out_imag   
);

    // S2P outputs
    wire [8*WIDTH1-1:0] parallel_real;
    wire [8*WIDTH1-1:0] parallel_imag;
    wire s2p_valid;

    // FFT outputs
    wire signed [8*WIDTH2-1:0] fft_out_real;
    wire signed [8*WIDTH2-1:0] fft_out_imag;
    wire fft_valid;

    // --------------------------------------------------
    //  S2P  (8 × sQ5.2 serial → 64-bit parallel bus)
    // --------------------------------------------------
    s2p #(WIDTH1) u_s2p (
        .clk             (clk),
        .reset           (reset),
        .serial_in_real  (serial_in_real),
        .serial_in_imag  (serial_in_imag),
        .in_valid        (in_valid),
        .parallel_out_real(parallel_real),
        .parallel_out_imag(parallel_imag),
        .out_valid       (s2p_valid)
    );

    // --------------------------------------------------
    //  FFT Core  (sQ5.2 in → sQ8.2 out, 3-cycle latency)
    // --------------------------------------------------
    fft_core u_fft (
        .clk       (clk),
        .reset     (reset),
        .in_real   (parallel_real),
        .in_img    (parallel_imag),
        .in_valid  (s2p_valid),
        .out_real  (fft_out_real),
        .out_img   (fft_out_imag),
        .out_valid (fft_valid)
    );

    // --------------------------------------------------
    //  P2S  (88-bit parallel → 8 × sQ8.2 serial)
    // --------------------------------------------------
    p2s #(WIDTH2) u_p2s (
        .clk             (clk),
        .reset           (reset),
        .parallel_in_real(fft_out_real),
        .parallel_in_imag(fft_out_imag),
        .in_valid        (fft_valid),
        .serial_out_real (serial_out_real),
        .serial_out_imag (serial_out_imag)
    );

endmodule
