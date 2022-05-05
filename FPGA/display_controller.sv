module display_controller #(
    parameter int unsigned t_41000us = 2050000, // delay for vcc rise
    parameter int unsigned t_154us   = 77000,   // delay for display clear
    parameter int unsigned t_40us    = 2000,    // delay for most commands
    parameter int unsigned t_1200ns  = 60,      // read/write delay for enable cycle
    parameter int unsigned t_140ns   = 7,       // read/write delay for enable pulse width
    parameter int unsigned t_100ns   = 5        // read/write delay for data delay time
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
        DISP_VCC_RISE,   // waiting for vcc rise
        DISP_FUNC_SET,   // set 
        DISP_CUR_MODE,   // 
        DISP_CLR,   // 
        DISP_ENTRY_MODE, // 
        DISP_READY,      // 
        DISP_BUSY        // 
    } disp_state_t;

    typedef enum {
        BUSY
    } ctrl_state_t;
/*
    function ctrl_state_t write_cmd (logic rs, rw, e)

    endfunction;
*/
    disp_state_t disp_state;
    int unsigned clk_cnt;
    bit reset_clk_cnt;

    // clock counting and reset conditions
    always_ff @(posedge clk or negedge reset) begin
        if (~reset) begin
            //{e, rs, rw, data} <= 11'b0;
            //busy <= 1'b1;
            //disp_state <= DISP_VCC_RISE;
            clk_cnt <= 0;
		end
        else 
            clk_cnt <= clk_cnt + 1;
    end

    // display state machine
    always_ff @(posedge clk or negedge reset) begin
        case (disp_state)
            DISP_VCC_RISE: begin
                if (clk_cnt >= t_41000us) begin
                    //{e, data} <= 9'b0_0011_1100;
                    if (clk_cnt >= (t_41000us + t_140ns)) begin
                        e <= 0;
                        if (clk_cnt >= (t_41000us + t_1200ns)) begin
                            disp_state <= DISP_FUNC_SET;
                            //clk_cnt <= 0;
                        end
                    end
                end
			end
            DISP_FUNC_SET: disp_state <= DISP_CUR_MODE;
            DISP_CUR_MODE: disp_state <= DISP_CLR;
            DISP_CLR: disp_state <= DISP_ENTRY_MODE;
            DISP_ENTRY_MODE: disp_state <= DISP_READY;
            DISP_READY: disp_state <= DISP_BUSY;
            DISP_BUSY: disp_state <= DISP_READY;
        endcase
    end

    /*
    always_ff @(posedge clk or negedge reset) begin
        if (reset == 1'b0) begin
            disp_state <= S0;
            clk_count  <= 0;

            // tell controller the display is in setup phase
            busy <= 1'b1;

            // set all lcd control pins to known state
            {e, rs, rw, data} <= 11'b0_00_0000_0000;
        end
        else
            clk_count <= clk_count + 1;

        case (disp_state)
            S0: begin // function set
                if (clk_count == 2500000)
                    {e, data} <= 9'b1_00110000;
                else if (clk_count == 2500010)
                    e <= 0;
                else if (clk_count == 3000000)
                    {e, data} <= 9'b1_00110000;
                else if (clk_count == 3000010) begin
                    e <= 0;

                    disp_state <= S1;
                    clk_count  <= 0;
                end
            end
            S1: begin // display control set
                if (clk_count == 500000)
                    {e, data} <= 9'b1_00001100;
                else if (clk_count == 500010) begin
                    e <= 0;

                    disp_state <= S2;
                    clk_count  <= 0;
                end
            end
            S2: begin // display clear
                if (clk_count == 500000)
                    {e, data} <= 9'b1_00000001;
                else if (clk_count == 500010) begin
                    e <= 0;

                    disp_state <= S3;
                    clk_count  <= 0;
                end
            end
            S3: begin // display clear
                if (clk_count == 500000)
                    {e, data} <= 9'b1_00000100;
                else if (clk_count == 500010) begin
                    e <= 0;

                    disp_state <= S4;
                    clk_count  <= 0;
                end
            end
        endcase
            
    end

*/   
endmodule
