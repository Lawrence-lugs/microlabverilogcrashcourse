`timescale 1ns / 1ps

module tpu_top(
    input clk,
    input nrst,
    input [7:0] activation [0:2][0:2],
    input [7:0] weight [0:2][0:2],
    output reg [23:0] matrix_out [0:2][0:2]
    );

reg [7:0] current_activation [2:0];
reg [3:0] state;
integer i,j;

wire [7:0] activation_pass_1_4;
wire [7:0] activation_pass_2_5;
wire [7:0] activation_pass_3_6;

wire [7:0] activation_pass_4_7;
wire [7:0] activation_pass_5_8;
wire [7:0] activation_pass_6_9;

wire [23:0] mac_pass_1_2;
wire [23:0] mac_pass_2_3;
wire [23:0] mac_out_3;
wire [23:0] mac_pass_4_5;
wire [23:0] mac_pass_5_6;
wire [23:0] mac_out_6;
wire [23:0] mac_pass_7_8;
wire [23:0] mac_pass_8_9;
wire [23:0] mac_out_9;

always@(posedge clk) begin
    if(!nrst) begin
        state <= 3'h0;
        for(i=0;i<3;i=i+1) begin
            current_activation[i] <= 8'h0;
            for(j=0;j<3;j=j+1) begin
                matrix_out[i][j] <= 24'h0;
            end
        end
    end else begin
            case(state)
                4'd0: begin
                    current_activation[0] <= activation[0][0];
                    current_activation[1] <= 0;
                    current_activation[2] <= 0;
                    state <= state + 1;
                end
               
                4'd1: begin
                    current_activation[0] <= activation[1][0];
                    current_activation[1] <= activation[0][1];
                    current_activation[2] <= 0;
                    state <= state + 1;
                end
               
                4'd2: begin
                    current_activation[0] <= activation[2][0];
                    current_activation[1] <= activation[1][1];
                    current_activation[2] <= activation[0][2];
                    state <= state + 1;
                end
               
                4'd3: begin
                    current_activation[0] <= 0;
                    current_activation[1] <= activation[2][1];
                    current_activation[2] <= activation[1][2];
                    state <= state + 1;
                end
               
                4'd4: begin
                    current_activation[0] <= 0;
                    current_activation[1] <= 0;
                    current_activation[2] <= activation[2][2];
                    matrix_out[0][0] <= mac_out_3;
                    state <= state + 1;
                end
               
                4'd5: begin
                    current_activation[0] <= 0;
                    current_activation[1] <= 0;
                    current_activation[2] <= 0;
                    matrix_out[1][0] <= mac_out_3;
                    matrix_out[0][1] <= mac_out_6;
                    state <= state + 1;
                end
                
                4'd6: begin
                    matrix_out[2][0] <= mac_out_3;
                    matrix_out[1][1] <= mac_out_6;
                    matrix_out[0][2] <= mac_out_9;
                    state <= state + 1;
                end
                
                4'd7: begin
                    matrix_out[2][1] <= mac_out_6;
                    matrix_out[1][2] <= mac_out_9;
                    state <= state + 1;
                end
                
                4'd8: begin
                    matrix_out[2][2] <= mac_out_9;
                    state <= 0;
                end
               
            endcase
    end
end

pe PE1 (
    .clk(clk),
    .nrst(nrst),
    .activation_in(current_activation[0]),
    .weight(weight[0][0]),
    .mac_in(0),
    .activation_out(activation_pass_1_4),
    .mac_out(mac_pass_1_2)
);

pe PE2 (
    .clk(clk),
    .nrst(nrst),
    .activation_in(current_activation[1]),
    .weight(weight[1][0]),
    .mac_in(mac_pass_1_2),
    .activation_out(activation_pass_2_5),
    .mac_out(mac_pass_2_3)
);

pe PE3(
    .clk(clk),
    .nrst(nrst),
    .activation_in(current_activation[2]),
    .weight(weight[2][0]),
    .mac_in(mac_pass_2_3),
    .activation_out(activation_pass_3_6),
    .mac_out(mac_out_3)
);

pe PE4(
    .clk(clk),
    .nrst(nrst),
    .activation_in(activation_pass_1_4),
    .weight(weight[0][1]),
    .mac_in(0),
    .activation_out(activation_pass_4_7),
    .mac_out(mac_pass_4_5)
);

pe PE5(
    .clk(clk),
    .nrst(nrst),
    .activation_in(activation_pass_2_5),
    .weight(weight[1][1]),
    .mac_in(mac_pass_4_5),
    .activation_out(activation_pass_5_8),
    .mac_out(mac_pass_5_6)
);

pe PE6(
    .clk(clk),
    .nrst(nrst),
    .activation_in(activation_pass_3_6),
    .weight(weight[2][1]),
    .mac_in(mac_pass_5_6),
    .activation_out(activation_pass_6_9),
    .mac_out(mac_out_6)
);

pe PE7(
    .clk(clk),
    .nrst(nrst),
    .activation_in(activation_pass_4_7),
    .weight(weight[0][2]),
    .mac_in(0),
    .activation_out(),
    .mac_out(mac_pass_7_8)
);

pe PE8(
    .clk(clk),
    .nrst(nrst),
    .activation_in(activation_pass_5_8),
    .weight(weight[1][2]),
    .mac_in(mac_pass_7_8),
    .activation_out(),
    .mac_out(mac_pass_8_9)
);

pe PE9(
    .clk(clk),
    .nrst(nrst),
    .activation_in(activation_pass_6_9),
    .weight(weight[2][2]),
    .mac_in(mac_pass_8_9),
    .activation_out(),
    .mac_out(mac_out_9)
);

endmodule
