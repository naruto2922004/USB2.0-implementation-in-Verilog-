//00 = K
//01 = J
//10 = SE0
//11 = SE1 (never driven)
module diff_tx_driver (
    input [1:0] line_state, 
    input full_speed,
    output reg dp, dm 
);
    always@(*) begin
        case (line_state)
            2'b00: {dp, dm} = full_speed ? 2'b01 : 2'b10; // K
            2'b01: {dp, dm} = full_speed ? 2'b10 : 2'b01; // J
            2'b10: {dp, dm} = 2'b00; // SE0
            default: {dp, dm} = 2'b11; // SE1 (never driven)
        endcase
    end

endmodule

