// CRC engine runs continuously.
// Assert reset before processing each new packet.
// CRC output is valid only immediately after the last valid input bit.
`include "../usb_pkg.vh"

module crc16_engine (
    input rst_n, clk, data_in,
    output reg [15:0]rx
);

reg [15:0] crc16;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        crc16 <= USB_CRC16_INIT;
    else begin
        if(data_in^crc16[15])
            crc16 <= {crc16[14:0], 1'b0} ^ USB_CRC16_POLY;
        else
            crc16 <= {crc16[14:0], 1'b0};
    end
end
assign rx = crc16;

endmodule
