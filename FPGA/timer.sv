module timer #(int unsigned cycles = 1) (output logic done, input logic start, clk, n_reset);

        typedef enum int unsigned { READY = 1, COUNTING, STOPPED } state_t;

        state_t state, next_state;
        int unsigned count;

        always_comb begin : next_state_logic
            case (state) 
                READY:    next_state = (start == 1) ? COUNTING : READY;
                COUNTING: next_state = (count == cycles) ? STOPPED : COUNTING;
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

        always_ff @(posedge clk or negedge n_reset) begin : update_state
            if (~n_reset)
                state <= READY;
            else
                state <= next_state;
        end

        always_ff @(posedge clk or negedge n_reset) begin : update_count
            if (~n_reset)
                count <= 0;
            else begin
                if (state == COUNTING)
                    count <= count + 1;
                else
                    count <= 0;
            end
        end

endmodule