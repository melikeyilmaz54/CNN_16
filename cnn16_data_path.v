`timescale 1ns / 1ps

module cnn16_data_path (
    input clk, rst,
    // Register yükleme sinyalleri
    input AC_Load, DR_Load, TR_Load, IR_Load, VREG_Load, KREG_Load, GREG_Load, OREG_Load,
    input INPR_Load, OUTR_Load, PC_Load, AR_Load, XREG_Load, YREG_Load, 
    // Register artırma sinyalleri
    input PC_Inc, AR_Inc, AC_Inc, DR_Inc,
    // ALU kontrol
    input [3:0] alu_sel,
    // BUS seçimi
    input [4:0] bus_sel,
    //Karşılaştırma
    input compare_en,
    input [15:0] compare_val,
    // bus 0 yap
    input Zero_Check_En, neg_check_en,
    // Bellek arayüzü
    input [15:0] from_memory,  // 16-bit bellek veri yolu
    output [15:0] to_memory,
    output [11:0] address,      // 12-bit adres yolu
    
    // Özel register çıkışları
    output [11:0] AR_Value,
    output [15:0] IR_Value,     // 16-bit çıkışlar
    output [15:0] TR_Value,
    output [15:0] AC_Value,
    output [15:0] DR_Value,
    output [11:0] PC_Value,
    output [7:0] XREG_Value,
    output [7:0] YREG_Value,
    output [15:0] VREG_Value,
    output [15:0] KREG_Value,
    output [15:0] GREG_Value,
    output [15:0] OREG_Value,
    
    output [15:0] bus_value,
    
    output reg zero, equal, neg
);

    // 16-bit registerlar (PC, AR, XREG, YREG hariç)
    reg [15:0] AC, DR, TR, IR, VREG, KREG, GREG, OREG, INPR, OUTR;
    // 12-bit registerlar
    reg [11:0] PC, AR;
    // 8-bit registerlar
    reg [7:0] XREG, YREG;
    //
    reg [1:0] IREG, JREG;
    
    // 16-bit veri yolu
    wire [15:0] bus;
    wire [15:0] alu_result;

    // BUS seçici (16-bit uyumlu)
    assign bus = (bus_sel == 5'd0)  ? DR :
                 (bus_sel == 5'd1)  ? AC :
                 (bus_sel == 5'd2)  ? TR :
                 (bus_sel == 5'd3)  ? {4'b0, PC} :
                 (bus_sel == 5'd4)  ? from_memory :
                 (bus_sel == 5'd5)  ? {8'b0, XREG} :
                 (bus_sel == 5'd6)  ? {8'b0, YREG} :
                 (bus_sel == 5'd7)  ? VREG :
                 (bus_sel == 5'd8)  ? KREG :
                 (bus_sel == 5'd9)  ? GREG :
                 (bus_sel == 5'd10) ? OREG :
                 (bus_sel == 5'd11) ? INPR :
                 (bus_sel == 5'd12) ? {12'b0, IREG} :
                 (bus_sel == 5'd13) ? {12'b0, JREG} :
                 (bus_sel == 5'd14) ? IR :
                 (bus_sel == 5'd15) ? OUTR :
                 (bus_sel == 5'd16) ? INPR :
                 (bus_sel == 5'd31) ? 16'd0 :   // ZERO_SELL
                 16'd0;                         // default fallback

                 
    // Çıkış bağlantıları
    assign bus = bus_value;
    assign to_memory = bus;
    assign AR_Value = AR;
    assign address = AR;
    assign IR_Value = IR;
    assign AC_Value = AC;
    assign PC_Value = PC;
    assign DR_Value = DR;
    assign XREG_Value = XREG;
    assign YREG_Value = YREG;
    assign VREG_Value = VREG;
    assign KREG_Value = KREG;
    assign GREG_Value = GREG;
    assign OREG_Value = OREG;
    

    // AC Register (16-bit)
    always @(posedge clk) begin
        if (rst) AC <= 16'b0;
        else if (AC_Load) AC <= alu_result;
    end
    
    // Bus 0 mı?
    always @(posedge clk) begin
        if (Zero_Check_En)
            zero <= (bus == 16'd0);
    end
    
    // Eşit mi, negatif mi?
    always @(posedge clk) begin
    if (compare_en)
        equal <= (bus == compare_val);
    if (neg_check_en)
        neg <= bus[15];
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

    // IR Register (16-bit)
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
            if (XREG_Load) XREG <= bus[7:0];
            if (YREG_Load) YREG <= bus[7:0];
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

    // 16-bit ALU birimi
    alu_fpu_16bit alu_unit (
        .clk(clk), 
        .op(alu_sel),
        .a(AC),
        .b(DR),
        .result(alu_result)
    );

endmodule
