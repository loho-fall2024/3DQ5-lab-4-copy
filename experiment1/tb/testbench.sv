/*
Copyright by Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`default_nettype none

module TB;

	logic [17:0] switch;
	logic [6:0] seven_seg_n[7:0];
	logic [17:0] led_red;
	logic [8:0] led_green;

	//UUT instance
	experiment1 UUT(
		.SWITCH_I(switch),
		.SEVEN_SEGMENT_N_O(seven_seg_n),
		.LED_RED_O(led_red),
		.LED_GREEN_O(led_green));

	initial begin
		$timeformat(-6, 2, "us", 10);
		switch = 18'h00000;
	end

	initial begin
		# 100;
		switch = 18'h00001;
		# 100;
		switch = 18'h00003;
		# 100;
		switch = 18'h00007;
		# 100;
		switch = 18'h00000;
		# 100;
	end

	always@(led_red) begin
		$display("%t: red leds = %b", $realtime, led_red);
	end
	always@(led_green) begin
		$display("%t: green leds = %b", $realtime, led_green);
	end
	always@(seven_seg_n[0]) begin
		$display("%t: seven_seg[0] = %b", $realtime, seven_seg_n[0]);
	end
	always@(seven_seg_n[7]) begin
		$display("%t: seven_seg[7] = %b", $realtime, seven_seg_n[7]);
	end


endmodule
