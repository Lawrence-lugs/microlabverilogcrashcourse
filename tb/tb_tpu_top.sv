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
    wire flag_valid;

    // Input matrix storage
    reg [7:0] activation_matrix [0:4][0:4];  // 5x5 matrix from txt
    integer file_handle;
    integer scan_count;
    integer row, col;

    // DUT instantiation
    tpu_system #(
        .dataSize       (dataSize),
        .numInChannel   (numInChannel),
        .kernelWidth    (kernelWidth),
        .numOutChannel  (numOutChannel),
        .numRegister    (numRegister)
    ) dut (
        .clk            (clk),
        .nrst           (nrst),
        .weight         (weight),
        .matrix_out     (matrix_out),
        .wr_addr        (wr_addr),
        .wr_data        (wr_data),
        .wr_en          (wr_en),
        .cfg_ifmap_width(cfg_ifmap_width),
        .ctrl_start     (ctrl_start),
        .flag_done      (flag_done),
        .flag_valid     (flag_valid)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    integer weight_file;
    integer scan_result;
    integer i, j;   

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
        
        weight_file = $fopen("../tb/w.txt", "r");
        if (weight_file == 0) begin
            $display("Error: Could not open weights.txt");
            $finish;
        end

        for (i = 0; i < nPEy; i++) begin
            for (j = 0; j < nPEx; j++) begin
                scan_result = $fscanf(weight_file, "%d", weight[i][j]);
                if (scan_result != 1) begin
                    $display("Error reading weight at position [%0d][%0d]", i, j);
                    $finish;
                end
            end
        end
        $fclose(weight_file);

        // Display read weights for verification
        $display("Read weight matrix:");
        for (i = 0; i < nPEy; i++) begin
            for (j = 0; j < nPEx; j++) begin
                $write("%4d ", weight[i][j]);
            end
            $display("");
        end
        

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
        wait(flag_valid);
        $display("Matrix Outputs");
        while(!flag_done) begin
            #(CLK_PERIOD);
            $display("%0d,%0d,%0d", matrix_out[0],matrix_out[1],matrix_out[2]);
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