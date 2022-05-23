module display_controller #(
    // delays in clock pulses
    parameter int unsigned cycles_100ms  = 5000000, // delay between writing new angle value to lcd
    parameter int unsigned cycles_40ms   = 2000000, // delay for vcc rise
    parameter int unsigned cycles_2ms    = 100000,  // delay for display clear
    parameter int unsigned cycles_43us   = 2150,    // delay for data register write
    parameter int unsigned cycles_39us   = 1950,    // delay for most instruction register writes
    parameter int unsigned cycles_1200ns = 60,      // write delay for enable pulse low
    parameter int unsigned cycles_140ns  = 7        // write delay for enable pulse high
)   (
    output logic [7:0] data,
    output logic rs,
    output logic rw,
    output logic e,
    input logic [31:0] angle,
    input logic clk,
    input logic n_reset
);

enum bit [7:0] {
    CMD_FUNC_SET   = 8'b0011_1000, // set 8 bit mode, 2 line display, and 5x8 font
    CMD_DISP_ON    = 8'b0000_1100, // turn display on, turn cursor and cursor blinking off
    CMD_CLR_DISP   = 8'b0000_0001, // clear the display
    CMD_ENTRY_MODE = 8'b0000_0110  // 
} cmd;

typedef enum int unsigned {
    S0 = 1, // waiting for vcc rise
    S1,     // func set 1
    S2,     // func set 2
    S3,     // disp on
    S4,     // disp clr
    S5,     // entry mode
    S6,     // ready
    S7,     // disp clr
    S8,     // data write
    S9      // pause
} state_t;

logic [11:0] bcd;
angle_to_bcd angle_converter(bcd, angle[11:0]);

int unsigned clk_cnt, ascii_index;
logic [7:0] ascii[3:0];
state_t state;

always_ff @(posedge clk or negedge n_reset) begin
    if (~n_reset) begin
        clk_cnt     <= 0;
        ascii_index <= 0;
        state       <= S0;

        {e, rs, rw, data} <= 11'b0;
    end
    else begin
        clk_cnt = clk_cnt + 1;

        case (state)
            S0: begin // vcc rise
                if (clk_cnt >= cycles_40ms) begin
                    clk_cnt <= 0;
                    state   <= S1;
                end
            end
            S1: begin // func set 1
                if (clk_cnt < cycles_140ns)
                    {e, rs, rw, data} <= {3'b100, CMD_FUNC_SET};
                else
                    e <= 0;
                if (clk_cnt >= cycles_39us + cycles_1200ns) begin
                    clk_cnt <= 0;
                    state   <= S2;
                end
            end
            S2: begin // func set 2
                if (clk_cnt < cycles_140ns)
                    {e, rs, rw, data} <= {3'b100, CMD_FUNC_SET};
                else
                    e <= 0;
                if (clk_cnt >= cycles_39us + cycles_1200ns) begin
                    clk_cnt <= 0;
                    state <= S3;
                end
            end
            S3: begin // display on
                if (clk_cnt < cycles_140ns)
                    {e, rs, rw, data} <= {3'b100, CMD_DISP_ON};
                else
                    e <= 0;
                if (clk_cnt >= cycles_39us + cycles_1200ns) begin
                    clk_cnt <= 0;
                    state <= S4;
                end
            end
            S4: begin // display clr
                if (clk_cnt < cycles_140ns)
                    {e, rs, rw, data} <= {3'b100, CMD_CLR_DISP};
                else
                    e <= 0;
                if (clk_cnt >= cycles_2ms + cycles_1200ns) begin
                    clk_cnt <= 0;
                    state <= S5;
                end
            end
            S5: begin // entry mode
                if (clk_cnt < cycles_140ns)
                    {e, rs, rw, data} <= {3'b100, CMD_ENTRY_MODE};
                else
                    e <= 0;
                if (clk_cnt >= cycles_39us + cycles_1200ns) begin
                    clk_cnt <= 0;
                    state <= S6;
                end
            end
            S6: begin // ready
                ascii[0] <= {4'b0011, bcd[11:8]};
                ascii[1] <= {4'b0011, bcd[7:4]};
                ascii[2] <= {4'b0011, bcd[3:0]};
                ascii[3] <= 8'b1101_1111;
                state <= S7;
            end
            S7: begin // display clr
                if (clk_cnt < cycles_140ns)
                    {e, rs, rw, data} <= {3'b100, CMD_CLR_DISP};
                else
                    e <= 0;
                if (clk_cnt >= cycles_2ms + cycles_1200ns) begin
                    clk_cnt <= 0;
                    state   <= S8;
                end
            end
            S8: begin // write data
                if (clk_cnt < cycles_140ns)
                    {e, rs, rw, data} <= {3'b110, ascii[ascii_index]};
                else
                    e <= 0;
                if (clk_cnt >= cycles_43us + cycles_1200ns) begin
                    clk_cnt <= 0;
                    ascii_index <= ascii_index + 1;
                    if (ascii_index == 3) begin
                        ascii_index <= 0;
                        state <= S9;
                    end
                end
            end
            S9: begin // pause
                if (clk_cnt >= cycles_100ms) begin
                    clk_cnt <= 0;
                    state   <= S6;
                end
            end
            default: begin
                clk_cnt     <= 0;
                ascii_index <= 0;
                state       <= S0;

                {e, rs, rw, data} <= 11'b0;
            end
        endcase
    end
end

endmodule