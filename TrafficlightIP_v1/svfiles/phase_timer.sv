module phase_timer(				//module timer to count down for the current state
	input logic tick_1s, clk,
	input logic rst_n, en,
	input logic [7:0] timer_value,
	
	input logic timer_add, timer_sub, timer_load,			//input for controlling the value of the timer
	
	input logic [7:0] manual_time,
	input logic manual_load,
	
	output logic [7:0] timer_count,
	output logic timer_10sec_remaining, timer_5sec_remaining, timer_expired
);

	always_ff @(posedge clk or negedge rst_n) begin
		 if (!rst_n) begin
			  timer_count <= 8'd0;
		 end
		 else if (manual_load) begin
			  timer_count <= manual_time;
		 end
		 else if (!en) begin
			  timer_count <= timer_count;
		 end
		 else if (timer_load) begin
			  timer_count <= timer_value;
		 end
		 else if (timer_add) begin
			  timer_count <= timer_count + timer_value;
		 end
		 else if (timer_sub) begin
			  if (timer_count > timer_value)
					timer_count <= timer_count - timer_value;
			  else
					timer_count <= 8'd0;
		 end
		 else if (tick_1s) begin
			  if (timer_count > 0)
					timer_count <= timer_count - 1'b1;
			  else
					timer_count <= 8'd0;
		 end
		 else begin
			  timer_count <= timer_count;
		 end
	end

	//always comb block to check the remaining time
	always_comb begin
		timer_expired = (timer_count == 0);
		timer_10sec_remaining = (timer_count <= 10);
		timer_5sec_remaining = (timer_count < 5);
	end
	
endmodule
				