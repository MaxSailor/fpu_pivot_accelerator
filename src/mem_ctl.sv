
module mem_ctl
  import acc_pkg::*;
(
    input logic rst_ni,
    input logic clk_i,

    // memory signals
    input  data_t mem_rdata_i,
    input  logic  mem_rvalid_i,
    input  logic  mem_wready_i,
    output logic  mem_rden_o,
    output logic  mem_wren_o,
    output data_t mem_wdata_o,
    output addr_t mem_waddr_o,
    output addr_t mem_raddr_o,

    // controller signals
    output data_t ctl_rdata_o,
    output logic  ctl_rvalid_o,
    output logic  ctl_wready_o,
    input  logic  ctl_rden_i,
    input  logic  ctl_wren_i,
    input  data_t ctl_wdata_i,
    input  addr_t ctl_waddr_i,
    input  addr_t ctl_raddr_i
);

  assign mem_rden_o   = ctl_rden_i;
  assign mem_wren_o   = ctl_wren_i;
  assign mem_wdata_o  = ctl_wdata_i;
  assign mem_waddr_o  = ctl_waddr_i;
  assign mem_raddr_o  = ctl_raddr_i;

  assign ctl_rdata_o  = mem_rdata_i;
  assign ctl_wready_o = mem_wready_i;
  assign ctl_rvalid_o = mem_rvalid_i;

endmodule
