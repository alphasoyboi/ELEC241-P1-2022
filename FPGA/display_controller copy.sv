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

enum bit [7:0] {
    CMD_FUNC_SET   = 8'b0011_1000, // set 8 bit mode, 2 line display, and 5x8 font
    CMD_DISP_ON    = 8'b0000_1100, // turn display on, turn cursor and cursor blinking off
    CMD_CLR_DISP   = 8'b0000_0001, //
    CMD_ENTRY_MODE = 8'b0000_0110  //
}en;

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

state_t state;

// timers
logic timer_done_40000us, timer_start_40000us;
logic timer_done_1530us, timer_start_1530us;
logic timer_done_43us, timer_start_43us;
logic timer_done_39us, timer_start_39us;
logic timer_done_1s, timer_start_1s;
timer #(cycles_40000us) timer_40000us (timer_done_40000us, timer_done_40000us, clk,  n_reset);
timer #(cycles_1530us) timer_1530us (timer_done_1530us, timer_start_1530us, clk, n_reset);
timer #(cycles_43us) timer_43us (timer_done_43us, timer_start_43us, clk, n_reset);
timer #(cycles_39us) timer_39us (timer_done_39us, timer_start_39us, clk, n_reset);
timer #(50000000) timer_1s (timer_done_1s, timer_start_1s, clk, n_reset);

bit data_written; 
logic [7:0] bus_data;
logic bus_write, bus_ir_dr, bus_busy;
display_data_bus_controller bus (data, rs, rw, e, bus_busy, bus_data, bus_write, bus_ir_dr, clk, n_reset);

logic [11:0] bcd;
angle_to_bcd angle_converter(bcd, angle);

logic [7:0] ascii[3:0];
int unsigned ascii_index;

always_ff @(posedge clk or negedge n_reset) begin
    if (~n_reset) begin
        state        <= S0;
        data_written <= 0;
        ascii_index  <= 0;
        ascii <= '{8'b0011_0011, 8'b0011_0110, 8'b0011_0000, 8'b1101_1111}; 

        {bus_write, bus_ir_dr, bus_data} <= 10'b0;
    end
    else begin
        case (state)
            S0: begin // vcc rise
                timer_start_40000us <= 1'b1;
                if (timer_done_40000us) begin
                    timer_start_40000us <= 1'b0;
                    state <= S1;
                end
            end
            S1: begin // func set 1
                if (~data_written && ~bus_busy) begin
                    {bus_write, bus_ir_dr, bus_data} <= {2'b11, CMD_FUNC_SET};
                    data_written <= 1'b1;
                end
                else begin
                    {bus_write, bus_ir_dr, bus_data} <= 10'b0;
                    timer_start_39us <= 1'b1;
                    if (timer_done_39us) begin
                        timer_start_39us <= 1'b0;
                        data_written <= 1'b0;
                        state <= S2;
                    end
                end
            end
            S2: begin // func set 2
                if (~data_written && ~bus_busy) begin
                    {bus_write, bus_ir_dr, bus_data} <= {2'b11, CMD_FUNC_SET};
                    data_written <= 1'b1;
                end
                else begin
                    {bus_write, bus_ir_dr, bus_data} <= 10'b0;
                    timer_start_39us <= 1'b1;
                    if (timer_done_39us) begin
                        timer_start_39us <= 1'b0;
                        data_written <= 1'b0;
                        state <= S3;
                    end
                end
            end
            S3: begin // display on
                if (~data_written && ~bus_busy) begin
                    {bus_write, bus_ir_dr, bus_data} <= {2'b11, CMD_DISP_ON};
                    data_written <= 1'b1;
                end
                else begin
                    {bus_write, bus_ir_dr, bus_data} <= 10'b0;
                    timer_start_39us <= 1'b1;
                    if (timer_done_39us) begin
                        timer_start_39us <= 1'b0;
                        data_written <= 1'b0;
                        state <= S4;
                    end
                end
            end
            S4: begin // display clr
                if (~data_written && ~bus_busy) begin
                    {bus_write, bus_ir_dr, bus_data} <= {2'b11, CMD_CLR_DISP};
                    data_written <= 1'b1;
                end
                else begin
                    {bus_write, bus_ir_dr, bus_data} <= 10'b0;
                    timer_start_1530us <= 1'b1;
                    if (timer_done_1530us) begin
                        timer_start_1530us <= 1'b0;
                        data_written <= 1'b0;
                        state <= S5;
                    end
                end
            end
            S5: begin // entry mode
                if (~data_written && ~bus_busy) begin
                    {bus_write, bus_ir_dr, bus_data} <= {2'b11, CMD_ENTRY_MODE};
                    data_written <= 1'b1;
                end
                else begin
                    {bus_write, bus_ir_dr, bus_data} <= 10'b0;
                    timer_start_39us <= 1'b1;
                    if (timer_done_39us) begin
                        timer_start_39us <= 1'b0;
                        data_written <= 1'b0;
                        state <= S6;
                    end
                end
            end
            S6: begin // ready
                state <= S7;
            end
            S7: begin // display clr
                if (~data_written && ~bus_busy) begin
                    {bus_write, bus_ir_dr, bus_data} <= {2'b11, CMD_CLR_DISP};
                    data_written <= 1'b1;
                end
                else begin
                    {bus_write, bus_ir_dr, bus_data} <= 10'b0;
                    timer_start_1530us <= 1'b1;
                    if (timer_done_1530us) begin
                        timer_start_1530us <= 1'b0;
                        data_written <= 1'b0;
                        state <= S8;
                    end
                end
            end
            S8: begin // write data
                if (~data_written && ~bus_busy) begin
                    {bus_write, bus_ir_dr, bus_data} <= {2'b10, ascii[ascii_index]};
                    data_written <= 1'b1;
                end
                else begin
                    {bus_write, bus_ir_dr, bus_data} <= 10'b0;
                    timer_start_43us <= 1'b1;
                    if (timer_done_43us) begin
                        timer_start_43us <= 1'b0;
                        data_written <= 1'b0;
                        if (ascii_index < 4) begin
                            ascii_index <= ascii_index + 1;
                            state <= S8;
                        end
                        else begin
                            ascii_index <= 0;
                            state <= S9;
                        end
                    end
                end
            end
            S9: begin // pause
                timer_start_1s <= 1'b1;
                if (timer_done_1s) begin
                    timer_start_1s <= 1'b0;
                    state <= S6;
                end
            end
            default: begin
                state <= S0;
                data_written <= 0;
                ascii_index <= 0;
            end
        endcase
    end
end

always_comb begin
    if (state == S6)
        busy = 0;
    else
        busy = 1;
end

endmodule