module TEST (
	input				CLK_SYS,		//系统时钟与晶振时钟是同一时钟
	input				CLK_RST,		//复位信号
	input				_1PPS_GPS,		//GPS的1pps
	input				_1PPS_Local,	//本地1pps
	
	output	reg			LED_Lock,		//锁定用灯
	output	reg	[31:0]	PWM_Duty,
	output	reg			DIV_RESET		//置1时，重新计数
);


reg 		flag_order;			//0位GPS超前，1位Local超前		
reg			flag_gps;			//GPS上升沿到来标志位
reg			flag_local;			//LOCAL上升沿到来标志位
reg			flag_cnt_start;		//开始计数标志位
reg			flag_cnt_stop;		//停止计数标志位
reg [31:0]	cnt_phase;			//相位差计数

//控制PWM
/*
	输出0V电压时，相位差变化0.7us每秒，0.7us/s
	输出5V电压时，相位差变化0.5us每秒，0.5us/s
	PWM_Duty	△
	1			0.7us/s
	0(最大)		0.5us/s
*/
always @(posedge CLK_SYS or negedge CLK_RST)
begin
    if(!CLK_RST) begin
		PWM_Duty <= 32'd32768;
		LED_Lock <= 1'b1;
		DIV_RESET <= 1'b0;
	end
    else begin
        if((flag_cnt_start == 1'b1) && (flag_cnt_stop == 1'b1)) begin	//测完相位差
			if (flag_order == 1'b0) begin			//GPS超前，增大电压
				if (cnt_phase > 32'd10) begin		//相位差过大，重新计数
					DIV_RESET <= 1'b1;
				end 
				else if (cnt_phase > 2) begin		
					PWM_Duty <= 32'd45000;
					LED_Lock <= 1'b1;
				end
				else begin
					PWM_Duty <= 32'd32768;
					LED_Lock <= 1'b0;
				end
			end
			else begin	//Local超前，减小电压
				if (cnt_phase > 32'd5) begin		//相位差过大，重新计数
					DIV_RESET <= 1'b1;
				end 
				else if (cnt_phase > 2) begin		
					PWM_Duty <= 32'd25000;
					LED_Lock <= 1'b1;
				end
				else begin
					PWM_Duty <= 32'd32768;
					LED_Lock <= 1'b0;
				end
			end
		end
        else begin
			DIV_RESET <= 1'b0;							//没有测完相位差
			if(cnt_phase > 32'd5000000) begin			//相位差过大，0.5s，GPS信号丢失
				PWM_Duty <= 32'd32768;
				LED_Lock <= 1'b1;
			end
			else begin
				
			end
		end
    end
end

//检测两个时钟信号上升沿，并相应给标志位 
always @(posedge CLK_SYS or negedge CLK_RST) begin
	if(!CLK_RST)begin
		flag_gps <= 1'b0;
		flag_local <= 1'b0;
	end
	else begin
		if(_1PPS_GPS == 1) begin
			flag_gps <= 1'b1;
		end
		if(_1PPS_Local == 1) begin
			flag_local <= 1'b1;
		end
		if((_1PPS_GPS == 0)&&(_1PPS_Local == 0) && (flag_gps == 1)&&(flag_local == 1))begin
			flag_gps <= 1'b0;										//清零
			flag_local <= 1'b0;
		end
	end
end

//开始计数标志
always @(posedge CLK_SYS or negedge CLK_RST)begin		
	if(!CLK_RST) begin
		flag_cnt_start <= 1'b0;										//开始计数，标志位清零
		flag_cnt_stop <= 1'b0;
	end
	else if(flag_gps ^ flag_local)begin								//两个标志位不同时，^为异或，开始计数条件		1 0 / 0 1
		flag_cnt_start <= 1'b1;										//开始计数标志置1
		flag_cnt_stop <= 1'b0;
		if (flag_gps == 1'b1) begin
			flag_order <= 1'b0;
		end
		else begin
			flag_order <= 1'b1;
		end
	end
	else if((flag_gps == 1'b1) && (flag_local == 1'b1))begin		//二者同时为1，停止计数条件		1 1
		flag_cnt_stop <= 1'b1;
	end
	else begin														//最后一种情况，二者同时为0		0 0
		flag_cnt_start <= 1'b0;
	end
end

//计数器
always @(posedge CLK_SYS or negedge CLK_RST) begin					
	if(!CLK_RST) begin
		cnt_phase <= 32'd0;													//两个寄存器全部清零
	end
	else if((flag_cnt_start == 1'b1) && (flag_cnt_stop == 1'b0)) begin		//仅有开始计数标志
		if (cnt_phase < 32'd10000000) begin
			cnt_phase <= cnt_phase + 1'b1;									//计数器增加
		end
		else begin
			cnt_phase <= 32'd0;
		end
	end
	else if((flag_cnt_start == 1'b1) && (flag_cnt_stop == 1'b1)) begin		//停止计数时刻，将相位差丢给串口
	end														
	else begin																//其他时刻理论上指开始为0，停止为1   或二者同时为0
		cnt_phase <= 32'd0;													//清零
	end
end



endmodule
