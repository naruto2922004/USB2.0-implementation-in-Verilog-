// CRC engine runs continuously.
// Assert reset before processing each new packet.
// CRC output is valid only immediately after the last valid input bit.
`include "../usb_pkg.vh"
module crc5_engine (
    input rst_n, clk, data_in,
    output reg [4:0]rx
);

reg [4:0] crc5;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        crc5 <= USB_CRC5_INIT;
    else begin
        if(data_in^crc5[4])
            crc5 <= {crc5[3:0], 1'b0} ^ USB_CRC5_POLY;
        else
            crc5 <= {crc5[3:0], 1'b0};
    end
    rx <= crc5;
end

endmodule
