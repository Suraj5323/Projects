

module complex_twiddle_block #(
    parameter WIDTH = 8
)(
    input  signed [WIDTH-1:0] a_real, a_img,
    input  signed [WIDTH-1:0] b_real, b_img,
    input  op,                              // 0 → W8^1 ,  1 → W8^3

    output signed [WIDTH:0] y0_real, y0_img,  // WIDTH+1 bits  sQ(WIDTH-2,2)
    output signed [WIDTH:0] y1_real, y1_img
);


    wire signed [WIDTH:0] a_real_ext = a_real;
    wire signed [WIDTH:0] a_img_ext  = a_img;
    wire signed [WIDTH:0] b_real_ext = b_real;
    wire signed [WIDTH:0] b_img_ext  = b_img;


  
    wire signed [WIDTH:0] t1 = b_real_ext + b_img_ext;
    wire signed [WIDTH:0] t2 = b_img_ext  - b_real_ext;


    wire signed [WIDTH:0] tw_real = (op == 1'b0) ?  t1 :  t2;
    wire signed [WIDTH:0] tw_imag = (op == 1'b0) ?  t2 : -t1;


    wire signed [WIDTH+10:0] mult_real_full = tw_real * $signed(10'sd181);
    wire signed [WIDTH+10:0] mult_imag_full = tw_imag * $signed(10'sd181);

 
    wire signed [WIDTH:0] wb_real = mult_real_full >>> 8;
    wire signed [WIDTH:0] wb_imag = mult_imag_full >>> 8;

 
    assign y0_real = a_real_ext + wb_real;
    assign y0_img  = a_img_ext  + wb_imag;

    assign y1_real = a_real_ext - wb_real;
    assign y1_img  = a_img_ext  - wb_imag;

endmodule
