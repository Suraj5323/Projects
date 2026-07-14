module pipeline_regs #(parameter width = 8)(
    input clk, reset,
    input wire [8*width-1:0]in_real, in_img,
    output reg [8*width-1:0]out_real, out_img
);

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            out_real <= 0;
            out_img <= 0;
        end
        else begin
            out_real <= in_real;
            out_img <= in_img; 
        end
    end

endmodule