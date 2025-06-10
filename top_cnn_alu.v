`timescale 1ns / 1ps

module top_cnn_alu(
    input  wire        clk,
    input  wire        reset,
    input  wire        mem_ready,
    input  wire [15:0] from_memory,
    input  wire        fp_mul_en,

    output wire [15:0] to_memory,
    output wire [11:0] address,

    // Expose internal register values
    output wire [15:0] IR_Value,
    output wire [15:0] AC_Value,
    output wire [11:0] PC_Value,
    output wire  [7:0] XREG_Value,
    output wire  [7:0] YREG_Value,
    output wire [15:0] FPLOAD_Value,
    output wire [15:0] FPMUL_Value,
    output wire [8:0]  state
);

// Control signals from control_unit
wire       AR_Load, DR_Load, AC_Load, IR_Load;
wire       PC_Inc, PC_Load, DR_Inc, write_en;
wire [3:0] bus_sel;
wire [1:0] alu_sel_cu;

// Unused load signals tied low
wire        zero_load = 1'b0;

// Instantiate control unit
control_unit CU (
    .clk       (clk),
    .reset     (reset),
    .IR        (IR_Value),
    .mem_ready (mem_ready),
    .state     (state),
    .AR_Load   (AR_Load),
    .DR_Load   (DR_Load),
    .AC_Load   (AC_Load),
    .IR_Load   (IR_Load),
    .PC_Inc    (PC_Inc),
    .PC_Load   (PC_Load),
    .DR_Inc    (DR_Inc),
    .write_en  (write_en),
    .bus_sel   (bus_sel),
    .alu_sel   (alu_sel_cu),
);

// Instantiate data path
cnn16_data_path DP (
    .clk        (clk),
    .rst        (reset),
    .AC_Load    (AC_Load),
    .DR_Load    (DR_Load),
    .TR_Load    (zero_load),
    .IR_Load    (IR_Load),
    .VREG_Load  (zero_load),
    .KREG_Load  (zero_load),
    .GREG_Load  (zero_load),
    .OREG_Load  (zero_load),
    .INPR_Load  (zero_load),
    .OUTR_Load  (zero_load),
    .PC_Load    (PC_Load),
    .AR_Load    (AR_Load),
    .XREG_Load  (zero_load),
    .YREG_Load  (zero_load),
    .FPLOAD_Load(zero_load),
    .FPMUL_Load (zero_load),
    .PC_Inc     (PC_Inc),
    .AR_Inc     (zero_load),
    .alu_sel    ({2'b00, alu_sel_cu}),
    .fp_mul_en  (fp_mul_en),
    .bus_sel    (bus_sel),
    .from_memory(from_memory),
    .to_memory  (to_memory),
    .address    (address),
    .IR_Value   (IR_Value),
    .AC_Value   (AC_Value),
    .PC_Value   (PC_Value),
    .XREG_Value (XREG_Value),
    .YREG_Value (YREG_Value),
    .FPLOAD_Value  (FPLOAD_Value),
    .FPMUL_Value   (FPMUL_Value)
);

endmodule
