module fifo_test #(
    parameter DEPTH = 8,
    parameter WIDTH = 8
) (
    fifo_interface fif,
    output logic clk,
    output logic rst_n
);

    // Local variables
    bit                 err_status    =   0; // Error status flag
    int                 fail_count    =   0; // FAILED tests count
    int                 pass_count    =   0; // PASSED tests count
    logic [WIDTH-1:0]   data_write    =   0; // Data to write to FIFO
    logic [WIDTH-1:0]   data_read     =   0; // Data read from FIFO
    bit                 debug         =   1; // Debug flag to enable/disable debug messages


/////////////////////////////////////////////////Initialization//////////////////////////////////////////////////

    initial begin
        clk         = 0; // Initialize clock
        rst_n       = 1; // Active low reset
        err_status  = 0; // Error status flag
        fif.w_en    = 0; // Write enable
        fif.r_en    = 0; // Read enable
        fif.data_in = '0;// Initialize data input

        forever #5 clk = ~clk; // Clock generation
    end

    // Reset logic for signals being driven
    always @( negedge rst_n ) begin 
        fif.w_en    = 0;   // Deassert write enable on reset
        fif.r_en    = 0;   // Deassert read enable on reset
        err_status  = 0;   // Reset error status
        fif.data_in = '0;  // Reset data input to zero  
    end

///////////////////////////////////////////////READ/WRITE TASKS//////////////////////////////////////////////////

    // Task to write data to FIFO
    task write_FIFO (input logic [WIDTH-1:0] data);
        @(negedge fif.clk);  
        // Write data to FIFO
        fif.data_in = data;
        fif.w_en = 1;
        @(posedge fif.clk);
        #1                  // Avoid Race Condition
        $display("[DEBUG][write_FIFO] Writing data: %0h", data);
        fif.w_en = 0;
    endtask 

    // Task to read data from FIFO
    task read_FIFO (output logic [WIDTH-1:0] data);
        @(negedge fif.clk);
        // Read data from FIFO
        fif.r_en = 1;
        @(posedge fif.clk);
        #1                  // Avoid Race Condition
        data = fif.data_out;
        $display("[DEBUG][read_FIFO] Reading data: %0h", data);
        fif.r_en = 0;
    endtask

    // Task to reset FIFO
    task reset();
        // Assert reset
        @(negedge clk);
        rst_n = 0;
        @(posedge clk);
        // Deassert reset
        rst_n = 1;
    endtask 

    // Task to read and write data to FIFO simultaneously
    task read_write_FIFO(input logic [WIDTH-1:0] write_data, output logic [WIDTH-1:0] read_data);
        fork
            write_FIFO(write_data); // Write data to FIFO
            read_FIFO(read_data); // Read data from FIFO
        join
    endtask
    
    // function to display test_status
    function void display_test_status();
        if (err_status == 0) begin
            $display("TEST PASS.");
        end else begin
            $display("TEST FAIL.");
        end
    endfunction

    // function to display final results
    function void display_final_results();
        $display("Total Tests: %0d", pass_count + fail_count);
        $display("Passed Tests: %0d", pass_count);
        $display("Failed Tests: %0d", fail_count);
        if (fail_count == 0) begin
            $display("All tests passed successfully!");
        end else begin
            $display("Some tests failed.");
        end
    endfunction

//////////////////////////////////////////////////Reset Test/////////////////////////////////////////////////////
    task Reset_Test(input bit dbg, output bit err);
        reset();                        // Reset FIFO        
        if (fif.empty && !fif.full) begin
            err = 0;
            pass_count++;
            if (dbg) $display("[DEBUG][Reset_Test] PASS: FIFO is empty and not full after reset.");
        end else begin
            err = 1;
            fail_count++;
            if (dbg) $display("[DEBUG][Reset_Test] FAIL: FIFO empty=%0b, full=%0b after reset.", fif.empty, fif.full);
            return;
        end
    endtask

//////////////////////////////////////////////Empty Flag Testing/////////////////////////////////////////////////
    task Empty_Flag_Test(input bit dbg, output bit err);
        reset(); // Reset FIFO
        data_write = $random % (1 << WIDTH); // Generate random data
        repeat (DEPTH) write_FIFO(data_write); // Write random data to FIFO
        if (fif.empty) begin
            err = 1;
            fail_count++;
            if (dbg) $display("[DEBUG][Empty_Flag_Test] FAIL: FIFO should not be empty after writes.");
            return;
        end else begin
            err = 0;
            if (dbg) $display("[DEBUG][Empty_Flag_Test] FIFO not empty after writes as expected.");
        end
        repeat (DEPTH) read_FIFO(data_read); // Read data from FIFO
        if (!fif.empty) begin
            err = 1;
            fail_count++;
            if (dbg) $display("[DEBUG][Empty_Flag_Test] FAIL: FIFO should be empty after reads.");
            return;
        end
        pass_count++;
        if (dbg) $display("[DEBUG][Empty_Flag_Test] PASS: FIFO empty after all reads.");
    endtask

//////////////////////////////////////////////////Write Test/////////////////////////////////////////////////////
    task Write_Test(input bit dbg, output bit err);
        reset(); // Reset FIFO
        // Write data to FIFO untill almost full
        repeat (DEPTH-1) begin
            data_write = $random % (1 << WIDTH); // Generate random data
            write_FIFO(data_write);
            if (fif.full || fif.empty) begin
                err = 1;
                fail_count++;
                if (dbg) $display("[DEBUG][Write_Test] FAIL: FIFO full=%0b, empty=%0b during write.", fif.full, fif.empty);
                return;
            end
            if (dbg) $display("[DEBUG][Write_Test] Wrote data: %0h, FIFO full=%0b, empty=%0b", data_write, fif.full, fif.empty);
        end
        err = 0;
        pass_count++;
        if (dbg) $display("[DEBUG][Write_Test] PASS: FIFO handled writes correctly.");
    endtask

//////////////////////////////////////////////////Full Flag//////////////////////////////////////////////////////
    task Full_Flag_Test(input bit dbg, output bit err);
        reset(); // Reset FIFO
        // Write data to FIFO until full
        repeat (DEPTH-1) begin
            data_write = $random % (1 << WIDTH); // Generate random data
            write_FIFO(data_write);
            if (fif.full) begin
                err = 1;
                fail_count++;
                if (dbg) $display("[DEBUG][Full_Flag_Test] FAIL: FIFO full before expected.");
                return;
            end
            if (dbg) $display("[DEBUG][Full_Flag_Test] Wrote data: %0h, FIFO full=%0b", data_write, fif.full);
        end
        // Try to write one more data to check full condition
        data_write = $random % (1 << WIDTH); // Generate random data
        write_FIFO(data_write);
        if (!fif.full) begin
            err = 1;
            fail_count++;
            if (dbg) $display("[DEBUG][Full_Flag_Test] FAIL: FIFO not full after expected number of writes.");
            return;
        end
        if (dbg) $display("[DEBUG][Full_Flag_Test] FIFO full after expected writes.");

        // Read a few values to make it partially filled
        repeat (2) begin
            read_FIFO(data_read);
            if (fif.full) begin
                err = 1;
                fail_count++;
                if (dbg) $display("[DEBUG][Full_Flag_Test] FAIL: FIFO still full after read.");
                return;
            end
            if (dbg) $display("[DEBUG][Full_Flag_Test] Read data: %0h, FIFO full=%0b", data_read, fif.full);
        end
        repeat(2) begin// Write again to check if FIFO is still full
            data_write = $random % (1 << WIDTH); // Generate random data
            write_FIFO(data_write);
        end
        if (!fif.full) begin
            err = 1;
            fail_count++;
            if (dbg) $display("[DEBUG][Full_Flag_Test] FAIL: FIFO not full after refill.");
            return;
        end
        if (dbg) $display("[DEBUG][Full_Flag_Test] FIFO full after refill.");
        err = 0;
        pass_count++;
        if (dbg) $display("[DEBUG][Full_Flag_Test] PASS: FIFO full flag behavior correct.");
    endtask

//////////////////////////////////////////////////READ TEST//////////////////////////////////////////////////////
    task Read_Test(input bit dbg, output bit err);
        reset(); // Reset FIFO
        // Write data to FIFO untill full
        repeat (DEPTH) begin
            data_write = $random % (1 << WIDTH); // Generate random data
            write_FIFO(data_write);
            if (dbg) $display("[DEBUG][Read_Test] Wrote data: %0h", data_write);
        end
        read_FIFO(data_read);
        if (fif.full || fif.empty) begin
            err = 1;
            fail_count++;
            if (dbg) $display("[DEBUG][Read_Test] FAIL: FIFO full=%0b, empty=%0b after first read.", fif.full, fif.empty);
            return;
        end
        repeat (DEPTH-1) begin
            read_FIFO(data_read);
            if (dbg) $display("[DEBUG][Read_Test] Read data: %0h", data_read);
        end
        if (fif.full || !fif.empty) begin
            err = 1;
            fail_count++;
            if (dbg) $display("[DEBUG][Read_Test] FAIL: FIFO full=%0b, empty=%0b after all reads.", fif.full, fif.empty);
            return;
        end
        err = 0;    
        pass_count++;    
        if (dbg) $display("[DEBUG][Read_Test] PASS: FIFO handled reads correctly.");
    endtask

////////////////////////////////////////////Read after Write Test////////////////////////////////////////////////
    task Read_After_Write_Test(input bit dbg, output bit err);
        reset(); // Reset FIFO
        // Write data to FIFO and then read the same data
        repeat (DEPTH) begin
            data_write = $random % (1 << WIDTH); // Generate random data
            write_FIFO(data_write);
            read_FIFO(data_read);
            if (dbg) $display("[DEBUG][Read_After_Write_Test] Wrote: %0h, Read: %0h", data_write, data_read);
            if (data_read != data_write) begin
                err = 1;
                fail_count++;
                if (dbg) $display("[DEBUG][Read_After_Write_Test] FAIL: Data mismatch.");
                return;
            end
        end
        err = 0;    
        pass_count++;    
        if (dbg) $display("[DEBUG][Read_After_Write_Test] PASS: Read after write matched for all.");
    endtask

//////////////////////////////////////////Write on FULL FIFO Test////////////////////////////////////////////////
    task Write_On_Full_Test(input bit dbg, output bit err);
        reset(); // Reset FIFO
        // Fill FIFO to full
        repeat (DEPTH+1) begin
            data_write = $random % (1 << WIDTH); // Generate random data
            write_FIFO(data_write);
            if (dbg) $display("[DEBUG][Write_On_Full_Test] Wrote data: %0h", data_write);
        end
        repeat (DEPTH+1) read_FIFO(data_read); // Read all data from FIFO and an additional read to check if the extra witten data is ignored
        
        if (data_read != 0) begin
            err = 1; // If the data read is same as written, it means FIFO did not ignore the write
            fail_count++;
            if (dbg) $display("[DEBUG][Write_On_Full_Test] FAIL: FIFO did not ignore write on full.");
            return;
        end
        err = 0; // If the data read is different, write_FIFO ignored the write correctly
        pass_count++;
        if (dbg) $display("[DEBUG][Write_On_Full_Test] PASS: FIFO ignored write on full as expected.");
    endtask

/////////////////////////////////////////Read from EMPTY FIFO Test///////////////////////////////////////////////
    task Read_From_Empty_Test(input bit dbg, output bit err);
        reset(); // Reset FIFO
        read_FIFO(data_read); // Try to read from empty FIFO
        if (dbg) $display("[DEBUG][Read_From_Empty_Test] Read from empty FIFO: %0h, empty=%0b", data_read, fif.empty);
        if (!fif.empty) begin
            err = 1; // If FIFO is not empty, it means read was successful which is incorrect
            fail_count++;
            if (dbg) $display("[DEBUG][Read_From_Empty_Test] FAIL: FIFO not empty after read from empty.");
            return;
        end
        data_write = $random % (1 << WIDTH); // Generate random data
        write_FIFO(data_write); // Write data to FIFO
        read_FIFO(data_read); // Read data from FIFO
        if (dbg) $display("[DEBUG][Read_From_Empty_Test] Wrote: %0h, Read: %0h", data_write, data_read);
        if (data_read != data_write) begin
            err = 1; // If the data read is not same as written, it means FIFO did not ignore the read
            fail_count++;
            if (dbg) $display("[DEBUG][Read_From_Empty_Test] FAIL: Data mismatch after write/read.");
            return;
        end
        err = 0; // If FIFO is empty, read was ignored correctly
        pass_count++;
        if (dbg) $display("[DEBUG][Read_From_Empty_Test] PASS: FIFO handled empty read and subsequent write/read correctly.");
    endtask

////////////////////////////////////Simultaneous Read/Write on Empty FIFO////////////////////////////////////////
    task Simultaneous_Read_Write_Empty_Test(input bit dbg, output bit err);
        reset(); // Reset FIFO
        data_write = $random % (1 << WIDTH); // Generate random data
        read_write_FIFO(data_write, data_read); // Simultaneous read/write on empty FIFO
        if (dbg) $display("[DEBUG][Simultaneous_Read_Write_Empty_Test] Wrote: %0h, Read: %0h, empty=%0b, full=%0b", data_write, data_read, fif.empty, fif.full);
        if (fif.empty || fif.full || data_read != 8'h00) begin
            err = 1; // If FIFO is not empty or full, or data read is not zero, it means simultaneous read/write failed
            fail_count++;
            if (dbg) $display("[DEBUG][Simultaneous_Read_Write_Empty_Test] FAIL: Unexpected FIFO state or data.");
            return;
        end
        err = 0; // If FIFO is empty and data read is zero, simultaneous read/write passed
        pass_count++;
        if (dbg) $display("[DEBUG][Simultaneous_Read_Write_Empty_Test] PASS: FIFO handled simultaneous read/write on empty correctly.");
    endtask

//////////////////////////////Simultaneous Read/Write on Partially filled FIFO///////////////////////////////////
    task Simultaneous_Read_Write_Partial_Test(input bit dbg, output bit err);
        bit [WIDTH-1:0] data_write_buff [DEPTH]; // last data buffer 
        reset(); // Reset FIFO
        // Fill FIFO partially
        foreach (data_write_buff[i]) begin
            data_write = $random % (1 << WIDTH); // Generate random data
            write_FIFO(data_write);
            data_write_buff[i] = data_write; // Store written data
            if (dbg) $display("[DEBUG][Simultaneous_Read_Write_Partial_Test] Fill: Wrote %0h at %0d", data_write, i);
            if (i == (DEPTH/2)-1) begin
                break; // Stop filling FIFO after half
            end
        end

        foreach (data_write_buff[i]) begin
            data_write = $random % (1 << WIDTH); // Generate random data
            data_write_buff[i+(DEPTH/2)] = data_write; // Store written data
            read_write_FIFO(data_write, data_read); // Simultaneous read/write on partially filled FIFO
            if (dbg) $display("[DEBUG][Simultaneous_Read_Write_Partial_Test] Simul: Wrote %0h, Read %0h, empty=%0b, full=%0b", data_write, data_read, fif.empty, fif.full);
            if ((fif.empty || fif.full) && (data_write_buff[i] != data_read)) begin
                err = 1; // If FIFO is empty or full, or data read is not the last written data, it means simultaneous read/write failed
                fail_count++;
                if (dbg) $display("[DEBUG][Simultaneous_Read_Write_Partial_Test] FAIL: Unexpected FIFO state or data mismatch.");
                return;
            end
            if (i == (DEPTH/2)-1) begin
                break; // Stop after half
            end
        end
        foreach (data_write_buff[i]) begin
            read_FIFO(data_read); // Read data from FIFO
            if (data_write_buff[i+(DEPTH/2)] != data_read) begin
                err = 1; 
                fail_count++;
                if (dbg) $display("[DEBUG][Simultaneous_Read_Write_Partial_Test] FAIL: Data mismatch after simultaneous read/write.");
                return;
            end
            if (i == (DEPTH/2)-1) begin
                break; // Stop after other half
            end
        end
        err = 0; // If FIFO is not empty or full, and data read is not zero, simultaneous read/write passed
        pass_count++;
        if (dbg) $display("[DEBUG][Simultaneous_Read_Write_Partial_Test] PASS: FIFO handled simultaneous read/write on partial fill correctly.");
    endtask

///////////////////////////////////Simultaneous Read/Write on Full FIFO//////////////////////////////////////////
    task Simultaneous_Read_Write_Full_Test(input bit dbg, output bit err);
        logic [WIDTH-1:0] data_write_buff [DEPTH*2]; // last data buffer
        reset(); // Reset FIFO
        // Fill FIFO to full    
        foreach (data_write_buff[i]) begin
            data_write = $random % (1 << WIDTH); // Generate random data
            write_FIFO(data_write);
            data_write_buff[i] = data_write; // Store written data
            if (dbg) $display("[DEBUG][Simultaneous_Read_Write_Full_Test] Fill: Wrote %0h at %0d", data_write, i);
            if (i == DEPTH-1) begin
                break; // Stop filling FIFO when full
            end
        end
        // Simultaneous read/write on full FIFO
        foreach (data_write_buff[i]) begin
            data_write = $random % (1 << WIDTH); // Generate random data
            data_write_buff[i+DEPTH] = data_write; // Store written data
            read_write_FIFO(data_write, data_read); // Simultaneous read/write on full FIFO
            if (dbg) $display("[DEBUG][Simultaneous_Read_Write_Full_Test] Simul: Wrote %0h, Read %0h, full=%0b", data_write, data_read, fif.full);
            if (!fif.full || (data_read != data_write_buff[i])) begin
                err = 1; // If FIFO is not full or data read is not the last written data, it means simultaneous read/write failed
                fail_count++;
                if (dbg) $display("[DEBUG][Simultaneous_Read_Write_Full_Test] FAIL: FIFO not full or data mismatch.");
                return;
            end
            if (i == DEPTH-1) begin
                break; // Stop after DEPTH
            end
        end
        foreach (data_write_buff[i]) begin
            read_FIFO(data_read); // Read data from FIFO
            if (data_write_buff[i+DEPTH] != data_read) begin
                err = 1; 
                fail_count++;
                if (dbg) $display("[DEBUG][Simultaneous_Read_Write_Full_Test] FAIL: Data mismatch after simultaneous read/write.");
                return;
            end
            if (i == DEPTH-1) begin
                break; // Stop after DEPTH
            end
        end
        err = 0;
        pass_count++;
        if (dbg) $display("[DEBUG][Simultaneous_Read_Write_Full_Test] PASS: FIFO handled simultaneous read/write on full correctly.");
    endtask


///////////////////////////////////////////Random Read Write Test////////////////////////////////////////////////
    task Random_Read_Write_Test(input bit dbg, output bit err);
        logic [WIDTH-1:0] dummy_FIFO [$]; // Dummy FIFO to store data
        logic [WIDTH-1:0] dummy_read; // Dummy read data
        reset(); // Reset FIFO
        // Randomly write and read data from FIFO
        repeat (100) begin
            if ($random % 2) begin // Randomly decide to write or read
                data_write = $random % (1 << WIDTH); // Generate random data
                write_FIFO(data_write);
                if (dummy_FIFO.size() < DEPTH) dummy_FIFO.push_back(data_write); // Store written data in dummy FIFO
                if (dbg) $display("[DEBUG][Random_Read_Write_Test] Wrote: %0h", data_write);
            end else begin
                read_FIFO(data_read);
                if (dummy_FIFO.size()) dummy_read = dummy_FIFO.pop_front(); // Remove the first element from dummy FIFO
                if (data_read != dummy_read) begin
                    err = 1; // If data read is not same as dummy read, it means FIFO did not handle read correctly
                    fail_count++;
                    if (dbg) $display("[DEBUG][Random_Read_Write_Test] FAIL: Data mismatch. Expected: %0h, Read: %0h", dummy_read, data_read);
                    return;
                end
                if (dbg) $display("[DEBUG][Random_Read_Write_Test] Read: %0h", data_read);
            end
            // Check FIFO status
            if (fif.empty ^ dummy_FIFO.size() == 0) begin
                err = 1; // If either FIFO is empty but other FIFO has data, it means FIFO did not handle empty correctly
                fail_count++;
                if (dbg) $display("[DEBUG][Random_Read_Write_Test] FAIL: FIFO empty flag state unexpected.");
                return;
            end
            if (fif.full ^ dummy_FIFO.size() == DEPTH) begin
                err = 1; // If either FIFO is full but other FIFO does not have data, it means FIFO did not handle full correctly
                fail_count++;
                if (dbg) $display("[DEBUG][Random_Read_Write_Test] FAIL: FIFO full flag state unexpected.");
                return;
            end
        end
        err = 0; // If no errors occurred, test passed
        pass_count++;
        if (dbg) $display("[DEBUG][Random_Read_Write_Test] PASS: Random read/write test completed successfully.");
    endtask

////////////////////////////////////////////Testbench Execution//////////////////////////////////////////////////

    initial begin 
        $display("Starting FIFO Testbench");

        $display("Start Reset Test");
        Reset_Test(debug, err_status);
        display_test_status();

        $display("Start Empty Flag Test");
        Empty_Flag_Test(debug, err_status);
        display_test_status();

        $display("Start Write Test");
        Write_Test(debug, err_status);
        display_test_status();

        $display("Start Read Test");
        Read_Test(debug, err_status);
        display_test_status();

        $display("Start Full Flag Test");
        Full_Flag_Test(debug, err_status);
        display_test_status();

        $display("Start Read After Write Test");
        Read_After_Write_Test(debug, err_status);
        display_test_status();

        $display("Start Write on Full FIFO Test");
        Write_On_Full_Test(debug, err_status);
        display_test_status();

        $display("Start Read from Empty FIFO Test");
        Read_From_Empty_Test(debug, err_status);
        display_test_status();

        $display("Start Simultaneous Read/Write on Empty FIFO Test");
        Simultaneous_Read_Write_Empty_Test(debug, err_status);
        display_test_status();

        $display("Start Simultaneous Read/Write on Partially filled FIFO Test");
        Simultaneous_Read_Write_Partial_Test(debug, err_status);
        display_test_status();

        $display("Start Simultaneous Read/Write on Full FIFO Test");
        Simultaneous_Read_Write_Full_Test(debug, err_status);
        display_test_status();

        $display("Start Random Read/Write Test");
        Random_Read_Write_Test(debug, err_status);
        display_test_status();

        $display("All tests completed.");

        display_final_results();

        $finish;
    end

endmodule