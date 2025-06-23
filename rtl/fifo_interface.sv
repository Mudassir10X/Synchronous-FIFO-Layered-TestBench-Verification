interface fifo_interface #(parameter DEPTH=8, WIDTH=8) (
input logic clk,
input logic rst_n
);
  logic             w_en, r_en;
  logic [WIDTH-1:0] data_in;
  logic [WIDTH-1:0] data_out;
  logic             full, empty;

  clocking drv_cb @(negedge clk);
  default output #2;
  output  w_en, r_en, data_in;
  endclocking

  clocking mon_cb @(negedge clk);
  default input #1;
  input w_en, r_en;
  input data_in;
  input data_out;
  input full, empty;
  endclocking

  modport DRIVER (
  input     clk, rst_n,
  clocking  drv_cb  
  );

  modport MONITOR (
  input     clk, rst_n,
  clocking  mon_cb
  );
  
endinterface : fifo_interface
