module tw_tb();
  
  reg write;
  reg clk;
  reg [15:0] data_sim = 16'b0101_0101_1111_0000;
  
  wire busy;
  wire dout;
  wire sclk;
  wire cs;
  
  parameter CLK_PER = 200; //200 ns --> 5MHz
  
  three_wire tw(write, clk, data_sim, busy, dout, sclk, cs);
  
  initial clk = 1'b0;
  
  always #(CLK_PER/2.0) clk = ~clk;
  
  initial write = 1'b0;
  
  initial 
    begin
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      write <= 1'b1;
      @(posedge clk);
	   write <= 1'b0;      
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
    end
endmodule

