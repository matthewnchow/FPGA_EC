/* Unclocked XOR that takes a flattened 2D array and performs XOR over each column
   Logic verified 4/18/19 by Matthew Chow*/

module nXOR(
	input [width*n - 1 : 0] in,
	output [width - 1 : 0] out
);

parameter width = 1;
parameter n = 1;

wire [n - 1 : 0] twoD [width - 1 : 0];
wire [width - 1 : 0] result;

genvar i;
generate 
	for (i = 0; i < n * width; i = i + 1) begin : unflatten
		assign twoD[i % width][i / width] = in[i];
	end
endgenerate

genvar j;
generate 
	for (j = 0; j < width; j = j + 1) begin : rowXOR
		assign result[j] = ^twoD[j];
	end
endgenerate

assign out = result;

endmodule 
