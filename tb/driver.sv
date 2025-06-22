`define DRIVER_IF vif.DRIVER.drv_cb
class driver#(
    parameter int DEPTH = 8,
    parameter int WIDTH = 8
);
    // Interface handle
    virtual fifo_interface vif;
    mailbox mbxgd;
    // Class Properties
    transaction#(DEPTH, WIDTH) tr;
    function new(virtual fifo_interface vif, mailbox mbxgd);
        // Initialize the interface handle
        this.vif = vif;
        // Initialize the mailbox
        this.mbxgd = mbxgd;
    endfunction //new()

    // Run the driver
    task run();
        // wait for reset
        wait (vif.DRIVER.rst_n == 1);
        // Wait for a transaction from the generator
        forever begin
            #2; // Small delay to allow for clocking events
            if (vif.DRIVER.rst_n == 0) begin
                // If reset is active, wait for it to be deasserted
                vif.r_en    <= 0;
                vif.w_en    <= 0;
                vif.data_in <= '0;
                $display("[%0t][DRIVER]: Reset is active, waiting for deassertion.", $time);
                // #5;
                @(`DRIVER_IF);
            end else begin
                // Get the transaction from the mailbox
                mbxgd.get(tr); 
                // Display the received transaction
                tr.display("DRIVER");
                // Driving the transaction to the FIFO interface
                vif.w_en    <= tr.w_en;
                vif.r_en    <= tr.r_en;
                vif.data_in <= tr.data_in;
                // Wait for the clocking event
                @(`DRIVER_IF);
            end
        end
    endtask //run()
endclass //driver