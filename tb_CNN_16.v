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
    wire [15:0] VREG_Value, KREG_Value, GREG_Value, OREG_Value;

    // Saat üretimi
    always #5 clk = ~clk;

    // Program belleği
    reg [15:0] program [0:15];  // Örnek olarak 16 komutluk yer

    // Sayaçlar ve durum FSM’i
    reg [3:0] durum = 0;
    reg [3:0] pcnt = 0;
    reg [11:0] row = 12'h010;  // Başlangıç adresi

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
        .we_out(we_out)
    );

    // Başlatma
    initial begin
        rst = 0;
        #20 rst = 1;

        // Örnek komut seti (Değişecek)
        program[0] = 16'h3005;  // LDA 0x05
        program[1] = 16'h4010;  // ADD 0x10
        program[2] = 16'h500F;  // STA 0x0F
        program[3] = 16'hF000;  // BRK
        program[4] = 16'hFFFF;  // Sonlandırıcı

        #1000 $finish;
    end

    // FSM: RAM'e yaz → CPU'ya bırak
    always @(posedge clk) begin
        case (durum)
            0: begin
                // Komutları RAM’e yaz
                if (program[pcnt] != 16'hFFFF) begin
                    adr_in <= row;
                    data_in <= program[pcnt];
                    we_in <= 1;
                    sel_in <= 1;
                    pcnt <= pcnt + 1;
                    row <= row + 1;
                end else begin
                    // Program yükleme bitti
                    we_in <= 0;
                    sel_in <= 0; // CPU çalışmaya başlasın
                    durum <= 1;
                end
            end

            1: begin
                // CPU çalışıyor. Sonuçlar gözlemlenir:
                if (PC_Value == 12'h014) begin
                    $display("IR: %h, AC: %h, DR: %h", IR_Value, AC_Value, DR_Value);
                    $display("Bellek yazma bitti, CPU çalıştı.");
                    durum <= 2;
                end
            end

            2: begin
                // Pasif bekleme veya test sonuçlarının karşılaştırması yapılabilir
            end
        endcase
    end

endmodule
