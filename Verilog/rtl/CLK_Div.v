module CLK_Div(
    input   CLK_Sys,    			//系统10M时钟
    input   CLK_Rst,    			//复位信号

	input	Phase_Compensate_Type,	//补偿方式，0是增加计数，1是减少计数
	input	Phase_Compensate,		//相位补偿，用一个24位带符号的数输入
    input   _1PPS_GPS,  			//输入GPS的1pps
    output	reg	_1PPS_Local			//输出本地的1pps
);

reg 		flag_gps_first;		//第一个gps的1pps标志位
reg	[23:0]	cnt_10M;			//计数到10M

//检测第一个GPS信号
always @(posedge _1PPS_GPS or negedge CLK_Rst) begin
	if (!CLK_Rst) begin
		flag_gps_first <= 1'b0;
	end
	else begin
		flag_gps_first <= 1'b1;
	end
end

//计数
always @(posedge CLK_Sys or negedge CLK_Rst) begin
	if (!CLK_Rst) begin
		cnt_10M <= 24'd0;
	end
	else if (flag_gps_first) begin
		if (Phase_Compensate_Type) begin
			if (cnt_10M < 10_000_000-1'b1-Phase_Compensate) begin	//减少补偿量
				cnt_10M <= cnt_10M + 1'b1;
			end
			else begin
				cnt_10M <= 21'd0;
			end
		end
		else begin
			if (cnt_10M < 10_000_000-1'b1+Phase_Compensate) begin	//增加补偿量
				cnt_10M <= cnt_10M + 1'b1;
			end
			else begin
				cnt_10M <= 21'd0;
			end
		end
	end
	else begin
		cnt_10M <= 24'd0;
	end
end

//输出本地1pps
always @(posedge CLK_Sys or negedge CLK_Rst) begin
	if (!CLK_Rst) begin
		_1PPS_Local <= 1'b0;
	end
	else begin
		if (cnt_10M < 1_000_000) begin
			_1PPS_Local <= 1'b1;
		end
		else begin
			_1PPS_Local <= 1'b0;
		end
	end
end
endmodule
