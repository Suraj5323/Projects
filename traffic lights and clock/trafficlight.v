module traffic_signal_controller(
    input wire clk,              // 1Hz clock
    input wire reset,            // Active high reset
    input wire Emergency_Left,   // Emergency from left side
    input wire Emergency_Right,  // Emergency from right side
    
    // Traffic light outputs
    output reg T1_RED, T1_YELLOW, T1_GREEN,
    output reg T2_RED, T2_YELLOW, T2_GREEN,
    
    // Pedestrian signals and buzzer
    output wire T1_WALK, T2_WALK,
    output wire buzzer_walk1, buzzer_walk2,
    
    // State and counter outputs
    output reg [1:0] T1_STATE, T2_STATE,
    output reg [5:0] T1_counter, T2_counter
);

    // State encoding
    parameter RED = 2'b00;
    parameter GREEN = 2'b01;
    parameter YELLOW = 2'b10;
    
    // FSM state registers
    reg [1:0] T1_state, T1_next_state;
    reg [1:0] T2_state, T2_next_state;
    
    // Saved states for emergency recovery
    reg [1:0] T1_saved_state, T2_saved_state;
    
    // Emergency counters
    reg [3:0] emergency_left_counter;
    reg [3:0] emergency_right_counter;
    
    // Emergency flags
    reg emergency_left_active;
    reg emergency_right_active;
    
    // T1_WALK and T2_WALK signals - HIGH when traffic light is RED, LOW during emergencies
    assign T1_WALK = (T1_state == RED) && !emergency_left_active && !emergency_right_active;
    
    // For T2_WALK, it's inactive only during Emergency
    assign T2_WALK = (T2_state == RED) && !emergency_left_active && !emergency_right_active;
    
    // Split buzzer logic for T1 and T2
    assign buzzer_walk1 = (T1_WALK && T1_state == RED && T1_counter >= 55);
    assign buzzer_walk2 = (T2_WALK && T2_state == RED && T2_counter >= 55);
    
    // State update and counter logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize everything on reset
            T1_state <= RED;
            T2_state <= RED;
            T1_counter <= 0;
            T2_counter <= 0;
            emergency_left_counter <= 0;
            emergency_right_counter <= 0;
            emergency_left_active <= 0;
            emergency_right_active <= 0;
            T1_saved_state <= RED;
            T2_saved_state <= RED;
        end else begin
            // Handle new emergencies
            if (Emergency_Left && !emergency_left_active && !emergency_right_active) begin
                emergency_left_active <= 1;
                emergency_left_counter <= 0;
                T1_saved_state <= T1_state; // Save only T1's state
            end
            
            if (Emergency_Right && !emergency_right_active) begin
                emergency_right_active <= 1;
                emergency_right_counter <= 0;
                T1_saved_state <= T1_state; // Save both T1 and T2 states
                T2_saved_state <= T2_state;
            end
            
            // Process emergency_left - affects only T1
            if (emergency_left_active) begin
                emergency_left_counter <= emergency_left_counter + 1;
                T1_state <= RED; // Force T1 to RED
                
                if (emergency_left_counter >= 9) begin
                    emergency_left_active <= 0;
                    T1_state <= T1_saved_state; // Restore only T1's state
                    
                end
            end
            
            // Process emergency_right - affects both T1 and T2
            if (emergency_right_active) begin
                emergency_right_counter <= emergency_right_counter + 1;
                T1_state <= RED; // Force T1 to RED
                T2_state <= RED; // Force T2 to RED
                
                if (emergency_right_counter >= 9) begin
                    emergency_right_active <= 0;
                    T1_state <= T1_saved_state;
                    T2_state <= T2_saved_state;
                    
                end
            end
            
            // Normal state update for T1 (when not in emergency_left or emergency_right)
            if (!emergency_left_active && !emergency_right_active) begin
                T1_state <= T1_next_state;
                
                if (T1_state != T1_next_state)
                    T1_counter <= 0; // Reset counter on state change
                else
                    T1_counter <= T1_counter + 1; // Increment counter
            end
            
            // Normal state update for T2 (when not in emergency_right)
            if (!emergency_right_active) begin
                T2_state <= T2_next_state;
                
                if (T2_state != T2_next_state)
                    T2_counter <= 0; // Reset counter on state change
                else
                    T2_counter <= T2_counter + 1; // Increment counter
            end
        end
    end
    
    // T1 Next State Logic with RED=60s, GREEN=30s, YELLOW=5s
    always @(*) begin
        T1_next_state = T1_state;
        
        if (!emergency_left_active && !emergency_right_active) begin
            case (T1_state)
                RED:    if (T1_counter >= 59) T1_next_state = GREEN;
                GREEN:  if (T1_counter >= 29) T1_next_state = YELLOW;
                YELLOW: if (T1_counter >= 4)  T1_next_state = RED;
                default: T1_next_state = RED;
            endcase
        end
    end
    
    // T2 Next State Logic with RED=60s, GREEN=30s, YELLOW=5s
    always @(*) begin
        T2_next_state = T2_state;
        
        if (!emergency_right_active) begin
            case (T2_state)
                RED:    if (T2_counter >= 59) T2_next_state = GREEN;
                GREEN:  if (T2_counter >= 29) T2_next_state = YELLOW;
                YELLOW: if (T2_counter >= 4)  T2_next_state = RED;
                default: T2_next_state = RED;
            endcase
        end
    end
    
    // Output Logic for Traffic Lights and State Output
    always @(*) begin
        // T1 Lights
        case (T1_state)
            RED: begin
                T1_RED = 1; T1_YELLOW = 0; T1_GREEN = 0;
            end
            GREEN: begin
                T1_GREEN = 1; T1_RED = 0; T1_YELLOW = 0;
            end
            YELLOW: begin
                T1_YELLOW = 1; T1_RED = 0; T1_GREEN = 0;
            end
            default: begin
                T1_RED = 1; T1_YELLOW = 0; T1_GREEN = 0;
            end
        endcase
        
        // T2 Lights
        case (T2_state)
            RED: begin
                T2_RED = 1; T2_YELLOW = 0; T2_GREEN = 0;
            end
            GREEN: begin
                T2_GREEN = 1; T2_RED = 0; T2_YELLOW = 0;
            end
            YELLOW: begin
                T2_YELLOW = 1; T2_RED = 0; T2_GREEN = 0;
            end
            default: begin
                T2_RED = 1; T2_YELLOW = 0; T2_GREEN = 0;
            end
        endcase
        
        // Output current states
        T1_STATE = T1_state;
        T2_STATE = T2_state;
    end

endmodule
