module PID (
	input				CLK_SYS,
	input				CLK_RST,

					
	input		[23:0]	Measure_Phase,		//得到相位差
	input				Measure_Done,		//测量完相位差之后，会产生一个时钟周期长的脉冲，表示测量完毕
	output	reg			Led_Lock,
	output	reg	[15:0]	PWM_Duty		//脉宽
);


always @(posedge Measure_Done or negedge CLK_RST) begin
	if (!CLK_RST) begin
		PWM_Duty <= 16'd35000;
		Led_Lock <= 1'b1;
	end
	else if (Measure_Phase > 5000000) begin
		Led_Lock <= 1'b0;
		PWM_Duty <= 16'd25000;
	end
	else if (Measure_Phase > 1'b0) begin
		Led_Lock <= 1'b1;
		PWM_Duty <= 16'd35000;
	end
	else begin
		Led_Lock <= 1'b1;
		PWM_Duty <= 16'd35000;
	end
end

endmodule
