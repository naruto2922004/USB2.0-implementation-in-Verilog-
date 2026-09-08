module serializer (
    input clk, rst_n, data_valid, halt, high_speed,
    input [7:0] data_byte,
    output reg serial_out, buffer_loaded, serial_valid
 

);
    reg [4:0] sync_count;
    reg [2:0] data_count;
    reg [7:0] buffer;
    reg [1:0] state;
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n || (state == 2'b00)) begin
            serial_out <= 1'b0;
            sync_count <= 5'd0;
            data_count <= 3'd0;
            buffer_loaded <= 1'b0;
            serial_valid <= 1'b0;
            buffer <= 8'd0;
            if(!rst_n)
                state <= 2'b00;
            else if (state == 2'b00)
                state <= data_valid? 2'b01: 2'b00;
        end 
        else if(!halt) begin
            if (state == 2'b01)begin
                serial_valid <= 1'b1;
                if(sync_count == (high_speed ? 5'd31 : 5'd7))begin
                    state <= 2'b10;
                    serial_out <= 1'b1;
                end
                else begin
                    serial_out <= 1'b0;
                    sync_count <= sync_count + 1'b1;
                end
            end
            else if(state == 2'b10)begin
                serial_valid <= 1'b1;
                if (data_count == 3'd0)begin
                    serial_out <= data_byte[0];
                    buffer <= {1'b0, data_byte[7:1]};
                    data_count <= data_count + 1'b1;
                    buffer_loaded <= 1'b1;
                end
                else begin
                    buffer_loaded <= 1'b0;
                    serial_out <= buffer[0];
                    buffer <= {1'b0, buffer[7:1]};
                    if(data_count == 3'd7)begin
                        if(data_valid)
                            data_count <= 3'd0;
                        else begin
                            state <= 2'b00;
                        end
                    end
                    else
                        data_count <= data_count + 1'b1;
                end
            end
            else
                state <= 2'b00;
        end
    end

endmodule
