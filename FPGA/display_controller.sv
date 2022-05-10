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

    typedef enum {
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

    typedef enum {
        CMD_STATE_READY = 1,
        CMD_STATE_WRITE_IR, // write to instruction register
        CMD_STATE_WRITE_DR, // wrtie to data register
        CMD_STATE_HOLD,
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
    logic t1_done, t1_start; 
    logic t2_done, t2_start; 
    logic t3_done, t3_start; 
    logic t4_done, t4_start; 
    logic t5_done, t5_start;
    logic t6_done, t6_start;
    timer #(cycles_40000us) t1(t1_done, clk, t1_start, reset);
    timer #(cycles_1530us)  t2(t2_done, clk, t2_start, reset);
    timer #(cycles_43us)    t3(t3_done, clk, t3_start, reset);
    timer #(cycles_39us)    t4(t4_done, clk, t4_start, reset);
    timer #(cycles_1060ns)  t5(t5_done, clk, t5_start, reset);
    timer #(cycles_140ns)   t6(t6_done, clk, t6_start, reset);
    logic t7_done, t7_start;
    timer #(50000000)   t7(t7_done, clk, t7_start, reset);

    // angle converter
    bit [11:0] bcd;
    angle_to_bcd angle_data_converter(bcd, angle);

    cmd_t cmd;
    cmd_state_t cmd_state, next_cmd_state;
    state_t state, next_state;

    bit [7:0] ascii [4];
    int unsigned ascii_index;

    always_latch begin : next_state_logic
        case (cmd_state)
            CMD_STATE_WRITE_IR,
            CMD_STATE_WRITE_DR: begin
                t6_start = 1;
                if (t6_done) begin
                    t6_start = 0;
                    next_cmd_state = CMD_STATE_HOLD;
                end
            end
            CMD_STATE_HOLD: begin
                t5_start = 1;
                if (t5_done) begin
                    t5_start = 0;
                    next_cmd_state = CMD_STATE_DONE;
                end
            end
            default: next_cmd_state = CMD_STATE_READY;
        endcase

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

                        next_cmd_state = CMD_STATE_READY;
                        next_state     = STATE_PAUSE;
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