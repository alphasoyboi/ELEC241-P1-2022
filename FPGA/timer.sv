module timer #(parameter int unsigned clk_cycles = 1)(output logic done, input logic clk, start, reset);

        typedef enum int unsigned { READY = 1, COUNTING, STOPPED } state_t;

        state_t state, next_state;
        int unsigned count;

        always_comb begin : next_state_logic
            //next_state = state;

            case (state) 
                READY:    next_state = (start == 1) ? COUNTING : READY;
                COUNTING: next_state = (count == clk_cycles) ? STOPPED : COUNTING;
                STOPPED:  next_state = (start == 0) ? READY : STOPPED;
                default:  next_state = READY;
            endcase
        end

        always_comb begin : output_logic
            if (state == STOPPED)
                done = 1;
            else
                done = 0;
        end

        always_ff @(posedge clk or negedge reset) begin : update_state
            if (~reset)
                state <= READY;
            else
                state <= next_state;
        end

        always_ff @(posedge clk or negedge reset) begin : update_count
            if (~reset)
                count <= 0;
            else begin
                if (state == COUNTING)
                    count <= count + 1;
                else
                    count <= 0;
            end
        end

endmodule