class environment #(
    parameter int DEPTH = 8,
    parameter int WIDTH = 8
);
    // Interface handle
    virtual fifo_interface vif;
    
    // Mailbox for communication between components
    mailbox mbxgd, mbxms;
    
    // Event for signaling completion
    event gdone;

    // Class Properties
    generator   #(DEPTH, WIDTH) gen;
    driver      #(DEPTH, WIDTH) drv;
    monitor     #(DEPTH, WIDTH) mon;
    scoreboard  #(DEPTH, WIDTH) sb;

    // Constructor
    function new(virtual fifo_interface vif);
        // Create the mailbox for generator and monitor
        mbxgd = new();
        mbxms = new();

        // Create the components
        gen = new(mbxgd, gdone);
        drv = new(vif, mbxgd);
        mon = new(vif, mbxms);
        sb  = new(vif, mbxms);
    endfunction //new()

    // Test
    task test();
        // Start the components
        fork
            gen.run();
            drv.run();
            mon.run();
            sb.run();
        join_any
    endtask //test()

    // Post Test
    task post_test();
        // Wait for the generator to finish
        wait (gdone.triggered);

        // Wait for the scoreboard to receive all transactions
        wait (sb.received_count == gen.repeat_count);
        
        // Display the final state of the scoreboard
        $display("Post Test: All transactions received by the scoreboard.");
        $display("Errors:\t%0d", sb.err_count);
        $display("Final Memory State:\t%p", sb.mem);
    endtask //post_test()

    // Run the environment
    task run();
        // Start the test
        test();
        // Start the post-test as soon as the test is done as it has wait conditions for the test to finish
        post_test();
    endtask //run()
endclass //environment