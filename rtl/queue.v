module queue (
    input wire clk,
    input wire nrst,
    input wire enq,
    input wire deq,
    input wire [3:0] din,
    output reg [3:0] dout
);

    reg [3:0] queue_mem [0:3]; // 4x4 queue memory
    reg [1:0] head, tail; // Head and tail pointers
    reg full, empty;

    // Initialize pointers and status flags
    initial begin
        head = 2'b00;
        tail = 2'b00;
        full = 1'b0;
        empty = 1'b1;
        dout = 4'b0000;
    end

    always @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            // Asynchronous reset
            head <= 2'b00;
            tail <= 2'b00;
            full <= 1'b0;
            empty <= 1'b1;
            dout <= 4'b0000;
        end else begin
            if (enq && !full) begin
                // Enqueue operation
                queue_mem[tail] <= din;
                tail <= tail + 1;
                empty <= 1'b0;
                if (tail == 2'b11) full <= 1'b1; // Queue is full after this enqueue
            end else if (deq && !empty) begin
                // Dequeue operation
                dout <= head != 3 ? queue_mem[head] : 0;
                head <= head + 1;
                full <= 1'b0;
                if (head == 2'b11) empty <= 1'b1; // Queue is empty after this dequeue
            end else begin
                dout <= 4'b0000; // Output zero when not dequeuing
            end
        end
    end
endmodule