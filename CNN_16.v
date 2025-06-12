`timescale 1ns / 1ps

module CNN_16 (
    input clk,
    input rst
);

    // Dahili sinyaller
    wire [15:0] to_memory;       // CPU → RAM
    wire [15:0] from_memory;     // RAM → CPU
    wire [11:0] address;         // RAM adresi
    wire mem_write;              // CPU'dan gelen yazma kontrol sinyali
    wire mem_ready;              // Bellek hazır (şu an sabit 1)

    // Bellek her zaman hazır kabul ediliyor (senkron RAM'de latency yoksa)
    assign mem_ready = 1'b1;

    // CPU instance
    top_cnn_alu cpu (
        .clk(clk),
        .rst(rst),
        .mem_ready(mem_ready),
        .from_memory(from_memory),
        .to_memory(to_memory),
        .address(address)
    );

    // RAM instance
    cnn16_ram #(
        .DATA_WIDTH(16),
        .ADDR_WIDTH(12)
    ) memory (
        .clk(clk),
        .mem_write(mem_write),
        .address(address),
        .data_in(to_memory),
        .data_out(from_memory)
    );

    // Gerçek yazma kontrolü: `write_en` sinyali CPU'dan çıkmalı
    // O yüzden top_cnn_alu modülünün çıktısı olarak expose edilmelidir
    // Örnek: top_cnn_alu'da → output write_en eklenmiş olmalı

endmodule