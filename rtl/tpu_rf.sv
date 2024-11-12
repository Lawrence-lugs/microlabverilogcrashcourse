`timescale 1ns / 1ps

module tpu_top #(
    parameter dataSize = 8,
    parameter numInChannel = 1,
    parameter kernelWidth = 3,
    parameter numOutChannel = 3,
    // localparam outputSize = dataSize * 2 + $clog2(numInChannel) + 1,
    localparam outputSize = 24, // For compatibility with existing PE
    localparam nPEy = kernelWidth*kernelWidth,
    localparam nPEx = numOutChannel
) (
    input clk,
    input nrst,
    input [dataSize-1:0] activation [0:nPEy-1],
    input [dataSize-1:0] weight [0:nPEy-1][0:nPEx-1],
    output reg [outputSize-1:0] matrix_out [0:numOutChannel-1]
);

reg [dataSize-1:0] current_activation [0:nPEy-1];

always@(posedge clk) begin
    if(!nrst) begin
        for(int i=0;i<kernelWidth;i=i+1) begin
            current_activation[i] <= {dataSize{1'b0}};
        end
    end else begin
        current_activation <= activation; 
    end
end

logic [dataSize-1:0] activation_pass [0:nPEx][0:nPEy-1];  // For passing activations to next row
logic [outputSize-1:0] mac_pass        [0:nPEx-1][0:nPEy];         // For passing MAC results within row

genvar i, j;
generate
    for (i = 0; i < nPEx; i++) begin : xpos
        for (j = 0; j < nPEy; j++) begin : ypos
            pe PE (
                .clk            (clk),
                .nrst           (nrst),
                .activation_in  (activation_pass[i][j]),
                .weight         (weight[j][i]), 
                .mac_in         (mac_pass[i][j]),
                .activation_out (activation_pass[i+1][j]),
                .mac_out        (mac_pass[i][j+1])
            );
        end
    end

    for (j = 0; j < nPEy; j++) begin
        assign activation_pass[0][j] = current_activation[j];
    end

    for (i = 0; i < nPEx; i++) begin
        assign matrix_out[i] = mac_pass[i][nPEy];
        assign mac_pass[i][0] = 0;
    end

endgenerate

endmodule
