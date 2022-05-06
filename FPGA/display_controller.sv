module display_controller #(
    parameter int unsigned t_41000us = 2050000, // delay for vcc rise
    parameter int unsigned t_154us   = 77000,   // delay for display clear
    parameter int unsigned t_40us    = 2000,    // delay for most commands
    parameter int unsigned t_1200ns  = 60,      // write delay for enable cycle
    parameter int unsigned t_140ns   = 7,       // write delay for enable pulse width
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

    typedef enum {
        DISP_VCC_RISE,   // 41ms  waiting for vcc rise
        DISP_FUNC_SET,   // 40us  set 
        DISP_CUR_MODE,   // 40us  
        DISP_CLR,        // 154us 
        DISP_ENTRY_MODE, // 
        DISP_READY,      // 
        DISP_BUSY        // 
    } disp_state_t;

    typedef enum {
        BUSY
    } ctrl_state_t;

    /*
    function ctrl_state_t write_cmd (int unsigned clk_cnt, delay, logic e)
        {e, data} <= 9'b1_0011_1000;
        if (clk_cnt >= delay) begin

    endfunction;
    */

    disp_state_t disp_state;
    int unsigned clk_cnt;

    always_ff @(posedge clk or negedge reset) begin
        if (~reset) begin
            clk_cnt    <= 0;
            disp_state <= DISP_VCC_RISE;

            {e, rs, rw, data} <= 12'b0;
            busy              <= 1'b1;
        end
        else begin
            clk_cnt <= clk_cnt + 1;
                
            case (disp_state)
                DISP_VCC_RISE: begin
                    if (clk_cnt >= t_41000us) begin
                        {e, data} <= 9'b1_0011_1000;
                        if (clk_cnt >= (t_41000us + t_140ns)) begin
                            e <= 0;

                            clk_cnt    <= 0;
                            disp_state <= DISP_FUNC_SET;
                        end
                    end
                end
                DISP_FUNC_SET: begin
                    if (clk_cnt >= (t_40us)) begin
                        {e, data} <= 9'b1_0011_1000;
                        if (clk_cnt >= (t_40us + t_140ns)) begin
                            e <= 0;

                            clk_cnt    <= 0;
                            disp_state <= DISP_CUR_MODE;
                        end
                    end
                end
                DISP_CUR_MODE: begin
                    if (clk_cnt >= t_40us) begin
                        {e, data} <= 9'b1_0000_1111;
                        if (clk_cnt >= (t_40us + t_140ns)) begin
                            e <= 0;

                            clk_cnt    <= 0;
                            disp_state <= DISP_CLR;
                        end
                    end
                end
                DISP_CLR: begin
                    if (clk_cnt >= t_40us) begin
                        {e, data} <= 9'b1_0000_0001;
                        if (clk_cnt >= (t_40us + t_140ns)) begin
                            e <= 0;

                            clk_cnt    <= 0;
                            disp_state <= DISP_ENTRY_MODE;
                        end
                    end
                end
                DISP_ENTRY_MODE: begin
                    if (clk_cnt >= t_154us) begin
                        {e, data} <= 9'b1_0000_0100;
                        if (clk_cnt >= (t_154us + t_140ns)) begin
                            e <= 0;

                            clk_cnt    <= 0;
                            disp_state <= DISP_READY;
                        end
                    end
                end
                DISP_READY: disp_state <= DISP_BUSY;
                DISP_BUSY: disp_state <= DISP_READY;
            endcase
        end
    end

endmodule
