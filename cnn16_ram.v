`timescale 1ns / 1ps

module cnn16_ram #(
    parameter DATA_WIDTH = 16,      // 16-bit veri genişliği
    parameter ADDR_WIDTH = 12       // 12-bit adres genişliği (4096 adres)
)(
    input  clk,                                 // Saat sinyali
    input  mem_write,                           // 1: yazma, 0: okuma
    input  [ADDR_WIDTH-1:0] address,            // Adres girişi
    input  [DATA_WIDTH-1:0] data_in,            // Yazılacak veri
    output reg [DATA_WIDTH-1:0] data_out        // Okunan veri
);

    // RAM belleği tanımı
    reg [DATA_WIDTH-1:0] memory [0:(1<<ADDR_WIDTH)-1];

    always @(posedge clk) begin
        if (mem_write) begin
            memory[address] <= data_in;         // Belleğe yaz
        end else begin
            data_out <= memory[address];        // Bellekten oku
        end
    end

endmodule
