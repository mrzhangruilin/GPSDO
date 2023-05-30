module PWM (
	input			Clk_Sys,
	input			Clk_Rst,

	input			PWM_En,			//PWM使能信号
	input	[31:0]	PWM_Duty,		//占空比，单位是时钟数
	output	reg		PWM_Out
);

parameter pulse = 65535;	//脉宽
reg [16:0]	cnt_pulse;		//计脉宽

always @(posedge Clk_Sys or negedge Clk_Rst) begin
	if (!Clk_Rst) begin
		cnt_pulse <= 1'b0;		
	end
	else if (PWM_En) begin
		if (cnt_pulse == pulse - 1'b1) begin
			cnt_pulse <= 1'b0;
		end
		else begin
			cnt_pulse <= cnt_pulse + 1'b1;
		end
	end
	else begin
		cnt_pulse <= 1'b0;	//没使能PWM的时候清空计数
	end
end

always @(posedge Clk_Sys or negedge Clk_Rst) begin
	if (!Clk_Rst) begin
		PWM_Out <= 1'b1;		
	end
	else if (cnt_pulse == (PWM_Duty - 1'b1)) begin
		PWM_Out <= 1'b0;
	end
	else begin
		PWM_Out <= 1'b1;
	end
end

endmodule