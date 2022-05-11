module display_data_bus_controller (
    output logic [7:0] data,
    output logic rs,
    output logic rw,
    output logic e,
    output logic busy,
    input logic clk,
    input logic operation,
    input logic reset,
);

typedef enum int unsigned {
    CMD_STATE_READY = 1,
    CMD_STATE_WRITE_IR,  // write to instruction register
    CMD_STATE_WRITE_DR,  // wrtie to data register
    CMD_STATE_DONE
} state_t;

state_t state;

always_comb begin : next_state_logic
    case (state)
        CMD_STATE_READY
end

always_ff @(posedge clk or negedge reset) begin : update_state
    if (~reset)
        state = CMD_STATE_READY;
    else
        
end

always_comb begin : output_logic
    if 
end
