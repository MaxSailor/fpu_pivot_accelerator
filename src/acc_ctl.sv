module acc_ctl
    import acc_pkg::*;
    import fpnew_pkg::*;
(
    input logic rst_ni,
    input logic clk_i,

    // CPU signals
    input logic             cpu_clk_i,
    input logic             cpu_rst_ni_i,
    input acc_instr_t       cpu_acc_instr_i,
    input logic             cpu_acc_instr_valid_i,
    output  logic             cpu_busy_o,
    output  logic             cpu_ready_o,
    output  reg_addr_t  [2:0] cpu_raddr_o,
    output  reg_addr_t        cpu_waddr_o,
    output  data_t            cpu_wdata_o,
    output  logic             cpu_wren_o,
    output  logic             cpu_rready_o,
    input data_t      [2:0] cpu_rdata_i,
    input logic             cpu_rvalid_i,
    input logic             cpu_wready_i,

    // mem signals
    input  data_t mem_rdata_i,
    input  logic  mem_rvalid_i,
    input  logic  mem_wready_i,
    output logic  mem_rden_o,
    output logic  mem_wren_o,
    output data_t mem_wdata_o,
    output addr_t mem_waddr_o,
    output addr_t mem_raddr_o,

    // FPU signals
    output logic [2:0][DATA_WIDTH-1:0]         fpu_operands_o,
    output fpnew_pkg::roundmode_e              fpu_rnd_mode_o,
    output fpnew_pkg::operation_e              fpu_op_o,
    output logic                               fpu_op_mod_o,
    output fpnew_pkg::fp_format_e              fpu_src_fmt_o,
    output fpnew_pkg::fp_format_e              fpu_dst_fmt_o,
    output fpnew_pkg::int_format_e             fpu_int_fmt_o,
    output logic                               fpu_vectorial_op_o,
    output TagType                             fpu_tag_o,
    output MaskType                            fpu_simd_mask_o,
    // Input Handshake
    output logic                              fpu_in_valid_o,
    input  logic                              fpu_in_ready_i,
    output  logic                              fpu_flush_o,
    // Output signals
    input logic [WIDTH-1:0]                  fpu_result_i,
    input fpnew_pkg::status_t                fpu_status_i,
    input TagType                            fpu_tag_i,
    // Output handshake
    input  logic                              fpu_out_valid_i,
    output logic                              fpu_out_ready_o,
    // Indication of valid data in flight
    input  logic                              fpu_busy_i
);

endmodule