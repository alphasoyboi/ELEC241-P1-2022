module display_data_bus_controller #(parameter int unsigned cycles_140ns) (
    output logic [7:0] ouput_data,
    output logic rs,
    output logic rw,
    output logic e,
    output logic busy,
    input logic [7:0] input_data,
    input logic write,
    input logic ir_dr,
    input logic clk,
    input logic n_reset,
);

typedef enum int unsigned {
    STATE_READY = 1,
    STATE_WRITE_IR,  // write to instruction register
    STATE_WRITE_DR,  // wrtie to data register
    STATE_DONE
} state_t;

state_t state, next_state;
logic timer_done, timer_start;
timer t (timer_done, cycles_140ns, timer_start, clk, n_reset);

always_comb begin : next_state_logic
    case (cmd_state)
        CMD_STATE_READY:
            if (cmd_write) begin
                if (cmd_ir_dr)
                    next_state = STATE_WRITE_IR;
                else
                    next_state = STATE_WRITE_DR;
            end
            else
                next_state = STATE_READY;
        STATE_WRITE_IR: next_state = timer_done ? STATE_DONE : STATE_WRITE_IR;
        STATE_WRITE_DR: next_state = timer_done ? STATE_DONE : STATE_WRITE_DR;
        STATE_DONE:     next_state = write ? STATE_DONE : STATE_READY;
        default:        next_state = STATE_READY;
    endcase
end

always_comb begin : timer_logic
    case (state) 
        STATE_WRITE_IR,
        STATE_WRITE_DR: timer_start = 1;
        default:        timer_start = 0;
    endcase
end

always_ff @(posedge clk or negedge n_reset) begin : update_state
    if (~n_reset)
        state = STATE_READY;
    else
        state = next_state;
end

always_latch begin : output_logic
    case (cmd_state)
        CMD_STATE_WRITE_IR: {e, rs, rw, output_data} = {3'b100, input_data};
        CMD_STATE_WRITE_DR: {e, rs, rw, output_data} = {3'b110, input_data};
        default: e = 0;
    endcase
end