/*
* TPU System Module
* 
* This module implements a Tensor Processing Unit (TPU) system that combines:
* - A systolic array processor (tpu_top)
* - A buffer router for managing input activations
* - Systolic buffering logic for proper data timing
* 
* The system takes weights and activations as inputs and produces matrix multiplication
* outputs. It includes configuration parameters for data size, channels, and kernel
* dimensions, along with control signals for operation management.
* 
* Key features:
* - Configurable data sizes and dimensions
* - Built-in systolic buffering for timing alignment
* - Done flag generation for process completion
* - Buffer routing for activation management
* - Parameterized design for flexibility
*/

module tpu_system #(
    parameter dataSize = 8,
    parameter numInChannel = 1,
    parameter kernelWidth = 3,
    parameter numOutChannel = 3,
    parameter numRegister = 256,
    localparam numAddrBuffer = $clog2(numRegister),
    // localparam outputSize = dataSize * 2 + $clog2(numInChannel) + 1,
    localparam outputSize = 24, // to match PE
    localparam nPEy = kernelWidth*kernelWidth,
    localparam nPEx = numOutChannel
) (
    input wire clk,
    input wire nrst,
    input wire [dataSize-1:0] weight [nPEy][nPEx],
    output wire [outputSize-1:0] matrix_out [nPEx],
    
    // Additional ports for buffer_router
    input wire [numAddrBuffer-1:0] wr_addr,
    input wire [numAddrBuffer-1:0] wr_data,
    input wire wr_en,
    input wire [15:0] cfg_ifmap_width,
    input wire ctrl_start,
    output reg flag_done,
    output reg flag_valid
);

// Done logic
wire router_flag_done;
reg [7:0] process_cycle_counter;
reg start_count;

localparam nCyclesToFinish = nPEx + nPEy + 1; // nPEy = systolic buffer delay, nPEx + 1 = systolic cluster delay
wire [15:0] cfg_ofmap_width;
assign cfg_ofmap_width = cfg_ifmap_width - kernelWidth + 1; // Assuming valid convolutions

always @ (posedge clk or negedge nrst) begin
    if(!nrst) begin
        process_cycle_counter <= 0;
        start_count <= 0;
    end else begin
        if (router_flag_done | (process_cycle_counter != 0)) begin
            if (process_cycle_counter == nCyclesToFinish) begin
                process_cycle_counter <= 0;
                $display("PC Counter hit max");
            end else begin
                process_cycle_counter <= process_cycle_counter + 1;
            end
        end
    end
end

always @(*) begin
    if (process_cycle_counter == nCyclesToFinish) begin
        flag_done = 1;
    end else begin
        flag_done = 0;
    end
    if (process_cycle_counter > (nCyclesToFinish - cfg_ofmap_width**2 - 1)) begin
        flag_valid = 1;
    end else begin
        flag_valid = 0;
    end
end

// Internal signals for connecting buffer_router to tpu_top
wire [dataSize-1:0] buffered_activation[nPEy];
wire [dataSize-1:0] tpu_activation_in[nPEy];

// Systolic Buffering
genvar y;
generate
    for (y = 1; y < nPEy; y = y + 1) begin
        delay_chain #(
            .dataSize   (dataSize),
            .nDelay     (y)
        ) u_delay_chain (
            .d      (buffered_activation[y]),
            .q      (tpu_activation_in[y]),
            .clk    (clk),
            .nrst   (nrst)
        );
    end
    assign tpu_activation_in[0] = buffered_activation[0];
endgenerate

logic [outputSize-1:0] matrix_out_unbuffered [nPEx];

genvar x;
generate
    for (x = 0; x < nPEx - 1; x = x + 1) begin
        delay_chain #(
            .dataSize   (outputSize),
            .nDelay     (nPEx - 1 - x)
        ) u_delay_chain (
            .d      (matrix_out_unbuffered[x]),
            .q      (matrix_out[x]),
            .clk    (clk),
            .nrst   (nrst)
        );
    end
    assign matrix_out[nPEx-1] = matrix_out_unbuffered[nPEx-1];
endgenerate

// Buffer Router
buffer_router #(
    .dataSize       (dataSize),
    .numRegister    (numRegister),  // Standard buffer size
    .nElementsOut   (nPEy)  // Matches kernelWidth*kernelWidth
) u_buffer_router (
    .clk            (clk),
    .nrst           (nrst),
    .wr_data        (wr_data),
    .wr_addr        (wr_addr),
    .wr_en          (wr_en),
    .rd_data        (buffered_activation),
    .cfg_ifmap_width(cfg_ifmap_width),
    .ctrl_start     (ctrl_start),
    .flag_done      (router_flag_done)
);

tpu_top #(
    .dataSize       (dataSize),
    .numInChannel   (numInChannel),
    .kernelWidth    (kernelWidth),
    .numOutChannel  (numOutChannel)
) u_tpu (
    .clk            (clk),
    .nrst           (nrst),
    .activation     (tpu_activation_in), 
    .weight         (weight),
    .matrix_out     (matrix_out_unbuffered)
);

endmodule