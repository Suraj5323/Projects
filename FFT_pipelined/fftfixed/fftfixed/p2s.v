module p2s #(
    parameter WIDTH = 8
)(
    input clk,
    input reset,
    input [8*WIDTH-1:0] parallel_in_real,
    input [8*WIDTH-1:0] parallel_in_imag,
    input in_valid,
    output reg [WIDTH-1:0] serial_out_real,
    output reg [WIDTH-1:0] serial_out_imag
);

reg [WIDTH-1:0] buffer_real [0:7];
reg [WIDTH-1:0] buffer_imag [0:7];
reg [2:0] count;
integer i;


always @(posedge clk or posedge reset) begin
    if (reset) begin
        count      <= 0;
    end else begin

        // Latch valid permanently on first in_valid
        if (in_valid)
            for (i = 0; i < 8; i = i + 1) begin
                buffer_real[i] <= parallel_in_real[(7-i)*WIDTH +: WIDTH];
                buffer_imag[i] <= parallel_in_imag[(7-i)*WIDTH +: WIDTH];
            end

        // Stream out
        if (1) begin
            count           <= count + 1;
            case(count)
                3'd0 : begin
                    serial_out_real <= buffer_real[3];
                    serial_out_imag <= buffer_imag[3];
                end
                3'd1 : begin
                    serial_out_real <= buffer_real[2];
                    serial_out_imag <= buffer_imag[2];
                end
                3'd2 : begin
                    serial_out_real <= buffer_real[1];
                    serial_out_imag <= buffer_imag[1];
                end
                3'd3 : begin
                    serial_out_real <= buffer_real[0];
                    serial_out_imag <= buffer_imag[0];
                end
                3'd4 : begin
                    serial_out_real <= buffer_real[7];
                    serial_out_imag <= buffer_imag[7];
                end
                3'd5 : begin
                    serial_out_real <= buffer_real[6];
                    serial_out_imag <= buffer_imag[6];
                end
                3'd6 : begin
                    serial_out_real <= buffer_real[5];
                    serial_out_imag <= buffer_imag[5];
                end
                3'd7 : begin
                    serial_out_real <= buffer_real[4];
                    serial_out_imag <= buffer_imag[4];
                end
            endcase
        end
    end
end
endmodule