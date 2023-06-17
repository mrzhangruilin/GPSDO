module PID (
	input				CLK_SYS,
	input				CLK_RST,

					
	input		[23:0]				Measure_Phase,		//得到相位差，带符号，负值表示Local超前，正值表示GPS超前
	input							Measure_Done,		//测量完相位差之后，会产生一个时钟周期长的脉冲，表示测量完毕
	output	reg						Led_Lock,			//锁定灯
	output	reg	signed	[16:0]		PWM_Duty,			//PWM脉宽
	output	reg	[7:0]				Data,
	output							Uart_En
);


parameter signed 	kp = 16'd500;
parameter signed 	ki = 16'd50;
parameter signed 	kd = 16'd0;
parameter signed	PWM_Duty_Half = 32768;

reg signed	[15:0]	en;				//偏差量，偏差量=Phase-Target
reg signed	[15:0]	en_1;			//En-1，上一次偏差量
reg signed	[15:0]	integral_en;	//偏差量积分
reg signed	[15:0]	un;				//△u

assign Uart_En = Measure_Done;
always @(posedge Measure_Done or negedge CLK_RST) begin
	if (!CLK_RST) begin
		PWM_Duty <= 32768;
		Led_Lock <= 1'b1;
	end
	else begin
		en = Measure_Phase[15:0] - 1;		//这里用阻塞赋值
		Data <= integral_en;						//串口发出去
		
		un = kp*en + ki*(integral_en + en);
		//un = kp*en + ki*(integral_en + en) + kd*(en-en_1);
		PWM_Duty <= PWM_Duty_Half + un;
		integral_en <= integral_en + en;
		//en_1 <= en;
	end

end



endmodule
