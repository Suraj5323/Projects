module simple_twiddle_block #(
    parameter WIDTH = 8
)(
    input  signed [WIDTH-1:0] a0_real, a0_img,
    input  signed [WIDTH-1:0] b0_real, b0_img,

    output signed [WIDTH:0] a1_real, a1_img,
    output signed [WIDTH:0] b1_real, b1_img
);

    assign a1_real = a0_real + b0_img;
    assign a1_img  = a0_img  - b0_real;

    assign b1_real = a0_real - b0_img;
    assign b1_img  = a0_img  + b0_real;

endmodule