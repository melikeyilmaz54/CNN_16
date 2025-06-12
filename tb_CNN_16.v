`timescale 1ns / 1ps

module tb_CNN_16;

    // Inputs
    reg clk;
    reg reset;
    reg mem_ready;
    reg [15:0] from_memory;
    
    // Outputs
    wire [15:0] to_memory;
    wire [11:0] address;
    wire [15:0] IR_Value;
    wire [15:0] AC_Value;
    wire [11:0] PC_Value;
    wire [7:0] XREG_Value;
    wire [7:0] YREG_Value;
    
    // Control signals (for monitoring)
    wire [8:0] state_o;
    wire AR_Load, DR_Load, AC_Load, TR_Load, IR_Load;
    wire PC_Load, write_en;
    wire [4:0] bus_sel;
    wire [3:0] alu_sel;
    
    // Test variables
    reg [15:0] memory [0:4095]; // 4K memory
    integer i;
    
    // Instantiate the Unit Under Test (UUT)
    control_unit cu (
        .clk(clk),
        .reset(reset),
        .IR(IR_Value),
        .mem_ready(mem_ready),
        .zero(zero),
        .equal(equal),
        .neg(neg),
        .state_o(state_o),
        .AR_Load(AR_Load),
        .DR_Load(DR_Load),
        .AC_Load(AC_Load),
        .TR_Load(TR_Load),
        .IR_Load(IR_Load),
        .PC_Load(PC_Load),
        .write_en(write_en),
        .bus_sel(bus_sel),
        .alu_sel(alu_sel)
    );
    
    cnn16_data_path dp (
        .clk(clk),
        .rst(reset),
        .AC_Load(AC_Load),
        .DR_Load(DR_Load),
        .TR_Load(TR_Load),
        .IR_Load(IR_Load),
        .PC_Load(PC_Load),
        .AR_Load(AR_Load),
        .XREG_Load(1'b0), // Not used in current test
        .YREG_Load(1'b0), // Not used in current test
        .VREG_Load(1'b0), // Not used in current test
        .KREG_Load(1'b0), // Not used in current test
        .GREG_Load(1'b0), // Not used in current test
        .OREG_Load(1'b0), // Not used in current test
        .INPR_Load(1'b0), // Not used in current test
        .OUTR_Load(1'b0), // Not used in current test
        .PC_Inc(1'b0),    // Not used in current test
        .AR_Inc(1'b0),    // Not used in current test
        .AC_Inc(1'b0),    // Not used in current test
        .DR_Inc(1'b0),    // Not used in current test
        .alu_sel(alu_sel),
        .bus_sel(bus_sel),
        .compare_en(1'b0), // Not used in current test
        .compare_val(16'b0), // Not used in current test
        .Zero_Check_En(1'b0), // Not used in current test
        .neg_check_en(1'b0), // Not used in current test
        .from_memory(from_memory),
        .to_memory(to_memory),
        .address(address),
        .IR_Value(IR_Value),
        .AC_Value(AC_Value),
        .PC_Value(PC_Value),
        .XREG_Value(XREG_Value),
        .YREG_Value(YREG_Value),
        .zero(zero),
        .equal(equal),
        .neg(neg)
    );
    
    // Clock generation
    always begin
        #5 clk = ~clk;
    end
    
    // Memory simulation
    always @(posedge clk) begin
        if (write_en) begin
            memory[address] <= to_memory;
            $display("Memory Write: Address %h, Data %h", address, to_memory);
        end
        from_memory <= memory[address];
    end
    
    // Test sequence
    initial begin
        // Initialize memory with some test instructions
        memory[0] = 16'h1000;  // LDA 0x000
        memory[1] = 16'h2001;  // STA 0x001
        memory[2] = 16'h3002;  // ADD 0x002
        memory[3] = 16'h4003;  // SUB 0x003
        memory[4] = 16'h5004;  // MUL 0x004
        memory[5] = 16'h6000;  // CLR
        memory[6] = 16'h7000;  // NORM
        memory[7] = 16'h8005;  // BUN 0x005
        
        // Initialize some data
        memory[16'h000] = 16'h1234;
        memory[16'h001] = 16'h0000;
        memory[16'h002] = 16'h5678;
        memory[16'h003] = 16'h1111;
        memory[16'h004] = 16'h0002;
        memory[16'h005] = 16'h9000;  // JZ (will jump if zero)
        
        // Initialize Inputs
        clk = 0;
        reset = 1;
        mem_ready = 1;
        
        // Reset the system
        #10;
        reset = 0;
        
        $display("Starting simulation...");
        $display("Time\tPC\tIR\t\tAC\t\tState\tOperation");
        
        // Monitor the execution
        $monitor("%t\t%h\t%h\t%h\t%d\t%s", 
            $time, PC_Value, IR_Value, AC_Value, state_o,
            get_operation_name(IR_Value));
            
        // Run for enough cycles to execute several instructions
        #1000;
        
        // Display final memory contents
        $display("\nFinal Memory Contents:");
        for (i = 0; i < 16; i = i + 1) begin
            $display("Mem[%h] = %h", i, memory[i]);
        end
        
        $display("\nFinal Register States:");
        $display("AC = %h, PC = %h, IR = %h", AC_Value, PC_Value, IR_Value);
        
        $finish;
    end
    
    // Helper function to display instruction names
    function string get_operation_name(input [15:0] ir);
        reg [2:0] op_type;
        reg [3:0] op_code;
        
        begin
            op_type = ir[15:13];
            op_code = ir[12:0];
            
            case(op_type)
                3'b000: begin // Data Transfer
                    case(op_code)
                        4'b0000: get_operation_name = "LDA";
                        4'b0001: get_operation_name = "STA";
                        4'b0010: get_operation_name = "LDG";
                        4'b0011: get_operation_name = "LDK";
                        4'b0100: get_operation_name = "LDO";
                        4'b0101: get_operation_name = "STO";
                        default: get_operation_name = "UNKNOWN_DATA";
                    endcase
                end
                3'b001: begin // Arithmetic
                    case(op_code)
                        4'b0000: get_operation_name = "ADD";
                        4'b0001: get_operation_name = "SUB";
                        4'b0010: get_operation_name = "MUL";
                        4'b1110: get_operation_name = "CLR";
                        4'b1111: get_operation_name = "NORM";
                        default: get_operation_name = "UNKNOWN_ARITH";
                    endcase
                end
                3'b010: begin // Control
                    case(op_code)
                        4'b0000: get_operation_name = "BUN";
                        4'b0001: get_operation_name = "JZ";
                        4'b0010: get_operation_name = "JN";
                        4'b0011: get_operation_name = "JZINT";
                        4'b0100: get_operation_name = "INC";
                        4'b0101: get_operation_name = "DEC";
                        4'b0110: get_operation_name = "CMP";
                        4'b1110: get_operation_name = "CLRINT";
                        default: get_operation_name = "UNKNOWN_CTRL";
                    endcase
                end
                3'b011: begin // CNN/Float
                    case(op_code)
                        4'b0000: get_operation_name = "PAD";
                        4'b0001: get_operation_name = "CONV";
                        4'b0010: get_operation_name = "FPLOAD";
                        4'b0011: get_operation_name = "FPMUL";
                        4'b0100: get_operation_name = "RELU";
                        4'b0101: get_operation_name = "OUT";
                        4'b0110: get_operation_name = "INT";
                        4'b0111: get_operation_name = "IN";
                        default: get_operation_name = "UNKNOWN_CNN";
                    endcase
                end
                default: get_operation_name = "UNKNOWN";
            endcase
        end
    endfunction

endmodule