
`timescale 1ns/1ps

module tb_i2s_independent;

    reg clk = 0;
    reg rst_n = 0;
    reg bclk = 0;
    reg ws = 1;
    reg sd = 0;

    wire signed [23:0] sample_data;
    wire sample_valid;

    integer slot_bit = 31;
    integer sample_index = -1;
    integer expected_index = 0;
    integer frame_count = 0;
    integer valid_in_frame = 0;
    integer pass_count = 0;
    integer fail_count = 0;

    reg [23:0] tx_sample = 0;
    reg [23:0] previous_data = 0;
    reg previous_valid = 0;

    // System clock: 27 MHz
    always #18.5185 clk = ~clk;

    // Independent I2S BCLK: 3.072 MHz
    always #162.7604 bclk = ~bclk;

    // Module under test
    i2s_rx dut (
        .clk(clk),
        .rst_n(rst_n),
        .bclk(bclk),
        .ws(ws),
        .sd(sd),
        .sample_data(sample_data),
        .sample_valid(sample_valid)
    );

    // Independent test vectors
    function [23:0] test_value;
        input integer index;
        begin
            case (index)
                0: test_value = 24'h123456;
                1: test_value = 24'h000000;
                2: test_value = 24'h7FFFFF;
                3: test_value = 24'h800000;
                4: test_value = 24'hFFFFFF;
                5: test_value = 24'hA5C39E;
                default: test_value = 24'h000000;
            endcase
        end
    endfunction

    // Simulate INMP441 independently.
    // Change WS and SD at falling BCLK edges.
    // First bit after WS transition is dummy.
    always @(negedge bclk) begin
        if (!rst_n) begin
            ws = 1;
            sd = 0;
            slot_bit = 31;
            sample_index = -1;
        end
        else begin
            if (slot_bit == 31) begin
                slot_bit = 0;

                // Check previous Left slot
                if (ws == 0) begin
                    if (valid_in_frame != 1) begin
                        $display("FAIL: Left frame has %0d valid pulses",
                                 valid_in_frame);
                        fail_count = fail_count + 1;
                    end
                    frame_count = frame_count + 1;
                    valid_in_frame = 0;
                end

                ws = ~ws;

                if (ws == 0) begin
                    sample_index = sample_index + 1;
                    tx_sample = test_value(sample_index);
                end
            end
            else begin
                slot_bit = slot_bit + 1;
            end

            // Slot bit 0: one-bit I2S delay
            // Slot bits 1..24: MSB to LSB
            // Slot bits 25..31: padding
            if (ws == 0 &&
                slot_bit >= 1 &&
                slot_bit <= 24)
                sd = tx_sample[24-slot_bit];
            else
                sd = 0;
        end
    end

    // Independent output checker
    always @(negedge clk) begin
        if (rst_n) begin
            if (sample_valid) begin
                valid_in_frame = valid_in_frame + 1;

                if (ws !== 0 || slot_bit != 24) begin
                    $display("FAIL: Wrong sample_valid timing");
                    fail_count = fail_count + 1;
                end

                if (sample_data === test_value(expected_index)) begin
                    $display("PASS: Expected=%h Received=%h",
                             test_value(expected_index), sample_data);
                    pass_count = pass_count + 1;
                end
                else begin
                    $display("FAIL: Expected=%h Received=%h",
                             test_value(expected_index), sample_data);
                    fail_count = fail_count + 1;
                end

                expected_index = expected_index + 1;
            end

            if (sample_valid && previous_valid) begin
                $display("FAIL: sample_valid lasts too long");
                fail_count = fail_count + 1;
            end

            if (!sample_valid && sample_data !== previous_data) begin
                $display("FAIL: sample_data changed without valid");
                fail_count = fail_count + 1;
            end

            previous_valid = sample_valid;
            previous_data = sample_data;
        end
    end

    initial begin
        #200;
        rst_n = 1;

        wait (frame_count == 6);
        #100;

        $display("==============================");
        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);
        $display("FRAMES     = %0d", frame_count);

        if (fail_count == 0 && pass_count == 6)
            $display("INDEPENDENT I2S TEST PASSED");
        else
            $display("INDEPENDENT I2S TEST FAILED");

        $display("==============================");
        $stop;
    end

endmodule

`timescale 1ns/1ps

module tb_i2s_independent;

    reg clk = 0;
    reg rst_n = 0;
    reg bclk = 0;
    reg ws = 1;
    reg sd = 0;

    wire signed [23:0] sample_data;
    wire sample_valid;

    integer slot_bit = 31;
    integer sample_index = -1;
    integer expected_index = 0;
    integer frame_count = 0;
    integer valid_in_frame = 0;
    integer pass_count = 0;
    integer fail_count = 0;

    reg [23:0] tx_sample = 0;
    reg [23:0] previous_data = 0;
    reg previous_valid = 0;

    // System clock: 27 MHz
    always #18.5185 clk = ~clk;

    // Independent I2S BCLK: 3.072 MHz
    always #162.7604 bclk = ~bclk;

    // Module under test
    i2s_rx dut (
        .clk(clk),
        .rst_n(rst_n),
        .bclk(bclk),
        .ws(ws),
        .sd(sd),
        .sample_data(sample_data),
        .sample_valid(sample_valid)
    );

    // Independent test vectors
    function [23:0] test_value;
        input integer index;
        begin
            case (index)
                0: test_value = 24'h123456;
                1: test_value = 24'h000000;
                2: test_value = 24'h7FFFFF;
                3: test_value = 24'h800000;
                4: test_value = 24'hFFFFFF;
                5: test_value = 24'hA5C39E;
                default: test_value = 24'h000000;
            endcase
        end
    endfunction

    // Simulate INMP441 independently.
    // Change WS and SD at falling BCLK edges.
    // First bit after WS transition is dummy.
    always @(negedge bclk) begin
        if (!rst_n) begin
            ws = 1;
            sd = 0;
            slot_bit = 31;
            sample_index = -1;
        end
        else begin
            if (slot_bit == 31) begin
                slot_bit = 0;

                // Check previous Left slot
                if (ws == 0) begin
                    if (valid_in_frame != 1) begin
                        $display("FAIL: Left frame has %0d valid pulses",
                                 valid_in_frame);
                        fail_count = fail_count + 1;
                    end
                    frame_count = frame_count + 1;
                    valid_in_frame = 0;
                end

                ws = ~ws;

                if (ws == 0) begin
                    sample_index = sample_index + 1;
                    tx_sample = test_value(sample_index);
                end
            end
            else begin
                slot_bit = slot_bit + 1;
            end

            // Slot bit 0: one-bit I2S delay
            // Slot bits 1..24: MSB to LSB
            // Slot bits 25..31: padding
            if (ws == 0 &&
                slot_bit >= 1 &&
                slot_bit <= 24)
                sd = tx_sample[24-slot_bit];
            else
                sd = 0;
        end
    end

    // Independent output checker
    always @(negedge clk) begin
        if (rst_n) begin
            if (sample_valid) begin
                valid_in_frame = valid_in_frame + 1;

                if (ws !== 0 || slot_bit != 24) begin
                    $display("FAIL: Wrong sample_valid timing");
                    fail_count = fail_count + 1;
                end

                if (sample_data === test_value(expected_index)) begin
                    $display("PASS: Expected=%h Received=%h",
                             test_value(expected_index), sample_data);
                    pass_count = pass_count + 1;
                end
                else begin
                    $display("FAIL: Expected=%h Received=%h",
                             test_value(expected_index), sample_data);
                    fail_count = fail_count + 1;
                end

                expected_index = expected_index + 1;
            end

            if (sample_valid && previous_valid) begin
                $display("FAIL: sample_valid lasts too long");
                fail_count = fail_count + 1;
            end

            if (!sample_valid && sample_data !== previous_data) begin
                $display("FAIL: sample_data changed without valid");
                fail_count = fail_count + 1;
            end

            previous_valid = sample_valid;
            previous_data = sample_data;
        end
    end

    initial begin
        #200;
        rst_n = 1;

        wait (frame_count == 6);
        #100;

        $display("==============================");
        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);
        $display("FRAMES     = %0d", frame_count);

        if (fail_count == 0 && pass_count == 6)
            $display("INDEPENDENT I2S TEST PASSED");
        else
            $display("INDEPENDENT I2S TEST FAILED");

        $display("==============================");
        $stop;
    end

endmodule
