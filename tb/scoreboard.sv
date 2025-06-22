class scoreboard #(
    parameter int DEPTH = 8,
    parameter int WIDTH = 8
);
    // Interface handle
    virtual fifo_interface vif;
    // Mailbox for communication with the monitor
    mailbox mbxms;
    // Class Properties
    transaction#(DEPTH, WIDTH) tr;
    int received_count;
    int err_count = 0; // Error count for mismatches
    // Flags for full and empty states
    bit full, empty;

    // Dummy memory
    logic [WIDTH-1:0] mem[$];
    logic [WIDTH-1:0] data_read;

    // Constructor
    function new(virtual fifo_interface vif, mailbox mbxms);
        // Initialize the interface handle
        this.vif = vif;

        // Initialize the mailbox
        this.mbxms = mbxms;

        // initialize dummy memory
        // mem = new;

        {empty, full} = 2'b10; // Initialize empty and full flags to zero state
    endfunction //new()

    // Run the scoreboard
    task run();
        // Wait for a transaction from the monitor
        forever begin
            if (vif.rst_n == 0) begin
                // If reset is active, wait for it to be deasserted
                $display("[SCOREBOARD]: Reset is active, clearing dummy FIFO.");
                // If reset is active, reset the memory
                repeat (DEPTH) begin
                    if (mem.size() > 0) begin
                        data_read = mem.pop_front();
                    end else begin
                        data_read = '0; // Empty case
                        break; // Exit the loop if memory is empty
                    end
                end
                {empty, full} = 2'b10; // Initialize empty and full flags to reset state
                @(posedge vif.rst_n);
            end else begin
                // Get the transaction from the mailbox
                mbxms.get(tr);
                
                // Display the received transaction
                tr.display("SCOREBOARD");

                // Check the transaction against the dummy memory
                if (tr.r_en) begin
                    // Read operation
                    if (mem.size() > 0) begin
                        data_read = mem.pop_front();
                        if (tr.data_out == data_read)
                            $display("[SCOREBOARD]: Read data matches memory.");
                        else begin
                            $display("[SCOREBOARD]: Read data does not match memory. Expected: %0h, Got: %0h", tr.data_out, data_read);
                            err_count++;
                        end
                    end else begin
                        $display("[SCOREBOARD]: Memory is empty, cannot read data.");
                        tr.data_out = '0; // Empty case
                    end
                end
                if (tr.w_en) begin
                    // Write operation
                    if (mem.size() >= DEPTH) begin
                        $display("[SCOREBOARD]: Memory is full, cannot write data.");
                    end else begin
                        mem.push_back(tr.data_in);
                    end
                end

                // Update the full and empty flags
                full  = (mem.size() == DEPTH);
                empty = (mem.size() == 0);

                if (tr.full != full)
                    $display("[SCOREBOARD]: Full flag mismatch. Expected: %0d, Got: %0d", full, tr.full);
                if (tr.empty != empty)
                    $display("[SCOREBOARD]: Empty flag mismatch. Expected: %0d, Got: %0d", empty, tr.empty);

                // increment the received count
                received_count++;
            end
        end
    endtask //run()
endclass