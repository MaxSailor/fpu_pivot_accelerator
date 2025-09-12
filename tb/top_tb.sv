`timescale 1ns / 1ps

import fpnew_pkg::*;
import acc_pkg::*;

module top_tb;
  logic             clk;
  logic             rst_n;

  // CPU EX interface
  acc_instr_t       acc_instr;
  logic             acc_instr_valid;
  logic             busy;
  logic             ready;

  // regfile interface
  reg_addr_t  [2:0] raddr;
  reg_addr_t        waddr;
  data_t            wdata;
  logic             wren;
  data_t      [2:0] rdata;
  logic             rvalid;

  // forwarded data from CPU
  data_t            fwd_data;
  logic             fwd_valid;

  data_t [15:0]     regfile;

  // Instantiate the DUT
  acc_top dut (
      .rst_ni(rst_n),
      .clk_i(clk),
      .acc_instr_i(acc_instr),
      .acc_instr_valid_i(acc_instr_valid),
      .busy_o(busy),
      .ready_o(ready),
      .raddr_o(raddr),
      .waddr_o(waddr),
      .wdata_o(wdata),
      .wren_o(wren),
      .rdata_i(rdata),
      .rvalid_i(rvalid),
      .fwd_data_i(fwd_data),
      .fwd_valid_i(fwd_valid)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100MHz clock
  end

  // Reset generation
  initial begin
    rst_n = 0;
    #15;
    rst_n = 1;
  end

  integer test_count = 0;
  integer fail_count = 0;

  // tags for pipeline testing
  tag_t   tag_0;
  tag_t   tag_1;

  // Test sequence
  initial begin : input_sequence

    $dumpfile("top_tb.vcd");
    $dumpvars();

    // Initialize inputs
    acc_instr       = '0;
    acc_instr_valid = 0;
    rdata           = '0;
    rvalid          = 0;
    fwd_data        = '0;
    fwd_valid       = 0;

    // Wait for reset deassertion
    @(posedge rst_n);
    #10;

    // Test case 1: ADD operation
    acc_instr = '{
        operation: '{fpu_operation: ADD},
        acc_op: 1'b0, // FPU operation
        op_mod_i: 1'b0,
        op0: 32'h00000000,  // Not used
        op1: 32'h3F800000,  // b = 1.0 (FP32)
        op2: 32'h40000000,  // c = 2.0 (FP32)
        rd: 5'd1  // Destination register
    };

    acc_instr_valid = 1;
    @(posedge clk);
    acc_instr_valid = 0;

  end

  initial begin : output_sequence
    // Wait for the accelerator to produce output
    wait (wren);

    regfile[waddr] = wdata;

    // TODO check result vs expected

  end

initial begin
    #2000;
    $display("Finish: %0d/%0d tests passed", test_count, fail_count);
    $finish;
end

endmodule
