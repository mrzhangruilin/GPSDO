module Filter(
	input		GPS_IN,		//原始GPS进入
	
	output	_1PPS_GPS	//输出滤波之后的GPS信号
);

assign _1PPS_GPS = GPS_IN&1'b1;


endmodule