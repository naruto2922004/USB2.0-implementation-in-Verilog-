// CRC engine runs continuously.
// Assert reset before processing each new packet.
// CRC output is valid only immediately after the last valid input bit.

module crc16_engine (
    input rst_n, clk, data_in,
    output reg [15:0]rx
);

reg [15:0] crc16;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        crc16 <= 16'hFFFF;
    else begin
        if(data_in^crc16[15])
            crc16 <= {crc16[14:0], 1'b0} ^ 16'h8005;
        else
            crc16 <= {crc16[14:0], 1'b0};
    end
    rx <= crc16;
end


endmodule
