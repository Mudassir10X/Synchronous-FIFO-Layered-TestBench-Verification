class RAW_Test #(
    parameter int DEPTH = 8,
    parameter int WIDTH = 8
) extends transaction;
    static int count;

    function void pre_randomize();
        // Disable randomization for w_en and r_en
        r_en.rand_mode(0);
        w_en.rand_mode(0);
        // Start the counting conditions on static variable so that the test can be controlled
        if (count % 2 == 0) begin
            // Write first
            w_en = 1;
            r_en = 0;
        end else  begin
            // Then Read to verify contents contents
            w_en = 0;
            r_en = 1;
        end 
        count++;
    endfunction
endclass //RAW_Test extends transaction

program test #(
    parameter int DEPTH = 8,
    parameter int WIDTH = 8
)
(
    fifo_interface vif
);
    // repeatition count for the generator
    int repeat_count = DEPTH*20;

    // Create the environment
    environment #(DEPTH, WIDTH) env = new(vif);

    // Create handle for the extended transaction test
    RAW_Test#(DEPTH, WIDTH) ex_tr = new();

    initial begin
        // Set the repeat count for the generator
        env.gen.repeat_count = repeat_count;
        env.gen.tr = ex_tr;
        // Run the environment
        env.run();
    end
endprogram