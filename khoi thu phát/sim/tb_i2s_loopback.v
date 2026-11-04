`timescale 1ns/1ps

module tb_i2s_loopback;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg bclk = 1'b0;
    reg ws = 1'b1;
    reg mic_sd = 1'b0;

    wire signed [23:0] rx_data;
    wire rx_valid;
    wire speaker_sd;

    integer slot_bit = 31;
    integer source_index = 0;
    integer rx_count = 0;
    integer checked_slots = 0;
    integer pass_slots = 0;
    integer fail_count = 0;
    integer slot_errors = 0;
    integer left_valid_count = 0;

    reg [23:0] mic_sample = 24'd0;
    reg [23:0] last_rx_sample = 24'd0;
    reg [23:0] tx_expected = 24'd0;
    reg [23:0] previous_data = 24'd0;
    reg previous_valid = 1'b0;
    reg rx_seen = 1'b0;
    reg check_tx = 1'b0;
    reg expected_bit;

    // Independent clocks for functional verification only.
    always #18.5185 clk = ~clk;       // approximately 27 MHz
    always #162.7604 bclk = ~bclk;    // approximately 3.072 MHz

    i2s_rx u_rx (
        .clk(clk), .rst_n(rst_n),
        .bclk(bclk), .ws(ws), .sd(mic_sd),
        .sample_data(rx_data), .sample_valid(rx_valid)
    );

    i2s_tx u_tx (
        .clk(clk), .rst_n(rst_n),
        .bclk(bclk), .ws(ws),
        .sample_data(rx_data), .sample_valid(rx_valid),
        .sd_out(speaker_sd)
    );

    function [23:0] vector;
        input integer n;
        begin
            case (n)
                0: vector = 24'h123456;
                1: vector = 24'h000000;
                2: vector = 24'h7FFFFF;
                3: vector = 24'h800000;
                4: vector = 24'hFFFFFF;
                5: vector = 24'hA5C39E;
                6: vector = 24'h555555;
                7: vector = 24'hAAAAAA;
                default: vector = 24'h000000;
            endcase
        end
    endfunction

    // INMP441 stimulus. WS changes every 32 BCLK bits; audio data is
    // left-justified after the one-bit I2S delay (slot bits 1..24).
    // Neither the RX nor TX internal counters are used here.
    always @(negedge bclk) begin
        if (!rst_n) begin
            ws = 1'b1;
            mic_sd = 1'b0;
            slot_bit = 31;
            source_index = 0;
            check_tx = 1'b0;
        end else begin
            if (slot_bit == 31) begin
                slot_bit = 0;
                if (ws == 1'b0 && left_valid_count != 1) begin
                    $display("FAIL: Left slot had %0d rx_valid pulses", left_valid_count);
                    fail_count = fail_count + 1;
                end
                ws = ~ws;
                if (ws == 1'b0) begin
                    mic_sample = vector(source_index);
                    source_index = source_index + 1;
                    left_valid_count = 0;
                    // TX must reproduce the previously received sample.
                    // The first frame is ignored while the pipeline fills.
                    tx_expected = last_rx_sample;
                    check_tx = rx_seen;
                end
            end else begin
                slot_bit = slot_bit + 1;
            end

            if (ws == 1'b0 && slot_bit >= 1 && slot_bit <= 24)
                mic_sd = mic_sample[24-slot_bit];
            else
                mic_sd = 1'b0;
        end
    end

    // Observe registered RX outputs between system-clock rising edges.
    always @(negedge clk) begin
        if (rst_n) begin
            if (rx_valid) begin
                if (ws !== 1'b0 || slot_bit != 24) begin
                    $display("FAIL: RX valid at wrong WS/bit position");
                    fail_count = fail_count + 1;
                end
                if (rx_data !== mic_sample) begin
                    $display("FAIL: RX expected %h, received %h", mic_sample, rx_data);
                    fail_count = fail_count + 1;
                end
                left_valid_count = left_valid_count + 1;
                rx_count = rx_count + 1;
                last_rx_sample = rx_data;
                rx_seen = 1'b1;
            end
            if (rx_valid && previous_valid) begin
                $display("FAIL: RX valid longer than one system-clock cycle");
                fail_count = fail_count + 1;
            end
            if (!rx_valid && rx_data !== previous_data) begin
                $display("FAIL: RX data changed without rx_valid");
                fail_count = fail_count + 1;
            end
            previous_valid = rx_valid;
            previous_data = rx_data;
        end
    end

    // Model of MAX98357A serial input. Check both L/R slots at the
    // rising BCLK edge, including I2S delay and zero padding.
    always @(posedge bclk) begin
        if (rst_n && check_tx) begin
            if (slot_bit == 0)
                slot_errors = 0;

            if (slot_bit >= 1 && slot_bit <= 24)
                expected_bit = tx_expected[24-slot_bit];
            else
                expected_bit = 1'b0;

            if (speaker_sd !== expected_bit) begin
                if (slot_errors == 0)
                    $display("BIT FAIL: WS=%b bit=%0d expected=%b got=%b",
                             ws, slot_bit, expected_bit, speaker_sd);
                slot_errors = slot_errors + 1;
            end

            if (slot_bit == 31) begin
                checked_slots = checked_slots + 1;
                if (slot_errors == 0) begin
                    pass_slots = pass_slots + 1;
                    $display("PASS: TX WS=%b sample=%h", ws, tx_expected);
                end else begin
                    fail_count = fail_count + 1;
                    $display("FAIL: TX WS=%b sample=%h bit_errors=%0d",
                             ws, tx_expected, slot_errors);
                end
            end
        end
    end

    initial begin
        #200;
        rst_n = 1'b1;
        wait (checked_slots == 12);
        #50;
        $display("====================================");
        $display("RX SAMPLES  = %0d", rx_count);
        $display("TX PASSES   = %0d", pass_slots);
        $display("TX CHECKED  = %0d", checked_slots);
        $display("FAIL COUNT  = %0d", fail_count);
        if (fail_count == 0 && pass_slots == 12 && rx_count >= 7)
            $display("I2S LOOPBACK TEST PASSED");
        else
            $display("I2S LOOPBACK TEST FAILED");
        $display("====================================");
        $stop;
    end

    initial begin
        #500000;
        $display("FAIL: timeout");
        $stop;
    end
endmodule
