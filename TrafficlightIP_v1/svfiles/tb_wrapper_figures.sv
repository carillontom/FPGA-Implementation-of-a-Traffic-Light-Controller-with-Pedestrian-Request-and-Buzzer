`timescale 1ns/1ps

module tb_wrapper_figures;

    //============================================================
    // Board-level signals
    //============================================================
    logic        CLOCK_50;
    logic [3:0]  KEY;
    logic [9:0]  SW;

    logic [9:0]  LEDR;
    logic [3:0]  GPIO;

    logic [6:0]  HEX5;
    logic [6:0]  HEX4;
    logic [6:0]  HEX3;
    logic [6:0]  HEX2;
    logic [6:0]  HEX1;
    logic [6:0]  HEX0;

    //============================================================
    // Report waveform view signals
    //
    // These are the signals you should add to waveform.
    // They are made only to make Figure 6.1 - 6.4 easy to read.
    //============================================================
    logic [3:0]  figure_id;

    logic        tick_1s_view;

    logic        green_view;
    logic        yellow_view;
    logic        red_view;

    logic        ped_view;
    logic        req_clear_view;

    logic [7:0]  timer_count_view;

    logic        timer_expired_view;
    logic        timer_10sec_view;
    logic        timer_5sec_view;

    logic        timer_load_view;
    logic        timer_add_view;
    logic        timer_sub_view;
    logic [7:0]  timer_value_view;

    logic        buzzer_view;
    logic [1:0]  beep_level_view;

    logic [3:0]  fsm_state_view;

    //============================================================
    // DUT
    //============================================================
    wrapper dut (
        .CLOCK_50 (CLOCK_50),
        .KEY      (KEY),
        .SW       (SW),

        .LEDR     (LEDR),
        .GPIO     (GPIO),

        .HEX5     (HEX5),
        .HEX4     (HEX4),
        .HEX3     (HEX3),
        .HEX2     (HEX2),
        .HEX1     (HEX1),
        .HEX0     (HEX0)
    );

    //============================================================
    // Speed up buzzer timing for simulation waveform only.
    //
    // This does NOT affect the hardware design.
    // It only makes buzzer_out toggles visible in ModelSim.
    //============================================================
    defparam dut.u_buzzer.CLK_FREQ_HZ = 1000;

    //============================================================
    // Connect internal DUT signals to clean waveform view signals
    //============================================================
    assign tick_1s_view = dut.u_core.tick_1s;

    assign red_view     = dut.led_red;
    assign yellow_view  = dut.led_yellow;
    assign green_view   = dut.led_green;

    assign ped_view       = dut.u_core.ped_request;
    assign req_clear_view = dut.u_core.req_clear;

    assign timer_count_view   = dut.u_core.timer_counter_debug;
    assign timer_expired_view = dut.u_core.timer_expired_signal;
    assign timer_10sec_view   = dut.u_core.timer_10sec_left;
    assign timer_5sec_view    = dut.u_core.timer_5sec_left;

    assign timer_load_view  = dut.u_core.u4.timer_load;
    assign timer_add_view   = dut.u_core.u4.timer_add;
    assign timer_sub_view   = dut.u_core.u4.timer_sub;
    assign timer_value_view = dut.u_core.u4.timer_value;

    assign buzzer_view     = dut.buzzer_out;
    assign beep_level_view = dut.beep_level;

    assign fsm_state_view = dut.u_core.u4.state;

    //============================================================
    // Clock generation: 50 MHz clock, period = 20 ns
    //============================================================
    initial begin
        CLOCK_50 = 1'b0;
        forever #10 CLOCK_50 = ~CLOCK_50;
    end

    //============================================================
    // Reset system
    //============================================================
    task automatic reset_system;
        begin
            KEY = 4'b1111;
            SW  = 10'b0;

            // Enable system
            SW[9] = 1'b1;

            // Manual load disabled
            SW[8] = 1'b0;

            // Manual time value reserved
            SW[7:0] = 8'd23;

            // Force internal simulation signals
            force dut.u_core.tick_1s       = 1'b0;
            force dut.u_core.button_pulsee = 1'b0;

            // Reset active-low
            KEY[0] = 1'b0;
            repeat (8) @(posedge CLOCK_50);

            KEY[0] = 1'b1;
            repeat (10) @(posedge CLOCK_50);
        end
    endtask

    //============================================================
    // Generate one simulated 1-second tick
    //
    // In hardware, tick_1s comes from clk_divider.
    // In simulation, we force it to avoid waiting 50M cycles.
    //============================================================
    task automatic pulse_tick_1s;
        begin
            @(negedge CLOCK_50);
            force dut.u_core.tick_1s = 1'b1;

            @(negedge CLOCK_50);
            force dut.u_core.tick_1s = 1'b0;

            repeat (4) @(posedge CLOCK_50);
        end
    endtask

    //============================================================
    // Generate one simulated pedestrian button pulse
    //
    // In hardware, KEY[2] goes through debounce.
    // In simulation, we force button_pulsee directly.
    //============================================================
    task automatic press_ped_button;
        begin
            @(negedge CLOCK_50);
            force dut.u_core.button_pulsee = 1'b1;

            @(negedge CLOCK_50);
            force dut.u_core.button_pulsee = 1'b0;

            repeat (6) @(posedge CLOCK_50);
        end
    endtask

    //============================================================
    // Wait until a phase and timer value are reached
    //============================================================
    task automatic wait_phase_timer(
        input string name,
        input logic exp_red,
        input logic exp_yellow,
        input logic exp_green,
        input logic [7:0] exp_timer
    );
        int timeout;
        begin
            timeout = 0;

            while (
                red_view          !== exp_red    ||
                yellow_view       !== exp_yellow ||
                green_view        !== exp_green  ||
                timer_count_view  !== exp_timer
            ) begin
                @(posedge CLOCK_50);
                timeout++;

                if (timeout > 5000) begin
                    $display("[%0t] FAIL: timeout waiting for %s", $time, name);
                    $display("red=%0b yellow=%0b green=%0b timer=%0d ped=%0b",
                             red_view, yellow_view, green_view, timer_count_view, ped_view);
                    $stop;
                end
            end

            $display("[%0t] PASS: %s | R=%0b Y=%0b G=%0b timer=%0d ped=%0b",
                     $time, name, red_view, yellow_view, green_view, timer_count_view, ped_view);
        end
    endtask

    //============================================================
    // Figure 6.1
    // Normal green-yellow-red cycle
    //============================================================
    task automatic figure_6_1_normal_cycle;
        begin
            figure_id = 4'd1;
            $display("==================================================");
            $display("Figure 6.1 - Normal GREEN-YELLOW-RED cycle");
            $display("==================================================");

            reset_system();

            wait_phase_timer("Initial GREEN", 1'b0, 1'b0, 1'b1, 8'd15);

            repeat (15) pulse_tick_1s;
            wait_phase_timer("YELLOW after GREEN expired", 1'b0, 1'b1, 1'b0, 8'd3);

            repeat (3) pulse_tick_1s;
            wait_phase_timer("RED after YELLOW expired", 1'b1, 1'b0, 1'b0, 8'd15);

            repeat (15) pulse_tick_1s;
            wait_phase_timer("Back to GREEN after RED expired", 1'b0, 1'b0, 1'b1, 8'd15);

            repeat (20) @(posedge CLOCK_50);
        end
    endtask

    //============================================================
    // Figure 6.2
    // Pedestrian request during green phase
    //============================================================
    task automatic figure_6_2_ped_green;
        begin
            figure_id = 4'd2;
            $display("==================================================");
            $display("Figure 6.2 - Pedestrian request during GREEN");
            $display("==================================================");

            reset_system();

            wait_phase_timer("Initial GREEN", 1'b0, 1'b0, 1'b1, 8'd15);

            // Press pedestrian button while green timer is still > 10.
            press_ped_button();

            // Expected: GREEN_DEC, timer forced to 2.
            wait_phase_timer("GREEN request accepted, timer forced to 2",
                             1'b0, 1'b0, 1'b1, 8'd2);

            repeat (30) @(posedge CLOCK_50);
        end
    endtask

    //============================================================
    // Figure 6.3
    // Pedestrian request during red phase
    //============================================================
    task automatic figure_6_3_ped_red;
        begin
            figure_id = 4'd3;
            $display("==================================================");
            $display("Figure 6.3 - Pedestrian request during RED");
            $display("==================================================");

            reset_system();

            wait_phase_timer("Initial GREEN", 1'b0, 1'b0, 1'b1, 8'd15);

            // Go to RED.
            repeat (15) pulse_tick_1s;
            wait_phase_timer("YELLOW", 1'b0, 1'b1, 1'b0, 8'd3);

            repeat (3) pulse_tick_1s;
            wait_phase_timer("RED", 1'b1, 1'b0, 1'b0, 8'd15);

            // Count RED down to 4 seconds.
            repeat (11) pulse_tick_1s;
            wait_phase_timer("RED timer = 4", 1'b1, 1'b0, 1'b0, 8'd4);

            // Press pedestrian button while red timer < 5.
            press_ped_button();

            // Expected: RED_INC, timer = 4 + 10 = 14.
            wait_phase_timer("RED request accepted, timer extended to 14",
                             1'b1, 1'b0, 1'b0, 8'd14);

            repeat (30) @(posedge CLOCK_50);
        end
    endtask

    //============================================================
    // Figure 6.4
    // Buzzer output and timer count during red phase
    //
    // Current wrapper enables buzzer when:
    //   red_active = led_red & ped_request_debug
    //
    // Therefore, for a visible buzzer waveform, we create a
    // pedestrian request during RED while timer is still large.
    // The request stays pending until timer < 5, so buzzer is active.
    //============================================================
    task automatic figure_6_4_buzzer_red;
        begin
            figure_id = 4'd4;
            $display("==================================================");
            $display("Figure 6.4 - Buzzer output during RED");
            $display("==================================================");

            reset_system();

            wait_phase_timer("Initial GREEN", 1'b0, 1'b0, 1'b1, 8'd15);

            // Go to RED.
            repeat (15) pulse_tick_1s;
            wait_phase_timer("YELLOW", 1'b0, 1'b1, 1'b0, 8'd3);

            repeat (3) pulse_tick_1s;
            wait_phase_timer("RED", 1'b1, 1'b0, 1'b0, 8'd15);

            // Press pedestrian button early in RED.
            // Since timer_5sec_view = 0, request will remain pending.
            press_ped_button();

            // Slow beep region: timer > 10.
            $display("[%0t] Slow beep region", $time);
            repeat (1200) @(posedge CLOCK_50);

            // Move timer to 10: medium beep region.
            repeat (5) pulse_tick_1s;
            wait_phase_timer("RED timer = 10", 1'b1, 1'b0, 1'b0, 8'd10);
            $display("[%0t] Medium beep region", $time);
            repeat (900) @(posedge CLOCK_50);

            // Move timer to 5: fast beep region.
            repeat (5) pulse_tick_1s;
            wait_phase_timer("RED timer = 5", 1'b1, 1'b0, 1'b0, 8'd5);
            $display("[%0t] Fast beep region", $time);
            repeat (700) @(posedge CLOCK_50);
        end
    endtask

    //============================================================
    // Main simulation
    //============================================================
    initial begin
        figure_id = 4'd0;

        figure_6_1_normal_cycle();
        figure_6_2_ped_green();
        figure_6_3_ped_red();
        figure_6_4_buzzer_red();

        $display("==================================================");
        $display("ALL REPORT WAVEFORM TESTS COMPLETED");
        $display("==================================================");

        #200;
        $stop;
    end

endmodule