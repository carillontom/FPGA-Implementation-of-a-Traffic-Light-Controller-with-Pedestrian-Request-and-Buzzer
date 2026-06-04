module button_pulse#(
    parameter integer DEBOUNCE_COUNT = 500000  // chỉnh theo clock
)(
	input logic clk, rst_n,
	input logic btn_in,
	output logic btn_pulse
);

    // 2-FF synchronizer
    logic btn_sync_0, btn_sync_1;

    // debounce
    logic btn_stable;
    logic btn_stable_prev;
    logic [$clog2(DEBOUNCE_COUNT):0] debounce_cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btn_sync_0      <= 1'b0;
            btn_sync_1      <= 1'b0;
            btn_stable      <= 1'b0;
            btn_stable_prev <= 1'b0;
            debounce_cnt    <= '0;
            btn_pulse       <= 1'b0;
        end
        else begin
            // =========================
            // 1) Synchronizer
            // =========================
            btn_sync_0 <= btn_in;
            btn_sync_1 <= btn_sync_0;

            // =========================
            // 2) Debounce
            // Nếu tín hiệu đồng bộ khác trạng thái ổn định hiện tại,
            // bắt đầu đếm. Khi đủ lâu thì mới cập nhật btn_stable.
            // =========================
            if (btn_sync_1 == btn_stable) begin
                debounce_cnt <= '0;
            end
            else begin
                if (debounce_cnt == DEBOUNCE_COUNT - 1) begin
                    btn_stable   <= btn_sync_1;
                    debounce_cnt <= '0;
                end
                else begin
                    debounce_cnt <= debounce_cnt + 1'b1;
                end
            end

            // =========================
            // 3) Edge detector
            // tạo xung 1 clock khi btn_stable đổi từ 0 -> 1
            // =========================
            btn_stable_prev <= btn_stable;
            btn_pulse       <= btn_stable & ~btn_stable_prev;
        end
    end

endmodule