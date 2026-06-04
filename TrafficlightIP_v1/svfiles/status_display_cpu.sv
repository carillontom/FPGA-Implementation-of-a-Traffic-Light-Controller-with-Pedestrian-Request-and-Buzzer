

module status_display_cpu (
    input  logic ped_req,

    output logic [6:0] HEX2,
    output logic [6:0] HEX1,
    output logic [6:0] HEX0
);

    // Active-low seven-segment encoding.
    localparam logic [6:0] SEG_P = 7'b0001100;
    localparam logic [6:0] SEG_E = 7'b0000110;
    localparam logic [6:0] SEG_D = 7'b0100001;

    localparam logic [6:0] SEG_N = 7'b0101011;
    localparam logic [6:0] SEG_O = 7'b1000000;
    localparam logic [6:0] SEG_R = 7'b0101111;

    always_comb begin
        if (ped_req) begin
            HEX2 = SEG_P;
            HEX1 = SEG_E;
            HEX0 = SEG_D;
        end
        else begin
            HEX2 = SEG_N;
            HEX1 = SEG_O;
            HEX0 = SEG_R;
        end
    end

endmodule : status_display_cpu