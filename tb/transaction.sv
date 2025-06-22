class transaction #(
    parameter int DEPTH = 8,
    parameter int WIDTH = 8
);
    rand    logic               w_en, r_en;
    rand    logic [WIDTH-1:0]   data_in;
            logic [WIDTH-1:0]   data_out;
            logic               full, empty;

    // Constructor
    function new();
        // Initialize the transaction properties
        w_en = 0;
        r_en = 0;
        data_in = '0;
        data_out = '0;
        full = 0;
        empty = 0; 
    endfunction // new

    // display the transaction
    function void display(string prefix = "Transaction", int curr_id = -1);
        if (curr_id == -1)
            $display("[%0t][%s]\t: w_en=%0d, r_en=%0d, data_in=%0h, data_out=%0h, full=%0d, empty=%0d", 
                       $time, prefix, w_en, r_en, data_in, data_out, full, empty);
        else
            $display("[%0d][%0t][%s]\t: w_en=%0d, r_en=%0d, data_in=%0h, data_out=%0h, full=%0d, empty=%0d", 
                       curr_id, $time, prefix,  w_en, r_en, data_in, data_out, full, empty);
    endfunction // display

    // copy the transaction
    function transaction#(DEPTH, WIDTH) copy();
        transaction#(DEPTH, WIDTH) tr = new();
        tr.w_en     = this.w_en;
        tr.r_en     = this.r_en;
        tr.data_in  = this.data_in;
        tr.data_out = this.data_out;
        tr.full     = this.full;
        tr.empty    = this.empty;
        return tr;
    endfunction // copy


    // Constraints for randomization
    constraint c_WR {
        // Ensure that one and only one of w_en or r_en is set
        (w_en ^ r_en); 
    }
endclass