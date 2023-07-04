module Preheat (
    input   				CLK_SYS,		
	input					CLK_RST,

	output	reg				Preheat_done	//预热完成标志位
);


reg [31:0]	cnt_3min;	//预热三分钟


always @(posedge CLK_SYS or negedge CLK_RST) begin
	if (!CLK_RST) begin
		cnt_3min <= 0;
		Preheat_done <= 1'b0;
	end
	else begin
		if (cnt_3min < 1_800_000_000) begin
			cnt_3min <= cnt_3min + 1'b1;
			Preheat_done <= 1'b0;
		end
		else begin
			cnt_3min <= cnt_3min;
			Preheat_done <= 1'b1;
		end
	end
end



endmodule


