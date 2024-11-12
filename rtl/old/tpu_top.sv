`timescale 1ns / 1ps

module tpu_top(
    input clk,
    input nrst,
    input [7:0] activation [0:2][0:2],
    input [7:0] weight [0:2][0:2],
    output reg [23:0] matrix_out [0:2][0:2]
    );

integer i,j; // for the for loop used during reset

always@(posedge clk) begin
    if(!nrst) begin
        // initializing every element of the output matrix to 0
        for(i=0;i<3;i=i+1) begin
            for(j=0;j<3;j=j+1) begin    
                matrix_out[i][j] <= 24'h0;
            end
        end
        // write your other initialization code here
        
    end else begin
        // write your control behavior here
        // this is where you need to sequence the input activation input to the PEs
        
    end
end

// 3x3 PE array instantiation
// You'd have to modify the port connections between the PEs and your control signals

pe PE1 (
    .clk(clk),
    .nrst(nrst),
    .activation_in( ),
    .weight( ),
    .mac_in( ),
    .activation_out( ),
    .mac_out( )
);

pe PE2 (
    .clk(clk),
    .nrst(nrst),
    .activation_in( ),
    .weight( ),
    .mac_in( ),
    .activation_out( ),
    .mac_out( )
);

pe PE3(
    .clk(clk),
    .nrst(nrst),
    .activation_in( ),
    .weight( ),
    .mac_in( ),
    .activation_out( ),
    .mac_out( )
);

pe PE4(
    .clk(clk),
    .nrst(nrst),
    .activation_in( ),
    .weight( ),
    .mac_in( ),
    .activation_out( ),
    .mac_out( )
);

pe PE5(
    .clk(clk),
    .nrst(nrst),
    .activation_in( ),
    .weight( ),
    .mac_in( ),
    .activation_out( ),
    .mac_out( )
);

pe PE6(
    .clk(clk),
    .nrst(nrst),
    .activation_in( ),
    .weight( ),
    .mac_in( ),
    .activation_out( ),
    .mac_out( )
);

pe PE7(
    .clk(clk),
    .nrst(nrst),
    .activation_in( ),
    .weight( ),
    .mac_in( ),
    .activation_out( ),
    .mac_out( )
);

pe PE8(
    .clk(clk),
    .nrst(nrst),
    .activation_in( ),
    .weight( ),
    .mac_in( ),
    .activation_out( ),
    .mac_out( )
);

pe PE9(
    .clk(clk),
    .nrst(nrst),
    .activation_in( ),
    .weight( ),
    .mac_in( ),
    .activation_out( ),
    .mac_out( )
);

endmodule