module eop_gen (
    input clk, rst_n, eop,
    output reg [1:0] line_state,
    output reg done
);
    reg [1:0] bit_count;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            line_state <= 2'b01;
            done <= 1'b0;
            bit_count <= 2'b00;
        end 
        else if(eop) begin
            if (bit_count != 2'd3)begin
                line_state <= 2'b10;
                bit_count <= bit_count + 1'b1;
            end
            else begin
                line_state <= 2'b01;
                done <= 1'b1;
                bit_count <= 2'b00;
            end
        end
    end
    endmodule
