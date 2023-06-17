module PID (
	input				CLK_SYS,
	input				CLK_RST,

					
	input		[23:0]	Measure_Phase,		//得到相位差
	input				Measure_Done,		//测量完相位差之后，会产生一个时钟周期长的脉冲，表示测量完毕
	output	reg			Led_Lock,
	output	reg	[15:0]	PWM_Duty		//脉宽
);

parameter Kp = 5;
parameter Ki = 5;
parameter Kd = 5;

reg [15:0] differ_u;
reg [15:0] uk;
reg [23:0] ek;
reg [23:0] pre_ek1;
reg [23:0] pre_ek2;

//always @(posedge Measure_Done or negedge CLK_RST) begin
//	if (!CLK_RST) begin
////		PWM_Duty <= 16'd35000;
//        Led_Flag <= 1'b1;
//    end
//	else if (Measure_Phase > 5000000) begin
//		Led_Lock <= 1'b0;
////		PWM_Duty <= 16'd25000;
//	end
//	else if (Measure_Phase < 24'd0) begin
//		Led_Lock <= 1'b1;
////		PWM_Duty <= 16'd35000;
//	end
//	else begin
//		Led_Lock <= 1'b1;
////		PWM_Duty <= 16'd35000;
//	end
//end

always @ (posedge Measure_Done or negedge CLK_RST) begin
    if((!CLK_RST)) begin
        ek <= 24'd0;
        pre_ek1 <= 24'd0;
        pre_ek2 <= 24'd0;
        differ_u <= 16'd0;
        PWM_Duty <= 16'd32768;
    end
    else if(Measure_Phase > 24'd5_000_000) begin
        ek <= 24'd10_000_000-Measure_Phase;
        pre_ek1 <= ek;
        pre_ek2 <= pre_ek1;
        differ_u <= Kp*(ek-pre_ek1)+Ki*ek+Kd*(ek-2*pre_ek1+pre_ek2);
        PWM_Duty <= PWM_Duty - differ_u;
    end
    else begin
        ek <= Measure_Phase;
        pre_ek1 <= ek;
        pre_ek2 <= pre_ek1;
        differ_u <= Kp*(ek-pre_ek1)+Ki*ek+Kd*(ek-2*pre_ek1+pre_ek2);
        PWM_Duty <= PWM_Duty + differ_u;
    end
end

endmodule
