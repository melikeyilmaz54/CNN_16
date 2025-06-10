module alu_fpu_16bit (
    input clk,
    input [3:0] op,             // Operasyon kodu
    input [15:0] a, b,          // 16-bit girişler
    output reg [15:0] result,   // 16-bit sonuç
    output reg zero,            // Sıfır bayrağı
    output reg carry,           // Taşma bayrağı (integer için)
    output reg fp_error         // FP hata bayrağı
);

    // Operasyon kodları
    localparam [3:0]
        ADD          = 4'd0,
        SUB          = 4'd1,
        MUL          = 4'd2,
        CMP          = 4'd3,
        SHR4         = 4'd4,
        ADD_CONST_1  = 4'd5,
        SUB_CONST_1  = 4'd6,
        MUL_CONST_10 = 4'd7,
        MUL_CONST_3  = 4'd8,
        FPMUL        = 4'd9,
        MUL_CONST_8  = 4'd10,
        FP_NORMALIZE = 4'd11;

    // IEEE 754 benzeri parçalama
    wire a_sign = a[15];
    wire [4:0] a_exp = a[14:10];
    wire [9:0] a_frac = a[9:0];
    wire b_sign = b[15];
    wire [4:0] b_exp = b[14:10];
    wire [9:0] b_frac = b[9:0];

    reg [31:0] mul_temp; // Integer çarpma için geniş register

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
            MUL: begin
                mul_temp = a * b;
                result = mul_temp[15:0]; // Taşan kısım atıldı, dilersen kullanabilirsin
                carry = |mul_temp[31:16];
                zero = (result == 0);
            end
            CMP: begin
                result = (a == b) ? 16'h0001 : 16'h0000;
                zero = (a == b);
            end
            SHR4: begin
                result = a >> 4;
                zero = (result == 0);
            end
            ADD_CONST_1: begin
                {carry, result} = a + 16'd1;
                zero = (result == 0);
            end
            SUB_CONST_1: begin
                {carry, result} = a - 16'd1;
                zero = (result == 0);
            end
            MUL_CONST_10: begin
                mul_temp = a * 16'd10;
                result = mul_temp[15:0];
                carry = |mul_temp[31:16];
                zero = (result == 0);
            end
            MUL_CONST_3: begin
                mul_temp = a * 16'd3;
                result = mul_temp[15:0];
                carry = |mul_temp[31:16];
                zero = (result == 0);
            end
            MUL_CONST_8: begin
                mul_temp = a * 16'd8;
                result = mul_temp[15:0];
                carry = |mul_temp[31:16];
                zero = (result == 0);
            end
            FPMUL: begin
                // Basit floating point çarpma fonksiyonunu çağır
                result = fp_mul(a, b);
                zero = (result[14:0] == 0);
                fp_error = fp_mul_error(a, b);
            end
            FP_NORMALIZE: begin
                result = fp_normalize(a);
                zero = (result[14:0] == 0);
            end
            default: begin
                result = 16'b0;
                zero = 1;
            end
        endcase
    end

    // Basit FP çarpma fonksiyonu
    function [15:0] fp_mul;
        input [15:0] x, y;
        reg sign;
        reg [5:0] exp_sum;
        reg [21:0] mant_x, mant_y, mant_mul;
        reg [9:0] mant_res;
        begin
            // İşaret XOR
            sign = x[15] ^ y[15];

            // Üstelikleri topla ve bias'ı çıkar (bias = 15)
            exp_sum = x[14:10] + y[14:10] - 5'd15;

            // Mantissa'ları 1. bit implicit 1 ile
            mant_x = {1'b1, x[9:0], 10'b0}; // 21 bit
            mant_y = {1'b1, y[9:0], 10'b0};

            mant_mul = mant_x * mant_y; // 42 bit çarpma

            // Normalizasyon: mant_mul en fazla 42 bit, en anlamlı 21-31 bit seçilecek
            // Burada örnek basit olarak mant_mul üst 22 bit'e kaydırılıyor
            mant_res = mant_mul[31:22]; 

            fp_mul = {sign, exp_sum[4:0], mant_res};
        end
    endfunction

    // Basit FP hata kontrolü (sıfıra bölme veya mantıha uygunluk kontrolü)
    function fp_mul_error;
        input [15:0] x, y;
        begin
            // Örnek: eğer exponent sıfırsa hata yok, yoksa 0
            fp_mul_error = 0;
        end
    endfunction

    // Basit FP normalize fonksiyonu
    function [15:0] fp_normalize;
        input [15:0] x;
        reg [4:0] exp;
        reg [10:0] mant;
        begin
            exp = x[14:10];
            mant = {1'b1, x[9:0]};
            while (mant[10] == 0 && mant != 0) begin
                mant = mant << 1;
                exp = exp - 1;
            end
            fp_normalize = {x[15], exp, mant[9:0]};
        end
    endfunction

endmodule
