module display_controller #(
    // delays in clock pulses
    parameter int unsigned cycles_40000us = 2000000, // delay for vcc rise
    parameter int unsigned cycles_1530us  = 76500,   // delay for display clear
    parameter int unsigned cycles_43us    = 2150,    // delay for data register write
    parameter int unsigned cycles_39us    = 1950,    // delay for most instruction register writes
    parameter int unsigned cycles_1200ns  = 60,      // write delay for enable pulse low
    parameter int unsigned cycles_140ns   = 7        // write delay for enable pulse high
)   (
    output logic [7:0] data,
    output logic rs,
    output logic rw,
    output logic e,
    output logic busy,
    input logic [11:0] angle,
    input logic write,
    input logic clk,
    input logic n_reset
);

typedef enum int unsigned {
    STATE_INIT_VCC_RISE = 1,
    STATE_INIT_FUNC_SET_1,
    STATE_INIT_FUNC_SET_2,
    STATE_INIT_DISP_ON,
    STATE_INIT_DISP_CLR,
    STATE_INIT_ENTRY_MODE,
    STATE_READY,
    STATE_DISP_CLR, 
    STATE_WRITE_DATA,
    STATE_PAUSE
} state_t;

enum bit [7:0] {
    CMD_FUNC_SET   = 8'b0011_1000, // set 8 bit mode, 2 line display, and 5x8 font
    CMD_DISP_ON    = 8'b0000_1100, // turn display on, turn cursor and cursor blinking off
    CMD_CLR_DISP   = 8'b0000_0001, //
    CMD_ENTRY_MODE = 8'b0000_0110  //
};

// timers
logic timer_done_40000us, timer_start_40000us;
logic timer_done_1530us, timer_start_1530us;
logic timer_done_43us, timer_start_43us;
logic timer_done_39us, timer_start_39us;
timer #(cycles_40000us) timer_40000us (timer_done_40000us, timer_done_40000us, clk,  n_reset);
timer #(cycles_1530us) timer_1530us (timer_done_1530us, timer_start_1530us, clk, n_reset);
timer #(cycles_43us) timer_43us (timer_done_43us, timer_start_43us, clk, n_reset);
timer #(cycles_39us) timer_39us (timer_done_39us, timer_start_39us, clk, n_reset);
timer #(50000000) timer_1s (timer_done_1s, timer_start_1s, clk, n_reset);

// angle converter
bit [11:0] bcd;
bit [11:0] bcd_temp;
angle_to_bcd angle_data_converter(bcd, angle);

bit [7:0] ascii [4];
int unsigned ascii_index;

state_t state, next_state;

logic [7:0] bus_data;
logic bus_write, bus_ir_dr, bus_busy;
display_data_bus_controller bus (data, rs, rw, e, bus_busy, bus_data, bus_write, bus_ir_dr, clk, n_reset);

always_comb begin : next_state_logic
    // initialization sequence according to Winstar Display Co. for component WH1602B-NYG-JT
    if (bus_busy)
        next_state = state;
    else begin
        case (state)
            STATE_INIT_VCC_RISE:   next_state = timer_done_40000us ? STATE_INIT_FUNC_SET_1 : state;
            STATE_INIT_FUNC_SET_1: next_state = timer_done_39us ? STATE_INIT_FUNC_SET_2 : state;
            STATE_INIT_FUNC_SET_2: next_state = timer_done_39us ? STATE_INIT_DISP_ON : state;
            STATE_INIT_DISP_ON:    next_state = timer_done_39us ? STATE_INIT_DISP_CLR : state;
            STATE_INIT_DISP_CLR:   next_state = timer_done_1530us ? STATE_INIT_ENTRY_MODE : state; 
            STATE_INIT_ENTRY_MODE: next_state = timer_done_39us ? STATE_READY : state;
            STATE_READY:           next_state = write ? STATE_DISP_CLR : state;
            STATE_DISP_CLR:        next_state = timer_1530us ? STATE_WRITE_DATA;
            STATE_WRITE_DATA:      next_state = (ascii_index == 4) ? STATE_PAUSE : state;
            STATE_PAUSE:           next_state = timer_done_1s ? STATE_READY : state;
            default: next_state = STATE_INIT_VCC_RISE;
        endcase
    end
end

always_comb begin : timer_logic
    case (state)

    endcase
end

always_ff @(posedge clk or negedge n_reset) begin : update_state
    if (~n_reset) begin
        ascii       <= '{8'b0011_0000, 8'b0011_0000, 8'b0011_0000, 8'b0011_0000};
        ascii_index <= 0;

        state <= STATE_INIT_VCC_RISE;
    end
    else begin
        state <= next_state;
    end
end

always_comb begin : output_logic
    case (state)
        STATE_INIT_FUNC_SET_1,
        STATE_INIT_FUNC_SET_2: {bus_write, bus_ir_dr, bus_data} = timer_done_39us ? {2'b11, CMD_FUNC_SET} : 10'b0;
        STATE_INIT_DISP_ON:    {bus_write, bus_ir_dr, bus_data} = timer_done_39us ? {2'b11, CMD_DISP_ON} : 10'b0;
        STATE_INIT_ENTRY_MODE: {bus_write, bus_ir_dr, bus_data} = timer_done_39us ? {2'b11, CMD_ENTRY_MODE} : 10'b0;
        STATE_INIT_DISP_CLR,
        STATE_DISP_CLR:        {bus_write, bus_ir_dr, bus_data} = timer_done_1530us ? {2'b11, CMD_CLR_DISP} : 10'b0;
        STATE_WRITE_DATA:      {bus_write, bus_ir_dr, bus_data} = {2'b10, ascii[ascii_index]};
        default:               {bus_write, bus_ir_dr, bus_data} = 10'b0;
    endcase
    end
    else
        {bus_write, bus_ir_dr, bus_data} = 10'b0;

    if (state == STATE_READY) 
        busy = 0;
    else
        busy = 1;
end

endmodule