`timescale 1ns / 1ps

module cnn_top_module (
    input clk,
    input rst,
    input sel_in,
    input mem_ready,                    // Bellekten okumanın tamamlandığını belirten sinyal
    input [15:0] from_memory,           // Bellekten gelen veri
    output [15:0] to_memory,            // Belleğe yazılacak veri
    output [11:0] address,               // Bellek adres yolu
    output [11:0] testAR, testPC,
    output [15:0] testIR, testAC, testbus, testDR, testTR,
    output [7:0] testXREG,
    output [7:0] testYREG,
    output [15:0] testVREG, testKREG, testGREG, testOREG,
    output [8:0] testState
    
);

    assign testIR = IR_Value;
    
    // Dahili sinyaller
    wire [15:0] IR_Value, AC_Value, TR_Value, DR_Value, bus_value;
    wire [11:0] PC_Value, AR_Value;
    wire [7:0] XREG_Value, YREG_Value;
    wire [15:0] VREG_Value, KREG_Value, GREG_Value, OREG_Value;

    // Kontrol sinyalleri
    wire AR_Load, DR_Load, AC_Load, TR_Load, IR_Load;
    wire PC_Load, IREG_Load, JREG_Load, write_en;
    wire OREG_Load, GREG_Load, KREG_Load, VREG_Load, XREG_Load, YREG_Load;
    wire OUTR_Load, INPR_Load;
    wire Zero_Check_En, compare_en, neg_check_en;
    wire AC_Inc, PC_Inc, DR_Inc;
    wire [15:0] compare_val;
    wire [4:0] bus_sel;
    wire [3:0] alu_sel;
    wire zero, equal, neg;

    // Datapath birimi
    cnn16_data_path datapath_inst (
        .clk(clk),
        .rst(rst),

        // Register yükleme
        .AC_Load(AC_Load),
        .DR_Load(DR_Load),
        .TR_Load(TR_Load),
        .IR_Load(IR_Load),
        .VREG_Load(VREG_Load),
        .KREG_Load(KREG_Load),
        .GREG_Load(GREG_Load),
        .OREG_Load(OREG_Load),
        .INPR_Load(INPR_Load),
        .OUTR_Load(OUTR_Load),
        .PC_Load(PC_Load),
        .AR_Load(AR_Load),
        .XREG_Load(XREG_Load),
        .YREG_Load(YREG_Load),

        // Register artışları
        .PC_Inc(PC_Inc),
        .AR_Inc(1'b0),         // kullanılmıyor ama tanımlı, default 0
        .AC_Inc(AC_Inc),
        .DR_Inc(DR_Inc),

        // ALU ve BUS
        .alu_sel(alu_sel),
        .bus_sel(bus_sel),

        // Karşılaştırma
        .compare_en(compare_en),
        .compare_val(compare_val),
        .Zero_Check_En(Zero_Check_En),
        .neg_check_en(neg_check_en),

        // Bellek arayüzü
        .from_memory(from_memory),
        .to_memory(to_memory),
        .address(address),

        // Output register değerleri
        .IR_Value(IR_Value),

        // Karşılaştırma bayrakları
        .zero(zero),
        .equal(equal),
        .neg(neg),
        
        //test amaçlı
        .XREG_Value(testXREG), 
        .YREG_Value(testYREG),
        .VREG_Value(testVREG),
        .KREG_Value(testKREG),
        .GREG_Value(testGREG),
        .OREG_Value(testOREG),
        .AC_Value(testAC), 
        .AR_Value(testAR),
        .PC_Value(testPC),
        .DR_Value(testDR),
        .TR_Value(testTR),
        .bus_value(testbus)
    );

    // Kontrol birimi
    control_unit ctrl_unit_inst (
        .clk(clk),
        .reset(rst),
        .sel_in(sel_in),
        .IR(IR_Value),
        .mem_ready(mem_ready),

        // Karşılaştırma bayrakları
        .zero(zero),
        .equal(equal),
        .neg(neg),

        // Debug state
        .state_o(testState),

        // Register yükleme
        .AR_Load(AR_Load),
        .DR_Load(DR_Load),
        .AC_Load(AC_Load),
        .TR_Load(TR_Load),
        .IR_Load(IR_Load),
        .PC_Load(PC_Load),
        .IREG_Load(IREG_Load),
        .JREG_Load(JREG_Load),
        .write_en(write_en),
        .OREG_Load(OREG_Load),
        .GREG_Load(GREG_Load),
        .KREG_Load(KREG_Load),
        .VREG_Load(VREG_Load),
        .XREG_Load(XREG_Load),
        .YREG_Load(YREG_Load),
        .OUTR_Load(OUTR_Load),
        .INPR_Load(INPR_Load),

        // Karşılaştırma kontrol
        .INTF(),  // kullanılmıyor gibi görünüyor, opsiyonel
        .Zero_Check_En(Zero_Check_En),
        .compare_en(compare_en),
        .neg_check_en(neg_check_en),

        // Artışlar
        .AC_Inc(AC_Inc),
        .PC_Inc(PC_Inc),
        .DR_Inc(DR_Inc),

        .compare_val(compare_val),
        .bus_sel(bus_sel),
        .alu_sel(alu_sel)
    );

endmodule
