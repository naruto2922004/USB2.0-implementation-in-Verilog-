`timescale 1ns/1ps

module tx_tb;

    //------------------------------------------------------------
    // Inputs
    //------------------------------------------------------------
    reg clk;
    reg rst_n;

    reg transfering;
    reg [7:0] data;
    reg [1:0] speed;

    //------------------------------------------------------------
    // Outputs
    //------------------------------------------------------------
    wire packet_done;
    wire buffer_loaded;
    wire dp;
    wire dm;

    //------------------------------------------------------------
    // DUT
    //------------------------------------------------------------
    tx dut (
        .clk(clk),
        .rst_n(rst_n),
        .transfering(transfering),
        .data(data),
        .speed(speed),
        .packet_done(packet_done),
        .buffer_loaded(buffer_loaded),
        .dp(dp),
        .dm(dm)
    );

    initial
        clk = 1'b0;

    always
        #10 clk = ~clk;

    initial begin

        rst_n       = 0;
        transfering = 0;
        data        = 8'h00;
        speed       = 2'b01;      // Full Speed

        repeat(3)
            @(posedge clk);

        rst_n = 1;

        @(posedge clk);

        transfering = 1;
        data = 8'h12; // 00010010

        while (!buffer_loaded)
            @(posedge clk);

        @(posedge clk);
        data = 8'h34; // 00110100

        while (!buffer_loaded)
            @(posedge clk);

        @(posedge clk);
        data = 8'h56; // 01010110

        while (!buffer_loaded)
            @(posedge clk);

        @(posedge clk);
        transfering = 0;
        data = 8'h00;

        while (!packet_done)
            @(posedge clk);

        repeat(5)
            @(posedge clk);

        
        //---------------------------------------------------------
        
        
        @(posedge clk);

        transfering = 1;
        data = 8'h12; // 00010010

        while (!buffer_loaded)
            @(posedge clk);

        @(posedge clk);
        data = 8'h34; // 00110100

        while (!buffer_loaded)
            @(posedge clk);

        @(posedge clk);
        data = 8'h56; // 01010110

        while (!buffer_loaded)
            @(posedge clk);

        @(posedge clk);
        transfering = 0;
        data = 8'h00;

        while (!packet_done)
            @(posedge clk);

        repeat(5)
            @(posedge clk);

        $stop;
    end

endmodule