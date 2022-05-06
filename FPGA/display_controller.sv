module display_controller #(
    // delays in clock pulses
    parameter int unsigned t_40000us = 2000000, // delay for vcc rise
    parameter int unsigned t_1530us  = 76500,   // delay for display clear
    parameter int unsigned t_39us    = 1950,    // delay for most other commands
    parameter int unsigned t_1200ns  = 60,      // write delay for enable cycle
    parameter int unsigned t_140ns   = 7        // write delay for enable pulse width
)   (
    output logic [7:0] data,
    output logic rs,
    output logic rw,
    output logic e,
    output logic busy,
    input logic [7:0] ascii_data,
    input logic write,
    input logic clk,
    input logic reset
);

    typedef enum bit [7:0] {
        CMD_CLR_DISP   = 8'b0000_0001, //
        CMD_RET_HOME   = 8'b0000_0010, //
        CMD_ENTRY_MODE = 8'b0000_0110, //
        CMD_DISP_CTRL  = 8'b0000_1111, // turn display on, turn cursor and cursor blinking off
        CMD_CUR_MODE   = 8'b0001_0000, // 
        CMD_FUNC_SET   = 8'b0011_1000  // set 8 bit mode, 2 line display, and 5x8 font
    } cmd_t;

    typedef enum {
        STATE_VCC_RISE,
        STATE_SETUP,
        STATE_DISP_ON,
        STATE_DISP_CLR,
        STATE_SET_ENTRY,
        STATE_READY,
        STATE_BUSY
    } disp_state_t;

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
            CMD_CUR_MODE,
            CMD_FUNC_SET: begin
                if (clk_cnt >= t_39us)
                    return 1'b1;
                else
                    return 1'b0;
            end
            default: return 1'b1;
        endcase
    endfunction

    disp_state_t disp_state;
    int unsigned clk_cnt;

    always_ff @(posedge clk or negedge reset) begin
        if (~reset) begin
            // reset internal logic
            clk_cnt    <= 0;
            disp_state <= STATE_VCC_RISE;

            // set default state for module io
            {e, rs, rw, data} <= 12'b0;
            busy              <= 1'b1;
        end
        else begin
            clk_cnt <= clk_cnt + 1; // increment count on clk posedge
                
            // initialization sequence according to Winstar Display Co. for component WH1602B-NYG-JT
            // initialization sequence continues from STATE_VCC_RISE to STATE_SET_ENTRY
            case (disp_state)
                // waiting 40ms for vcc to rise to 4.5V and send first function set command
                STATE_VCC_RISE: begin
                    if (clk_cnt >= t_40000us) begin
                        if (send_cmd(CMD_FUNC_SET, clk_cnt)) begin
                            clk_cnt    <= 0;
                            disp_state <= STATE_SETUP;
                        end
                    end
                end
                // send second function set command (set 8 bit mode, 2 line, and 5x8 font)
                STATE_SETUP: begin
                    if (send_cmd(CMD_FUNC_SET, clk_cnt)) begin
                        clk_cnt    <= 0;
                        disp_state <= STATE_DISP_ON;
                    end
                end
                // send command to enable display (and cursor appearance)
                STATE_DISP_ON: begin
                    if (send_cmd(CMD_DISP_CTRL, clk_cnt)) begin
                        clk_cnt    <= 0;
                        disp_state <= STATE_DISP_CLR;
                    end
                end
                // send command to clear display
                STATE_DISP_CLR: begin
                    if (send_cmd(CMD_CLR_DISP, clk_cnt)) begin
                        clk_cnt    <= 0;
                        disp_state <= STATE_SET_ENTRY;
                    end
                end
                // send command to set entry mode (increment/decrement cursor and display shift on/off)
                STATE_SET_ENTRY: begin
                    if (send_cmd(CMD_ENTRY_MODE, clk_cnt)) begin
                        clk_cnt    <= 0;
                        disp_state <= STATE_READY;

                        busy <= 1'b0;
                    end
                end
                STATE_READY: disp_state <= STATE_BUSY;
                STATE_BUSY: disp_state <= STATE_READY;
            endcase
        end
    end

endmodule
