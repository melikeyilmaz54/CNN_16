`timescale 1ns / 1ps

module tb_lda_fsm(
     input clkn, rstn, we_in, sel_in,
     input [15:0] data_in,
     input [11:0] adr_in,
     output [11:0] tbAR, tbPC,
     output [15:0] tbIR, tbAC, tbBus, tbDR,
     output [7:0] tbXREG, tbYREG,
     output [7:0] data_out, data_mem_in,
     output we_out
);
    wire we;
    wire [15:0] to_mem, cpu_mem, cpu_we;
    wire [15:0] from_mem;
    wire [11:0] addr, cpu_adr;

    wire [15:0] testDR, testAC, testIR, testBus;
    wire [11:0] testAR, testPC;
    wire [7:0] testXREG, testYREG;
    
    assign data_out=from_mem;
    assign data_mem_in=to_mem;
    assign we_out=we;
    
    //test amaçlý
    assign tbDR=testDR;
    assign tbAC=testAC;
    assign tbPC=testPC;
    assign tbAR=testAR;
    assign tbIR=testIR;
    assign tbBus=testBus;
    
    //dýþardan ram a program yüklemek için
    //sel_in=1 ise RAM a program yükleniyor
    assign to_mem = (sel_in==1'b1) ? data_in : cpu_mem; 
    assign adr = (sel_in==1'b1) ? adr_in : cpu_adr;
    assign we = (sel_in==1'b1) ? we_in : cpu_we;
    
    cnn_top_module uut (
        .clk(clkn),
        .rst(rstn),
        .mem_ready(sel_in),///SEL İN KONUSUNDA EKSİKLER VAR MEM READY NEYE BAĞLANICAK BİLMİYORUM
        .from_memory(from_mem),
        .to_memory(cpu_mem),
        .address(cpu_adr),
        
        .testDR(testDR), 
        .testAC(testAC), 
        .testAR(testAR), 
        .testPC(testPC),
        .testIR(testIR),
        .testBus(testBus),
        .testXREG(),
        .testYREG()
    );

    // RAM modülü
    cnn16_ram mem (
        .clk(clkn),
        .mem_write(tmem_write),//YANLISLAR VAR DÜZELTİLMELİ
        .address(addr),
        .data_in(to_mem),
        .data_out(from_mem)
    );
endmodule
