module CLK_DIV (
    input   				CLK_SYS,		
	input					CLK_RST,
    input   				_1PPS_GPS,

	input	signed [24:0] 	compensate,		
    output  reg				_1PPS_Local
);
    

parameter	period 	= 10_000_000;
parameter	pulse	= 1_000_000;

reg signed	[24:0]	cnt_period;		    
reg         		flag_start;         

/* 等待GPS信号到来 */
always @(posedge CLK_SYS or negedge CLK_RST) begin
    if (!CLK_RST) begin
        flag_start <= 1'b0;
    end
    else if (_1PPS_GPS==1'b1) begin
		flag_start <= 1'b1;
	end
	else begin
		flag_start <= flag_start;
	end
end

/* 分频计数 */
always @(posedge CLK_SYS or negedge CLK_RST) begin
	if (!CLK_RST) begin
		cnt_period <= 25'd0;		
	end
	else if (flag_start == 1'b1) begin
      	if (cnt_period == period + compensate - 1'b1) begin
			cnt_period <= 25'd0;
		end
		else begin
			cnt_period <= cnt_period + 1'b1;
		end
   end
   else begin
		cnt_period <= 25'd0;
   end

end

/* 输出本地1PPS */
always @(posedge CLK_SYS or negedge CLK_RST) begin
	if (!CLK_RST) begin
		_1PPS_Local <= 1'b0;		
	end
	else if (cnt_period == pulse - 1'b1) begin
		_1PPS_Local <= 1'b0;
	end
	else if (cnt_period == period + compensate - 1'b1) begin
		_1PPS_Local <= 1'b1;
	end
	else begin
		_1PPS_Local <= _1PPS_Local;
	end
end

endmodule
