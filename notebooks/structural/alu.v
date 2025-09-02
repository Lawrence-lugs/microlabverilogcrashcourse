
module ALU #(parameter WIDTH = 4) (
    input  logic [WIDTH-1:0] a, b,
    input  logic [2:0] opcode,
    input  logic cin,
    output logic [WIDTH-1:0] result,
    output logic cout,
    output logic zero
);

    // Internal signals
    logic [WIDTH-1:0] add_result, logic_result, shift_result;
    logic add_cout;

    // TODO: Instantiate the building blocks
    // 1. Instantiate ripple_carry_adder
    // 2. Instantiate logical_unit  
    // 3. Instantiate shifter
    // 4. Implement output multiplexer based on opcode
    // 5. Generate zero flag

    // Your code here...

endmodule
