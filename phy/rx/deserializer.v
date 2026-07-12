// After byte_valid is asserted, the next byte deserialization 
//happens in the exact next cycle if sync_detect is asserted.
// byte_valid is asserted till the next byte is ready.
module deserializer (
    input wire clk, rst_n, serial_in, sync_detect, halt,
    output reg [7:0] data_out,
    output byte_valid
);

    reg [2:0] bit_count;
    reg s;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || !sync_detect) begin
            bit_count <= 3'd0;
            s <= 1'b0;
            data_out <= 8'd0;
        end
        else if (!halt && sync_detect) begin
                if (!s) begin
                    data_out[7] <= serial_in;
                    bit_count <= 3'b0;
                    s <= 1'b1;
                end
                else if (s) begin
                    data_out <= {serial_in, data_out[7:1]};
                    bit_count <= bit_count + 1'b1;
                    if (bit_count == 3'b110)
                        s <= 1'b0;  
                end 
        end
    end
    assign byte_valid = (bit_count == 3'b111);
    
endmodule
