class Full_Flag_Test #(
    parameter int DEPTH = 8,
    parameter int WIDTH = 8
) extends transaction;
    static int count;

    function void pre_randomize();
        r_en.rand_mode(0);
        w_en.rand_mode(0);
        if (count <= 2) begin
            // Write to the FIFO to fill it up
            w_en = 1;
            r_en = 0;
        end else if (count <= 6) begin
            // Set the empty flag to 0 for subsequent transactions
            w_en = 0;
            r_en = 1;
        end else begin
            // Randomize the transaction normally
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
    int repeat_count = 10;

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