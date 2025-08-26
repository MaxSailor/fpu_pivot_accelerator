module cpu_ctl
  import acc_pkg::*;
(
    input logic clk_i,
    input logic rst_ni,

    // CPU EX signals
    input acc_instr_t acc_instr_i,
    input logic acc_instr_valid_i,
    output logic busy_o,
    output logic ready_o,

    // CPU reg signals
    output reg_addr_t [2:0] reg_raddr_o,
    output reg_addr_t reg_waddr_o,
    output data_t reg_wdata_o,
    output logic reg_wren_o,
    output logic reg_rready_o,
    input data_t [2:0] reg_rdata_i,
    input logic reg_rvalid_i,
    input logic reg_wready_i,

    // CTL signals
    output logic             ctl_clk_o,
    output logic             ctl_rst_ni_o,
    output acc_instr_t       ctl_acc_instr_o,
    output logic             ctl_acc_instr_valid_o,
    input  logic             ctl_busy_i,
    input  logic             ctl_ready_i,
    input  reg_addr_t  [2:0] ctl_raddr_i,
    input  reg_addr_t        ctl_waddr_i,
    input  data_t            ctl_wdata_i,
    input  logic             ctl_wren_i,
    input  logic             ctl_rready_i,
    output data_t      [2:0] ctl_rdata_o,
    output logic             ctl_rvalid_o,
    output logic             ctl_wready_o
);

endmodule
