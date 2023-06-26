module Measure(
	input   				CLK_SYS,		
	input					CLK_RST,
    input					Flag_GPS_posedge,
	input					Flag_Local_negedge,

	
	output	reg		[23:0]			Measure_Phase,	//测完的相位差
	output							Measure_Done	//测量完成标志位
	
);


reg	flag_cnt_phase_start;						//计相位差开始标志位
assign Measure_Done = ~flag_cnt_phase_start;	//捕获计数完成下降标志位

//控制计数开关
always @(posedge CLK_SYS or negedge CLK_RST) begin
	if (!CLK_RST) begin
		flag_cnt_phase_start <= 1'b0;
	end
	else if (Flag_GPS_posedge) begin
		flag_cnt_phase_start <= 1'b1;
	end
	else if (Flag_Local_negedge) begin
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

