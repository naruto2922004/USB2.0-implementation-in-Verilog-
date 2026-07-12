// sync_detected is asserted for the entire length of the packet
module sync_detect (
    input wire clk, rst_n, data_in, high_speed, SE0_detected,
    output wire sync_detected
);
    
    reg [4:0] counter;
    reg [1:0] ps, ns;
   always @(posedge clk or negedge rst_n) begin
        if (!rst_n || SE0_detected)begin
            counter <= 5'b0;
            ps <= 2'b00;
        end
        else begin
            ps <= ns;
            if(ps == 2'b00)
                counter <= (!data_in) ? counter + 1'b1: 5'b0;
            else
                counter <= 5'b0;
        end
   end  

    always @(*) begin
        case (ps)
            2'b00: ns = (high_speed && counter >= 5'd30 && !data_in) ? 2'b01 :(!high_speed && counter >= 5'd6 && !data_in) ? 2'b01 : 2'b00;
            2'b01: ns = (data_in) ? 2'b10 : 2'b00;
            2'b10: ns = SE0_detected ? 2'b00 : 2'b10;
            default: ns = 2'b00;
        endcase
    end
    assign sync_detected = (ps == 2'b10);
endmodule
