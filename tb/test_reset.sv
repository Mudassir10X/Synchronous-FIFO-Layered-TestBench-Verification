class reset_Test #(
    parameter int DEPTH = 8,
    parameter int WIDTH = 8
) extends transaction;
    function void pre_randomize();
        // Disable randomization for w_en and r_en
        r_en.rand_mode(0);
        w_en.rand_mode(0);
        // After the reset occurs, reading the FIFO to check the state
        r_en = 1;
        w_en = 0;
    endfunction
endclass //reset_Test extends transaction

program test#(
    parameter int DEPTH = 8,
    parameter int WIDTH = 8
)
(
    fifo_interface vif
);
    // repeatition count for the generator
    int repeat_count = 5;

    // Create the environment
    environment #(DEPTH, WIDTH) env = new(vif);

    // Create handle for the extended transaction test
    reset_Test  #(DEPTH, WIDTH) ex_tr = new();

    initial begin
        // Set the repeat count for the generator
        env.gen.repeat_count = repeat_count;
        env.gen.tr = ex_tr;
        // Run the environment
        env.run();
    end
endprogram