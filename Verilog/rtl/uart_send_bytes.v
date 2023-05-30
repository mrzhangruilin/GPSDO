module UART_SEND_BYTES (
    input					CLK_SYS			,             	//系统时钟
    input					CLK_RST			,           	//系统复位，低电平有效

    input				 	Bytes_EN			,         		//使能信号
	 input	[31:0]		Bytes_DR			,					//数据输入
	 input					Uart_TX_busy   ,    				//发送忙状态标志
    output  reg         Bytes_busy		,       			//多字节发送中

    output  reg			Uart_EN			,             	//发送使能信号
    output  reg [ 7:0]	Uart_din				           	//待发送数据
);
	 
parameter bytes_num = 4;	//用来判断要发送几个字节	

reg 	[31:0] 	data;					//发送的四字节数据
reg 	[31:0]	cnt_bytes;			//用来计发送到第几个字节，状态位，0-4

reg				bytes_en_d0; 
reg        		bytes_en_d1;  

wire				flag_en;

//捕获uart_en上升沿，得到一个时钟周期的脉冲信号
assign flag_en = (~bytes_en_d1) & bytes_en_d0;

//对发送使能信号uart_en延迟两个时钟周期
always @(posedge CLK_SYS or negedge CLK_RST) begin         
    if (!CLK_RST) begin
        bytes_en_d0 <= 1'b0;                                  
        bytes_en_d1 <= 1'b0;
    end                                                      
    else begin                                               
        bytes_en_d0 <= Bytes_EN;                               
        bytes_en_d1 <= bytes_en_d0;                            
    end
end


always @(posedge CLK_SYS or negedge CLK_RST) begin         
    if (!CLK_RST) begin
		Bytes_busy <= 1'b0;
		data <= 32'd0;
	end
	else begin
		if((flag_en)&&(Bytes_busy == 1'b0)) begin
			Bytes_busy <= 1'b1;
			data <= Bytes_DR;
		end
		else if(cnt_bytes == bytes_num) begin
			Bytes_busy <= 1'b0;
		end
		else begin
			Bytes_busy <= Bytes_busy;
		end
		
	end
end

always @(negedge Uart_TX_busy or posedge flag_en) begin      
	if(flag_en) begin
		cnt_bytes <= 1'b1;
	end
	else begin
		if (cnt_bytes == bytes_num)
			cnt_bytes <= 1'b0;
		else 
			cnt_bytes <= cnt_bytes + 1'b1;
	end
end

always @(posedge CLK_SYS or negedge CLK_RST) begin 
	if (!CLK_RST) begin
		Uart_EN <= 1'b0;
	end
	else begin
		if ((cnt_bytes > 1'b0)&&(Uart_EN == 1'b0)&&(cnt_bytes<=bytes_num)) begin
			Uart_din <= data>>((bytes_num-cnt_bytes)*8);
			Uart_EN <= 1'b1;
		end
		else if (Uart_TX_busy == 1'b0) begin
			Uart_EN <= 1'b0;
		end
		else begin
			Uart_EN <= Uart_EN;
		end
	end
end


endmodule
