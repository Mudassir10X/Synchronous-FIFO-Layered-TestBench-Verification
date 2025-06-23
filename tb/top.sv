// Include the neccessary test
// `include "test.sv"  
// `include "test_reset.sv"
// `include "test_empty_flag.sv"  
// `include "test_full_flag.sv"
// `include "test_simultaneous_RW.sv"
// `include "test_basic_RW.sv"
`include "test_RAW.sv"

module top ();
    localparam  WIDTH = 8;
    localparam  DEPTH = 8;
    bit         clk;
    bit         rst_n=1;
    
    //  Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 time units clock period
    end

    // //  Reset Generation
    initial begin
        rst_n = 0; // Assert reset
        #10; // Hold reset for 20 time units
        rst_n = 1; // Release reset
    end

    //  Instantiating FIFO Interface
    fifo_interface #(DEPTH, WIDTH) fifo_if (
        .clk(clk),
        .rst_n(rst_n)
    );

    //  Instantiating FIFO Module
    synchronous_fifo #(DEPTH, WIDTH) FIFO (
        .clk(fifo_if.clk),
        .rst_n(fifo_if.rst_n),
        .w_en(fifo_if.w_en),
        .r_en(fifo_if.r_en),
        .data_in(fifo_if.data_in),
        .data_out(fifo_if.data_out),
        .full(fifo_if.full),
        .empty(fifo_if.empty)
    );

    // Below are layered and simple testbenches instantiations for FIFO testbenches. Comment and uncomment as reqired.

    // Layered TestBench for FIFO
    test #(DEPTH, WIDTH) fifo_test (
        .vif(fifo_if)
    );

    // `include "fifo_test.sv"
    // // Simple TestBench and tests for FIFO
    // fifo_test #(DEPTH, WIDTH) fifo_test (
    //     .vif(fifo_if)
    // );

endmodule