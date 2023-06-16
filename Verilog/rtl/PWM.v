module PWM (
	input			CLK_SYS,
	input			CLK_RST,

	input	[15:0]	PWM_Duty,		//脉宽
	output	reg		PWM_Out
);

parameter pulse = 65535;	//脉冲周期
reg [15:0]	cnt_pulse;		//脉冲周期计数

always @(posedge CLK_SYS or negedge CLK_RST) begin
	if (!CLK_RST) begin
		cnt_pulse <= 1'b0;		
	end
	else begin
		if (cnt_pulse == pulse - 1'b1) begin
			cnt_pulse <= 1'b0;
		end
		else begin
			cnt_pulse <= cnt_pulse + 1'b1;
		end
	end
end

always @(posedge CLK_SYS or negedge CLK_RST) begin
	if (!CLK_RST) begin
		PWM_Out <= 1'b1;		
	end
	else if (cnt_pulse == (PWM_Duty - 1'b1)) begin
		PWM_Out <= 1'b0;
	end
	else if (cnt_pulse == pulse - 1'b1) begin
		PWM_Out <= 1'b1;
	end
	else begin
		PWM_Out <= PWM_Out;
	end
end

endmodule