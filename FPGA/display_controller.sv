module display_controller #(
    // delays in clock pulses
    parameter int unsigned cycles_40000us = 2000000, // delay for vcc rise
    parameter int unsigned cycles_1530us  = 76500,   // delay for display clear
    parameter int unsigned cycles_43us    = 2150,    // delay for data register write
    parameter int unsigned cycles_39us    = 1950,    // delay for most instruction register writes
    parameter int unsigned cycles_1060ns  = 53,      // write delay for enable pulse low
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
    input logic reset
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

    typedef enum int unsigned {
        CMD_STATE_READY = 1,
        CMD_STATE_WRITE_IR,  // write to instruction register
        CMD_STATE_WRITE_DR,  // wrtie to data register
        CMD_STATE_DONE
    } cmd_state_t;

    typedef enum bit [7:0] {
        CMD_CLR_DISP   = 8'b0000_0001, //
        CMD_RET_HOME   = 8'b0000_0010, //
        CMD_ENTRY_MODE = 8'b0000_0110, //
        CMD_DISP_ON    = 8'b0000_1100, // turn display on, turn cursor and cursor blinking off
        CMD_FUNC_SET   = 8'b0011_1000  // set 8 bit mode, 2 line display, and 5x8 font
    } cmd_t;

    // timers
    logic cmd_timer_done, state_timer_done;
    logic cmd_timer_start, state_timer_start;
    int unsigned cmd_timer_count, state_timer_count;
    timer cmd_timer (cmd_timer_done, cmd_timer_count, clk, cmd_timer_start, reset);
    timer state_timer (state_timer_done, state_timer_count, clk, state_timer_start, reset);

    // angle converter
    bit [11:0] bcd;
    bit [11:0] bcd_temp;
    angle_to_bcd angle_data_converter(bcd, angle);

    cmd_t cmd;
    cmd_state_t cmd_state, next_cmd_state;
    state_t state, next_state;

    bit [7:0] ascii [4];
    int unsigned ascii_index;

    always_comb begin : next_cmd_state_logic
        case (cmd_state)
            CMD_STATE_READY:
            CMD_STATE_WRITE_IR,
            CMD_STATE_WRITE_DR: begin
                if (timer_done)
                    next_cmd_state = CMD_STATE_DONE;
            end
            CMD_STATE_DONE:
            default: next_cmd_state = CMD_STATE_READY;
        endcase
    end

    always_latch begin : next_state_logic
        // initialization sequence according to Winstar Display Co. for component WH1602B-NYG-JT
        case (state)
            STATE_INIT_VCC_RISE: begin
                t1_start = 1;
                if (t1_done) begin
                    t1_start = 0;
                    next_cmd_state = CMD_STATE_READY;
                    next_state     = STATE_INIT_FUNC_SET_1;
                end
            end
            STATE_INIT_FUNC_SET_1: begin
                if (cmd_state == CMD_STATE_READY) begin
                    cmd = CMD_FUNC_SET;
                    next_cmd_state = CMD_STATE_WRITE_IR;
                end
                if (cmd_state == CMD_STATE_DONE) begin
                    t4_start = 1;
                    if (t4_done) begin
                        t4_start = 0;
                        next_cmd_state = CMD_STATE_READY;
                        next_state     = STATE_INIT_FUNC_SET_2;
                    end
                end
            end
            STATE_INIT_FUNC_SET_2: begin
                if (cmd_state == CMD_STATE_READY) begin
                    cmd = CMD_FUNC_SET;
                    next_cmd_state = CMD_STATE_WRITE_IR;
                end
                if (cmd_state == CMD_STATE_DONE) begin
                    t4_start = 1;
                    if (t4_done) begin
                        t4_start = 0;
                        next_cmd_state = CMD_STATE_READY;
                        next_state     = STATE_INIT_DISP_ON;
                    end
                end
            end
            STATE_INIT_DISP_ON: begin
                if (cmd_state == CMD_STATE_READY) begin
                    cmd = CMD_DISP_ON;
                    next_cmd_state = CMD_STATE_WRITE_IR;
                end
                if (cmd_state == CMD_STATE_DONE) begin
                    t4_start = 1;
                    if (t4_done) begin
                        t4_start = 0;
                        next_cmd_state = CMD_STATE_READY;
                        next_state     = STATE_INIT_DISP_CLR;
                    end
                end
            end
            STATE_INIT_DISP_CLR: begin
                if (cmd_state == CMD_STATE_READY) begin
                    cmd = CMD_CLR_DISP;
                    next_cmd_state = CMD_STATE_WRITE_IR;
                end
                if (cmd_state == CMD_STATE_DONE) begin
                    t2_start = 1;
                    if (t2_done) begin
                        t2_start = 0;
                        next_cmd_state = CMD_STATE_READY;
                        next_state     = STATE_INIT_ENTRY_MODE;
                    end
                end
            end
            STATE_INIT_ENTRY_MODE: begin
                if (cmd_state == CMD_STATE_READY) begin
                    cmd = CMD_ENTRY_MODE;
                    next_cmd_state = CMD_STATE_WRITE_IR;
                end
                if (cmd_state == CMD_STATE_DONE) begin
                    t4_start = 1;
                    if (t4_done) begin
                        t4_start = 0;
                        next_cmd_state = CMD_STATE_READY;
                        next_state     = STATE_DISP_CLR;
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
                        next_state     = STATE_WRITE_DATA;
                    end
                end
            end
            STATE_WRITE_DATA: begin
                if (cmd_state == CMD_STATE_READY) begin
                    next_cmd_state = CMD_STATE_WRITE_DR;
                end
                if (cmd_state == CMD_STATE_DONE) begin
                    t3_start = 1;
                    if (t3_done) begin
                        t3_start = 0;
                        ascii_index = ascii_index + 1;
                        next_cmd_state = CMD_STATE_READY;
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
                t7_start = 1;
                if (t7_done) begin
                    t7_start = 0;
                    next_state = STATE_READY;
                end
            end
            default: next_state = STATE_INIT_VCC_RISE;
        endcase
    end

    always_ff @(posedge clk or negedge reset) begin : update_state
        if (~reset) begin
            ascii       <= '{8'b0011_0000, 8'b0011_0000, 8'b0011_0000, 8'b0011_0000};
            ascii_index <= 0;

            cmd_state <= CMD_STATE_READY;
            state     <= STATE_INIT_VCC_RISE;
        end
        else begin
            cmd_state <= next_cmd_state;
            state     <= next_state;
        end
    end

    always_comb begin : timer_logic
        case (cmd_state) 

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

    always_latch begin : output_logic
        case (cmd_state)
            CMD_STATE_WRITE_IR: {e, rs, rw, data} = {3'b100, cmd};
            CMD_STATE_WRITE_DR: {e, rs, rw, data} = {3'b110, ascii[ascii_index]};
            default: e = 0;
        endcase

        if (state == STATE_READY) 
            busy = 0;
        else
            busy = 1;
    end

endmodule