// Continuously searches for the USB SYNC pattern while the receiver is in
// the idle state. On successful detection, sync_detected is asserted for
// one clock cycle, indicating the start of a new packet.
module sync_detect (
    input wire clk, rst_n, data_in, high_speed, idle,
    output wire sync_detected
);
    
    reg [4:0] counter;
    reg [1:0] ps, ns;
   always @(posedge clk or negedge rst_n) begin
        if (!rst_n)begin
            counter <= 5'b0;
            ps <= 2'b00;
        end
        else if (idle)begin
            ps <= ns;
            if(ps == 2'b00)
                counter <= (!data_in) ? counter + 1'b1: 5'b0;
        end
   end  

    always @(*) begin
        case (ps)
            2'b00: ns = (high_speed && counter >= 5'd31) ? 2'b01 :(!high_speed && counter >= 5'd7) ? 2'b01 : 2'b00;
            2'b01: ns = (data_in) ? 2'b10 : 2'b00;
            2'b10: ns = 2'b00;
            2'b11: ns = 2'b00;
            default: ns = 2'b00;
        endcase
    end
    assign sync_detected = (ps == 2'b10) ? 1'b1 : 1'b0;
endmodule
