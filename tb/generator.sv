class generator;
    // Class Properties
    transaction tr;
    int         repeat_count;
    int         curr_id;
    event       gdone;
    mailbox     mbxgd;

    
    function new(mailbox mbxgd, event gdone, int repeat_count = 10);
        // Initialize the repeat count
        this.repeat_count = repeat_count;
        this.mbxgd = mbxgd;
        this.gdone = gdone;
        tr = new();
    endfunction //new()

    // Generate a transaction
    task run();
        repeat (repeat_count) begin
            // Generate a random transaction
            if (tr.randomize()) begin
                // Display the generated transaction
                tr.display("Generator", curr_id);
                // Send the transaction to the mailbox
                mbxgd.put(tr.copy());
            end else begin
                $display("Generator: Failed to generate a valid transaction.");
            end
            // Increment the transaction ID
            curr_id++;
        end
        
        // Notify that generation is done
        -> gdone;
    endtask //run()
endclass //generator 