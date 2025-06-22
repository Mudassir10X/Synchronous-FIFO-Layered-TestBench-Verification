class Simultaneous_RW_Test #(
    parameter int DEPTH = 8,
    parameter int WIDTH = 8
) extends transaction;
    static int count;

    function void pre_randomize();
        r_en.rand_mode(0);
        w_en.rand_mode(0);
        c_WR.constraint_mode(0);
        if (count < DEPTH/2) begin
            // Write to the FIFO to make it partially filled
            w_en = 1;
            r_en = 0;
        end else if (count < DEPTH+(DEPTH/2)) begin
            // Simultaneously Read and write from the FIFO 
            w_en = 1;
            r_en = 1;
        end else begin
            // Read to make it empty again
            w_en = 0;
            r_en = 1;
        end
        count++;
    endfunction
endclass //Simultaneous_RW_Test extends transaction

program test#(
    parameter int DEPTH = 8,
    parameter int WIDTH = 8
)
(
    fifo_interface vif
);
    // repeatition count for the generator
    int repeat_count = DEPTH*2;

    // Create the environment
    environment #(DEPTH, WIDTH) env = new(vif);

    // Create handle for the extended transaction test
    Simultaneous_RW_Test#(DEPTH, WIDTH) ex_tr = new();

    initial begin
        // Set the repeat count for the generator
        env.gen.repeat_count = repeat_count;
        env.gen.tr = ex_tr;
        // Run the environment
        env.run();
    end
endprogram