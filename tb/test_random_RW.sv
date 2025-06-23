class Random_RW_Test #(
    parameter int DEPTH = 8,
    parameter int WIDTH = 8
) extends transaction;
        // Constraint ensure that at least one of w_en or r_en is set so that compute is not wasted on useless transactions
        constraint c_RW {
            (w_en || r_en);
        }
    function void pre_randomize();
        // Disable constraing c_WR
        c_WR.constraint_mode(0);
        
    endfunction
endclass //Random_RW_Test extends transaction

program test#(
    parameter int DEPTH = 8,
    parameter int WIDTH = 8
)
(
    fifo_interface vif
);
    // repeatition count for the generator
    int repeat_count = DEPTH*100;

    // Create the environment
    environment #(DEPTH, WIDTH) env = new(vif);

    // Create handle for the extended transaction test
    Random_RW_Test#(DEPTH, WIDTH) ex_tr = new();

    initial begin
        // Set the repeat count for the generator
        env.gen.repeat_count = repeat_count;
        env.gen.tr = ex_tr;
        // Run the environment
        env.run();
    end
endprogram