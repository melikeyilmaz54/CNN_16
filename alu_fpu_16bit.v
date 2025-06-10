module alu_fpu_16bit (
    input clk,
    input [3:0] op,             // Operasyon kodu
    input [15:0] a, b,          // 16-bit girişler
    output reg [15:0] result,   // 16-bit sonuç
    output reg zero,            // Sıfır bayrağı
    output reg carry,           // Taşma bayrağı (yalnızca integer için)
    output reg fp_error         // FP hata bayrağı (örneğin sıfıra bölme)
);

    // Operasyon kodları
    localparam [3:0]
        ADD     = 4'b0000,
        SUB     = 4'b0001,
        AND_OP  = 4'b0010,
        OR_OP   = 4'b0011,
        XOR_OP  = 4'b0100,
        NOT_OP  = 4'b0101,
        SHL     = 4'b0110,
        SHR     = 4'b0111,
        EQ      = 4'b1000,
        LT      = 4'b1001,
        FP_ADD  = 4'b1010,
        FP_SUB  = 4'b1011;

    // IEEE 754 16-bit parçalama
    wire a_sign = a[15];
    wire [4:0] a_exp = a[14:10];
    wire [9:0] a_frac = a[9:0];
    wire b_sign = b[15];
    wire [4:0] b_exp = b[14:10];
    wire [9:0] b_frac = b[9:0];

    always @(*) begin
        // Varsayılan değerler
        result = 16'b0;
        zero = 0;
        carry = 0;
        fp_error = 0;

        case(op)
            ADD: begin
                {carry, result} = a + b;
                zero = (result == 0);
            end
            SUB: begin
                {carry, result} = a - b;
                zero = (result == 0);
            end
            AND_OP: begin
                result = a & b;
                zero = (result == 0);
            end
            OR_OP: begin
                result = a | b;
                zero = (result == 0);
            end
            XOR_OP: begin
                result = a ^ b;
                zero = (result == 0);
            end
            NOT_OP: begin
                result = ~a;
                zero = (result == 0);
            end
            SHL: begin
                result = a << b[3:0];
                zero = (result == 0);
            end
            SHR: begin
                result = a >> b[3:0];
                zero = (result == 0);
            end
            EQ: begin
                result = (a == b) ? 16'h0001 : 16'h0000;
                zero = (a == b);
            end
            LT: begin
                result = (a < b) ? 16'h0001 : 16'h0000;
                zero = (a < b);
            end

            // Floating-Point Toplama (basit örnek)
            FP_ADD: begin
                result = fp_add(a, b);
                zero = (result[14:0] == 0);
            end

            // Floating-Point Çıkarma (basit örnek)
            FP_SUB: begin
                result = fp_sub(a, b);
                zero = (result[14:0] == 0);
            end

            default: begin
                result = 16'b0;
                zero = 1;
            end
        endcase
    end

    // Basit FP toplama fonksiyonu (aynı işaret ve aynı üstelik varsayılarak)
    function [15:0] fp_add;
        input [15:0] a, b;
        reg sign;
        reg [4:0] exp;
        reg [10:0] mant_a, mant_b, mant_sum;
        begin
            sign = a[15];
            exp = a[14:10];
            mant_a = {1'b1, a[9:0]};
            mant_b = {1'b1, b[9:0]};

            // Basit: exp aynıymış gibi topla (gerçekte hizalama yapılmalı)
            mant_sum = mant_a + mant_b;

            // Normalize (örnek)
            if (mant_sum[10]) begin
                mant_sum = mant_sum >> 1;
                exp = exp + 1;
            end

            fp_add = {sign, exp, mant_sum[9:0]};
        end
    endfunction

    // Basit FP çıkarma fonksiyonu (aynı işaret ve aynı üstelik varsayılarak)
    function [15:0] fp_sub;
        input [15:0] a, b;
        reg sign;
        reg [4:0] exp;
        reg [10:0] mant_a, mant_b, mant_diff;
        begin
            sign = a[15];
            exp = a[14:10];
            mant_a = {1'b1, a[9:0]};
            mant_b = {1'b1, b[9:0]};

            // Basit: exp aynıymış gibi çıkar (gerçekte hizalama yapılmalı)
            if (mant_a >= mant_b)
                mant_diff = mant_a - mant_b;
            else begin
                mant_diff = mant_b - mant_a;
                sign = ~sign;
            end

            // Normalize (örnek)
            while (mant_diff[10] == 0 && mant_diff != 0) begin
                mant_diff = mant_diff << 1;
                exp = exp - 1;
            end

            fp_sub = {sign, exp, mant_diff[9:0]};
        end
    endfunction

endmodule