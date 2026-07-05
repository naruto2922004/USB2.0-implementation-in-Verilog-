// Reset initializes the encoder to the USB idle (J) state.
// The transmit controller is responsible for asserting reset
// before the start of every new packet, ensuring each packet
// begins from the correct line state.
module nrzi_encoder (
    input wire clk, rst_n, data_in, full_speed,
    output reg line_state
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            line_state <= full_speed ; 
        else begin
            if (data_in == 1'b0)
                line_state <= ~line_state;  
        end
    end
endmodule
