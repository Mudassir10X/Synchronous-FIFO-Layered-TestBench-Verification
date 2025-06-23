class Empty_Flag_Test #(
    parameter int DEPTH = 8,
    parameter int WIDTH = 8
) extends transaction;
    static int count;

    function void pre_randomize();
        // Disable randomization for w_en and r_en
        r_en.rand_mode(0);
        w_en.rand_mode(0);
        // Start the counting conditions on static variable so that the test can be controlled
        if (count <= 2) begin
            // Write to the FIFO to fill it partially
            w_en = 1;
            r_en = 0;
        end else if (count <= 6) begin
            // Read to make the FIFO empty again and test underflow
            w_en = 0;
            r_en = 1;
        end else begin
            // write again after underflow to check if the empty flag is set to 0
            w_en = 1;
            r_en = 0;
        end
        count++;
    endfunction
endclass //Empty_Flag_Test extends transaction

program test#(
    parameter int DEPTH = 8,
    parameter int WIDTH = 8
)
(
    fifo_interface vif
);
    // repeatition count for the generator
    int repeat_count = 10;

    // Create the environment
    environment #(DEPTH, WIDTH) env = new(vif);

    // Create handle for the extended transaction test
    Empty_Flag_Test#(DEPTH, WIDTH) ex_tr = new();

    initial begin
        // Set the repeat count for the generator
        env.gen.repeat_count = repeat_count;
        env.gen.tr = ex_tr;
        // Run the environment
        env.run();
    end
endprogram