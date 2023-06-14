module Measure(
    input   			CLK_Sys,    			//系统10M时钟
    input   			CLK_Rst,    			//复位信号
    input   			_1PPS_GPS,  			//GPS的1pps
    input				_1PPS_Local,			//本地的1pps

	output  reg			GPS_Exist,				//GPS信号存在检测，0-不存在，1-存在
	output	reg			uart_en,				//发送使能信号
	output	reg	[7:0]	data,					//
	output 	reg	[15:0]	PWM_Duty
);

reg [23:0]	cnt_GPS_exist;			//用来计算GPS是否存在
reg [23:0]	phase_average;			//保存五次的相位差平均值
reg [23:0]	cnt_phase;				//计算相位差
reg [2:0]	cnt_measure;			//采样周期计数，1-5
reg			flag_cnt_phase_start;	//相位差计数开始标志位，GPS上升沿开始计数


reg GPS_edg0;
reg GPS_edg1;
reg Local_edg0;
reg Local_edg1;

//捕获上升沿，得到一个时钟周期的脉冲信号
assign GPS_posedge = (~GPS_edg1) & GPS_edg0;
assign Local_posedge = (~Local_edg1) & Local_edg0;

//对GPS信号延迟两个时钟周期
always @(posedge CLK_Sys or negedge CLK_Rst) begin         
    if (!CLK_Rst) begin
        GPS_edg0 <= 1'b0;                                  
        GPS_edg1 <= 1'b0;
    end                                                      
    else begin                                               
        GPS_edg0 <= _1PPS_GPS;                               
        GPS_edg1 <= GPS_edg0;                            
    end
end

//对Local信号延迟两个时钟周期
always @(posedge CLK_Sys or negedge CLK_Rst) begin         
    if (!CLK_Rst) begin
        Local_edg0 <= 1'b0;                                  
        Local_edg1 <= 1'b0;
    end                                                      
    else begin                                               
        Local_edg0 <= _1PPS_Local;                               
        Local_edg1 <= Local_edg0;                            
    end
end

/*
//检测GPS信号存在
always @(posedge CLK_Sys or negedge CLK_Rst) begin
	if (!CLK_Rst) begin
		cnt_GPS_exist <= 24'd0;		//清零计数
		GPS_Exist <= 1'b0;			//上电不存在
	end
	else begin
		if (_1PPS_GPS) begin
			GPS_Exist <= 1'b1;
			cnt_GPS_exist <= 24'd0;
		end
		else if (cnt_GPS_exist < 10_000_000) begin
			cnt_GPS_exist <= cnt_GPS_exist + 1'b1;
		end
		else begin
			GPS_Exist <= 1'b0;
			cnt_GPS_exist <= 24'd0;
		end
	end
end
*/

//相位差计时开关
always @(posedge CLK_Sys or negedge CLK_Rst) begin
	if (!CLK_Rst) begin
		flag_cnt_phase_start <= 1'b0;
	end
	else if (GPS_posedge) begin
		flag_cnt_phase_start <= 1'b1;
	end
	else if (Local_posedge) begin
		flag_cnt_phase_start <= 1'b0;
	end
	else begin
		flag_cnt_phase_start <= flag_cnt_phase_start;
	end
end

//计相位差
always @(posedge CLK_Sys or negedge CLK_Rst) begin
	if (!CLK_Rst) begin
		cnt_phase <= 24'd0;
		PWM_Duty <= 32'd32768;
	end
	else if (flag_cnt_phase_start) begin
		cnt_phase <= cnt_phase + 1'b1;
		data <= cnt_phase;
		uart_en <= 1'b0;
	end
	else begin
		uart_en <= 1'b1;
		cnt_phase <= 24'd0;
	end
end

//采样周期计数，5次
always @(negedge flag_cnt_phase_start or negedge CLK_Rst) begin		//计数开关下降沿，代表计数完成
	if (!CLK_Rst) begin
		cnt_measure <= 3'd0;
	end
	else begin
		if (cnt_measure < 5) begin
			phase_average <= (phase_average + cnt_phase)>>1;
			cnt_measure <= cnt_measure + 1'b1;
		end
		else begin
			phase_average <= cnt_phase;
			cnt_measure <= 3'd0;
		end
	end
end

endmodule