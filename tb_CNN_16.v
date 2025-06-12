`timescale 1ns / 1ps

module tb_CNN_16;

    // Testbench sinyalleri
    reg clk = 0;
    reg rst = 0;
    reg sel_in = 1;               // Başta dıştan yazma
    reg we_in = 0;
    reg [15:0] data_in;
    reg [11:0] adr_in;

    wire [7:0] data_out;
    wire [7:0] data_mem_in;
    wire we_out;

    // Gözlemleme sinyalleri
    wire [11:0] PC_Value, AR_Value;
    wire [15:0] IR_Value, AC_Value, TR_Value, DR_Value, bus_value;
    wire [7:0] XREG_Value, YREG_Value;
    wire [8:0] state_value;
    wire [15:0] VREG_Value, KREG_Value, GREG_Value, OREG_Value;

    // Saat üretimi
    always #5 clk = ~clk;

    // Test verileri
    real kernel_real[0:8];
    real image_real[0:255];
    integer i;

    // FSM sayaçları
    reg [3:0] durum = 0;
    reg [8:0] pcnt = 0;
    reg [11:0] row = 12'h000;

    // DUT
    CNN_16 cnn_test (
        .clkn(clk),
        .rstn(rst),
        .we_in(we_in),
        .sel_in(sel_in),
        .data_in(data_in),
        .adr_in(adr_in),
        .PC_Value(PC_Value),
        .AR_Value(AR_Value),
        .IR_Value(IR_Value),
        .AC_Value(AC_Value),
        .TR_Value(TR_Value),
        .DR_Value(DR_Value),
        .bus_value(bus_value),
        .XREG_Value(XREG_Value),
        .YREG_Value(YREG_Value),
        .VREG_Value(VREG_Value),
        .KREG_Value(KREG_Value),
        .GREG_Value(GREG_Value),
        .OREG_Value(OREG_Value),
        .data_out(data_out),
        .data_mem_in(data_mem_in),
        .we_out(we_out),
        .state_value(state_value)
    );

    // Başlatma bloğu
    initial begin
        rst = 1;
        #20 rst = 0;

        // Kernel değerleri (0.1 - 0.9)
        kernel_real[0] = 0.1;
        kernel_real[1] = 0.2;
        kernel_real[2] = 0.3;
        kernel_real[3] = 0.4;
        kernel_real[4] = 0.5;
        kernel_real[5] = 0.6;
        kernel_real[6] = 0.7;
        kernel_real[7] = 0.8;
        kernel_real[8] = 0.9;

        // Görsel verileri: 0.0 - 1.0 arası rastgele
        for (i = 0; i < 256; i = i + 1)
            image_real[i] = $urandom_range(0, 1000) / 1000.0;
    end

    // FSM
    always @(posedge clk) begin
        case (durum)
            0: begin
                // Kernel verilerini belleğe yaz (adres: 0x000 - 0x008)
                if (pcnt < 9) begin
                    adr_in <= 12'h000 + pcnt;
                    data_in <= $shortrealtobits(kernel_real[pcnt]);  // float16/32 encode
                    we_in <= 1;
                    sel_in <= 1;
                    pcnt <= pcnt + 1;
                end else begin
                    pcnt <= 0;
                    row <= 12'h100;
                    durum <= 1;
                end
            end

            1: begin
                // Görsel verileri belleğe yaz (adres: 0x100 - 0x1FF)
                if (pcnt < 256) begin
                    adr_in <= row;
                    data_in <= $shortrealtobits(image_real[pcnt]);
                    we_in <= 1;
                    sel_in <= 1;
                    row <= row + 1;
                    pcnt <= pcnt + 1;
                end else begin
                    pcnt <= 0;
                    row <= 12'h010;
                    durum <= 2;
                end
            end

            2: begin
                // Komutları belleğe yaz (adres: 0x010 - ...)
                sel_in <= 1;
                we_in <= 1;
                adr_in <= row;

                case (pcnt)
                    0: data_in <= 16'h0300; // LDK 0
                    1: data_in <= 16'h0301;
                    2: data_in <= 16'h0302;
                    3: data_in <= 16'h0303;
                    4: data_in <= 16'h0304;
                    5: data_in <= 16'h0305;
                    6: data_in <= 16'h0306;
                    7: data_in <= 16'h0307;
                    8: data_in <= 16'h0308;
                    9: data_in <= 16'h3000; // CONV
                   10: data_in <= 16'hFFFF; // SON
                endcase

                row <= row + 1;
                pcnt <= pcnt + 1;

                if (pcnt == 10) begin
                    pcnt <= 0;
                    durum <= 3;
                end
            end

            3: begin
                // Bellek yazımı tamamlandı, CPU'ya bırak
                sel_in <= 0;
                we_in <= 0;
                durum <= 4;
            end

            4: begin
                // CPU çalışıyor, sonuçlar bekleniyor
                if (PC_Value == 12'h014) begin
                    $display("==== CONV TAMAMLANDI ====");
                    $display("IR   = %h", IR_Value);
                    $display("AC   = %h", AC_Value);
                    $display("GREG = %h", GREG_Value);
                    $display("VREG = %h", VREG_Value);
                    $display("OREG = %h", OREG_Value);
                    $display("bus  = %h", bus_value);
                    $display("State= %d", state_value);
                    $display("=========================");
                    durum <= 5;
                    #100 $finish;
                end
            end
        endcase
    end

endmodule
