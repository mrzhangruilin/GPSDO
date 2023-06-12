module CLK_DIV (
    input   	CLK_SYS,		//暂定系统时钟和10M是同一个时钟
	input		CLK_RST,
    input   	_1PPS_GPS,

	input		DIV_RESET,		//相位差过大时重新计数分频
    output  reg	_1PPS_Local
);
    

parameter	pulse = 10_000_000;   
reg [23:0]	cnt_pulse;		    
reg         flag_start;         

/* 等待GPS信号到来 */
always @(posedge CLK_SYS or negedge CLK_RST) begin
    if (!CLK_RST) begin
        flag_start <= 1'b0;
    end
    else begin
		if (DIV_RESET) begin
			flag_start <= 1'b0;
		end
		else if (_1PPS_GPS==1'b1) begin
			flag_start <= 1'b1;
		end
		else begin
			flag_start <= flag_start;
		end
    end
end

/* 分频计数 */
always @(posedge CLK_SYS or negedge CLK_RST) begin
	if (!CLK_RST) begin
		cnt_pulse <= 24'd0;		
	end
	else if (flag_start == 1'b1) begin
      	if (cnt_pulse == pulse - 1'b1) begin
			cnt_pulse <= 24'd0;
		end
		else begin
			cnt_pulse <= cnt_pulse + 1'b1;
		end
   end
   else begin
		cnt_pulse <= 24'd0;
   end

end

/* 输出本地1PPS */
always @(posedge CLK_SYS or negedge CLK_RST) begin
	if (!CLK_RST) begin
		_1PPS_Local <= 1'b0;		
	end
	else if (cnt_pulse == ((pulse / 10)- 1)) begin
		_1PPS_Local <= 1'b0;
	end
	else if (cnt_pulse == pulse - 1'b1) begin
		_1PPS_Local <= 1'b1;
	end
	else if (cnt_pulse == 1'b1) begin
		_1PPS_Local <= 1'b1;
	end
	else if (flag_start == 1'b0) begin
		_1PPS_Local <= 1'b0;
	end
	else begin
		_1PPS_Local <= _1PPS_Local;
	end
end

endmodule
