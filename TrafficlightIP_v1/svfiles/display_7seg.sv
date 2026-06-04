module display_7seg(
	input  logic [7:0] timer_count,

	// OLD:
	// output logic [6:0] hex1, hex2
	//
	// MODIFIED:
	// 3-digit display:
	// hex_hundreds -> HEX5
	// hex_tens     -> HEX4
	// hex_ones     -> HEX3
	output logic [6:0] hex_hundreds,
	output logic [6:0] hex_tens,
	output logic [6:0] hex_ones
);

    logic [3:0] hundreds;
    logic [3:0] tens;
    logic [3:0] ones;

    always_comb begin
        // MODIFIED:
        // Use sized constants to avoid Quartus truncation warnings.
        hundreds = timer_count / 8'd100;
        tens     = (timer_count % 8'd100) / 8'd10;
        ones     = timer_count % 8'd10;
    end

    // MODIFIED:
    // HEX5 always displays the hundreds digit.
    // Therefore:
    //   15  -> 015
    //   3   -> 003
    //   0   -> 000
    hexled u_hundreds (
        .data_in  (hundreds),
        .hex_data (hex_hundreds)
    );

    hexled u_tens (
        .data_in  (tens),
        .hex_data (hex_tens)
    );

    hexled u_ones (
        .data_in  (ones),
        .hex_data (hex_ones)
    );

endmodule