module three_wire(
    input write,
    input clk,
    input [16 - 1 : 0] din,
    output busy,
    output reg dout,
    output sclk,
    output reg cs
);

parameter BITS = 16; //Change din to be parameterized by BITS
parameter CLK_DIVIDE = 4; //Divide clk by 2^CLK_DIVIDE

reg [CLK_DIVIDE:0] clk_accumulator; //1 bit bigger than necessary, useful for latching

integer count = 0;
reg [BITS - 1 : 0] d;
initial cs = 1'b1;

reg write_latch;

always @(posedge clk) begin
	if (write) begin
		clk_accumulator <= 0;
		d <= din;
		write_latch <= 1'b1;
	end
	else begin 
		clk_accumulator <= clk_accumulator + 1'b1;
		write_latch <= write_latch && !(clk_accumulator >= {(CLK_DIVIDE){1'b1}}); //Stays on for one period after write signal
	end
end

assign sclk = clk_accumulator[CLK_DIVIDE-1];
assign busy = ~cs;

always @(posedge sclk) begin
	if (write_latch) cs <= 1'b0;
	else if (count >= BITS) cs <= 1'b1;
end

always @(negedge sclk) begin
	if (!cs) begin 
		dout <= d[count];
		count <= count + 1;
	end
	else begin
		count <= 0;
	end 
end 

endmodule


//always @(negedge sclk) begin //Update dout on falling edge (assuming that it is read on rising edge)
//
//	if (write) begin
//		count <= 1;
//		dout <= 0;
//		d <= din;
//		dout <= din[0];
//		cs <= 1'b0;
//	end
//
//	else begin
//		if (!cs) begin 
//			 if (count < bits) begin
//				dout <= d[count];
//				count <= count + 1;
//			 end
//			 else begin
//				cs <= 1'b1;
//			 end
//		end
//	end
//
//end