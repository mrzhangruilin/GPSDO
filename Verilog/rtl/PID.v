module PID(
    input   			CLK_Sys,    			//系统10M时钟
    input   			CLK_Rst,    			//复位信号

	input  		        GPS_Exist,				//GPS信号存在检测，0-不存在，1-存在
    input               Flag_Measure_Dir,		//相位方向，0-GPS超前，1-GPS滞后
	input			    Flag_Measure_Done,		//采样完成信号，上升沿检测
	input   	[15:0]	Phase_Out,				//输入相位差

	output	reg			[15:0]	PWM_Duty
);

parameter PWM_Duty_Half = 16'd32768;
reg [11:0]	cnt_shifting;	//偏移

/*
//补偿算法
always @(posedge Flag_Measure_Done or negedge CLK_Rst) begin
	if (!CLK_Rst) begin
		Phase_Compensate_Type <= 1'b0;
		Phase_Compensate <= 24'd0;
	end	
	else begin
		Phase_Compensate <= Phase_Out;
		Phase_Compensate_Type <= ~Flag_Measure_Dir;
	end
end
*/

always @(negedge Flag_Measure_Done or negedge CLK_Rst) begin
	if (!CLK_Rst) begin
		PWM_Duty <= PWM_Duty_Half;
		cnt_shifting <= 12'd0;
	end
	else begin
		if (Phase_Out > 1'b1) begin
			PWM_Duty <= PWM_Duty_Half + 9'd150*cnt_shifting;
			if (cnt_shifting < 3'd5) begin
				cnt_shifting <= cnt_shifting + 1'b1;
			end
			else begin
				cnt_shifting <= 3'd5;
			end
		end
		else begin
			cnt_shifting <= 12'd1;
			PWM_Duty <= PWM_Duty_Half;
		end
	end
end

/*
//串口发送相位差
always @(posedge CLK_Sys or negedge CLK_Rst) begin
	if (!CLK_Rst) begin
		uart_data <= 8'd0;
		uart_en <= 1'b0;
	end	
	else begin
		if (Flag_Measure_Done) begin
			uart_data <= Phase_Out;
			uart_en <= 1'b1;
		end
		else begin
			uart_en <= 1'b0;
		end
	end
end
*/


endmodule

