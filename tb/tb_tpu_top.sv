`timescale 1ns/1ps

module tpu_system_tb;

    // Parameters
    parameter dataSize = 8;
    parameter numInChannel = 1;
    parameter kernelWidth = 3;
    parameter numOutChannel = 3;
    parameter numRegister = 256;
    parameter CLK_PERIOD = 10;

    // Local parameters
    localparam numAddrBuffer = $clog2(numRegister);
    localparam outputSize = dataSize * 2 + $clog2(numInChannel) + 1;
    localparam nPEy = kernelWidth*kernelWidth;
    localparam nPEx = numOutChannel;

    // Signals
    reg clk;
    reg nrst;
    reg [dataSize-1:0] weight [nPEy][nPEx];
    wire signed [outputSize-1:0] matrix_out [nPEx];
    reg [numAddrBuffer-1:0] wr_addr;
    reg [dataSize-1:0] wr_data;
    reg wr_en;
    reg [15:0] cfg_ifmap_width;
    reg ctrl_start;
    wire flag_done;

    // Input matrix storage
    reg [7:0] activation_matrix [0:4][0:4];  // 5x5 matrix from txt
    integer file_handle;
    integer scan_count;
    integer row, col;

    // DUT instantiation
    tpu_system #(
        .dataSize(dataSize),
        .numInChannel(numInChannel),
        .kernelWidth(kernelWidth),
        .numOutChannel(numOutChannel),
        .numRegister(numRegister)
    ) dut (
        .clk(clk),
        .nrst(nrst),
        .weight(weight),
        .matrix_out(matrix_out),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .wr_en(wr_en),
        .cfg_ifmap_width(cfg_ifmap_width),
        .ctrl_start(ctrl_start),
        .flag_done(flag_done)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test stimulus
    initial begin
        $vcdpluson();
        $vcdplusmemon;
        $vcdplusfile("wave.vpd"); 

        // Initialize signals
        nrst = 1;
        wr_en = 0;
        ctrl_start = 0;
        cfg_ifmap_width = 5;  // 5x5 input matrix

        // Initialize weight matrix
        weight[0][0] = 10;  weight[0][1] = -11; weight[0][2] = 12;
        weight[1][0] = -13; weight[1][1] = 14;  weight[1][2] = -15;
        weight[2][0] = 16;  weight[2][1] = -17; weight[2][2] = 18;
        weight[3][0] = -42; weight[3][1] = 65;  weight[3][2] = 17;
        weight[4][0] = 92;  weight[4][1] = -23; weight[4][2] = 41;
        weight[5][0] = 79;  weight[5][1] = 11;  weight[5][2] = -64;
        weight[6][0] = -5;  weight[6][1] = 38;  weight[6][2] = 27;
        weight[7][0] = 71;  weight[7][1] = -19; weight[7][2] = 8;
        weight[8][0] = 33;  weight[8][1] = 54;  weight[8][2] = -29;

        // Reset sequence
        #(CLK_PERIOD*2);
        nrst = 0;
        #(CLK_PERIOD*2);
        nrst = 1;
        #(CLK_PERIOD*2);

        // Read activation matrix from txt
        file_handle = $fopen("../tb/a.txt", "r");
        if (file_handle == 0) begin
            $display("Error: Could not open file a.txt");
            $finish;
        end

        // Read space-separated values
        for (row = 0; row < 5; row++) begin
            for (col = 0; col < 5; col++) begin
                scan_count = $fscanf(file_handle, "%d", activation_matrix[row][col]);
                if (scan_count != 1) begin
                    $display("Error reading value at row %0d, col %0d", row, col);
                    $finish;
                end
            end
        end
        $fclose(file_handle);

        // Display read matrix for verification
        $display("Read activation matrix:");
        for (row = 0; row < 5; row++) begin
            for (col = 0; col < 5; col++) begin
                $write("%3d ", activation_matrix[row][col]);
            end
            $display("");
        end

        // Write activation data to buffer_router
        for (row = 0; row < 5; row++) begin
            for (col = 0; col < 5; col++) begin
                @(posedge clk);
                wr_en = 1;
                wr_addr = row * 5 + col;
                wr_data = activation_matrix[row][col];
            end
        end

        // Finish writing data
        #(CLK_PERIOD);
        wr_en = 0;

        // Start processing
        #(CLK_PERIOD*2);
        ctrl_start = 1;
        #(CLK_PERIOD);
        ctrl_start = 0;

        // Wait for processing to complete
        wait(dut.router_flag_done);
        $display("Matrix Outputs");
        while(!flag_done) begin
            $display("%0d,%0d,%0d", matrix_out[0],matrix_out[1],matrix_out[2]);
            #(CLK_PERIOD);
        end
        #(CLK_PERIOD*10);

        // Display results
        $display("Processing complete!");
        $display("Output matrix:");
        for (integer i = 0; i < nPEx; i++) begin
            $display("Channel %0d: %0d", i, matrix_out[i]);
        end

        // End simulation
        #(CLK_PERIOD*10);
        $finish;
    end

    // Monitor flag_done
    always @(posedge flag_done) begin
        $display("Processing completed at time %0t", $time);
    end

    // Monitor writes to buffer
    always @(posedge clk) begin
        if (wr_en) begin
            $display("Writing to buffer - Address: %0d, Data: %0d", wr_addr, wr_data);
        end
    end

    // Timeout watchdog
    parameter MAX_CYCLES = 10000;
    initial begin
        #(CLK_PERIOD*MAX_CYCLES);
        $display("Error: Simulation timeout after %d cycles", MAX_CYCLES);
        $finish;
    end

    // Waveform generation
    initial begin
        $dumpfile("tpu_system_tb.vcd");
        $dumpvars(0, tpu_system_tb);
    end

endmodule