module UART_SEND_BYTES (
    input					CLK_SYS			,             	//系统时钟
    input					CLK_RST			,           	//系统复位，低电平有效

    input				 	bytes_en			,         		//使能信号
	 input	[31:0]		bytes_dr			,					//数据输入
	 input					uart_tx_busy   ,    				//发送忙状态标志
    output  reg         bytes_busy		,       			//多字节发送中

    output  reg			uart_en			,             	//发送使能信号
    output  reg [ 7:0]	uart_din				           	//待发送数据
     
    );

reg [31:0] 	data;			//发送的四字节数据
reg [31:0]	bytes_cnt;		//用来计发送到第几个字节，状态位，0-4
parameter bytes_num = 4;	//用来判断要发送几个字节	
reg			bytes_en_d0; 
reg        	bytes_en_d1;  


//捕获uart_en上升沿，得到一个时钟周期的脉冲信号
assign en_flag = (~bytes_en_d1) & bytes_en_d0;

//对发送使能信号uart_en延迟两个时钟周期
always @(posedge CLK_SYS or negedge CLK_RST) begin         
    if (!CLK_RST) begin
        bytes_en_d0 <= 1'b0;                                  
        bytes_en_d1 <= 1'b0;
    end                                                      
    else begin                                               
        bytes_en_d0 <= bytes_en;                               
        bytes_en_d1 <= bytes_en_d0;                            
    end
end


always @(posedge CLK_SYS or negedge CLK_RST) begin         
    if (!CLK_RST) begin
		bytes_busy <= 1'b0;
		data <= 32'd0;
	end
	else begin
		if((en_flag)&&(bytes_busy == 1'b0)) begin
			bytes_busy <= 1'b1;
			data <= bytes_dr;
		end
		else if(bytes_cnt == bytes_num) begin
			bytes_busy <= 1'b0;
		end
		else begin
			bytes_busy <= bytes_busy;
		end
		
	end
end

always @(negedge uart_tx_busy or posedge en_flag) begin      
	if(en_flag) begin
		bytes_cnt <= 1'b1;
	end
	else begin
		if (bytes_cnt == bytes_num)
			bytes_cnt <= 1'b0;
		else 
			bytes_cnt <= bytes_cnt + 1'b1;
	end
end

always @(posedge CLK_SYS or negedge CLK_RST) begin 
	if (!CLK_RST) begin
		uart_en <= 1'b0;
	end
	else begin
		if ((bytes_cnt > 1'b0)&&(uart_en == 1'b0)&&(bytes_cnt<=bytes_num)) begin
			uart_din <= data>>((bytes_num-bytes_cnt)*8);
			uart_en <= 1'b1;
		end
		else if (uart_tx_busy == 1'b0) begin
			uart_en <= 1'b0;
		end
		else begin
			uart_en <= uart_en;
		end
	end
end


endmodule