module clk_divider(
	input logic clk_50,
	input logic rst_n,
	output logic tick_1s
);
	logic [31:0] counter;

    always_ff @(posedge clk_50 or negedge rst_n) begin
        if (!rst_n) begin
            counter  <= 32'd0;
            tick_1s  <= 1'b0;
        end
        else begin
            if (counter == 50_000_000 - 1) begin   // debug = 5, kit test = 50M
                counter <= 32'd0;
                tick_1s <= 1'b1;
            end
            else begin
                counter <= counter + 1'b1;
                tick_1s <= 1'b0;
            end
        end
    end
	
endmodule