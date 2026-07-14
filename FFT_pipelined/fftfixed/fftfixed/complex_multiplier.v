
module cmplx_mult(
    input  signed [7:0]  a_real, a_img,   
    input  signed [7:0]  b_real, b_img,   
    output signed [7:0]  out_real, out_img 
);

    wire signed [15:0] rr = a_real * b_real;
    wire signed [15:0] ii = a_img  * b_img;
    wire signed [15:0] ri = a_real * b_img;
    wire signed [15:0] ir = a_img  * b_real;
    wire signed [16:0] sum_real = rr - ii;  
    wire signed [16:0] sum_imag = ri + ir;  


    assign out_real = sum_real >>> 2;  
    assign out_img  = sum_imag >>> 2;

endmodule
