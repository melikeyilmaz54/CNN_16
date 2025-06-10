// control_unit.v
// FSM-based control unit with 9-bit state encoding (decimal steps of 10)
module control_unit(
    input clk,
    input reset,
    input [15:0] IR,
    input mem_ready,
    output reg [8:0] state,       // 9-bit state
    output reg AR_Load, DR_Load, AC_Load, IR_Load, PC_Inc, PC_Load, DR_Inc, write_en,
    output reg [3:0] bus_sel,
    output reg [1:0] alu_sel,
    output reg Address 
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

           // ACT sequence
           S_ACT_4		= 16'd110,
           S_ACT_5		= 16'd110,

           // NORM sequence
           S_NORM_4		= 16'd120,
           S_NORM_5		= 16'd120,

           // JMP sequence
           S_JMP_4		= 16'd130,
           S_JMP_5		= 16'd130,

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
    BUN     = 8'b010_0000,  // Tip=010, AltOp=0000  (JMP)
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
                    next = S_JMP_4;
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
            S_ACT_4: begin
                next = S_ACT_5;
            end
            S_ACT_5: begin
                next = S_FETCH_0;
            end
            //------------------------------------------12
            S_NORM_4: begin
                next = S_NORM_5;
            end
            S_NORM_5: begin
                next = S_FETCH_0;
            end
            //------------------------------------------13
            S_JMP_4: begin
                next = S_JMP_5;
            end
            S_JMP_5: begin
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

    //output logic
    always @(state)
    begin
        IR_Load=1'b0;
        AR_Load=1'b0;
        PC_Load=1'b0;
        AC_Load=1'b0;
        DR_Load=1'b0;
        bus_sel=1'b0;
        alu_sel=2'b00;
        write_en=1'b0;
        PC_Inc=1'b0;
        DR_Inc=1'b0;
        
        case(state)
            S_FETCH_0: begin
                bus_sel=2'b11;
                AR_Load=1'b1;
            end
            
            S_FETCH_1: begin
                PC_Inc=1'b1;
            end
            
            S_FETCH_2: begin
                bus_sel=2'b10; //bus<<from_memory
                IR_Load=1;
            end
            
            S_DECODE_3: begin
                //OPCODE yukarýdaki always bloðunda çözüldü ve 
                //sonraki durumu geçildi
            end
            
            // DURUMLARIN KODLARI
            
            
            
            // DURUMLARIN KODLARI SONU
            default: begin
                IR_Load=1'b0;
                AR_Load=1'b0;
                PC_Load=1'b0;
                bus_sel=1'b0;
                alu_sel=2'b00;
                write_en=1'b0;
                AC_Load=1'b0;
                AC_Inc=1'b0;
                PC_Inc=1'b0;
            end
        endcase
    end    
    
endmodule
