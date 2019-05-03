/* Parameterized pulse generator logic module. 
	Takes clock, initial state, period and array of edges. 
	Edges have following format: 
		1 bit: On/off
		log2(max channels) bits: Channel number 
		Countbits: Edge value (in clk cycles)
		Countbits: Change in edge value (in clk cycles)
	Outputs N channel pulse wvfm. */
module pulse_logic (
	input 											reset,
	input 											clk,
	input		[COUNT_BITS - 1 : 0] 			period,
	input 	[COUNT_BITS - 1 : 0]				outer_period,
	input	 	[CH_MAX - 1 : 0] 					state0,
	input 	[ED_BITS * ED_MAX - 1 : 0] 	eds,
	output 	[CH_MAX - 1 : 0] 					state
	);

	// Can be passed down to modify size of inputs and outputs
	parameter COUNT_BITS = 32; // Must be >= 1
	parameter CH_LOG2 = 3; // Must be >= 0
	parameter ED_MAX = 100;
	
	// Internals
	localparam CH_MAX = 8'b0000_0001 << CH_LOG2; //Maximum of 128 channels
	localparam ED_BITS = COUNT_BITS * 2 + 1;
	
	// Counter that restarts at period, with outer counter that rolls restarts at big period
	reg signed [COUNT_BITS - 1 : 0] count; //Signed so that comparisons and math are clear later
	reg signed [COUNT_BITS - 1 : 0] outer_count; // Signed so that comparison and math are clear later
	always @(posedge clk) begin
		if (reset) begin
			count <= 0;
			outer_count <= 0;
		end 
		else begin 
			if (count >= period) begin
				count <= 0;
				outer_count <= outer_count + 1;
			end 
			else count <= count + 1;
			if (outer_count >= outer_period) outer_count <= 0;
		end 
	end
	
	// Combinatorial logic, compare count to edge value
	genvar i;
   generate
		wire [CH_MAX - 1 : 0] temp; 
		wire toggle; // On/off
		wire ch_id; // Channel ID bits
		wire signed [COUNT_BITS - 1 : 0] x; // Value
		wire signed [COUNT_BITS - 1 : 0] dx; // Change in value each time
		for (i = 0; i < ED_MAX; i = i + 1) begin : ed_logic
			assign toggle = eds[i*ED_BITS];
			assign ch_id = eds[i*ED_BITS + CH_LOG2 : i*ED_BITS + 1];
			assign x = eds[i*ED_BITS + CH_LOG2 + COUNT_BITS : i*ED_BITS + CH_LOG2 + 1];
			assign dx = eds[i*ED_BITS + CH_LOG2 + COUNT_BITS + COUNT_BITS : i*ED_BITS + COUNT_BITS + CH_LOG2 + 1];
			assign temp = temp ^ ({(CH_MAX){toggle}} 
									 & ((x + dx * outer_count >= count) << ch_id));
		end 
		assign state = state0 ^ temp;
	endgenerate 
	
endmodule
