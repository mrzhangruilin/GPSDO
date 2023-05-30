module UART_SEND(
    input	           CLK_SYS			,     //系统时钟
    input              CLK_RST			,		//系统复位，低电平有效
    
    input              uart_tx_en		,     //发送使能信号
    input       [ 7:0] uart_din			,     //待发送数据
    output             uart_tx_busy		,     //发送忙状态标志 
    output             flag_en     		,
    output  reg        flag_tx			,     //发送过程标志信号
    output  reg [ 7:0] data_tx			,     //寄存发送数据
    output  reg [ 3:0] cnt_tx				,     //发送数据计数器
    output  reg        uart_txd             	//UART发送端口
    );
    
//parameter define
parameter  CLK_FREQ = 50000000;             	//系统时钟频率
parameter  UART_BPS = 9600;                 	//串口波特率

localparam  BPS_CNT  = CLK_FREQ/UART_BPS;   	//为得到指定波特率，对系统时钟计数BPS_CNT次

//reg define
reg        uart_en_d0; 
reg        uart_en_d1;  
reg [15:0] clk_cnt;                           //系统时钟计数器

//*****************************************************
//**                    main code
//*****************************************************
//在串口发送过程中给出忙状态标志
assign uart_tx_busy = flag_tx;

//捕获uart_en上升沿，得到一个时钟周期的脉冲信号
assign flag_en = (~uart_en_d1) & uart_en_d0;

//对发送使能信号uart_en延迟两个时钟周期
always @(posedge CLK_SYS or negedge CLK_RST) begin         
    if (!CLK_RST) begin
        uart_en_d0 <= 1'b0;                                  
        uart_en_d1 <= 1'b0;
    end                                                      
    else begin                                               
        uart_en_d0 <= uart_tx_en;                               
        uart_en_d1 <= uart_en_d0;                            
    end
end

//当脉冲信号flag_en到达时,寄存待发送的数据，并进入发送过程          
always @(posedge CLK_SYS or negedge CLK_RST) begin         
    if (!CLK_RST) begin                                  
        flag_tx <= 1'b0;
        data_tx <= 8'd0;
    end 
    else if (flag_en) begin                 //检测到发送使能上升沿                      
            flag_tx <= 1'b1;                //进入发送过程，标志位flag_tx拉高
            data_tx <= uart_din;            //寄存待发送的数据
        end
                                            //计数到停止位结束时，停止发送过程
        else if ((cnt_tx == 4'd9) && (clk_cnt == BPS_CNT - (BPS_CNT/16))) begin                                       
            flag_tx <= 1'b0;                //发送过程结束，标志位flag_tx拉低
            data_tx <= 8'd0;
        end
        else begin
            flag_tx <= flag_tx;
            data_tx <= data_tx;
        end 
end

//进入发送过程后，启动系统时钟计数器
always @(posedge CLK_SYS or negedge CLK_RST) begin         
    if (!CLK_RST)                             
        clk_cnt <= 16'd0;                                  
    else if (flag_tx) begin                 //处于发送过程
        if (clk_cnt < BPS_CNT - 1)
            clk_cnt <= clk_cnt + 1'b1;
        else
            clk_cnt <= 16'd0;               //对系统时钟计数达一个波特率周期后清零
    end
    else                             
        clk_cnt <= 16'd0; 				        //发送过程结束
end

//进入发送过程后，启动发送数据计数器
always @(posedge CLK_SYS or negedge CLK_RST) begin         
    if (!CLK_RST)                             
        cnt_tx <= 4'd0;
    else if (flag_tx) begin               //处于发送过程
        if (clk_cnt == BPS_CNT - 1)			//对系统时钟计数达一个波特率周期
            cnt_tx <= cnt_tx + 1'b1;		//此时发送数据计数器加1
        else
            cnt_tx <= cnt_tx;       
    end
    else                              
        cnt_tx  <= 4'd0;				    //发送过程结束
end

//根据发送数据计数器来给uart发送端口赋值
always @(posedge CLK_SYS or negedge CLK_RST) begin        
    if (!CLK_RST)  
        uart_txd <= 1'b1;        
    else if (flag_tx)
        case(cnt_tx)
            4'd0: uart_txd <= 1'b0;         //起始位 
            4'd1: uart_txd <= data_tx[0];   //数据位最低位
            4'd2: uart_txd <= data_tx[1];
            4'd3: uart_txd <= data_tx[2];
            4'd4: uart_txd <= data_tx[3];
            4'd5: uart_txd <= data_tx[4];
            4'd6: uart_txd <= data_tx[5];
            4'd7: uart_txd <= data_tx[6];
            4'd8: uart_txd <= data_tx[7];   //数据位最高位
            4'd9: uart_txd <= 1'b1;         //停止位
            default: ;
        endcase
    else 
        uart_txd <= 1'b1;                   //空闲时发送端口为高电平
end

endmodule	          



