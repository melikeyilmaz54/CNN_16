module cnn16_ram #(
    parameter DATA_WIDTH = 16,      // 16-bit veri genişliği
    parameter ADDR_WIDTH = 12       // 12-bit adres genişliği (4096 adres)
)(
    input  clk,                       // Saat sinyali
    input  mem_write,                 // Yazma enable (1: yazma, 0: okuma)
    input  [ADDR_WIDTH-1:0] address,  // Bellek adresi
    input  [DATA_WIDTH-1:0] data_in,  // Yazılacak veri
    output [DATA_WIDTH-1:0] data_out  // Okunan veri
);
