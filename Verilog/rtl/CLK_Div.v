module CLK_DIV (
    input   				CLK_SYS,		
	input					CLK_RST,
    input   				_1PPS_GPS,

	input					DIV_RST,		//分频复位
	input					Preheat_done,	//预热完成标志位
    output  reg				_1PPS_Local,
	output					Flag_GPS_posedge,
	output					Flag_Local_negedge
);
    

parameter	period 	= 10_000_000;
parameter	pulse	= 1_000_000;

	    
reg         		flag_start;         
reg [23:0]			cnt_period;	

reg _1PPS_GPS_e0;
reg _1PPS_GPS_e1;
reg _1PPS_Local_e0;
reg _1PPS_Local_e1;
reg DIV_RST_e0;
reg DIV_RST_e1;
//捕获上升沿
//在Local上升沿开始计数，在GPS下降沿停止计数
assign Flag_GPS_posedge = (~_1PPS_GPS_e1)&(_1PPS_GPS_e0);		//GPS上升沿
assign Flag_Local_negedge = (~_1PPS_Local_e0)&(_1PPS_Local_e1);	//Local下降沿
assign flag_DIV_RST_posedge = (~DIV_RST_e1)&(DIV_RST_e0);		//DIV_EN上升沿

always @(posedge CLK_SYS) begin                                                 
	_1PPS_GPS_e0 <= _1PPS_GPS;                               
	_1PPS_GPS_e1 <= _1PPS_GPS_e0;                            
end

always @(posedge CLK_SYS) begin                                                 
	_1PPS_Local_e0 <= _1PPS_Local;                               
	_1PPS_Local_e1 <= _1PPS_Local_e0;                            
end

always @(posedge CLK_SYS) begin                                                 
	DIV_RST_e0 <= DIV_RST;                               
	DIV_RST_e1 <= DIV_RST_e0;                            
end



/* 等待GPS信号到来 */
always @(posedge CLK_SYS or negedge CLK_RST) begin
    if (!CLK_RST) begin
        flag_start <= 1'b0;
    end
    else if ((Flag_GPS_posedge)&&(Preheat_done)) begin		//GPS上升沿到来给计时信号
		flag_start <= 1'b1;
	end
	else if (flag_DIV_RST_posedge) begin	//复位信号来停止计时
		flag_start <= 1'b0;
	end
	else begin
		flag_start <= flag_start;
	end
end

/* 分频计数 */
always @(posedge CLK_SYS or negedge CLK_RST) begin
	if (!CLK_RST) begin
		cnt_period <= 24'd0;		
	end
	else if (flag_start == 1'b1) begin
      	if (cnt_period == period - 1'b1) begin
			cnt_period <= 24'd0;
		end
		else begin
			cnt_period <= cnt_period + 1'b1;
		end
   end
   else begin
		cnt_period <= 24'd0;
   end

end

/* 输出本地1PPS */
always @(posedge CLK_SYS or negedge CLK_RST) begin
	if (!CLK_RST) begin
		_1PPS_Local <= 1'b0;		
	end
	else if ((cnt_period < pulse - 1'b1)&&(flag_start)) begin		//不在复位状态，且开始计时
		_1PPS_Local <= 1'b1;
	end
	else begin
		_1PPS_Local <= 1'b0;
	end
end

endmodule
