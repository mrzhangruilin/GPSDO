module Measure(
	input   				CLK_SYS,		
	input					CLK_RST,
    input   				_1PPS_GPS,
	input					_1PPS_Local,

	
	output	reg		[23:0]			Measure_Phase,	//测完的相位差
	output							Measure_Done,	//测量完成标志位
	output							flag_GPS_posedge,
	output							flag_Local_negedge
);

reg _1PPS_GPS_e0;
reg _1PPS_GPS_e1;
reg _1PPS_Local_e0;
reg _1PPS_Local_e1;


reg	flag_cnt_phase_start;	//计相位差开始标志位


//捕获上升沿
//在Local上升沿开始计数，在GPS下降沿停止计数
assign flag_GPS_posedge = (~_1PPS_GPS_e1)&(_1PPS_GPS_e0);		//GPS上升沿
assign flag_Local_negedge = (~_1PPS_Local_e0)&(_1PPS_Local_e1);	//Local下降沿
assign Measure_Done = (~_1PPS_Local_e0)&(_1PPS_Local_e1);
//assign	Measure_Done = ~flag_cnt_phase_start;

always @(posedge CLK_SYS) begin                                                 
	_1PPS_GPS_e0 <= _1PPS_GPS;                               
	_1PPS_GPS_e1 <= _1PPS_GPS_e0;                            
end

always @(posedge CLK_SYS) begin                                                 
	_1PPS_Local_e0 <= _1PPS_Local;                               
	_1PPS_Local_e1 <= _1PPS_Local_e0;                            
end
//捕获上升沿

//控制计数开关
always @(posedge CLK_SYS or negedge CLK_RST) begin
	if (!CLK_RST) begin
		flag_cnt_phase_start <= 1'b0;
	end
	else if (flag_GPS_posedge) begin
		flag_cnt_phase_start <= 1'b1;
	end
	else if (flag_Local_negedge) begin
		flag_cnt_phase_start <= 1'b0;
	end
	else begin
		flag_cnt_phase_start <= flag_cnt_phase_start;
	end
end


//计数
always @(posedge CLK_SYS or negedge CLK_RST) begin
	if (!CLK_RST) begin
		Measure_Phase <= 24'd0;
	end
	else if (flag_cnt_phase_start) begin
		Measure_Phase <= Measure_Phase + 1'b1;
	end
	else begin
		Measure_Phase <= 24'd0;
	end
end

endmodule

