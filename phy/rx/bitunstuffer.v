// After six consecutive '1's, stall_downstream is asserted for one clock
// cycle to prevent the downstream module from sampling the stuffed bit,
// allowing it to be discarded transparently. If the expected stuffed bit
// is '1' instead of '0', stuff_error is asserted for one clock cycle as
// an indication that a bit-stuffing error occurred in the current packet.
// Error handling is left to the higher protocol layers.
module bitunstuffer (
    input wire clk, rst_n, data_in, full_speed,
    output reg data_out, 
    output wire stall_downstream
);
    
    reg [2:0] one_count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            one_count <= 3'b000;
            data_out <= full_speed;
        end else begin
            if(one_count == 3'b110) 
                one_count <= 3'b000;
            else if (data_in == 1'b1) begin
                one_count <= one_count + 1'b1;
                data_out <= 1'b1;
            end
            else begin
                one_count <= 3'b000;
                data_out <= 1'b0;
            end
        end
    end

assign stall_downstream = (one_count == 3'b110);
endmodule
