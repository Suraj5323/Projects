
module cmplx_adder_subt(
    input  signed [7:0] a_real, a_img,   // sQ5.2
    input  signed [7:0] b_real, b_img,   // sQ5.2
    input  op,
    output signed [8:0] out_real, out_img // sQ6.2 
);
    // Sign-extend to 9 bits then add/subtract.
    // op=0 → addition, op=1 → subtraction
    assign out_real = op ? ($signed(a_real) - $signed(b_real))
                        : ($signed(a_real) + $signed(b_real));
    assign out_img  = op ? ($signed(a_img)  - $signed(b_img))
                        : ($signed(a_img)  + $signed(b_img));
endmodule
