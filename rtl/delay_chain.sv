module delay_chain #(
    nDelay = 4,
    dataSize = 8
) (
    input clk, nrst,
    input [dataSize-1:0] d,
    output [dataSize-1:0] q
);

reg [nDelay:0][dataSize-1:0] delay_chain;

always @ (posedge clk or negedge nrst) begin
    if(!nrst) begin
        delay_chain <= 0;
    end else begin
        for(int i = 0; i < nDelay-1; i = i + 1) begin
            delay_chain[i] <= delay_chain[i+1]; 
        end
        delay_chain[nDelay-1] <= d;
    end
end
assign q = delay_chain[0];
    
endmodule