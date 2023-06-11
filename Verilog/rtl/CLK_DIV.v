module CLK_DIV (
    input   	CLK_SYS,		//暂定系统时钟和10M是同一个时钟
	 input		CLK_RST,
    //input   	CLK_10M,
    input   	_1PPS_GPS,

    output  reg	_1PPS_Local
);
    

parameter	pulse = 10_000_000;   
reg [23:0]	cnt_pulse;		    
reg         flag_start;         

always @(posedge _1PPS_GPS or negedge CLK_RST) begin
    if (!CLK_RST) begin
        flag_start <= 1'b0;
    end
    else begin
        flag_start <= 1'b1;
    end
end

always @(posedge CLK_SYS or negedge CLK_RST) begin	//此处应该是晶振时钟，暂用系统时钟
	if (!CLK_RST) begin
		cnt_pulse <= 24'd0;		
	end
	else if (flag_start == 1'b1) begin
      if (cnt_pulse == pulse - 1'b1) begin
			cnt_pulse <= 24'd0;
		end
		else begin
			cnt_pulse <= cnt_pulse + 1'b1;
		end
   end
   else begin
		cnt_pulse <= 24'd0;
   end

end

always @(posedge CLK_SYS or negedge CLK_RST) begin
	if (!CLK_RST) begin
		_1PPS_Local <= 1'b1;		
	end
	else if (cnt_pulse == ((pulse / 10)- 1)) begin
		_1PPS_Local <= 1'b0;
	end
	else if (cnt_pulse == pulse - 1'b1) begin
		_1PPS_Local <= 1'b1;
	end
	else begin
		_1PPS_Local <= _1PPS_Local;
	end
end

endmodule
