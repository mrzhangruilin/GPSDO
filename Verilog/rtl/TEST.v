module test (
	input		CLK_SYS,
	input		CLK_RST,
	
	output	reg	LED,
	output	reg	clk_div
);


reg	[31:0]	cnt;

parameter	max = 20_000000;

always @(posedge CLK_SYS or negedge CLK_RST)
	if(!CLK_RST) begin
		cnt <= 32'd0;
	end
	else if(cnt == max) begin
		cnt <= 32'd0;
	end
	else begin
		cnt <= cnt + 1'b1;
	end
	
always @(posedge CLK_SYS or negedge CLK_RST)
	if(!CLK_RST) begin
		clk_div <= 1'b0;
	end
	else if(cnt == (max/2) - 1'b1) begin
		clk_div <= ~clk_div;
	end
	else if(cnt == max) begin
		clk_div <= ~clk_div;
	end
	else begin
		clk_div <= clk_div;
	end

always @(posedge CLK_SYS or negedge CLK_RST)
	if(!CLK_RST)
		LED <= 1'b1;
	else if(cnt == (max/2) - 1'b1)
		LED <= 1'b0;
	else if(cnt == max)
		LED <= 1'b1;
	else
		LED <= LED;
			
endmodule
