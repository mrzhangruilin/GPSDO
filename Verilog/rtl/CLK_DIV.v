module CLK_DIV (
    input   	CLK_SYS,
	input		CLK_RST,
    input   	CLK_10M,
    input   	_1PPS_GPS,

    output  reg	_1PPS_Local
);
    

parameter pulse = 10_000_000;   //鑴夊啿鍛ㄦ湡
reg [24:0]	cnt_pulse;		    //鑴夊啿鍛ㄦ湡璁℃暟
reg         flag_start;         //鏈湴1pps寮€濮嬩骇鐢熸爣蹇椾綅

always @(posedge _1PPS_GPS or negedge CLK_RST) begin
    if (!CLK_RST) begin
        flag_start <= 1'b0;
    end
    else begin
        flag_start <= 1'b1;
    end
end

always @(posedge CLK_10M or negedge CLK_RST) begin
	if (!CLK_RST) begin
		cnt_pulse <= 16'd0;		
	end
	else if (flag_start == 1'b1) begin
        if (cnt_pulse == pulse - 1'b1) begin
			cnt_pulse <= 16'd0;
		end
		else begin
			cnt_pulse <= cnt_pulse + 1'b1;
		end
    end
    else begin
        cnt_pulse <= cnt_pulse;
    end

end

always @(posedge CLK_SYS or negedge CLK_RST) begin
	if (!CLK_RST) begin
		_1PPS_Local <= 1'b1;		
	end
	else if (cnt_pulse == 999999) begin
		_1PPS_Local <= 1'b0;
	end
	else if (cnt_pulse == 9999999) begin
		_1PPS_Local <= 1'b1;
	end
	else begin
		_1PPS_Local <= _1PPS_Local;
	end
end
endmodule