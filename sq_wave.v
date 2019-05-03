module sq_wave (
	input clk,
	input [per_bits - 1 : 0] period,
	input [per_bits - 1 : 0] ed1,
	output wv
);

parameter per_bits = 32;

integer counter;

always @(posedge clk) begin
	if (counter < period) counter <= counter + 1;
	else counter <= 0;
end

assign wv = (counter >= ed1 && counter <= period);

endmodule	
	