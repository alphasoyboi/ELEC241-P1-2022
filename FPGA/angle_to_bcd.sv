module angle_to_bcd (output logic [11:0] bcd, input logic [11:0] angle);

    int unsigned deg, i;
    bit [8:0] bin;
    always_comb begin
        deg = (359 * angle) / 1006;
        bin = deg;
        bcd = 0;

        // double dabble algorithm
        // iterate once for each bit in binary angle value
        for (i = 0; i < 9; i = i + 1) begin
            // if any bcd digit is >= 5 then add 3
            if (bcd[3:0]  >= 5) bcd[3:0]  = bcd[3:0]  + 3; 
            if (bcd[7:4]  >= 5) bcd[7:4]  = bcd[7:4]  + 3;
            if (bcd[11:8] >= 5) bcd[11:8] = bcd[11:8] + 3;
            // shift one bit and shift in msb from angle 
            bcd = {bcd[10:0], bin[8 - i]};
        end
    end

endmodule