`timescale 1s/1ms

module traffic_signal_controller_tb;

  // Inputs
  reg clk;
  reg reset;
  reg Emergency_Left;
  reg Emergency_Right;
  
  // Outputs
  wire T1_RED, T1_YELLOW, T1_GREEN;
  wire T2_RED, T2_YELLOW, T2_GREEN;
  wire T1_WALK, T2_WALK;
  wire buzzer_walk1, buzzer_walk2;
  wire [1:0] T1_STATE, T2_STATE;
  wire [5:0] T1_counter, T2_counter;

  // Instantiate the Unit Under Test (UUT)
  traffic_signal_controller uut (
    .clk(clk),
    .reset(reset),
    .Emergency_Left(Emergency_Left),
    .Emergency_Right(Emergency_Right),
    .T1_RED(T1_RED),
    .T1_YELLOW(T1_YELLOW),
    .T1_GREEN(T1_GREEN),
    .T2_RED(T2_RED),
    .T2_YELLOW(T2_YELLOW),
    .T2_GREEN(T2_GREEN),
    .T1_WALK(T1_WALK),
    .T2_WALK(T2_WALK),
    .buzzer_walk1(buzzer_walk1),
    .buzzer_walk2(buzzer_walk2),
    .T1_STATE(T1_STATE),
    .T2_STATE(T2_STATE),
    .T1_counter(T1_counter),
    .T2_counter(T2_counter)
  );
  
  // Clock generation (1Hz)
  initial begin
    clk = 0;
    forever #0.5 clk = ~clk; // 1 time unit per cycle (1s)
  end
// BEEP display for buzzers
always @(posedge clk) begin
  if (buzzer_walk1) begin
    $display("Time=%0t: BEEP from buzzer_walk1", $time);
  end
  if (buzzer_walk2) begin
    $display("Time=%0t: BEEP from buzzer_walk2", $time);
  end
end

  // VCD Dump for GTKWave
  initial begin
    $dumpfile("traffic2.vcd");
    $dumpvars(0, traffic_signal_controller_tb);
  end

  // Monitor for outputs
  initial begin
    $monitor("Time=%0t | T1_STATE=%0d T2_STATE=%0d | T1: R=%b Y=%b G=%b | T2: R=%b Y=%b G=%b | Walk: T1=%b T2=%b ", 
            $time, T1_STATE, T2_STATE, T1_RED, T1_YELLOW, T1_GREEN, T2_RED, T2_YELLOW, T2_GREEN, 
            T1_WALK, T2_WALK);
  end
  
  // Test cases
  initial begin
    // Initialize inputs
    reset = 1;
    Emergency_Left = 0;
    Emergency_Right = 0;
    
    // Apply reset
    #2 reset = 0;
    
    // Case 1: Normal operation for a few cycles
    $display("=== Case 1: Normal Operation ===");
    #100;
    
    // Case 2: Emergency_Left (should only affect T1)
    $display("=== Case 2: Emergency from Left ===");
    Emergency_Left = 1;
    #2;
    Emergency_Left = 0;
    #20;
    
    // Case 3: Emergency_Right (should affect both T1 and T2)
    $display("=== Case 3: Emergency from Right ===");
    Emergency_Right = 1;
    #2;
    Emergency_Right = 0;
    #20;
    
    // Case 4: Buzzer activation during pedestrian walk
    $display("=== Case 4: Pedestrian Signal with Buzzer ===");
    // Wait until we're in RED state with counter near end
    #80;
    
    $display("=== Simulation Complete ===");
    $finish;
  end

endmodule
