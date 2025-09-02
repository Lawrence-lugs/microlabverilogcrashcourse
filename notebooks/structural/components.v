
module full_adder (
    input  logic a, b, cin,
    output logic sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule

module ripple_carry_adder #(parameter WIDTH = 4) (
    input  logic [WIDTH-1:0] a, b,
    input  logic cin,
    output logic [WIDTH-1:0] sum,
    output logic cout
);
    logic [WIDTH:0] carry;
    assign carry[0] = cin;
    assign cout = carry[WIDTH];

    genvar i;
    generate
        for (i = 0; i < WIDTH; i++) begin : adder_chain
            full_adder fa_inst (
                .a(a[i]),
                .b(b[i]),
                .cin(carry[i]),
                .sum(sum[i]),
                .cout(carry[i+1])
            );
        end
    endgenerate
endmodule

module logical_unit #(parameter WIDTH = 4) (
    input  logic [WIDTH-1:0] a, b,
    input  logic [1:0] op,
    output logic [WIDTH-1:0] result
);
    always_comb begin
        case (op)
            2'b00: result = a & b;  // AND
            2'b01: result = a | b;  // OR
            2'b10: result = a ^ b;  // XOR
            2'b11: result = ~a;     // NOT
        endcase
    end
endmodule

module shifter #(parameter WIDTH = 4) (
    input  logic [WIDTH-1:0] data,
    input  logic [1:0] shift_op,
    output logic [WIDTH-1:0] result
);
    always_comb begin
        case (shift_op)
            2'b00: result = data;           // No shift
            2'b01: result = data << 1;      // Left shift
            2'b10: result = data >> 1;      // Right shift
            2'b11: result = {data[0], data[WIDTH-1:1]}; // Rotate right
        endcase
    end
endmodule
