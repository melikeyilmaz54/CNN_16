`timescale 1ns / 1ps

module CNN_16(
     input clkn, rstn, we_in, 
     input sel_in,
     input [15:0] data_in,
     input [11:0] adr_in,
     output [11:0] PC_Value, AR_Value,
     output [15:0] IR_Value, AC_Value, TR_Value, DR_Value, bus_value,
     output [7:0] XREG_Value, YREG_Value,
     output [15:0] VREG_Value, KREG_Value, GREG_Value, OREG_Value,
     output [7:0] data_out, data_mem_in,
     output we_out
);
    wire we;
    wire [15:0] to_mem, cpu_mem, cpu_we;
    wire [15:0] from_mem;
    wire [11:0] addr, cpu_adr;

    wire [15:0] testIR, testAC, testbus, testDR, testTR;
    wire [11:0] testAR, testPC;
    wire [7:0] testXREG, testYREG;
    wire [15:0]  testVREG, testKREG, testGREG, testOREG;
     
    assign data_out=from_mem;
    assign data_mem_in=to_mem;
    assign we_out=we;
    
    //test amaçlý
    assign AR_Value = testAR;
    assign address = testAR;
    assign IR_Value = testIR;
    assign AC_Value = testAC;
    assign PC_Value = testPC;
    assign DR_Value = testDR;
    assign XREG_Value = testXREG;
    assign YREG_Value = testYREG;
    assign VREG_Value = testVREG;
    assign KREG_Value = testKREG;
    assign GREG_Value = testGREG;
    assign OREG_Value = testOREG;
    assign bus_value =  testbus; 
    
    //dýþardan ram a program yüklemek için
    //sel_in=1 ise RAM a program yükleniyor
    assign to_mem = (sel_in==1'b1) ? data_in : cpu_mem; 
    assign adr = (sel_in==1'b1) ? adr_in : cpu_adr;
    assign we = (sel_in==1'b1) ? we_in : cpu_we;
    
    cnn_top_module uut (
        .clk(clkn),
        .rst(rstn),
        .sel_in(sel_in),
        .mem_ready(sel_in),///SEL İN KONUSUNDA EKSİKLER VAR MEM READY NEYE BAĞLANICAK BİLMİYORUM
        .from_memory(from_mem),
        .to_memory(cpu_mem),
        .address(cpu_adr),
        
        .testDR(testDR), 
        .testAC(testAC), 
        .testAR(testAR), 
        .testPC(testPC),
        .testIR(testIR),
        .testTR(testTR), 
        .testbus(testbus),
        .testXREG(testXREG),
        .testYREG(testYREG),
        .testVREG(testVREG),
        .testKREG(testKREG),
        .testGREG(testGREG),
        .testOREG(testOREG)      
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
