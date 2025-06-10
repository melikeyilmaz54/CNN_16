module top_cnn_alu (
    input clk,
    input mem_write,                       // RAM yazma enable
    input alu_enable,                      // ALU/FPU enable
    input [3:0] alu_op,                    // ALU/FPU operasyon kodu
    input [11:0] ram_addr_a, ram_addr_b,   // RAM adresleri
    input [15:0] ram_data_in,              // RAM'e yazılacak veri
    output [15:0] ram_data_out,            // RAM'den okunan veri
    output [15:0] alu_result,              // ALU/FPU sonucu
    output alu_zero, alu_carry, alu_fp_error // ALU/FPU bayrakları
);

    // RAM instance'ı
    wire [15:0] ram_data_a, ram_data_b;

    cnn16_ram #(
        .DATA_WIDTH(16),
        .ADDR_WIDTH(12)
    ) ram_inst (
        .clk(clk),
        .mem_write(mem_write),
        .address(ram_addr_a),
        .data_in(ram_data_in),
        .data_out(ram_data_a)
    );

    // ALU/FPU instance'ı
    alu_fpu_16bit alu_fpu_inst (
        .clk(clk),
        .op(alu_op),
        .a(ram_data_a),
        .b(ram_data_b),
        .result(alu_result),
        .zero(alu_zero),
        .carry(alu_carry),
        .fp_error(alu_fp_error)
    );

    // İkinci RAM portu okuma (b için)
    cnn16_ram #(
        .DATA_WIDTH(16),
        .ADDR_WIDTH(12)
    ) ram_inst_b (
        .clk(clk),
        .mem_write(1'b0), // Sadece okuma
        .address(ram_addr_b),
        .data_in(16'b0),
        .data_out(ram_data_b)
    );

    assign ram_data_out = ram_data_a;

endmodule
