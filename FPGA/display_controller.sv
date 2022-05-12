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

    typedef enum bit [7:0] {
        CMD_NULL,
        CMD_FUNC_SET   = 8'b0011_1000, // set 8 bit mode, 2 line display, and 5x8 font
        CMD_DISP_ON    = 8'b0000_1100, // turn display on, turn cursor and cursor blinking off
        CMD_CLR_DISP   = 8'b0000_0001, //
        CMD_RET_HOME   = 8'b0000_0010, //
        CMD_ENTRY_MODE = 8'b0000_0110  //
    } cmd_t;

    // timer
    logic timer_done, timer_start;
    int unsigned timer_count;
    timer t (timer_done, timer_count, clk, timer_start, n_reset);

    // angle converter
    bit [11:0] bcd;
    bit [11:0] bcd_temp;
    angle_to_bcd angle_data_converter(bcd, angle);

    cmd_t cmd;
    bit [7:0] ascii [4];
    int unsigned ascii_index;

    state_t state, next_state;

    logic [7:0] bus_data;
    logic bus_write, bus_ir_dr, bus_busy;
    display_data_bus_controller #(cycles_140ns) bus (data, rs, rw, e, bus_busy, bus_data, bus_write, bus_ir_dr, clk, n_reset);

    always_latch begin : next_state_logic
        // initialization sequence according to Winstar Display Co. for component WH1602B-NYG-JT
        case (state)
            STATE_INIT_VCC_RISE: begin
                if (state_timer_done) begin
                    next_state = STATE_INIT_FUNC_SET_1;
                end
            end
            STATE_INIT_FUNC_SET_1: begin
                if (cmd_state == CMD_STATE_READY) begin
                    cmd = CMD_FUNC_SET;
                    {cmd_write, cmd_ir_dr} = 2'b11;
                end
                if (cmd_state == CMD_STATE_DONE) begin
                    if (state_timer_done) begin
                        next_state = STATE_INIT_FUNC_SET_2;
                    end
                end
            end
            STATE_INIT_FUNC_SET_2: begin
                if (cmd_state == CMD_STATE_READY) begin
                    cmd = CMD_FUNC_SET;
                    {cmd_write, cmd_ir_dr} = 2'b11;
                end
                if (cmd_state == CMD_STATE_DONE) begin
                    if (t4_done) begin
                        next_state = STATE_INIT_DISP_ON;
                    end
                end
            end
            STATE_INIT_DISP_ON: begin
                if (cmd_state == CMD_STATE_READY) begin
                    cmd = CMD_DISP_ON;
                    {cmd_write, cmd_ir_dr} = 2'b11;
                end
                if (cmd_state == CMD_STATE_DONE) begin
                    if (t4_done) begin
                        next_state = STATE_INIT_DISP_CLR;
                    end
                end
            end
            STATE_INIT_DISP_CLR: begin
                if (cmd_state == CMD_STATE_READY) begin
                    cmd = CMD_CLR_DISP;
                    {cmd_write, cmd_ir_dr} = 2'b11;
                end
                if (cmd_state == CMD_STATE_DONE) begin
                    if (t2_done) begin
                        next_state = STATE_INIT_ENTRY_MODE;
                    end
                end
            end
            STATE_INIT_ENTRY_MODE: begin
                if (cmd_state == CMD_STATE_READY) begin
                    cmd = CMD_ENTRY_MODE;
                    {cmd_write, cmd_ir_dr} = 2'b11;
                end
                if (cmd_state == CMD_STATE_DONE) begin
                    if (t4_done) begin
                        next_state = STATE_DISP_CLR;
                    end
                end
            end
            STATE_READY: begin
                if (write)
                    next_state = STATE_DISP_CLR;
            end
            STATE_DISP_CLR: begin
                if (cmd_state == CMD_STATE_READY) begin
                    cmd = CMD_CLR_DISP;
                    next_cmd_state = CMD_STATE_WRITE_IR;
                end
                if (cmd_state == CMD_STATE_DONE) begin
                    t2_start = 1;
                    if (t2_done) begin
                        t2_start = 0;

                        next_cmd_state = CMD_STATE_READY;
                        next_state = STATE_WRITE_DATA;
                    end
                end
            end
            STATE_WRITE_DATA: begin
                if (cmd_state == CMD_STATE_READY) begin
                    {cmd_write, cmd_ir_dr} = 2'b10;
                end
                if (cmd_state == CMD_STATE_DONE) begin
                    if (t3_done) begin
                        ascii_index = ascii_index + 1;
                        if (ascii_index < 4)
                            next_state = STATE_WRITE_DATA;
                        else begin
                            ascii_index = 0;
                            next_state = STATE_PAUSE;
                        end
                    end
                end
            end
            STATE_PAUSE: begin
                if (t7_done) begin
                    next_state = STATE_READY;
                end
            end
            default: begin
                next_state = STATE_INIT_VCC_RISE;
                cmd_write = 0;
                cmd_ir_dr = 0;
            end
        endcase
    end

    always_comb begin : timer_logic
        case (state)
            STATE_INIT_VCC_RISE:   timer_count = cycles_40000us;
            STATE_INIT_FUNC_SET_1,
            STATE_INIT_FUNC_SET_2,
            STATE_INIT_DISP_ON,
            STATE_INIT_ENTRY_MODE: timer_count = cycles_39us;
            STATE_INIT_DISP_CLR,
            STATE_DISP_CLR:        timer_count = cycles_1530us;
            STATE_READY,
            STATE_WRITE_DATA:      timer_count = cycles_43us;
            STATE_PAUSE:           timer_count = 50000000;
            default:               timer_count = 1;
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
        if (state == STATE_READY) 
            busy = 0;
        else
            busy = 1;
    end

endmodule