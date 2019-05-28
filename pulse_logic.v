/* Parameterized pulse generator logic module. 
	Takes clock, initial state, period and array of edges. 
	Edges have following format (MSB to LSB): 
		1 bit: On/off enable
		log2(max channels) bits: Channel number 
		Countbits: Change in edge value (in clk cycles)
		Countbits: Edge value (in clk cycles)
	Outputs N channel pulse wvfm. 
	
	Author  : Matthew Chow
	email : matthewnchow@berkeley.edu
	Worked in simulation as of 5/10/2019
	*/
	
module pulse_logic (reset, clk, period, outer_period, state0, eds, state, trig_out);

	// Can be passed down to modify size of inputs and outputs
	parameter COUNT_BITS = 32; // Must be >= 1
	parameter CH_LOG2 = 3; // Must be >= 0
	parameter ED_MAX = 255;
		
	// Internals
	localparam CH_MAX = 8'b0000_0001 << CH_LOG2; //8 for testing
	localparam ED_BITS = COUNT_BITS * 2 + CH_LOG2 + 1; //68 bits if default parameters

	// IO
	input								reset;
	input								clk;
	input		signed [31 : 0] 	period;
	input		signed [31 : 0]	outer_period;
	input				 [7 : 0]		state0;
	input 			[68*ED_MAX - 1 : 0] 	eds;
	output 			[7 : 0] 		state;
	output  							trig_out;
	
	// Counter that restarts at period, with outer counter that rolls restarts at big period
	reg signed [COUNT_BITS - 1 : 0] count = 0; 
	reg signed [COUNT_BITS - 1 : 0] outer_count = 0; 

	// Nested, clocked counters with synchronous reset
	always @(posedge clk) begin
		if (reset) begin
			count <= 0;
			outer_count <= 0;
		end 
		else begin 
			if (count >= period - 1'b1) begin
				count <= 0;
				if (outer_count >= outer_period - 1'b1) outer_count <= 0;
				else outer_count <= outer_count + 2'sd1;
			end 
			else count <= count + 2'sd1;
		end 
	end
	
	// Combinatorial logic, compare count to edge value. Uses ed_comp module for comparison of each edge
	genvar i;
	wire [ED_MAX * CH_MAX - 1 : 0] combo;
   generate
		for (i = 0; i < ED_MAX; i = i + 1) begin : ed_logic
			ed_comp #(.IN_BITS(COUNT_BITS), .OUT_BITS(CH_MAX), .OUT_BITS_LOG2(CH_LOG2)) ec(
							.count			(count),
							.outer_count	(outer_count),
							.x					(eds[(i * ED_BITS) + COUNT_BITS - 1 : (i * ED_BITS) + 0]),
							.dx				(eds[(i * ED_BITS) + (2 * COUNT_BITS) - 1 : (i * ED_BITS) + COUNT_BITS]),
							.ch_ID			(eds[((i + 1) * ED_BITS) - 2 : (i + 1) * ED_BITS - CH_LOG2 - 1]),
							.enable			(eds[((i + 1) * ED_BITS) - 1]),
							.out				(combo[(i+1) * CH_MAX - 1 : i * CH_MAX])
							);
		end 
	endgenerate 
	wire [CH_MAX - 1 : 0] temp; 
	nXOR #(.width(CH_MAX), .n(ED_MAX)) nXOR0 (.in(combo), .out(temp));
	assign  state = state0 ^ temp;
	
	assign  trig_out = (outer_count == 0 && count <= 5); //50 ns trig
	
endmodule
