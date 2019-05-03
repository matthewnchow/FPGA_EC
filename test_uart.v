module test_uart(
	input sys_clk,
	input rx,
	output [31:0] info,
	output reg update,
	output tx
);

// UART communication 
localparam rst = 1'b0;
reg transmit;
reg [7:0] tx_byte = 8'b0101_0101;
wire received;
wire [7:0] rx_byte;
wire is_receiving;
wire is_transmitting;
wire recv_error;

uart u0 (
    .clk(sys_clk), // The master clock for this module
    .rst(rst), // Synchronous reset.
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

reg [7:0] mem0 [4:0];
reg [3:0] idx = 4'b0000;
reg got_one = 1'b0;
parameter CR = 8'h0d;
parameter NL = 8'h0a;

reg CR_last;
	 
always @(posedge sys_clk) begin 

	if (~is_transmitting) begin //Always transmit, use for debug
		transmit <= 1'b1;
		if (got_one) begin
			tx_byte <= idx;
		end
	end
	else begin
		transmit <= 1'b0;
	end

	if (received) begin
		got_one <= 1'b1;
		CR_last <= (rx_byte == CR);
		if (!(rx_byte == NL && CR_last)) begin
			mem0[idx] <= rx_byte;
			idx <= idx + 1'b1;
			update <= 1'b0;
			end
		else begin
			idx <= 4'b0000;
			update <= 1'b1;
		end
	end
	else update <= 1'b0;
end

assign info[7:0] = mem0[0];
assign info[15:8] = mem0[1];
assign info[23:16] = mem0[2];
assign info[31:24] = mem0[3];

endmodule
