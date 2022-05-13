module display_data_bus_controller #(
    parameter int unsigned cycles_1200ns = 60,
    parameter int unsigned cycles_140ns = 7
)   (
    output logic [7:0] output_data,
    output logic rs,
    output logic rw,
    output logic e,
    output logic busy,
    input logic [7:0] input_data,
    input logic write,
    input logic ir_dr,
    input logic clk,
    input logic n_reset
);

typedef enum int unsigned {
    STATE_READY = 1,
    STATE_WRITE_IR,  // write to instruction register
    STATE_WRITE_DR,  // wrtie to data register
    STATE_HOLD,
    STATE_DONE
} state_t;

state_t state, next_state;
logic pulse_timer_done, pulse_timer_start, period_timer_done, period_timer_start;
timer #(cycles_140ns) pulse_timer (pulse_timer_done, pulse_timer_start, clk, n_reset);
timer #(cycles_1200ns) period_timer (period_timer_done, period_timer_start, clk, n_reset);

always_comb begin : next_state_logic
    case (state)
        STATE_READY:
            if (write) begin
                if (ir_dr)
                    next_state = STATE_WRITE_IR;
                else
                    next_state = STATE_WRITE_DR;
            end
            else
                next_state = STATE_READY;
        STATE_WRITE_IR: next_state = pulse_timer_done ? STATE_HOLD : STATE_WRITE_IR;
        STATE_WRITE_DR: next_state = pulse_timer_done ? STATE_HOLD : STATE_WRITE_DR;
        STATE_HOLD:     next_state = period_timer_done ? STATE_DONE : STATE_HOLD;
        STATE_DONE:     next_state = write ? STATE_DONE : STATE_READY;
        default:        next_state = STATE_READY;
    endcase
end

always_comb begin : timer_logic
    case (state) 
        STATE_WRITE_IR,
        STATE_WRITE_DR: {pulse_timer_start, period_timer_start} = 2'b11;
        STATE_HOLD:     {pulse_timer_start, period_timer_start} = 2'b01;
        default:        {pulse_timer_start, period_timer_start} = 2'b00;
    endcase
end

always_ff @(posedge clk or negedge n_reset) begin : update_state
    if (~n_reset)
        state = STATE_READY;
    else
        state = next_state;
end

always_latch begin : output_logic
    case (state)
        STATE_WRITE_IR: {e, rs, rw, output_data} = {3'b100, input_data};
        STATE_WRITE_DR: {e, rs, rw, output_data} = {3'b110, input_data};
        default: e = 0;
    endcase

    if (state == STATE_READY)
        busy = 0;
    else
        busy = 1;
end

endmodule