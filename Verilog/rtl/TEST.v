module TEST (
	input				CLK_SYS,		//系统时钟与晶振时钟是同一时钟
	input				CLK_RST,		//复位信号
	input				_1PPS_GPS,		//GPS的1pps
	input				_1PPS_Local,	//本地1pps
	
	output	reg			LED_Lock,		//锁定用灯
	output	reg	[31:0]	PWM_Duty,

	input				Uart_Busy,
	output	reg			Uart_En,
	output	reg	[7:0]	Uart_Data
);


reg 		flag_order;			//0位GPS超前，1位Local超前		
reg			flag_gps;			//GPS上升沿到来标志位
reg			flag_local;			//LOCAL上升沿到来标志位
reg			flag_cnt_start;		//开始计数标志位
reg			flag_cnt_stop;		//停止计数标志位
reg [31:0]	cnt_phase;			//相位差计数

//串口发送相位差，控制PWM
always @(posedge CLK_SYS or negedge CLK_RST)
begin
    if(!CLK_RST) begin
      	Uart_En <= 1'b0;
		PWM_Duty <= 32768;
		Uart_Data <= 8'd13;
		LED_Lock <= 1'b1;
	end
    else begin
        if((flag_cnt_start == 1'b1) && (flag_cnt_stop == 1'b1)) begin
			if ((flag_order == 1'b0)&&(cnt_phase > 5)) begin		//GPS超前，增大电压
				Uart_Data <= cnt_phase;
				PWM_Duty <= 45000;		//gps超前电压
				LED_Lock <= 1'b1;
			end
			else if ((flag_order == 1'b1)&&(cnt_phase > 5)) begin	//Local超前，减小电压
				Uart_Data <= 8'd255-cnt_phase;
				PWM_Duty <= 20000;		//local超前电压
				LED_Lock <= 1'b1;
			end
			else begin
				Uart_Data <= 8'd0;
				PWM_Duty <= 32768;		//保持电压
				LED_Lock <= 1'b0;
			end
			Uart_En <= 1'b1;
		end
        else if(cnt_phase > 50000000)begin	
			PWM_Duty <= 33800;
			Uart_Data <= 8'd255;
        	Uart_En <= 1'b1;
			LED_Lock <= 1'b1;
		end
		else begin
			Uart_En <= 1'b0;
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
		cnt_phase <= cnt_phase + 1'b1;										//缓冲寄存器自加
	end
	else if((flag_cnt_start == 1'b1) && (flag_cnt_stop == 1'b1)) begin		//停止计数时刻，将相位差丢给串口
	end														
	else begin																//其他时刻理论上指开始为0，停止为1   或二者同时为0
		cnt_phase <= 32'd0;													//清零
	end
end



endmodule
