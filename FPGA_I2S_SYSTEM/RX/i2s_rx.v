
module i2s_rx (
    input  wire              clk,
    input  wire              rst_n,
    input  wire              bclk,
    input  wire              ws,
    input  wire              sd,

    output reg signed [23:0] sample_data,
    output reg               sample_valid
);

    reg bclk_d;
    reg ws_prev_bclk;

    reg [5:0] bit_count;
    reg [23:0] shift_reg;

    wire bclk_rise = bclk & ~bclk_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bclk_d       <= 1'b0;
            ws_prev_bclk <= 1'b1;
            bit_count    <= 6'd0;
            shift_reg    <= 24'd0;
            sample_data  <= 24'd0;
            sample_valid <= 1'b0;
        end
        else begin
            bclk_d       <= bclk;
            sample_valid <= 1'b0;

            if (bclk_rise) begin

                // Chi ghi nho WS tai canh len BCLK
                ws_prev_bclk <= ws;

                // Phat hien bat dau slot moi
                if (ws != ws_prev_bclk) begin
                    bit_count <= 6'd0;
                end
                else begin
                    if (bit_count < 6'd31)
                        bit_count <= bit_count + 1'b1;

                    // Thu 24 bit cua kenh Left
                    // Bo qua chu ky dau sau khi WS doi
                    if (ws == 1'b0 &&
                        bit_count < 6'd24) begin

                        shift_reg <= {shift_reg[22:0], sd};

                        // Hoan thanh 24 bit
                        if (bit_count == 6'd23) begin
                            sample_data <= {shift_reg[22:0], sd};
                            sample_valid <= 1'b1;
                        end
                    end
                end
            end
        end
    end

endmodule
