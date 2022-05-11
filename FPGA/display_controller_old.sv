module display_controller(
   output logic [7:0] data,
   output logic rs,
   output logic rw,
   output logic e,
   output logic busy
   input logic [7:0] ascii_data,
   input logic write,
   input logic clk
   input logic reset);

    typedef enum {
        S0, // waiting for vcc rise
        S1, // set 
        S2,
        S3,
        S4,
    } disp_state_t;

    disp_state_t disp_state;
    int unsigned clk_count;
    
    always_ff @(posedge clk or negedge reset) begin
        if (~reset) begin
            disp_state <= 1;
            clk_count  <= 0;

            // tell controller the display is in setup phase
            busy <= 1'b1;

            // set all lcd control pins to known state
            data <= 8'b0000_0000;
            rs   <= 0'b0;
            rw   <= 0'b0;
            e    <= 0'b0;
        end
        else begin
            clk_count <= clk_count + 1;
        end

        case (disp_state)
            S0: begin // function set
                if (clk_count == 2500000)
                    {e, data} <= 11'b1_00110000;
                else if (clk_count == 2500010)
                    e <= 0;
                else if (clk_count == 3000000)
                    {e, data} <= 11'b1_00110000;
                else if (clk_count == 3000010) begin
                    e <= 0;

                    disp_state <= S1;
                    clk_count  <= 0;
                end
            end
            S1: begin // display control set
                if (clk_count == 500000)
                    {e, data} <= 11'b1_00001100;
                else if (clk_count == 500010) begin
                    e <= 0;

                    disp_state <= S2;
                    clk_count  <= 0;
                end
            end
            S2: begin // display clear
                if (clk_count == 500000)
                    {e, data} <= 11'b1_00000001;
                else if (clk_count == 500010)
                    e <= 0;

                    disp_state <= S3;
                    clk_count  <= 0;
                end
            end
            S3: begin // display clear
                if (clk_count == 500000)
                    {e, data} <= 11'b1_00000100;
                else if (clk_count == 500010)
                    e <= 0;

                    disp_state <= S4;
                    clk_count  <= 0;
                end
            end
        endcase
            
    end

   
endmodule
   
