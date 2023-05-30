module TEST (
	input						CLK_GPS,		//gps时钟信号
	input						CLK_10M,		//晶振时钟信号
	input						CLK_CNT,		//1khz频率计数时钟
	input						CLK_RST,		//复位信号
	input						CLK_SYS,		//系统时钟
	input       			Uart_TX_busy,
	input						Bytes_busy,
	
	output	reg [31:0]	cnt_f	,//相位差
	output	reg         send_bytes_start
);


parameter	min_cnt = 0;					//最小计数值0
parameter	mid_cnt = 499_999;			//计数中值，（1_000_000 / 2） - 1


reg					flag_gps;		//gps上升沿标志
reg					flag_local;		//晶振上升沿标志
reg					cnt_start;		//开始计数标志
reg					cnt_stop;		//停止计数标志
reg					order;			//0表示GPS信号先来，1表示1pps信号先来
reg		[31:0]	cnt;			//缓冲寄存器


//检测两个时钟信号上升沿，并相应给标志位 
always @(posedge CLK_SYS or negedge CLK_RST)
	if(!CLK_RST)begin
		flag_gps <= 1'b0;
		flag_local <= 1'b0;
	end
	else begin
		if(CLK_GPS == 1) begin
			flag_gps <= 1'b1;
		end
		if(CLK_10M == 1) begin
			flag_local <= 1'b1;
		end
		if((CLK_GPS == 0)&&(CLK_10M == 0) && (flag_gps == 1)&&(flag_local == 1))begin
			flag_gps <= 1'b0;										//清零
			flag_local <= 1'b0;
		end
	end
	

		
//开始计数标志
always @(posedge CLK_SYS or negedge CLK_RST)begin		
	if(!CLK_RST) begin
		cnt_start <= 1'b0;										//开始计数，标志位清零
		cnt_stop <= 1'b0;
	end
	else if(flag_gps ^ flag_local)begin						//两个标志位不同时，^为异或，开始计数条件		1 0 / 0 1
		cnt_start <= 1'b1;										//开始计数标志置1
		cnt_stop <= 1'b0;
		if (flag_gps == 1'b1) begin
			order <= 1'b0;
		end
		else begin
			order <= 1'b1;
		end
	end
	else if((flag_gps == 1'b1) && (flag_local == 1'b1))begin		//二者同时为1，停止计数条件			1 1
		cnt_stop <= 1'b1;
	end
	else begin														//最后一种情况，二者同时为0						0 0
		cnt_start <= 1'b0;
	end
end
		
//计数器
always @(posedge CLK_CNT or negedge CLK_RST) begin					//频率计数时钟
	if(!CLK_RST) begin
		cnt <= 32'd0;															//两个寄存器全部清零
		cnt_f <= 32'd0;
	end
	else if((cnt_start == 1'b1) && (cnt_stop == 1'b0)) begin		//仅有开始计数标志
		cnt <= cnt + 1'b1;													//缓冲寄存器自加
	end
	else if((cnt_start == 1'b1) && (cnt_stop == 1'b1)) begin		//停止计数时刻，读取cnt数值并存到cnt_f
		if(order) begin
			cnt_f <= cnt | 1<<24;
		end
		else begin
			cnt_f <= cnt;
		end
	end														//cnt清零
	else begin																	//其他时刻理论上指开始为0，停止为1   或二者同时为0
		cnt <= 32'd0;															//清零
	end
end

always @(posedge CLK_CNT or negedge CLK_RST)
begin
    if(!CLK_RST)
        send_bytes_start <= 1'b0;
    else
    begin
        if((cnt_start == 1'b1) && (cnt_stop == 1'b1))
            send_bytes_start <= 1'b1;
        else
            send_bytes_start <= 1'b0;
    end
end
endmodule
















