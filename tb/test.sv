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


    initial begin
        // Set the repeat count for the generator
        env.gen.repeat_count = repeat_count;
        
        // Run the environment
        env.run();
    end
endprogram