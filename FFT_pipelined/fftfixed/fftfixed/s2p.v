module s2p #(
    parameter WIDTH = 8
)(
    input clk,
    input reset,
    input [WIDTH-1:0] serial_in_real,
    input [WIDTH-1:0] serial_in_imag,
    input in_valid,

    output reg [8*WIDTH-1:0] parallel_out_real,
    output reg [8*WIDTH-1:0] parallel_out_imag,
    output reg out_valid
);

    reg [WIDTH-1:0] buffer_real [0:7];
    reg [WIDTH-1:0] buffer_imag [0:7];
    reg [2:0] count;

    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 0;
            out_valid <= 0;
            for (i = 0; i < 8; i = i + 1) begin
                buffer_real[i] <= 0;
                buffer_imag[i] <= 0;
            end
        end else begin
            out_valid <= 0;

            if (in_valid) begin
                buffer_real[count] <= serial_in_real;
                buffer_imag[count] <= serial_in_imag;
                count <= count + 1;

						if (count == 3'd7) begin
                    parallel_out_real <= {
                        serial_in_real, buffer_real[6], buffer_real[5], buffer_real[4], 
                        buffer_real[3], buffer_real[2], buffer_real[1], buffer_real[0]
                    };
                    parallel_out_imag <= {
                        serial_in_imag, buffer_imag[6], buffer_imag[5], buffer_imag[4], 
                        buffer_imag[3], buffer_imag[2], buffer_imag[1], buffer_imag[0]
                    };
                    out_valid <= 1;
                    count <= 0;
                end
            end
        end
    end

endmodule