`timescale 1ns / 1ps

module pe(
    input clk,
    input nrst,
    input [7:0] activation_in,
    input [7:0] weight,
    input [23:0] mac_in,
    output reg [7:0] activation_out,
    output reg [23:0] mac_out
    );
   
always@(posedge clk) begin
    if (!nrst) begin
        mac_out <= 24'h0;
        activation_out <= 8'h0;
    end else begin
        mac_out <= $signed(mac_in) + $signed(activation_in)*$signed(weight);
        activation_out <= activation_in;
    end
end

endmodule
