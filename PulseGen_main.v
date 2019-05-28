// Main processor that handles UART communication and instantiates all modules.

module PulseGen_main (

	// Communication and processing clock (50M)
	input sys_clk,

	// RS232 communication lines
	input rx,
	output tx,
	
	// Pulse clock input (100M)
	input pulse_base_clk,
	
	// User electrical IO
	input trig_in,
	output trig_out,
	output [CH_MAX - 1 : 0] wvfm,
	
	output reg [67:0] test_ed,
	output reg [28:0] test_per,
	output pulse_clk_out,
	
	output [3 : 0] debug
	
);

//////////////////////Clock Generation/////////////////////////////////////
wire pulse_clk;
wire PLL_locked;
assign pulse_clk = pulse_base_clk;
//PLL250M_125M PLL250M_125M_0 (.inclk0(pulse_base_clk), .c0(pulse_clk), .locked(PLL_locked)); //Produces 250MHz clk from 125MHz base
//PLL400M_50M PLL400M_50M_0 (.inclk0(pulse_base_clk), .c0(pulse_clk), .locked(PLL_locked)); //Produces 400MHz clk from 50MHz base
assign pulse_clk_out = pulse_clk;

//////////////////////Logic Module Instantiation////////////////////////////
// Hard-coded limitations (number of edges, bits per edge, maximum count bits)
parameter CH_LOG2 = 3;
parameter ED_MAX = 32;
parameter COUNT_BITS = 32; //longest period is set by number of bits
parameter ED_BITS = COUNT_BITS + COUNT_BITS + CH_LOG2 + 1;
localparam CH_MAX = 8'b0000_0001 << CH_LOG2;

// User set parameters (initial state, period in clk cycles, and flip edges)
reg reset = 1'b0;
reg [CH_MAX - 1 : 0] state0 = 0;
reg signed [COUNT_BITS - 1 : 0] period;
reg signed [COUNT_BITS - 1 : 0] outer_period = 1;
reg [ED_BITS - 1 : 0] eds [ED_MAX - 1 : 0];
wire [ED_BITS * ED_MAX - 1 : 0] flat_eds;
genvar j;
generate 
	for (j = 0; j < ED_MAX; j = j + 1) begin : flatten_eds
		assign flat_eds[ED_BITS*(j+1)-1 : ED_BITS*j] = eds[j];
	end
endgenerate 

pulse_logic #(.COUNT_BITS(COUNT_BITS), .CH_LOG2(CH_LOG2), .ED_MAX(ED_MAX)) pulse_logic0 (
	.reset(reset), // trig_in| (~PLL_locked)
	.clk(pulse_clk), //pulse_clk
	.period(period),
	.outer_period(outer_period),
	.state0(state0),
	.eds(flat_eds),
	.state(wvfm),
	.trig_out(trig_out)
);

////////////////////////Processor and UART Module Instantiation///////////////////

// UART transceiver 
reg rst_uart = 1'b0;
localparam RST_COUNTFROM = 50_000_000; //Reset if haven't heard anything for 1s
reg [31:0] rst_countdown = RST_COUNTFROM;
reg transmit;
reg [7:0] tx_byte;
wire received;
wire [7:0] rx_byte;
wire is_transmitting;
wire recv_error;
wire is_receiving;

uart u0 (
    .clk(sys_clk), // The master clock for this module
    .rst(rst_uart), // Synchronous reset.
    .rx(rx), // Incoming serial line
    .tx(tx), // Outgoing serial line
	 .transmit(transmit), // Signal to transmit
    .tx_byte(tx_byte), // Byte to transmit
    .received(received), // Indicated that a byte has been received.
    .rx_byte(rx_byte), // Byte received
    .is_receiving(is_receiving), // Low when receive line is idle.
    .is_transmitting(is_transmitting), // Low when transmit line is idle.
    .recv_error(recv_error) // Indicates error in receiving packet.
);

// Constants, don't change
parameter CR = 8'h0d; //Carriage Return
parameter NL = 8'h0a; //New line 

// Memory to store information received
parameter BYTES = 16; // Maximum command length
reg [7:0] mem [BYTES - 1:0]; //Read buffer
integer idx = 0; //Address
integer trans_idx = 0;
reg [7:0] trans_mem [BYTES - 1:0]; //Write buffer
wire [8 * BYTES - 1 : 0] flat_mem;  
genvar i;
generate 
	for (i = 0; i < BYTES; i = i + 1) begin : flatten_mem
		assign flat_mem[8*(i+1)-1 : 8*i] = mem[i];
	end
endgenerate 

reg execute = 0; //Goes high when CR, NL is received

// Possible commands types (will be indicated in the first received byte)
localparam STATE0 = 1;  //Don't use 0!
localparam PER = 2; 
localparam OUTER_PER = 3;
localparam ED = 4; 
localparam CLEAR = 5;
localparam PRINT = 6;

localparam SPI1 = 98;
localparam SPI2 = 99;

always @(posedge sys_clk) begin
	if (received) begin
		rst_countdown <= RST_COUNTFROM;
		if (mem[idx - 1] == CR && rx_byte == NL) begin
			execute <= 1'b1;
			idx <= 0;
		end
		else begin
			mem[idx] <= rx_byte;
			idx <= idx + 1;
		end
		if (idx >= BYTES) begin
			idx <= 0;
			rst_uart <= 1;
		end
		else rst_uart <= 0;
	end
	else if (!(execute | transmit)) begin
		if (rst_countdown <= 0) begin
			rst_uart <= 1;
			rst_countdown <= RST_COUNTFROM;
			idx <= 0;
		end
		else begin
			rst_countdown <= rst_countdown - 1;
			rst_uart <= 0;
		end
	end
	
	if (execute) begin
		execute <= 1'b0;
		transmit <= 1'b1; // Start response to PC
		tx_byte <= mem[0]; 
		case (mem[0])
			STATE0: state0 <= mem[1];
			PER: begin
				period <= flat_mem[COUNT_BITS - 1 + 8 : 8];
				test_per <= flat_mem[31 + 8 : 8];
			end
			ED: begin //mem[1] contains edge number (limited to 255 edges)
				eds[mem[1]] <= flat_mem[ED_BITS - 1 + 16 : 16];
				test_ed <= flat_mem[ED_BITS+15:16];
				reset <= 1'b1;
			end
			OUTER_PER: begin
				outer_period <= flat_mem[COUNT_BITS - 1 + 8 : 8];
			end
			PRINT: begin
				// Select what to print based on mem[1], mem[2]
			end
			CLEAR: begin
				integer k;
				for (k = 0; k < ED_MAX; k = k + 1) begin
					eds[k] <= 0;
				end
			end
		endcase
	end	
	else begin
		transmit <= 1'b0;
		reset <= 1'b0;
	end
	
	//	if (transmit) 
	
	if (rst_uart) begin
		integer j;
		for (j = 0; j < BYTES; j = j + 1) begin
			mem[j] <= 0;
		end
		idx <= 0;
		rst_uart <= 0;
	end
	
end

assign debug[2:0] = state0[2:0];
//assign debug[0] = is_receiving;
//assign debug[1] = execute;
//assign debug[2] = rst_uart;
//assign debug[3] = (mem[0] == ED);

endmodule 


