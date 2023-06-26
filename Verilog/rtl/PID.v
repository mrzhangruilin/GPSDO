module PID (
	input							CLK_SYS,
	input							CLK_RST,

					
	input		[23:0]				Measure_Phase,		//得到相位差，带符号，负值表示Local超前，正值表示GPS超前
	input							Measure_Done,		//测量完相位差之后，会产生一个时钟周期长的脉冲，表示测量完毕
	output	reg						Led_Lock,			//锁定灯
	output	reg	signed	[16:0]		PWM_Duty,			//PWM脉宽
	output	reg	[7:0]				Data,
	output							Uart_En,
	output	reg						DIV_RST	
);


parameter signed 	kp = 500;
parameter signed 	ki = 10;
parameter signed 	kd = 0;
parameter signed	PWM_Duty_Half = 32768;

reg signed	[24:0]	en;				//偏差量，偏差量=Phase-Target
reg signed	[24:0]	en_1;			//En-1，上一次偏差量
reg signed	[7:0]	integral_en;	//偏差量积分
reg signed	[24:0]	un;				//△u

assign Uart_En = Measure_Done;

reg	[23:0]	cnt_phase;


always @(posedge Measure_Done or negedge CLK_RST) begin
	if (!CLK_RST) begin
		Data <= 8'd0;
		cnt_phase <= 24'd0;
		en <= 25'd0;
		DIV_RST <= 1'b0;
		integral_en <= 0;
	end
	else begin
		cnt_phase <= Measure_Phase;
		en <= cnt_phase - 24'd1_000_000;
		Data <= integral_en;


		un <= kp*en + ki*integral_en;
		//un = kp*en + ki*(integral_en + en) + kd*(en-en_1);
		

		//限制积分上限
		if ((en > 100)||(en < -100)) begin
			integral_en <= integral_en;
		end
		else begin
			if (integral_en > 100) begin
				integral_en <= 100;
			end
			else if (integral_en < -100) begin
				integral_en <= -100;
			end
			else begin
				integral_en <= integral_en + en;
			end
		end

		if ((en < -10)||(en > 10)) begin
			DIV_RST <= 1'b1;
		end
		else begin
			DIV_RST <= 1'b0;
		end

		if (en == 0) begin
			Led_Lock <= 0;
		end
		else begin
			Led_Lock <= 1;
		end
	end
end


//控制PWM_Duty
always @(posedge CLK_SYS or negedge CLK_RST) begin
	if (!CLK_RST) begin
		PWM_Duty <= 32768;
	end
	else begin
		PWM_Duty <= PWM_Duty_Half + un;
	end
end


endmodule
