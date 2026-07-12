// When six consecutive '1's have been transmitted, stall_upstream is asserted to
// pause the upstream bit source for one clock cycle. During this pause,
// the bit stuffer inserts the required stuffed '0', then clears the
// consecutive-one counter and deasserts stall_upstream so transmission can resume.
// The upstream module should treat stall_upstream as a clock-enable/stall signal
// and hold the current input bit while stall_upstream is asserted.
module bitstuffer (
    input wire clk, rst_n, data_in, serial_valid_in,
    output reg data_out, serial_valid_out,
    output wire stall_upstream
);
    
    reg [2:0] one_count;

    always @(posedge clk or negedge rst_n) begin
    
        if (!rst_n) begin
            one_count <= 3'b000;
            data_out <= 1'b1;
            serial_valid_out <= 1'b0;
        end 
        else begin 
            serial_valid_out <= serial_valid_in;
            if(serial_valid_in)begin
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
    end


assign stall_upstream = (one_count == 3'b110);
endmodule
