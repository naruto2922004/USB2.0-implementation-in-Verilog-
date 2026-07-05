// Reset initializes the previous line state to the USB idle (J) state.
module nrzi_decoder (
    input wire clk, rst_n, line_state, full_speed,
    output reg data_out
);
    reg prev_line_state;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)begin
            prev_line_state <= full_speed;
            data_out <= full_speed;
        end
        else begin
            prev_line_state <= line_state;
            if (prev_line_state != line_state)
                data_out <= 1'b0;  
            else
                data_out <= 1'b1;
        end
    end
endmodule
