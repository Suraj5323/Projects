`timescale 1ns/1ps


module tb;

    reg        clk, reset;
    reg signed [7:0]  serial_in_real;
    reg signed [7:0]  serial_in_imag;
    reg               in_valid;

    wire signed [10:0] serial_out_real;   // sQ8.2  output
    wire signed [10:0] serial_out_imag;   // sQ8.2  output


    top uut (
        .clk             (clk),
        .reset           (reset),
        .serial_in_real  (serial_in_real),
        .serial_in_imag  (serial_in_imag),
        .in_valid        (in_valid),
        .serial_out_real (serial_out_real),
        .serial_out_imag (serial_out_imag)
    );

    always #5 clk = ~clk;

    integer i, frame;

    initial begin
        clk            = 0;
        reset          = 1;
        in_valid       = 0;
        serial_in_real = 0;
        serial_in_imag = 0;

        $dumpfile("top.vcd");
        $dumpvars(0, tb);


        #20;
        reset = 0;
        @(posedge clk);


        in_valid = 1;

        for (frame = 0; frame < 3; frame = frame + 1) begin
            for (i = 0; i < 8; i = i + 1) begin
                @(negedge clk);

                serial_in_real = (i + 1 + (frame * 8)) * 4;
                serial_in_imag = 1 * 4;   // constant imag = 1.0  → bits = 4
            end
        end

        @(negedge clk);
        in_valid       = 0;
        serial_in_real = 0;
        serial_in_imag = 0;

        #400;
        $finish;
    end


    real out_real_f, out_imag_f;

    always @(posedge clk) begin
        
        out_real_f = $itor($signed(serial_out_real)) / 4.0;
        out_imag_f = $itor($signed(serial_out_imag)) / 4.0;

        $display("Time=%0t | OUT_real = %8.4f | OUT_imag = %8.4f",
                 $time, out_real_f, out_imag_f);
    end

endmodule