
`timescale 1ns/1ps

module tb_i2s_tx_dynamic;

    reg clk = 0;
    reg rst_n = 0;
    reg bclk = 0;
    reg ws = 1;

    reg signed [23:0] sample_data = 0;
    reg sample_valid = 0;

    wire sd_out;

    integer slot_bit = 31;
    integer pass_count = 0;
    integer fail_count = 0;
    integer bit_errors = 0;

    reg [23:0] queued_expected = 0;
    reg [23:0] frame_expected = 0;
    reg stimulus_ready = 0;
    reg checking = 0;
    reg expected_bit;

    // System clock 27 MHz
    always #18.5185 clk = ~clk;

    // Independent BCLK 3.072 MHz
    always #162.7604 bclk = ~bclk;

    i2s_tx dut (
        .clk(clk),
        .rst_n(rst_n),
        .bclk(bclk),
        .ws(ws),
        .sample_data(sample_data),
        .sample_valid(sample_valid),
        .sd_out(sd_out)
    );

    // Create WS: 32 BCLK per channel
    always @(negedge bclk) begin
        if (!rst_n) begin
            ws = 1;
            slot_bit = 31;
            checking = 0;
        end
        else if (slot_bit == 31) begin
            slot_bit = 0;
            ws = ~ws;

            // Snapshot expected data at Left start
            if (ws == 0) begin
                frame_expected = queued_expected;
                checking = stimulus_ready;
            end
        end
        else begin
            slot_bit = slot_bit + 1;
        end
    end

    // Independent MAX98357A receiver model
    always @(posedge bclk) begin
        if (rst_n && checking) begin

            // I2S: one-bit delay, 24 data bits
            if (slot_bit >= 1 && slot_bit <= 24)
                expected_bit = frame_expected[24-slot_bit];
            else
                expected_bit = 0;

            if (sd_out !== expected_bit) begin
                $display(
                    "BIT FAIL: WS=%b Bit=%0d Expected=%b Got=%b",
                    ws, slot_bit, expected_bit, sd_out
                );
                bit_errors = bit_errors + 1;
            end

            if (slot_bit == 31) begin
                if (bit_errors == 0) begin
                    $display("PASS: WS=%b PCM=%h",
                             ws, frame_expected);
                    pass_count = pass_count + 1;
                end
                else begin
                    $display("FAIL: WS=%b PCM=%h",
                             ws, frame_expected);
                    fail_count = fail_count + 1;
                end

                bit_errors = 0;
            end
        end
    end

    // Send new PCM sample during Right slot
    task send_sample;
        input [23:0] value;
        begin
            @(posedge ws);
            @(negedge clk);

            sample_data = value;
            sample_valid = 1;
            queued_expected = value;
            stimulus_ready = 1;

            @(negedge clk);
            sample_valid = 0;

            // Wait for the corresponding Left slot
            @(negedge ws);
        end
    endtask

    initial begin
        #200;
        rst_n = 1;

        send_sample(24'h123456);
        send_sample(24'h000000);
        send_sample(24'h7FFFFF);
        send_sample(24'h800000);
        send_sample(24'hFFFFFF);
        send_sample(24'hA5C39E);

        // Finish checking both channels
        @(posedge ws);
        @(negedge ws);
        #1000;

        $display("==========================");
        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);

        if (pass_count == 12 && fail_count == 0)
            $display("DYNAMIC I2S TX TEST PASSED");
        else
            $display("DYNAMIC I2S TX TEST FAILED");

        $display("==========================");
        $stop;
    end

endmodule
