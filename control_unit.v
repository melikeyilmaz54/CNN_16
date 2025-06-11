`timescale 1ns / 1ps
// control_unit.v
// FSM-based control unit with 9-bit state encoding (decimal steps of 10)
module control_unit(
    input clk,
    input reset,
    input [15:0] IR,
    input mem_ready,
    input zero, equal, neg,
    output reg [8:0] state_o,       // 9-bit state
    output reg AR_Load, DR_Load, AC_Load, TR_Load,  IR_Load,  PC_Load, IREG_Load, JREG_Load, write_en,
    output reg OREG_Load, GREG_Load, KREG_Load, VREG_Load, XREG_Load, YREG_Load, OUTR_Load, INPR_Load,
    output reg INTF, Zero_Check_En, compare_en, neg_check_en,
    output reg AC_Inc, PC_Inc, DR_Inc,
    output reg [15:0] compare_val,
    output reg [4:0] bus_sel, 
    output reg [4:0] alu_sel
); 

// State encoding
localparam reg [15:0]
		   S_FETCH_0	= 16'd0,
           S_FETCH_1	= 16'd1,
           S_FETCH_2	= 16'd2,
           S_DECODE_3	= 16'd4,

           // LDA sequence
           S_LDA_4		= 16'd10,
           S_LDA_5		= 16'd11,
           S_LDA_6		= 16'd12,
           S_LDA_7		= 16'd13,

           // STA sequence
           S_STA_4		= 16'd20,
           S_STA_5		= 16'd21,
           S_STA_6		= 16'd22,
           S_STA_7		= 16'd23,

           // LDG sequence
           S_LDG_4		= 16'd30,
           S_LDG_5		= 16'd31,
           S_LDG_6		= 16'd32,
           S_LDG_7		= 16'd33,

           // LDK sequence
           S_LDK_4		= 16'd40,
           S_LDK_5		= 16'd41,
           S_LDK_6		= 16'd42,
           S_LDK_7		= 16'd43,

           // LDO sequence
           S_LDO_4		= 16'd50,
           S_LDO_5		= 16'd51,
           S_LDO_6		= 16'd52,
           S_LDO_7		= 16'd53,

           // STO sequence
           S_STO_4		= 16'd60,
           S_STO_5		= 16'd61,
           S_STO_6		= 16'd62,
           S_STO_7		= 16'd63,

           // ADD sequence
           S_ADD_4		= 16'd70,
           S_ADD_5		= 16'd71,
           S_ADD_6		= 16'd72,
           S_ADD_7		= 16'd73,
           S_ADD_8		= 16'd74,

           // SUB sequence
           S_SUB_4		= 16'd80,
           S_SUB_5		= 16'd81,
           S_SUB_6		= 16'd82,
           S_SUB_7		= 16'd83,
           S_SUB_8		= 16'd84,

           // MUL sequence
           S_MUL_4		= 16'd90,
           S_MUL_5		= 16'd91,
           S_MUL_6		= 16'd92,
           S_MUL_7		= 16'd93,
           S_MUL_8		= 16'd94,

           // CLR sequence
           S_CLR_4		= 16'd100,
           S_CLR_5		= 16'd100,


           // NORM sequence
           S_NORM_4		= 16'd120,
           S_NORM_5		= 16'd120,

           // BUN sequence
           S_BUN_4		= 16'd130,
           S_BUN_5		= 16'd130,

           // JZ sequence
           S_JZ_4		= 16'd140,
           S_JZ_5		= 16'd140,

           // JN sequence
           S_JN_4		= 16'd150,
           S_JN_5		= 16'd150,

           // JZINT sequence
           S_JZINT_4	= 16'd160,
           S_JZINT_5	= 16'd160,

           // CLRINT sequence
           S_CLRINT_4	= 16'd170,
           S_CLRINT_5	= 16'd170,

           // INC sequence
           S_INC_4		= 16'd180,
           S_INC_5		= 16'd181,
           S_INC_6		= 16'd182,
           S_INC_7		= 16'd183,
           S_INC_8		= 16'd184,
           S_INC_9		= 16'd185,

           // DEC sequence
           S_DEC_4		= 16'd190,
           S_DEC_5		= 16'd191,
           S_DEC_6		= 16'd192,
           S_DEC_7		= 16'd193,
           S_DEC_8		= 16'd194,
           S_DEC_9		= 16'd195,

           // CMP sequence
           S_CMP_4		= 16'd200,
           S_CMP_5		= 16'd201,
           S_CMP_6		= 16'd202,
           S_CMP_7		= 16'd203,

           // CONV sequence
           S_CONV_4		= 16'd210,
           S_CONV_5		= 16'd211,
           S_CONV_6		= 16'd212,
           S_CONV_7		= 16'd213,
           S_CONV_8		= 16'd214,
           S_CONV_9		= 16'd215,
           S_CONV_10	= 16'd216,
           S_CONV_11	= 16'd217,
           S_CONV_12	= 16'd218,
           S_CONV_13	= 16'd219,
           S_CONV_14	= 16'd220,
           S_CONV_15	= 16'd221,
           S_CONV_16	= 16'd222,
           S_CONV_17	= 16'd223,
           S_CONV_18	= 16'd224,
           S_CONV_19	= 16'd225,
           S_CONV_20	= 16'd226,
           S_CONV_21	= 16'd227,
           S_CONV_22	= 16'd228,
           S_CONV_23	= 16'd229,
           S_CONV_24	= 16'd230,
           S_CONV_25	= 16'd231,
           S_CONV_26	= 16'd232,

           // FPLOAD sequence
           S_FPLOAD_4	= 16'd240,
           S_FPLOAD_5	= 16'd241,
           S_FPLOAD_6	= 16'd242,
           S_FPLOAD_7	= 16'd243,

           // FPMUL sequence
           S_FPMUL_4	= 16'd250,
           S_FPMUL_5	= 16'd251,
           S_FPMUL_6	= 16'd252,
           S_FPMUL_7	= 16'd253,
           S_FPMUL_8	= 16'd254,

           // RELU sequence
           S_RELU_4		= 16'd260,
           S_RELU_5		= 16'd261,
           S_RELU_6     = 16'd262,

           // OUT sequence
           S_OUT_4		= 16'd270,
           S_OUT_5		= 16'd271,

           // INT sequence
           S_INT_4		= 16'd280,
           S_INT_5		= 16'd281,

           // IN sequence
           S_IN_4		= 16'd290,
           S_IN_5		= 16'd291,
           S_IN_6		= 16'd292,
           S_IN_7		= 16'd293;

    //komutlar------ opcode IR[15:12]----------
    // -----------------------------------------------------------------
// Veri Transfer Komutları  (Tip = 3'b000)
// -----------------------------------------------------------------
localparam reg [7:0]
    LDA  = 8'b000_0000,  // Tip=000, AltOp=0000
    STA  = 8'b000_0001,  // Tip=000, AltOp=0001
    LDG  = 8'b000_0010,  // Tip=000, AltOp=0010
    LDK  = 8'b000_0011,  // Tip=000, AltOp=0011
    LDO  = 8'b000_0100,  // Tip=000, AltOp=0100
    STO  = 8'b000_0101;  // Tip=000, AltOp=0101

// -----------------------------------------------------------------
// Aritmetik ve Mantıksal Komutlar  (Tip = 3'b001)
// -----------------------------------------------------------------
localparam reg [7:0]
    ADD  = 8'b001_0000,  // Tip=001, AltOp=0000
    SUB  = 8'b001_0001,  // Tip=001, AltOp=0001
    MUL  = 8'b001_0010,  // Tip=001, AltOp=0010
    CLR  = 8'b001_1110,  // Tip=001, AltOp=1110
    NORM = 8'b001_1111;  // Tip=001, AltOp=1111

// -----------------------------------------------------------------
// Kontrol Komutları  (Tip = 3'b010)
// -----------------------------------------------------------------
localparam reg [7:0]
    BUN     = 8'b010_0000,  // Tip=010, AltOp=0000  (BUN)
    JZ      = 8'b010_0001,  // Tip=010, AltOp=0001
    JN      = 8'b010_0010,  // Tip=010, AltOp=0010
    JZINT   = 8'b010_0011,  // Tip=010, AltOp=0011
    INC     = 8'b010_0100,  // Tip=010, AltOp=0100
    DEC     = 8'b010_0101,  // Tip=010, AltOp=0101
    CMP     = 8'b010_0110,  // Tip=010, AltOp=0110
    CLRINT  = 8'b010_1110;  // Tip=010, AltOp=1110

// -----------------------------------------------------------------
// CNN ve Float Özel Komutları  (Tip = 3'b011)
// -----------------------------------------------------------------
localparam reg [7:0]
    PAD    = 8'b011_0000,  // Tip=011, AltOp=0000
    CONV   = 8'b011_0001,  // Tip=011, AltOp=0001
    FPLOAD = 8'b011_0010,  // Tip=011, AltOp=0010
    FPMUL  = 8'b011_0011,  // Tip=011, AltOp=0011
    RELU   = 8'b011_0100,  // Tip=011, AltOp=0100
    OUT    = 8'b011_0101,  // Tip=011, AltOp=0101
    INT    = 8'b011_0110,  // Tip=011, AltOp=0110
    IN     = 8'b011_0111;  // Tip=011, AltOp=0111

	
	// State registers
	reg [8:0] state, next;

    always @(posedge clk or posedge reset) begin
        if (reset)    state <= S_FETCH_0;
        else        state <= next;
    end

    always @(state, IR)
    begin
        case(state)
            S_FETCH_0: begin
                next = S_FETCH_1;
            end
            
            S_FETCH_1: begin
                next = S_FETCH_2;
            end
            
            S_FETCH_2: begin
                next = S_DECODE_3;
            end
            
            S_DECODE_3: begin
                if(IR == LDA) begin
                    next = S_LDA_4;
                end
                if (IR == STA) begin
                    next = S_STA_4;
                end   
                if (IR == LDG) begin
                    next = S_LDG_4;
                end     
                if (IR == LDK) begin
                    next = S_LDK_4;
                end     
                if (IR == LDO) begin
                    next = S_LDO_4;
                end    
                if (IR == STO) begin
                    next = S_STO_4;
                end   
                if (IR == ADD) begin
                    next = S_ADD_4;
                end   
                if (IR == SUB) begin
                    next = S_SUB_4;
                end    
                if (IR == MUL) begin
                    next = S_MUL_4;
                end  
                if (IR == CLR) begin
                    next = S_CLR_4;
                end   

                if (IR == NORM) begin
                    next = S_NORM_4;
                end  
                if (IR == BUN) begin
                    next = S_BUN_4;
                end  
                if (IR == JZ) begin
                    next = S_JZ_4;
                end
                if (IR == JN) begin
                    next = S_JN_4;
                end  
                if (IR == JZINT) begin
                    next = S_JZINT_4;
                end  
                if (IR == CLRINT) begin
                    next = S_CLRINT_4;
                end  
                if (IR == INC) begin
                    next = S_INC_4;
                end  
                if (IR == DEC) begin
                    next = S_DEC_4;
                end  
                if (IR == CMP) begin
                    next = S_CMP_4;
                end   
                if (IR == CONV) begin
                    next = S_CONV_4;
                end  
                if (IR == FPLOAD) begin
                    next = S_FPLOAD_4;
                end    
                if (IR == FPMUL) begin
                    next = S_FPMUL_4;
                end  
                if (IR == RELU) begin
                    next = S_RELU_4;
                end   
                if (IR == OUT) begin
                    next = S_OUT_4;
                end  
                if (IR == INT) begin
                    next = S_INT_4;
                end  
                if (IR == IN) begin
                    next = S_IN_4;
                end
               end
            endcase
            
            case(IR)
            //------------------------------------1
            S_LDA_4: begin
                next = S_LDA_5;
            end
            
            S_LDA_5: begin
                next = S_LDA_6;
            end
            
            S_LDA_6: begin
                next = S_LDA_7;
            end
            
            S_LDA_7: begin
                next = S_FETCH_0;
            end
            //---------------------------------------2
            S_STA_4: begin
                next = S_STA_5;
            end
            S_STA_5: begin
                next = S_STA_6;
            end
            S_STA_6: begin
                next = S_STA_7;
            end
            S_STA_7: begin
                next = S_FETCH_0;
            end
            //--------------------------------------------3
            S_LDG_4: begin
                next = S_LDG_5;
            end
            S_LDG_5: begin
                next = S_LDG_6;
            end
            S_LDG_6: begin
                next = S_LDG_7;
            end
            S_LDG_7: begin
                next = S_FETCH_0;
            end
            //----------------------------------------------4
            S_LDK_4: begin
                next = S_LDK_5;
            end
            S_LDK_5: begin
                next = S_LDK_6;
            end
            S_LDK_6: begin
                next = S_LDK_7;
            end
            S_LDK_7: begin
                next = S_FETCH_0;
            end
            //---------------------------------------------5
            S_LDO_4: begin
                next = S_LDO_5;
            end
            S_LDO_5: begin
                next = S_LDO_6;
            end
            S_LDO_6: begin
                next = S_LDO_7;
            end
            S_LDO_7: begin
                next = S_FETCH_0;
            end
            //------------------------------------------6
            S_STO_4: begin
                next = S_STO_5;
            end
            S_STO_5: begin
                next = S_STO_6;
            end
            S_STO_6: begin
                next = S_STO_7;
            end
            S_STO_7: begin
                next = S_FETCH_0;
            end
            //------------------------------------------7
            S_ADD_4: begin
                next = S_ADD_5;
            end
            S_ADD_5: begin
                next = S_ADD_6;
            end
            S_ADD_6: begin
                next = S_ADD_7;
            end
            S_ADD_7: begin
                next = S_ADD_8;
            end
            S_ADD_8: begin
                next = S_FETCH_0;
            end
            //------------------------------------------8
            S_SUB_4: begin
                next = S_SUB_5;
            end
            S_SUB_5: begin
                next = S_SUB_6;
            end
            S_SUB_6: begin
                next = S_SUB_7;
            end
            S_SUB_7: begin
                next = S_SUB_8;
            end
            S_SUB_8: begin
                next = S_FETCH_0;
            end
            //------------------------------------------9
            S_MUL_4: begin
                next = S_MUL_5;
            end
            S_MUL_5: begin
                next = S_MUL_6;
            end
            S_MUL_6: begin
                next = S_MUL_7;
            end
            S_MUL_7: begin
                next = S_MUL_8;
            end
            S_MUL_8: begin
                next = S_FETCH_0;
            end
            //------------------------------------------10
            S_CLR_4: begin
                next = S_CLR_5;
            end
            S_CLR_5: begin
                next = S_FETCH_0;
            end
            //------------------------------------------11

            //------------------------------------------12
            S_NORM_4: begin
                next = S_NORM_5;
            end
            S_NORM_5: begin
                next = S_FETCH_0;
            end
            //------------------------------------------13
            S_BUN_4: begin
                next = S_BUN_5;
            end
            S_BUN_5: begin
                next = S_FETCH_0;
            end
            //------------------------------------------14
            S_JZ_4: begin
                next = S_JZ_5;
            end
            S_JZ_5: begin
                next = S_FETCH_0;
            end
            //------------------------------------------15
            S_JN_4: begin
                next = S_JN_5;
            end
            S_JN_5: begin
                next = S_FETCH_0;
            end
            //------------------------------------------16
            S_JZINT_4: begin
                next = S_JZINT_5;
            end
            S_JZINT_5: begin
                next = S_FETCH_0;
            end
            //------------------------------------------17
            S_CLRINT_4: begin
                next = S_CLRINT_5;
            end
            S_CLRINT_5: begin
                next = S_FETCH_0;
            end
            //------------------------------------------18
            S_INC_4: begin
                next = S_INC_5;
            end
            S_INC_5: begin
                next = S_INC_6;
            end
            S_INC_6: begin
                next = S_INC_7;
            end
            S_INC_7: begin
                next = S_INC_8;
            end
            S_INC_8: begin
                next = S_INC_9;
            end
            S_INC_9: begin
                next = S_FETCH_0;
            end
            //------------------------------------------19
            S_DEC_4: begin
                next = S_DEC_5;
            end
            S_DEC_5: begin
                next = S_DEC_6;
            end
            S_DEC_6: begin
                next = S_DEC_7;
            end
            S_DEC_7: begin
                next = S_DEC_8;
            end
            S_DEC_8: begin
                next = S_DEC_9;
            end
            S_DEC_9: begin
                next = S_FETCH_0;
            end
            //------------------------------------------20
            S_CMP_4: begin
                next = S_CMP_5;
            end
            S_CMP_5: begin
                next = S_CMP_6;
            end
            S_CMP_6: begin
                next = S_CMP_7;
            end
            S_CMP_7: begin
                next = S_FETCH_0;
            end
            //------------------------------------------21
            S_CONV_4: begin
                next = S_CONV_5;
            end
            S_CONV_5: begin
                next = S_CONV_6;
            end
            S_CONV_6: begin
                next = S_CONV_7;
            end
            S_CONV_7: begin
                next = S_CONV_8;
            end
            S_CONV_8: begin
                next = S_CONV_9;
            end
            S_CONV_9: begin
                next = S_CONV_10;
            end
            S_CONV_10: begin
                next = S_CONV_11;
            end
            S_CONV_11: begin
                next = S_CONV_12;
            end
            S_CONV_12: begin
                next = S_CONV_13;
            end
            S_CONV_13: begin
                next = S_CONV_14;
            end
            S_CONV_14: begin
                next = S_CONV_15;
            end
            S_CONV_15: begin
                next = S_CONV_16;
            end
            S_CONV_16: begin
                next = S_CONV_17;
            end
            S_CONV_17: begin
                next = S_CONV_18;
            end
            S_CONV_18: begin
                next = S_CONV_19;
            end
            S_CONV_19: begin
                next = S_CONV_20;
            end
            S_CONV_20: begin
                next = S_CONV_21;
            end
            S_CONV_21: begin
                next = S_CONV_22;
            end
            S_CONV_22: begin
                next = S_CONV_23;
            end
            S_CONV_23: begin
                next = S_CONV_24;
            end
            S_CONV_24: begin
                next = S_CONV_25;
            end
            S_CONV_25: begin
                next = S_CONV_26;
            end
            S_CONV_26: begin
                next = S_FETCH_0;
            end
            //------------------------------------------22
            S_FPLOAD_4: begin
                next = S_FPLOAD_5;
            end
            S_FPLOAD_5: begin
                next = S_FPLOAD_6;
            end
            S_FPLOAD_6: begin
                next = S_FPLOAD_7;
            end
            S_FPLOAD_7: begin
                next = S_FETCH_0;
            end
            //------------------------------------------23
            S_FPMUL_4: begin
                next = S_FPMUL_5;
            end
            S_FPMUL_5: begin
                next = S_FPMUL_6;
            end
            S_FPMUL_6: begin
                next = S_FPMUL_7;
            end
            S_FPMUL_7: begin
                next = S_FETCH_0;
            end
            //------------------------------------------24
            S_RELU_4: begin
                next = S_RELU_5;
            end
            S_RELU_5: begin
                next = S_RELU_6;
            end
            S_RELU_6: begin
                next = S_FETCH_0;
            end
            //------------------------------------------25
            S_OUT_4: begin
                next = S_OUT_5;
            end
            S_OUT_5: begin
                next = S_FETCH_0;
            end
            //------------------------------------------26
            S_INT_4: begin
                next = S_INT_5;
            end
            S_INT_5: begin
                next = S_FETCH_0;
            end
            //------------------------------------------27
            S_IN_4: begin
                next = S_IN_5;
            end
            S_IN_5: begin
                next = S_IN_6;
            end
            S_IN_6: begin
                next = S_IN_7;
            end
            S_IN_7: begin
                next = S_FETCH_0;
            end
            // case sonu-------------------------
        endcase
    end

    reg [1:0] i = 2'b0, j = 2'b0;
    // Bus seçim sabitleri
    localparam [4:0]
        DR_SEL        = 5'd0,
        AC_SEL        = 5'd1,
        TR_SEL        = 5'd2,
        PC_SEL        = 5'd3,
        FROM_MEM_SEL  = 5'd4,
        XREG_SEL      = 5'd5,
        YREG_SEL      = 5'd6,
        VREG_SEL      = 5'd7,
        KREG_SEL      = 5'd8,
        GREG_SEL      = 5'd9,
        OREG_SEL      = 5'd10,
        INPR_SEL      = 5'd11,
        IREG_SEL      = 5'd12,
        JREG_SEL      = 5'd13,
        IR_SEL        = 5'd14,
        OUTR_SEL      = 5'd15,
        INPUT_SEL     = 5'd16,
        ZERO_SELL     = 5'd31;    // En son değer

    // ALU operasyon kodları
    localparam [3:0]
        ALU_ADD          = 4'b0000,
        ALU_SUB          = 4'b0001,
        ALU_MUL          = 4'b0010,
        ALU_ADD_CONST1   = 4'b0101,
        ALU_SUB_CONST1   = 4'b0110,
        ALU_SHR4         = 4'b0111,
        ALU_MUL_CONST10  = 4'b1000,
        ALU_MUL_CONST3   = 4'b1001,
        ALU_FPMUL        = 4'b1010,
        ALU_FP_NORMALIZE = 4'b1011,
        ALU_MUL_CONST8   = 4'b1100;
        
    //output logic
    always @(state)
    begin
        IR_Load=1'b0;
        AR_Load=1'b0;
        PC_Load=1'b0;
        AC_Load=1'b0;
        DR_Load=1'b0;
        bus_sel=ZERO_SELL;
        alu_sel=4'b0000;
        write_en=1'b0;
        PC_Inc=1'b0;
        DR_Inc=1'b0;
        
        case(state)
            S_FETCH_0: begin
                bus_sel=5'b00011;
                AR_Load=1'b1;
            end
            
            S_FETCH_1: begin
                PC_Inc=1'b1;
            end
            
            S_FETCH_2: begin
                bus_sel=5'b00010; //bus<<from_memory
                IR_Load=1;
            end
            
            S_DECODE_3: begin
                //OPCODE yukarýdaki always bloðunda çözüldü ve 
                //sonraki durumu geçildi
            end
            
            // DURUMLARIN KODLARI
            // -------LDA----------
            S_LDA_4: begin
                // AR ← IR[15:0]
                bus_sel = IR_SEL;  // IR → bus
                AR_Load = 1'b1;
            end

            S_LDA_5: begin
                // DR ← M[AR]
                bus_sel = 5'b00100; // from_memory → bus
                DR_Load = 1'b1;
            end

            S_LDA_6: begin
                // AC ← DR
                bus_sel = ZERO_SELL; // DR → bus
                AC_Load = 1'b1;
            end

            S_LDA_7: begin
                // NOP / tamamlandı (FETCH döngüsü tekrar başlatılacak)
            end
            
            // STA komut adımları
            S_STA_4: begin
                // AR ← IR[15:0]
                bus_sel  = IR_SEL;   // IR → bus
                AR_Load  = 1'b1;
            end
            
            S_STA_5: begin
                // DR ← AC
                bus_sel  = 5'b00001;  // AC → bus
                DR_Load  = 1'b1;
            end
            
            S_STA_6: begin
                // M[AR] ← DR
                bus_sel   = ZERO_SELL; // DR → bus
                write_en  = 1'b1;    // memory write
            end
            
            S_STA_7: begin
                // komut tamamlandı - FETCH döngüsüne dönülecek
            end
            
            // LDG komut adımları
            S_LDG_4: begin
                // AR ← IR[15:0]
                bus_sel = IR_SEL;   // IR → bus
                AR_Load = 1'b1;
            end
            
            S_LDG_5: begin
                // DR ← M[AR] (IMAGE bölgesinden okuma)
                bus_sel = 5'b00100;  // from_memory → bus
                DR_Load = 1'b1;
            end
            
            S_LDG_6: begin
                // AC ← DR
                bus_sel = ZERO_SELL;  // DR → bus
                AC_Load = 1'b1;
            end
            
            S_LDG_7: begin
                // komut tamamlandı - FETCH döngüsüne dönülecek
            end
            
            // LDK komut adımları
            S_LDK_4: begin
                // AR ← IR[15:0]
                bus_sel  = IR_SEL;   // IR → bus
                AR_Load  = 1'b1;
            end
            
            S_LDK_5: begin
                // DR ← M[AR] (KERNEL bölgesinden okuma)
                bus_sel  = 5'b00100;  // from_memory → bus
                DR_Load  = 1'b1;
            end
            
            S_LDK_6: begin
                // AC ← DR
                bus_sel  = ZERO_SELL;  // DR → bus
                AC_Load  = 1'b1;
            end
            
            S_LDK_7: begin
                // komut tamamlandı - FETCH döngüsüne dönülecek
            end
            
            // LDO komut adımları
            S_LDO_4: begin
                // AR ← IR[15:0]
                bus_sel  = IR_SEL;   // IR → bus
                AR_Load  = 1'b1;
            end
            
            S_LDO_5: begin
                // DR ← M[AR] (OUTPUT bölgesinden okuma)
                bus_sel  = 5'b00100;  // from_memory → bus
                DR_Load  = 1'b1;
            end
            
            S_LDO_6: begin
                // AC ← DR
                bus_sel  = ZERO_SELL;  // DR → bus
                AC_Load  = 1'b1;
            end
            
            S_LDO_7: begin
                // komut tamamlandı - FETCH döngüsüne dönülecek
            end
            
             // STO komut adımları
            S_STO_4: begin
                // AR ← IR[15:0]
                bus_sel  = IR_SEL;   // IR → bus
                AR_Load  = 1'b1;
            end
            
            S_STO_5: begin
                // DR ← AC
                bus_sel  = 5'b00001;  // AC → bus
                DR_Load  = 1'b1;
            end
            
            S_STO_6: begin
                // M[AR] ← DR (OUTPUT bölgesine yazma)
                bus_sel    = ZERO_SELL; // DR → bus
                write_en   = 1'b1;    // memory write
            end
            
            S_STO_7: begin
                // komut tamamlandı - FETCH döngüsüne dönülecek
            end
            
            // ADD komut adımları
            S_ADD_4: begin
                // AR ← IR[15:0]
                bus_sel   = IR_SEL;   // IR → bus
                AR_Load   = 1'b1;
            end

            S_ADD_5: begin
                // DR ← M[AR]
                bus_sel   = 5'b00100;  // from_memory → bus
                DR_Load   = 1'b1;
            end

            S_ADD_6: begin
                // TR ← DR
                bus_sel   = ZERO_SELL;  // DR → bus
                TR_Load   = 1'b1;
            end

            S_ADD_7: begin
                // AC ← AC + TR (ALU toplama)
                alu_sel   = ALU_ADD;  // localparam ALU_ADD = e.g. 2'b00
                AC_Load   = 1'b1;     // ALU sonucu AC'ye yüklenecek
            end

            S_ADD_8: begin
                // komut tamamlandı - FETCH döngüsüne dönülecek
            end
               
             // SUB komut adımları
            S_SUB_4: begin
                // AR ← IR[15:0]
                bus_sel  = IR_SEL;   // IR → bus
                AR_Load  = 1'b1;
            end
            
            S_SUB_5: begin
                // DR ← M[AR]
                bus_sel  = 5'b00100;  // from_memory → bus
                DR_Load  = 1'b1;
            end
            
            S_SUB_6: begin
                // TR ← DR
                bus_sel  = ZERO_SELL;  // DR → bus
                TR_Load  = 1'b1;
            end
            
            S_SUB_7: begin
                // AC ← AC - TR (ALU çıkarma)
                alu_sel  = ALU_SUB;  // localparam ALU_SUB = 4'b0001
                AC_Load  = 1'b1;
            end
            
            S_SUB_8: begin
                // komut tamamlandı - FETCH döngüsüne dönülecek
            end
            
              // MUL komut adımları
              S_MUL_4: begin
                  // AR ← IR[15:0]
                  bus_sel  = IR_SEL;   // IR → bus
                  AR_Load  = 1'b1;
              end

              S_MUL_5: begin
                  // DR ← M[AR]
                  bus_sel  = 5'b00100;  // from_memory → bus
                  DR_Load  = 1'b1;
              end

              S_MUL_6: begin
                  // TR ← DR
                  bus_sel  = ZERO_SELL;  // DR → bus
                  TR_Load  = 1'b1;
              end

              S_MUL_7: begin
                  // AC ← AC × TR (ALU çarpma)
                  alu_sel  = ALU_MUL;  // localparam ALU_MUL = 4'b0010
                  AC_Load  = 1'b1;     // ALU sonucu AC'ye yüklenecek
              end

              S_MUL_8: begin
                  // komut tamamlandı - FETCH döngüsüne dönülecek
              end
              
              // CLR komut adımları
              S_CLR_4: begin
                  // AC ← 0
                  AC_Load = 1'b1;
              end
              
              S_CLR_5: begin
                  // komut tamamlandı - FETCH döngüsüne dönülecek
              end
              
              // NORM komut adımları
              S_NORM_4: begin
                  // AC ← AC >> 4 (mantıksal sağ kaydırma)
                  alu_sel  = ALU_SHR4;   // localparam ALU_SHR4 = e.g. 4'b0111
                  AC_Load  = 1'b1;       // ALU sonucunu AC'ye yükle
              end
              
              S_NORM_5: begin
                  // komut tamamlandı - FETCH döngüsüne dönülecek
              end
              
              // BUN (unconditional jump) komut adımları
            S_BUN_4: begin
                // PC ← IR[15:0]
                bus_sel  = IR_SEL;   // IR → bus
                PC_Load  = 1'b1;
            end
            
            S_BUN_5: begin
                // komut tamamlandı - bir sonraki döngüde FETCH'e dönülecek
            end
            
            // JZ (Jump If Zero) komut adımları
            S_JZ_4: begin
                bus_sel   = AC_SEL;    // AC → Bus
                Zero_Check_En = 1'b1;  // Zero kontrol sinyalini aktif et
            end
            
            S_JZ_5: begin
                if (zero == 1'b1) begin
                    bus_sel = IR_SEL;  // IR → Bus
                    PC_Load = 1'b1;    // PC ← IR (atlama yapılır)
                end
                // değilse PC zaten FETCH_1 adımında artmıştı
            end 
            
            // JZINT (Jump If Interrupt Flag Set) komut adımları
            S_JZINT_4: begin
                // if (INTF == 1) PC ← IR[15..0]
                if (INTF == 1'b1) begin
                    bus_sel  = IR_SEL;   // IR → bus
                    PC_Load  = 1'b1;
                end
                // else: PC zaten bir önceki FETCH_1 adımında increment edildi
            end
            
            S_JZINT_5: begin
                // komut tamamlandı - FETCH döngüsüne dönülecek
            end
            
            // CLRINT (Clear Interrupt Flag) komut adımları
            S_CLRINT_4: begin
                // INTF ← 0
                INTF     = 1'b0;
            end
            
            S_CLRINT_5: begin
                // komut tamamlandı - FETCH döngüsüne dönülecek
            end
            // INC komut adımları
            S_INC_4: begin
                // AR ← IR[15:0]
                bus_sel  = IR_SEL;   // IR → bus
                AR_Load  = 1'b1;
            end
            
            S_INC_5: begin
                // DR ← M[AR]
                bus_sel  = 5'b00100;  // from_memory → bus
                DR_Load  = 1'b1;
            end
            
            S_INC_6: begin
                // TR ← DR
                bus_sel  = ZERO_SELL;  // DR → bus
                TR_Load  = 1'b1;
            end
            
            S_INC_7: begin
                // DR ← TR + 1  (ALU ile sabit 1 ekleme)
                alu_sel  = ALU_ADD_CONST1;  // localparam ALU_ADD_CONST1 = 4'b0101 (örnek)
                DR_Load  = 1'b1;            // ALU(TR,1) sonucunu DR'ye yükle
            end
            
            S_INC_8: begin
                // M[AR] ← DR
                bus_sel   = ZERO_SELL;  // DR → bus
                write_en  = 1'b1;
            end
            
            S_INC_9: begin
                // komut tamamlandı - FETCH döngüsüne dönülecek
            end
            // DEC komut adımları
            S_DEC_4: begin
                // AR ← IR[15:0]
                bus_sel  = IR_SEL;       // IR → bus
                AR_Load  = 1'b1;
            end
            
            S_DEC_5: begin
                // DR ← M[AR]
                bus_sel  = 5'b00100;      // from_memory → bus
                DR_Load  = 1'b1;
            end
            
            S_DEC_6: begin
                // TR ← DR
                bus_sel  = ZERO_SELL;      // DR → bus
                TR_Load  = 1'b1;
            end
            
            S_DEC_7: begin
                // DR ← TR - 1 (ALU ile sabit 1 çıkarma)
                alu_sel  = ALU_SUB_CONST1; // localparam ALU_SUB_CONST1 = 4'b0110
                DR_Load  = 1'b1;           // ALU(TR,1) sonucunu DR'ye yükle
            end
            
            S_DEC_8: begin
                // M[AR] ← DR
                bus_sel   = ZERO_SELL;      // DR → bus
                write_en  = 1'b1;         // memory write
            end
            
            S_DEC_9: begin
                // komut tamamlandı - FETCH döngüsüne dönülecek
            end
            
            // CMP komut adımları
            S_CMP_4: begin
                // AR ← IR[15:0]
                bus_sel  = IR_SEL;   // IR → bus
                AR_Load  = 1'b1;
            end
            
            S_CMP_5: begin
                // DR ← M[AR]
                bus_sel  = 5'b00100;  // from_memory → bus
                DR_Load  = 1'b1;
            end
            
            S_CMP_6: begin
                // AC ← AC - DR (ALU çıkarma; bayraklar etkilenir)
                alu_sel  = ALU_SUB;  // localparam ALU_SUB = 4'b0001
                AC_Load  = 1'b1;     // ALU sonucu AC'ye yüklenecek ve zero/negative bayrakları güncellenecek
            end
            
            S_CMP_7: begin
                // komut tamamlandı - FETCH döngüsüne dönülecek
            end
            
            // CONV komutu kontrol adımları
            S_CONV_4: begin
                bus_sel    = ZERO_SELL;
                XREG_Load  = 1'b1;
                YREG_Load  = 1'b1;
                VREG_Load  = 1'b1;
            end
            
            S_CONV_5: begin
                bus_sel     = YREG_SEL;
                compare_val = 16'd8;
                compare_en  = 1'b1;
            end
            
            S_CONV_6: begin
                if (equal)
                    next = S_CONV_26;
                else begin
                    bus_sel     = XREG_SEL;
                    compare_val = 16'd8;
                    compare_en  = 1'b1;
                end
            end
            
            S_CONV_7: begin
                if (equal) begin
                    bus_sel    = ZERO_SELL;
                    XREG_Load  = 1'b1;
                    alu_sel    = ALU_ADD_CONST1;
                    YREG_Load  = 1'b1;
                    next       = S_CONV_5;
                end else begin
                    bus_sel    = ZERO_SELL;
                    VREG_Load  = 1'b1;
                end
            end
            
            S_CONV_8: begin
                bus_sel    = ZERO_SELL;
                IREG_Load  = 1'b1;
            end
            
            S_CONV_9: begin
                bus_sel    = ZERO_SELL;
                JREG_Load  = 1'b1;
            end
            
            S_CONV_10: begin
                bus_sel     = IREG_SEL;
                compare_val = 16'd3;
                compare_en  = 1'b1;
            end
            
            S_CONV_11: begin
                if (equal)
                    next = S_CONV_14;
                else begin
                    bus_sel     = JREG_SEL;
                    compare_val = 16'd3;
                    compare_en  = 1'b1;
                end
            end
            
            S_CONV_12: begin
                if (equal) begin
                    // i ← i + 1
                    bus_sel   = IREG_SEL;
                    alu_sel   = ALU_ADD_CONST1;
                    IREG_Load = 1'b1;
                    // j ← 0
                    bus_sel   = ZERO_SELL;
                    JREG_Load = 1'b1;
                    next = S_CONV_10;
                end else begin
                    alu_sel = ALU_MUL_CONST10;
                    AR_Load = 1'b1;
                end
            end
            
            S_CONV_13: begin
                bus_sel    = FROM_MEM_SEL;
                GREG_Load  = 1'b1;
            end
            
            S_CONV_14: begin
                alu_sel = ALU_MUL_CONST3;
                AR_Load = 1'b1;
            end
            
            S_CONV_15: begin
                bus_sel    = FROM_MEM_SEL;
                KREG_Load  = 1'b1;
            end
            
            S_CONV_16: begin
                bus_sel   = GREG_SEL;
                TR_Load   = 1'b1;
            end
            
            S_CONV_17: begin
                alu_sel   = ALU_FPMUL;
                AC_Load   = 1'b1;
            end
            
            S_CONV_18: begin
                bus_sel   = AC_SEL;
                alu_sel   = ALU_ADD;
                VREG_Load = 1'b1;
            end
            
            S_CONV_19: begin
                // j ← j + 1
                bus_sel   = JREG_SEL;
                alu_sel   = ALU_ADD_CONST1;
                JREG_Load = 1'b1;
                next = S_CONV_11;
            end
            
            S_CONV_20: begin
                bus_sel       = VREG_SEL;
                AC_Load       = 1'b1;
                neg_check_en  = 1'b1;
            end
            
            S_CONV_21: begin
                if (neg) begin
                    bus_sel = ZERO_SELL;
                    AC_Load = 1'b1;
                end
                alu_sel = ALU_SHR4;
                AC_Load = 1'b1;
            end
            
            S_CONV_22: begin
                alu_sel = ALU_MUL_CONST8;
                AR_Load = 1'b1;
            end
            
            S_CONV_23: begin
                bus_sel = AC_SEL;
                DR_Load = 1'b1;
            end
            
            S_CONV_24: begin
                bus_sel  = DR_SEL;
                write_en = 1'b1;
            end
            
            S_CONV_25: begin
                bus_sel   = XREG_SEL;
                alu_sel   = ALU_ADD_CONST1;
                XREG_Load = 1'b1;
                next = S_CONV_6;
            end
            
            S_CONV_26: begin
                next = S_FETCH_0;
            end
            
            
            // FPLOAD komut adımları
            S_FPLOAD_4: begin
                // AR ← IR[15:0]
                bus_sel  = IR_SEL;   // IR → bus
                AR_Load  = 1'b1;
            end
            
            S_FPLOAD_5: begin
                // DR ← M[AR]
                bus_sel  = 5'b00100;  // from_memory → bus
                DR_Load  = 1'b1;
            end
            
            S_FPLOAD_6: begin
                // AC ← FP_Normalize(DR)
                alu_sel  = ALU_FP_NORMALIZE;  // örn. 4'b1001
                AC_Load  = 1'b1;
            end
            
            S_FPLOAD_7: begin
                // komut tamamlandı - FETCH döngüsüne dönülecek
            end
            
            // FPMUL (Floating-Point Multiply) komut adımları
            S_FPMUL_4: begin
                // AR ← IR[15:0]
                bus_sel  = IR_SEL;   // IR → bus
                AR_Load  = 1'b1;
            end
            
            S_FPMUL_5: begin
                // DR ← M[AR]
                bus_sel  = 5'b00100;  // from_memory → bus
                DR_Load  = 1'b1;
            end
            
            S_FPMUL_6: begin
                // TR ← DR
                bus_sel  = ZERO_SELL;  // DR → bus
                TR_Load  = 1'b1;
            end
            
            S_FPMUL_7: begin
                // AC ← FP(AC) × FP(TR)
                alu_sel  = ALU_FPMUL;  // örnek: 4'b1010
                AC_Load  = 1'b1;
            end
            
            S_FPMUL_8: begin
                // komut tamamlandı - FETCH döngüsüne dönülecek
            end
            
            // RELU (Rectified Linear Unit) komut adımları

            S_RELU_4: begin
                bus_sel       = AC_SEL;        // AC → bus
                neg_check_en  = 1'b1;          // işaret biti kontrolü (AC < 0 ?)
            end
            
            S_RELU_5: begin
                if (neg) begin                 // AC negatifse
                    bus_sel = ZERO_SELL;       // bus ← 0
                    AC_Load = 1'b1;            // AC ← 0
                end
            end
            
            S_RELU_6: begin
                // komut tamamlandı - FETCH döngüsüne dönülecek
            end
            
            // OUT (Output Register Yükleme) komut adımları
            S_OUT_4: begin
                // OUTR ← AC
                bus_sel    = 5'b00001;   // AC → bus
                OUTR_Load  = 1'b1;
            end
            
            S_OUT_5: begin
                // komut tamamlandı - FETCH döngüsüne dönülecek
            end
            
            // INT (Interrupt Flag Set) komut adımları
            S_INT_4: begin
                // INTF ← 1
                INTF = 1'b1;
            end
            
            S_INT_5: begin
                // komut tamamlandı - FETCH döngüsüne dönülecek
            end
            
            // IN (Harici Girişten Veri Oku) komut adımları
            S_IN_4: begin
                // AR ← IR[15:0]
                bus_sel  = IR_SEL;     // IR → bus
                AR_Load  = 1'b1;
            end
            
            S_IN_5: begin
                // DR ← INPUT[AR]
                bus_sel  = INPUT_SEL;  // INPUT[AR] → bus
                DR_Load  = 1'b1;
            end
            
            S_IN_6: begin
                // AC ← DR
                bus_sel  = ZERO_SELL;    // DR → bus
                AC_Load  = 1'b1;
            end
            
            S_IN_7: begin
                // komut tamamlandı - FETCH döngüsüne dönülecek
            end
            default: begin
                            IR_Load=1'b0;
                            AR_Load=1'b0;
                            PC_Load=1'b0;
                            bus_sel=5'b0;
                            alu_sel=2'b00;
                            write_en=1'b0;
                            AC_Load=1'b0;
                            AC_Inc=1'b0;
                            PC_Inc=1'b0;
                        end
                    endcase
                end    
                
            endmodule
