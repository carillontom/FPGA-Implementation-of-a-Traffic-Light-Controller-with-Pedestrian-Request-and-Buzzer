module ped_req_reg(
	input logic clk, rst_n,
	input logic btn_pulse, 			//from button_pulse.sv
	input logic req_clr,				//clear request signal from processor
	output logic ped_req
);

	always_ff @(posedge clk or negedge rst_n) begin
		if(~rst_n)
			ped_req <= 1'b0;
		else if(req_clr)
			ped_req <= 1'b0;
		else if(btn_pulse)
			ped_req <= 1'b1;
	end
endmodule
