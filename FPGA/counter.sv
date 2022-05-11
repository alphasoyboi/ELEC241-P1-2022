module counter (output int unsigned count, input logic clk, enable, reset);

    always_ff @(posedge clk or negedge reset) begin
        if (~reset)
            count <= 0;
        else begin
            if (enable)
                count <= count + 1;
            else
                count <= 0;
        end
    end

endmodule