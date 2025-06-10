module cnn16_data_path (
    input clk, rst,
    // Register yükleme sinyalleri
    input AC_Load, DR_Load, TR_Load, IR_Load, VREG_Load, KREG_Load, GREG_Load, OREG_Load,
    input INPR_Load, OUTR_Load, PC_Load, AR_Load, XREG_Load, YREG_Load,
    input FPLOAD_Load, FPMUL_Load,
    // Register artırma sinyalleri
    input PC_Inc, AR_Inc,
    // ALU ve FPU kontrol
    input [3:0] alu_sel,
    input fp_mul_en,
    // BUS seçimi
    input [3:0] bus_sel,
    // Bellek arayüzü
    input [15:0] from_memory,  // 16-bit bellek veri yolu
    output [15:0] to_memory,
    output [11:0] address,      // 12-bit adres yolu
    // Özel register çıkışları
    output [15:0] IR_Value,     // 16-bit çıkışlar
    output [15:0] AC_Value,
    output [11:0] PC_Value,
    output [7:0] XREG_Value,
    output [7:0] YREG_Value,
    output [15:0] FPLOAD_Value, // 16-bit FP registerlar
    output [15:0] FPMUL_Value
);

    // 16-bit registerlar (PC, AR, XREG, YREG hariç)
    reg [15:0] AC, DR, TR, IR, VREG, KREG, GREG, OREG, INPR, OUTR;
    reg [15:0] FPLOAD, FPMUL;
    // 12-bit registerlar
    reg [11:0] PC, AR;
    // 8-bit registerlar
    reg [7:0] XREG, YREG;
    
    // 16-bit veri yolu
    wire [15:0] bus;
    wire [15:0] alu_result;
    wire [15:0] fp_mul_result;

    // BUS seçici (16-bit uyumlu)
    assign bus = (bus_sel == 4'b0000) ? DR :
                (bus_sel == 4'b0001) ? AC :
                (bus_sel == 4'b0010) ? TR :
                (bus_sel == 4'b0011) ? {4'b0, PC} :    // 12-bit PC -> 16-bit
                (bus_sel == 4'b0100) ? from_memory :
                (bus_sel == 4'b0101) ? {8'b0, XREG} :  // 8-bit XREG -> 16-bit
                (bus_sel == 4'b0110) ? {8'b0, YREG} :  // 8-bit YREG -> 16-bit
                (bus_sel == 4'b0111) ? VREG :
                (bus_sel == 4'b1000) ? KREG :
                (bus_sel == 4'b1001) ? GREG :
                (bus_sel == 4'b1010) ? OREG :
                (bus_sel == 4'b1011) ? INPR :
                (bus_sel == 4'b1100) ? FPLOAD :
                (bus_sel == 4'b1101) ? FPMUL :
                (bus_sel == 4'b1110) ? IR :  // IR bus'tan okunabilir
                OUTR;

    // Çıkış bağlantıları
    assign to_memory = bus;
    assign address = AR;
    assign IR_Value = IR;
    assign AC_Value = AC;
    assign PC_Value = PC;
    assign XREG_Value = XREG;
    assign YREG_Value = YREG;
    assign FPLOAD_Value = FPLOAD;
    assign FPMUL_Value = FPMUL;

    // AC Register (16-bit)
    always @(posedge clk) begin
        if (rst) AC <= 16'b0;
        else if (AC_Load) AC <= alu_result;
    end

    // DR Register (16-bit)
    always @(posedge clk) begin
        if (rst) DR <= 16'b0;
        else if (DR_Load) DR <= bus;
    end

    // TR Register (16-bit)
    always @(posedge clk) begin
        if (rst) TR <= 16'b0;
        else if (TR_Load) TR <= bus;
    end

    // IR Register (16-bit) - SADECE BUS'TAN YÜKLENİYOR
    always @(posedge clk) begin
        if (rst) IR <= 16'b0;
        else if (IR_Load) IR <= bus;
    end

    // PC Register (12-bit)
    always @(posedge clk) begin
        if (rst) PC <= 12'b0;
        else if (PC_Load) PC <= bus[11:0];  // 16-bit'ten 12-bit'e
        else if (PC_Inc) PC <= PC + 1;
    end

    // AR Register (12-bit)
    always @(posedge clk) begin
        if (rst) AR <= 12'b0;
        else if (AR_Load) AR <= bus[11:0];  // 16-bit'ten 12-bit'e
        else if (AR_Inc) AR <= AR + 1;
    end

    // XREG ve YREG (8-bit)
    always @(posedge clk) begin
        if (rst) begin
            XREG <= 8'b0;
            YREG <= 8'b0;
        end
        else begin
            if (XREG_Load) XREG <= bus[7:0];  // 16-bit'ten 8-bit'e
            if (YREG_Load) YREG <= bus[7:0];  // 16-bit'ten 8-bit'e
        end
    end

    // VREG, KREG, GREG, OREG (16-bit)
    always @(posedge clk) begin
        if (rst) begin
            VREG <= 16'b0;
            KREG <= 16'b0;
            GREG <= 16'b0;
            OREG <= 16'b0;
        end
        else begin
            if (VREG_Load) VREG <= bus;
            if (KREG_Load) KREG <= bus;
            if (GREG_Load) GREG <= bus;
            if (OREG_Load) OREG <= bus;
        end
    end

    // INPR ve OUTR (16-bit)
    always @(posedge clk) begin
        if (rst) begin
            INPR <= 16'b0;
            OUTR <= 16'b0;
        end
        else begin
            if (INPR_Load) INPR <= bus;
            if (OUTR_Load) OUTR <= bus;
        end
    end

    // FPLOAD Register (16-bit kayan nokta)
    always @(posedge clk) begin
        if (rst) FPLOAD <= 16'b0;
        else if (FPLOAD_Load) FPLOAD <= from_memory;
    end

    // FPMUL Register (16-bit kayan nokta)
    always @(posedge clk) begin
        if (rst) FPMUL <= 16'b0;
        else if (FPMUL_Load) FPMUL <= fp_mul_result;
        else if (fp_mul_en) begin
            // 16-bit kayan nokta çarpma (IEEE 754 half-precision)
            FPMUL <= fp16_mul(FPLOAD, AC);
        end
    end

    // 16-bit ALU birimi
    alu_fpu_16bit alu_unit (
        .op(alu_sel),
        .a(AC),
        .b(DR),
        .result(alu_result)
    );

    // 16-bit FP çarpma fonksiyonu
    function [15:0] fp16_mul;
        input [15:0] a, b;
        // Basitleştirilmiş 16-bit floating point çarpma
        begin
            // Sign bit
            fp16_mul[15] = a[15] ^ b[15];
            // Exponent (bias 15)
            fp16_mul[14:10] = a[14:10] + b[14:10] - 5'd15;
            // Mantissa (10-bit)
            fp16_mul[9:0] = (a[9:0] * b[9:0]) >> 10;
        end
    endfunction

endmodule
