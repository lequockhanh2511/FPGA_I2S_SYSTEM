
module i2s_clock_gen (
    input  wire clk,
    input  wire rst_n,
    output reg  bclk,
    output wire ws
);

    // Clock he thong: 27 MHz
    // Muc tieu:
    // BCLK = 3.072 MHz
    // WS = 48 kHz

    reg [31:0] phase_acc;
    reg [5:0] bit_count;

    // Bo chia tan so phan so:
    // 27 MHz * 6.144 / 27 = 6.144 MHz
    // Tao canh BCLK voi tan so 6.144 MHz
    localparam integer STEP = 6144;
    localparam integer LIMIT = 27000;

    assign ws = (bit_count >= 32);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_acc <= 0;
            bit_count <= 0;
            bclk      <= 0;
        end
        else begin
            if (phase_acc >= LIMIT - STEP) begin
                phase_acc <= phase_acc + STEP - LIMIT;
                bclk <= ~bclk;

                // Dem moi canh len BCLK
                if (!bclk)
                    bit_count <= bit_count + 1'b1;
            end
            else begin
                phase_acc <= phase_acc + STEP;
            end
        end
    end

endmodule
