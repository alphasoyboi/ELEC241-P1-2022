module interface_controller(output [15:0] outgoingData, output [31:0] incomingData, input [31:0] statusReg, input [15:0] spi_data, input readBusy, writeBusy, clk);

logic [31:0] inDat = 32'd0;
logic [15:0] outDat = 16'd0;
logic [12:0] desiredAngle, data;
logic [3:0] controls;

//delay is for testing purposes only
assign #(10ps) outgoingData = outDat;
assign #(10ps) incomingData = inDat;

always_ff @(posedge writeBusy, posedge clk) begin
	if(writeBusy == 1'b1)
		outDat = outDat;
	else begin
		outDat[11:0] = statusReg[11:0];
	end
end

always_ff @(negedge readBusy) begin
	{controls, data} = spi_data;
	if(controls == 2'd2)
		inDat[11:0] = data;
	else if(controls == 2'd3)
		inDat[19:12] = data[7:0];
	else if(controls == 2'd4)
		inDat[28:27] = data[1:0];
	else if(controls == 2'd5)
		inDat[30:29] = data[1:0];
	else if(controls == 2'd6)
		inDat[31] = data[0];
end

endmodule