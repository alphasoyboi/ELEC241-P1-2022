module display_controller #(
    // delays in clock pulses
    parameter int unsigned t_40000us = 2000000, // delay for vcc rise
    parameter int unsigned t_15000us = 2000000, // delay for vcc rise
    parameter int unsigned t_4100us  = 205000,  //
    parameter int unsigned t_1530us  = 78000,  // delay for display clear
    parameter int unsigned t_100us   = 5000,
    parameter int unsigned t_43us    = 2500,   // 
    parameter int unsigned t_39us    = 2000,   // delay for most other commands
    parameter int unsigned t_200ns   = 10,     // write delay for enable pulse width
    parameter int unsigned t_140ns   = 10      // write delay for enable pulse width
)   (
    output logic [7:0] data,
    output logic rs,
    output logic rw,
    output logic e,
    output logic busy,
    input logic [11:0] angle_data,
    input logic write,
    input logic clk,
    input logic reset
);

    typedef enum bit [7:0] {
        CMD_CLR_DISP   = 8'b0000_0001, //
        CMD_RET_HOME   = 8'b0000_0010, //
        CMD_ENTRY_MODE = 8'b0000_0110, //
        CMD_DISP_CTRL  = 8'b0000_1100, // turn display on, turn cursor and cursor blinking off
        CMD_FUNC_SET   = 8'b0011_1000  // set 8 bit mode, 2 line display, and 5x8 font
    } cmd_t;

    typedef enum {
        STATE_INIT_VCC_RISE,
        STATE_INIT_SET_FUNC1,
        STATE_INIT_SET_FUNC2,
        STATE_INIT_SET_FUNC3,
        STATE_INIT_DISP_ON,
        STATE_INIT_DISP_CLR,
        STATE_INIT_SET_ENTRY,
        STATE_READY,
        STATE_PAUSE,
        STATE_DISP_CLR,
        STATE_READ_DATA
    } disp_state_t;

    typedef enum {
        CMD_STATE_WRITE,
        CMD_STATE_HOLD,
        CMD_STATE_DELAY
    } cmd_state_t;

    // this function returns a high bit once the specified command is complete
    function bit send_cmd (cmd_t cmd, int unsigned clk_cnt);
        if (clk_cnt < t_140ns)
            {e, rs, rw, data} = {3'b100, cmd}; // pulse enable high, set register read/write controls, and write data to bus
        else 
            e = 0; // write lcd enable low after required pulse time (140ns)
        case (cmd)
            CMD_CLR_DISP, // fall through on case statement for commands with 1.53ms processing period
            CMD_RET_HOME: begin
                if (clk_cnt >= t_1530us)
                    return 1'b1;
                else
                    return 1'b0;
            end
            CMD_ENTRY_MODE, // fall through on case statement for commands with 39us processing period
            CMD_DISP_CTRL,
            CMD_FUNC_SET: begin
                if (clk_cnt >= t_43us)
                    return 1'b1;
                else
                    return 1'b0;
            end
            default: return 1'b1;
        endcase
    endfunction

    function bit send_ascii (bit [7:0] ascii, int unsigned clk_cnt);
        if (clk_cnt < t_140ns)
            {e, rs, rw, data} = {3'b110, ascii}; // pulse enable high, set register read/write controls, and write data to bus
        else 
            e = 0; // write lcd enable low after required pulse time (140ns)
        if (clk_cnt >= t_43us)
            return 1'b1;
        else
            return 1'b0;
    endfunction

    bit [7:0] ascii_angle [4];
    bit [7:0] ascii_angle2 [4];
    int unsigned i;
    int unsigned clk_cnt;
    disp_state_t disp_state;
    cmd_state_t  cmd_state;

    always_ff @(posedge clk or negedge reset) begin
        if (~reset) begin
            // reset internal logic
            i          <= 0;
            clk_cnt    <= 0;
            disp_state <= STATE_INIT_VCC_RISE;
            ascii_angle[0] <= 8'b0011_0011;
            ascii_angle[1] <= 8'b0011_0110;
            ascii_angle[2] <= 8'b0011_0000;
            ascii_angle[3] <= 8'b1101_1111;

            // set default state for module io
            {e, rs, rw, data} <= 11'b0;
            busy              <= 1'b1;
        end
        else begin
            clk_cnt <= clk_cnt + 1; // increment count on clk posedge
                
            // initialization sequence according to Winstar Display Co. for component WH1602B-NYG-JT
            // initialization sequence continues from STATE_INIT_VCC_RISE to STATE_INIT_SET_ENTRY
            case (disp_state)
                // waiting 40ms for vcc to rise to 4.5V and send first function set command
                STATE_INIT_VCC_RISE: begin
                    if (clk_cnt >= t_15000us) begin
                        clk_cnt    <= 0;
                        disp_state <= STATE_INIT_SET_FUNC1;
                    end
                end
                // send second function set command (set 8 bit mode, 2 line, and 5x8 font)
                STATE_INIT_SET_FUNC1: begin
                    case (cmd_state)
                        CMD_STATE_WRITE: begin
                            {e, rs, rw, data} <= {3'b100, CMD_FUNC_SET};
                            cmd_state         <= CMD_STATE_HOLD;
                        end
                        CMD_STATE_HOLD: begin
                            if (clk_cnt >= t_200ns) begin
                                e         <= 1'b0;
                                cmd_state <= CMD_STATE_DELAY;
                            end
                        end
                        CMD_STATE_DELAY: begin
                            if (clk_cnt >= t_39us) begin
                                clk_cnt    <= 0;
                                disp_state <= STATE_INIT_SET_FUNC2;
                                cmd_state <= CMD_STATE_WRITE;
                            end
                        end
                    endcase
                end
                STATE_INIT_SET_FUNC2: begin
                    case (cmd_state)
                        CMD_STATE_WRITE: begin
                            {e, rs, rw, data} <= {3'b100, CMD_FUNC_SET};
                            cmd_state         <= CMD_STATE_HOLD;
                        end
                        CMD_STATE_HOLD: begin
                            if (clk_cnt >= t_200ns) begin
                                e         <= 1'b0;
                                cmd_state <= CMD_STATE_DELAY;
                            end
                        end
                        CMD_STATE_DELAY: begin
                            if (clk_cnt >= t_39us) begin
                                clk_cnt    <= 0;
                                disp_state <= STATE_INIT_DISP_ON;
                                cmd_state <= CMD_STATE_WRITE;
                            end
                        end
                    endcase
                end
                // send command to enable display (and cursor appearance)
                STATE_INIT_DISP_ON: begin
                    case (cmd_state)
                        CMD_STATE_WRITE: begin
                            {e, rs, rw, data} <= {3'b100, CMD_DISP_CTRL};
                            cmd_state         <= CMD_STATE_HOLD;
                        end
                        CMD_STATE_HOLD: begin
                            if (clk_cnt >= t_200ns) begin
                                e         <= 1'b0;
                                cmd_state <= CMD_STATE_DELAY;
                            end
                        end
                        CMD_STATE_DELAY: begin
                            if (clk_cnt >= t_39us) begin
                                clk_cnt    <= 0;
                                disp_state <= STATE_INIT_DISP_CLR;
                                cmd_state <= CMD_STATE_WRITE;
                            end
                        end
                    endcase
                end
                // send command to clear display
                STATE_INIT_DISP_CLR: begin
                    case (cmd_state)
                        CMD_STATE_WRITE: begin
                            {e, rs, rw, data} <= {3'b100, CMD_CLR_DISP};
                            cmd_state         <= CMD_STATE_HOLD;
                        end
                        CMD_STATE_HOLD: begin
                            if (clk_cnt >= t_200ns) begin
                                e         <= 1'b0;
                                cmd_state <= CMD_STATE_DELAY;
                            end
                        end
                        CMD_STATE_DELAY: begin
                            if (clk_cnt >= t_39us) begin
                                clk_cnt    <= 0;
                                disp_state <= STATE_INIT_SET_ENTRY;
                                cmd_state  <= CMD_STATE_WRITE;
                            end
                        end
                    endcase
                end
                // send command to set entry mode (increment/decrement cursor and display shift on/off)
                STATE_INIT_SET_ENTRY: begin
                    case (cmd_state)
                        CMD_STATE_WRITE: begin
                            {e, rs, rw, data} <= {3'b100, CMD_ENTRY_MODE};
                            cmd_state         <= CMD_STATE_HOLD;
                        end
                        CMD_STATE_HOLD: begin
                            if (clk_cnt >= t_200ns) begin
                                e         <= 1'b0;
                                cmd_state <= CMD_STATE_DELAY;
                            end
                        end
                        CMD_STATE_DELAY: begin
                            if (clk_cnt >= t_39us) begin
                                clk_cnt    <= 0;
                                disp_state <= STATE_READY;
                                cmd_state <= CMD_STATE_WRITE;
                            end
                        end
                    endcase
                end
                STATE_READY: begin
                    clk_cnt    <= 0;
                    disp_state <= STATE_READ_DATA;
                end
                STATE_PAUSE: begin
                    if (clk_cnt >= 50000000) begin
                        clk_cnt    <= 0;
                        disp_state <= STATE_DISP_CLR;
                    end
                end
                STATE_DISP_CLR: begin
                    case (cmd_state)
                        CMD_STATE_WRITE: begin
                            {e, rs, rw, data} <= {3'b100, CMD_CLR_DISP};
                            cmd_state         <= CMD_STATE_HOLD;
                        end
                        CMD_STATE_HOLD: begin
                            if (clk_cnt >= t_200ns) begin
                                e         <= 1'b0;
                                cmd_state <= CMD_STATE_DELAY;
                            end
                        end
                        CMD_STATE_DELAY: begin
                            if (clk_cnt >= t_1530us) begin
                                i          <= 0;
                                clk_cnt    <= 0;
                                disp_state <= STATE_READY;
                                cmd_state <= CMD_STATE_WRITE;
                            end
                        end
                    endcase
                end
                STATE_READ_DATA: begin
                    case (cmd_state)
                        CMD_STATE_WRITE: begin
                            {e, rs, rw, data} <= {3'b110, ascii_angle[i]};
                            cmd_state         <= CMD_STATE_HOLD;
                        end
                        CMD_STATE_HOLD: begin
                            if (clk_cnt >= t_200ns) begin
                                e         <= 1'b0;
                                cmd_state <= CMD_STATE_DELAY;
                            end
                        end
                        CMD_STATE_DELAY: begin
                            if (clk_cnt >= t_1530us) begin
                                i          <= i + 1;
                                clk_cnt    <= 0;
                                cmd_state <= CMD_STATE_WRITE;
                                if (i < 4)
                                    disp_state <= STATE_READY;
                                else
                                    disp_state <= STATE_PAUSE;
                            end
                        end
                    endcase
                end
            endcase
        end
    end

endmodule
/*

            // initialization sequence according to Winstar Display Co. for component WH1602B-NYG-JT
            // initialization sequence continues from STATE_INIT_VCC_RISE to STATE_INIT_SET_ENTRY
            case (disp_state)
                // waiting 40ms for vcc to rise to 4.5V and send first function set command
                STATE_INIT_VCC_RISE: begin
                    if (clk_cnt >= t_40000us) begin
                        if (send_cmd(CMD_FUNC_SET, clk_cnt)) begin
                            clk_cnt    <= 0;
                            disp_state <= STATE_INIT_SET_FUNC1;
                        end
                    end
                end
                // send second function set command (set 8 bit mode, 2 line, and 5x8 font)
                STATE_INIT_SET_FUNC1: begin
                    if (send_cmd(CMD_FUNC_SET, clk_cnt)) begin
                        clk_cnt    <= 0;
                        disp_state <= STATE_INIT_SET_FUNC2;
                    end
                end
                STATE_INIT_SET_FUNC2: begin

                end
                // send command to enable display (and cursor appearance)
                STATE_INIT_DISP_ON: begin
                    if (send_cmd(CMD_DISP_CTRL, clk_cnt)) begin
                        clk_cnt    <= 0;
                        disp_state <= STATE_INIT_DISP_CLR;
                    end
                end
                // send command to clear display
                STATE_INIT_DISP_CLR: begin
                    if (send_cmd(CMD_CLR_DISP, clk_cnt)) begin
                        clk_cnt    <= 0;
                        disp_state <= STATE_INIT_SET_ENTRY;
                    end
                end
                // send command to set entry mode (increment/decrement cursor and display shift on/off)
                STATE_INIT_SET_ENTRY: begin
                    if (send_cmd(CMD_ENTRY_MODE, clk_cnt)) begin
                        clk_cnt    <= 0;
                        disp_state <= STATE_READY;
                    end
                end
                STATE_READY: begin
                    if (clk_cnt >= 5000) begin
                        clk_cnt    <= 0;
                        disp_state <= STATE_READ_DATA;
                    end
                end
                STATE_PAUSE: begin
                    if (clk_cnt >= 50000000) begin
                        clk_cnt    <= 0;
                        disp_state <= STATE_DISP_CLR;
                    end
                end
                STATE_PAUSE2: begin
                    if (clk_cnt >= 50000000) begin
                        clk_cnt    <= 0;
                        disp_state <= STATE_DISP_CLR2;
                    end
                end
                STATE_DISP_CLR: begin
                    if (send_cmd(CMD_CLR_DISP, clk_cnt)) begin
                        i          <= 0;
                        clk_cnt    <= 0;
                        disp_state <= STATE_READY;
                    end
                end
                STATE_DISP_CLR2: begin
                    if (send_cmd(CMD_CLR_DISP, clk_cnt)) begin
                        i          <= 0;
                        clk_cnt    <= 0;
                        disp_state <= STATE_READY;
                    end
                end
                STATE_READ_DATA: begin
                    if (send_ascii(ascii_angle[i], clk_cnt)) begin
                        i = i + 1;
                        clk_cnt <= 0;
                        disp_state <= STATE_READY;
                        if (i == 4) begin
                            disp_state <= STATE_PAUSE;
                        end
                    end
                end
                STATE_READ_DATA2: begin
                    if (send_ascii(ascii_angle[i], clk_cnt)) begin
                        i = i + 1;
                        clk_cnt <= 0;
                        disp_state <= STATE_READY;
                        if (i == 4) begin
                            disp_state <= STATE_PAUSE;
                        end
                    end
                end
            endcase
            */