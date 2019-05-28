// signed comparator, shifts answer over by ch_ID

module ed_comp(count, outer_count, x, dx, ch_ID, enable, out);
	
	parameter IN_BITS = 32;
	parameter OUT_BITS = 8;
	parameter OUT_BITS_LOG2 = 3; //need to pass down one greater than log2 if not power of two
	
	input signed [IN_BITS-1 : 0] count;
	input signed [IN_BITS-1 : 0] outer_count;
	input signed [IN_BITS-1 : 0] x;
	input signed [IN_BITS-1 : 0] dx;
	input 		 [OUT_BITS_LOG2 - 1 : 0] ch_ID;
	input							  		  enable;
	output 		 [OUT_BITS - 1 : 0] out;

	wire result = enable & (count >= (x) + (dx * outer_count)); //
	assign out = ({{(OUT_BITS - 1){1'b0}},result} << ch_ID);

endmodule 
