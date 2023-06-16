版本说明
V3.1
1.Measure是测相位模块，PID是计算PWM占空比模块，PWM是输出模块，CLK_DIV是控制产生本地1PPS模块
2.Measure中，测相位方式如下：
	_1PPS_Local信号上升沿到来，Measure_Done上产生一个时钟周期的脉冲
	_1PPS_GPS信号上升沿到来，flag_cnt_phase_start置高，开始计数
	优先判断了_1PPS_Local，这样如果本地和GPS上升沿同时到来，那么就不开始计数，但是产生计数完成的信号Measure_Done
3.Measure_Phase是直接当计数存储器用的，里面的数据只保留一个时钟周期即计数完成信号Measure_Done那个周期
4.由于第三条，所以PID中，在检测到Measure_Done上升沿时，就要将Measure_Phase相位差暂存下来，否则将丢失，变成0；
5.CLK_DIV模块中，有一个补偿输入，是有符号的，相位差过大时，通过补偿计数来调整相位差，而不是PID算法



技术说明：
1.更改模块常量时，一定要重新创建元件，然后在顶层中更新，重新例化顶层模块
2.减少大于小于的使用量，改成使用==可以减少一些资源使用率