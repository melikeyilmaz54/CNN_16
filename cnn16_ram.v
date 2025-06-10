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

    // RAM dizisi
    reg [DATA_WIDTH-1:0] memory [0:(1<<ADDR_WIDTH)-1];
    reg [DATA_WIDTH-1:0] data_reg;

    always @(posedge clk) begin
        if (mem_write) begin
            memory[address] <= data_in;  // Yazma işlemi
        end else begin
            data_reg <= memory[address]; // Okuma işlemi
        end
    end

    assign data_out = data_reg;

endmodule
