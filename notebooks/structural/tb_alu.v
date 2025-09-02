
`timescale 1ns/1ps

module tb_alu;
    // Parameters
    parameter WIDTH = 4;
    parameter CLK_PERIOD = 10;

    // DUT signals
    logic [WIDTH-1:0] a, b;
    logic [2:0] opcode;
    logic cin;
    logic [WIDTH-1:0] result;
    logic cout;
    logic zero;

    // Clock for timing (not used by DUT but useful for waveforms)
    logic clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Instantiate DUT
    ALU #(.WIDTH(WIDTH)) dut (
        .a(a),
        .b(b),
        .opcode(opcode),
        .cin(cin),
        .result(result),
        .cout(cout),
        .zero(zero)
    );

    // Test variables
    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;

    // Test task
    task automatic test_operation(
        input [WIDTH-1:0] test_a,
        input [WIDTH-1:0] test_b,
        input [2:0] test_opcode,
        input test_cin,
        input [WIDTH-1:0] expected_result,
        input expected_cout,
        input expected_zero,
        input string operation_name
    );
        test_count++;

        // Apply inputs
        a = test_a;
        b = test_b;
        opcode = test_opcode;
        cin = test_cin;

        // Wait for combinational logic to settle
        #1;

        // Check results
        if (result === expected_result && cout === expected_cout && zero === expected_zero) begin
            $display("✓ PASS: %s | a=%b, b=%b, opcode=%b, cin=%b | result=%b, cout=%b, zero=%b", 
                    operation_name, test_a, test_b, test_opcode, test_cin, result, cout, zero);
            pass_count++;
        end else begin
            $display("✗ FAIL: %s | a=%b, b=%b, opcode=%b, cin=%b", 
                    operation_name, test_a, test_b, test_opcode, test_cin);
            $display("     Expected: result=%b, cout=%b, zero=%b", 
                    expected_result, expected_cout, expected_zero);
            $display("     Got:      result=%b, cout=%b, zero=%b", 
                    result, cout, zero);
            fail_count++;
        end
    endtask

    initial begin
        $display("=== ALU Structural Testbench ===");
        $display("Testing %d-bit ALU implementation", WIDTH);
        $display("");

        // Initialize
        a = 0; b = 0; opcode = 0; cin = 0;
        #10;

        $display("--- Arithmetic Operations ---");
        // Test Addition (opcode 000)
        test_operation(4'b0001, 4'b0010, 3'b000, 1'b0, 4'b0011, 1'b0, 1'b0, "ADD: 1+2");
        test_operation(4'b1111, 4'b0001, 3'b000, 1'b0, 4'b0000, 1'b1, 1'b1, "ADD: 15+1 (overflow)");
        test_operation(4'b0101, 4'b1010, 3'b000, 1'b1, 4'b0000, 1'b1, 1'b1, "ADD: 5+10+1 (carry in)");

        // Test Subtraction (opcode 001) - assuming 2's complement subtraction
        test_operation(4'b0101, 4'b0010, 3'b001, 1'b1, 4'b0100, 1'b1, 1'b0, "SUB: 5-2");
        test_operation(4'b0000, 4'b0001, 3'b001, 1'b1, 4'b0000, 1'b1, 1'b1, "SUB: 0-1 (zero result)");

        $display("");
        $display("--- Logical Operations ---");
        // Test AND (opcode 010)
        test_operation(4'b1100, 4'b1010, 3'b010, 1'b0, 4'b1000, 1'b0, 1'b0, "AND: 1100 & 1010");
        test_operation(4'b1111, 4'b0000, 3'b010, 1'b0, 4'b0000, 1'b0, 1'b1, "AND: 1111 & 0000");

        // Test OR (opcode 011)
        test_operation(4'b1100, 4'b1010, 3'b011, 1'b0, 4'b1110, 1'b0, 1'b0, "OR: 1100 | 1010");
        test_operation(4'b0000, 4'b0000, 3'b011, 1'b0, 4'b0000, 1'b0, 1'b1, "OR: 0000 | 0000");

        $display("");
        $display("--- Shift Operations ---");
        // Test Left Shift (opcode 100)
        test_operation(4'b0011, 4'b0000, 3'b100, 1'b0, 4'b0110, 1'b0, 1'b0, "SHL: 0011 << 1");
        test_operation(4'b1000, 4'b0000, 3'b100, 1'b0, 4'b0000, 1'b1, 1'b1, "SHL: 1000 << 1 (overflow)");

        // Test Right Shift (opcode 101)  
        test_operation(4'b1100, 4'b0000, 3'b101, 1'b0, 4'b0110, 1'b0, 1'b0, "SHR: 1100 >> 1");
        test_operation(4'b0001, 4'b0000, 3'b101, 1'b0, 4'b0000, 1'b0, 1'b1, "SHR: 0001 >> 1 (zero)");

        $display("");
        $display("--- XOR and NOT Operations ---");
        // Test XOR (assuming opcode 110)
        test_operation(4'b1100, 4'b1010, 3'b110, 1'b0, 4'b0110, 1'b0, 1'b0, "XOR: 1100 ^ 1010");
        test_operation(4'b1111, 4'b1111, 3'b110, 1'b0, 4'b0000, 1'b0, 1'b1, "XOR: 1111 ^ 1111");

        // Test NOT (assuming opcode 111)
        test_operation(4'b1010, 4'b0000, 3'b111, 1'b0, 4'b0101, 1'b0, 1'b0, "NOT: ~1010");
        test_operation(4'b1111, 4'b0000, 3'b111, 1'b0, 4'b0000, 1'b0, 1'b1, "NOT: ~1111");

        $display("");
        $display("--- Edge Cases ---");
        // Test all zeros
        test_operation(4'b0000, 4'b0000, 3'b000, 1'b0, 4'b0000, 1'b0, 1'b1, "Edge: All zeros");

        // Test all ones
        test_operation(4'b1111, 4'b1111, 3'b000, 1'b0, 4'b1110, 1'b1, 1'b0, "Edge: All ones ADD");

        $display("");
        $display("=== Test Summary ===");
        $display("Total Tests: %d", test_count);
        $display("Passed:      %d", pass_count);
        $display("Failed:      %d", fail_count);

        if (fail_count == 0) begin
            $display("🎉 ALL TESTS PASSED! 🎉");
        end else begin
            $display("❌ Some tests failed. Check your ALU implementation.");
        end

        $finish;
    end

    // Generate VCD for waveform viewing
    initial begin
        $dumpfile("alu_test.vcd");
        $dumpvars(0, tb_alu);
    end

endmodule
