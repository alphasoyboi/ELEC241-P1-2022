module timer_tb;

    logic done, clk, start, reset;
    timer #(2) t (done, clk, start, reset);

    initial begin
        int unsigned i;

        reset = 1;
        #10ps;
        reset = 0;
        #10ps;
        reset = 1;
        
        start = 1;
        for (i = 0; i < 3; i = i + 1) begin
            clk = 1;
            #10ps;
            clk = 0;
            #10ps;
        end
        assert (done)
            $display("counter finished");
    end

endmodule