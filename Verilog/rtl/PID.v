module PID (
	input				CLK_SYS,
	input				CLK_RST,

					
	input		[23:0]				Measure_Phase,		//得到相位差，带符号，负值表示Local超前，正值表示GPS超前
	input							Measure_Done,		//测量完相位差之后，会产生一个时钟周期长的脉冲，表示测量完毕
	output	reg						Led_Lock,			//锁定灯
	output	reg	signed	[16:0]		PWM_Duty,			//PWM脉宽
	output	reg	[7:0]				Data,
	output							Uart_En,
	output	reg	signed	[24:0]		compensate	
);


parameter signed 	kp = 500;
parameter signed 	ki = 10;
parameter signed 	kd = 0;
parameter signed	PWM_Duty_Half = 32768;

reg signed	[15:0]	en;				//偏差量，偏差量=Phase-Target
reg signed	[15:0]	en_1;			//En-1，上一次偏差量
reg signed	[15:0]	integral_en;	//偏差量积分
reg signed	[15:0]	un;				//△u

//计算Un
assign Uart_En = Measure_Done;
always @(posedge Measure_Done or negedge CLK_RST) begin
	if (!CLK_RST) begin
		en <= 0;
		//en_1 <= 0;
		integral_en <= 0;
		un <= 0;
		Led_Lock <= 1'b1;
		Data <= 0;
	end 
	else begin
		//得到相位差，Measure_Phase测得的是GPS上升沿到Local的下降沿
		en <= ($signed(Measure_Phase) - $signed(1_000_000));
		Data <= en;						//串口发出去，这里如果发integral_en就会有问题，不知道为什么
		
		//计算PI
		un <= $signed(500)*en + $signed(10)*integral_en;
		//un = kp*en + ki*(integral_en + en) + kd*(en-en_1);
		

		//限制积分上限
		if (($signed(en) > $signed(100))||($signed(en) < $signed(-100))) begin
			integral_en <= integral_en;
		end
		else begin
			if (integral_en > $signed(100)||(integral_en < $signed(-100))) begin
				integral_en <= integral_en;
			end
			else begin
				integral_en <= integral_en + en;
			end
		end
		

		
	end

end


//控制PWM_Duty
always @(posedge CLK_SYS or negedge CLK_RST) begin
	if (!CLK_RST) begin
		PWM_Duty <= 32768;
		compensate <= 0;
	end
	else begin
		PWM_Duty <= $signed(PWM_Duty_Half) + $signed(un);
	end
end


endmodule
