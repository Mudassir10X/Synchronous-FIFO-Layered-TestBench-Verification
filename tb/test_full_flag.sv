class Full_Flag_Test #(
    parameter int DEPTH = 8,
    parameter int WIDTH = 8
) extends transaction;
    static int count;

    function void pre_randomize();
        // Disable randomization for w_en and r_en
        r_en.rand_mode(0);
        w_en.rand_mode(0);
        // Start the counting conditions on static variable so that the test can be controlled
        if (count <= DEPTH) begin
            // Write to the FIFO to make it full and cause overflow
            w_en = 1;
            r_en = 0;
        end else if (count <= DEPTH+2) begin
            // Read it to make it partially filled
            w_en = 0;
            r_en = 1;
        end else begin
            // write again to make it full
            w_en = 1;
            r_en = 0;
        end
        count++;
    endfunction
endclass //Full_Flag_Test extends transaction

program test#(
    parameter int DEPTH = 8,
    parameter int WIDTH = 8
)
(
    fifo_interface vif
);
    // repeatition count for the generator
    int repeat_count = DEPTH+5;

    // Create the environment
    environment #(DEPTH, WIDTH) env = new(vif);

    // Create handle for the extended transaction test
    Full_Flag_Test#(DEPTH, WIDTH) ex_tr = new();

    initial begin
        // Set the repeat count for the generator
        env.gen.repeat_count = repeat_count;
        env.gen.tr = ex_tr;
        // Run the environment
        env.run();
    end
endprogram