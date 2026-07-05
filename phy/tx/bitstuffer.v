// When six consecutive '1's have been transmitted, stall_upstream is asserted to
// pause the upstream bit source for one clock cycle. During this pause,
// the bit stuffer inserts the required stuffed '0', then clears the
// consecutive-one counter and deasserts stall_upstream so transmission can resume.
// The upstream module should treat stall_upstream as a clock-enable/stall signal
// and hold the current input bit while stall_upstream is asserted.
module bitstuffer (
    input wire clk, rst_n, data_in, full_speed,
    output reg data_out,
    output wire stall_upstream
);
    
    reg [2:0] one_count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            one_count <= 3'b000;
            data_out <= full_speed;
        end else begin
            if(one_count == 3'b110) begin
                one_count <= 3'b000;
                data_out <= 1'b0;
            end
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

assign stall_upstream = (one_count == 3'b110) ? 1'b1 : 1'b0;
endmodule
