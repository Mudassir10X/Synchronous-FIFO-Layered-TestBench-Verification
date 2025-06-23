`define MONITOR_IF vif.MONITOR.mon_cb
class monitor;
    // Interface handle
    virtual fifo_interface vif;
    mailbox mbxms;
    // Class Properties
    transaction tr;

    // Constructor
    function new(virtual fifo_interface vif, mailbox mbxms);
        // Initialize the interface handle
        this.vif = vif;
        // Initialize the mailbox
        this.mbxms = mbxms;
        // Create a new transaction object
        tr = new();
    endfunction //new()

    // Run the monitor
    task run();
        // Wait for reset to be deasserted
        wait (vif.MONITOR.rst_n == 1);
        // Wait for a transaction from the driver
        forever begin
            // Wait for the next clocking event
            @(`MONITOR_IF);
            // #1; // Small delay to allow for clocking events
            // Read the FIFO interface signals
            tr.w_en     = `MONITOR_IF.w_en;
            tr.r_en     = `MONITOR_IF.r_en;
            tr.data_in  = `MONITOR_IF.data_in;
            tr.data_out = `MONITOR_IF.data_out;
            tr.full     = `MONITOR_IF.full;
            tr.empty    = `MONITOR_IF.empty;

            // Display the received transaction
            tr.display("MONITOR");
            
            // Send the transaction to the mailbox
            mbxms.put(tr.copy());
            
        end
    endtask //run()
endclass //monitor