module acc_top
    import acc_pkg::*;
    import fpnew_pkg::*;
(
    input logic             rst_ni,
    input logic             clk_i,

    // CPU EX interface
    input  acc_instr_t      acc_instr_i,
    input  logic            acc_instr_valid_i,
    output logic            busy_o,
    output logic            ready_o,

    // CPU regfile interface
    output reg_addr_t       raddr_o,
    output reg_addr_t       waddr_o,
    output data_t           wdata_o,
    output logic            wren_o,
    input  data_t           rdata_i,
    input  logic            rvalid_i,

    // forwarded data from CPU
    input  data_t           fwd_data_i,
    input  logic            fwd_valid_i
);

// FPnew config from CVA6
localparam int unsigned LAT_COMP_FP32 = 'd2;
localparam int unsigned LAT_COMP_FP64 = 'd3;
localparam int unsigned LAT_COMP_FP16 = 'd1;
localparam int unsigned LAT_COMP_FP16ALT = 'd1;
localparam int unsigned LAT_COMP_FP8 = 'd1;
localparam int unsigned LAT_DIVSQRT = 'd2;
localparam int unsigned LAT_NONCOMP = 'd2;
localparam int unsigned LAT_CONV = 'd2;

localparam fpu_implementation_t CUSTOM_SNITCH = '{
    PipeRegs: '{  // FP32, FP64, FP16, FP8, FP16alt
        '{
            unsigned'(LAT_COMP_FP32),
            unsigned'(LAT_COMP_FP64),
            unsigned'(LAT_COMP_FP16),
            unsigned'(LAT_COMP_FP8),
            unsigned'(LAT_COMP_FP16ALT)
        },  // ADDMUL
        '{default: unsigned'(LAT_DIVSQRT)},  // DIVSQRT
        '{default: unsigned'(LAT_NONCOMP)},  // NONCOMP
        '{default: unsigned'(LAT_CONV)}
    },  // CONV
    UnitTypes: '{
        '{default: PARALLEL},  // ADDMUL
        '{default: MERGED},  // DIVSQRT
        '{default: PARALLEL},  // NONCOMP
        '{default: MERGED}  // CONV
    },
    PipeConfig: DISTRIBUTED
};

// FPU interface
fpu_req_t                   fpu_req;
fpu_resp_t                  fpu_resp;

// FPU input signals
logic [2:0][DATA_WIDTH-1:0] fpu_operands;
roundmode_e                 fpu_rnd_mode;
operation_e                 fpu_op;
logic                       fpu_op_mod;
fp_format_e                 fpu_src_fmt;
fp_format_e                 fpu_dst_fmt;
int_format_e                fpu_int_fmt;
logic                       fpu_vectorial_op;
tag_t                       fpu_tag_in;
logic                       fpu_simd_mask;
logic                       fpu_in_valid;
logic                       fpu_flush;
logic                       fpu_out_ready;

// FPU output signals
logic [DATA_WIDTH-1:0]      fpu_result;
status_t                    fpu_status;
tag_t                       fpu_tag_out;
logic                       fpu_in_ready;
logic                       fpu_out_valid;
logic                       fpu_busy;

assign fpu_operands       = fpu_req.operands;
assign fpu_rnd_mode       = fpu_req.rnd_mode;
assign fpu_op             = fpu_req.op;
assign fpu_op_mod         = fpu_req.op_mod;
assign fpu_src_fmt        = fpu_req.src_fmt;
assign fpu_dst_fmt        = fpu_req.dst_fmt;
assign fpu_int_fmt        = fpu_req.int_fmt;
assign fpu_vectorial_op   = fpu_req.vectorial_op;
assign fpu_tag_in         = fpu_req.tag;
assign fpu_simd_mask      = fpu_req.simd_mask;

assign fpu_resp = '{
    result: fpu_result,
    status: fpu_status,
    tag:    fpu_tag_out
};

acc_ctl acc_ctl (
    .rst_ni(rst_ni),
    .clk_i(clk_i),
    .cpu_acc_instr_i(acc_instr_i),
    .cpu_acc_instr_valid_i(acc_instr_valid_i),
    .cpu_busy_o(busy_o),
    .cpu_ready_o(ready_o),
    .cpu_raddr_o(raddr_o),
    .cpu_waddr_o(waddr_o),
    .cpu_wdata_o(wdata_o),
    .cpu_wren_o(wren_o),
    .cpu_rdata_i(rdata_i),
    .cpu_fwd_data_i(fwd_data_i),
    .cpu_fwd_valid_i(fwd_valid_i),
    .cpu_rvalid_i(rvalid_i),
    .fpu_in_valid_o(fpu_in_valid),
    .fpu_in_ready_i(fpu_in_ready),
    .fpu_flush_o(fpu_flush),
    .fpu_out_valid_i(fpu_out_valid),
    .fpu_out_ready_o(fpu_out_ready),
    .fpu_busy_i(fpu_busy),
    .fpu_req_o(fpu_req),
    .fpu_resp_i(fpu_resp)
);

// FPU instance
fpnew_top #(
    .Features(RV32F),
    .Implementation(DEFAULT_NOREGS),
    .TagType(tag_t)
) fpu (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .operands_i(fpu_operands),
    .rnd_mode_i(fpu_rnd_mode),
    .op_i(fpu_op),
    .op_mod_i(fpu_op_mod),
    .src_fmt_i(fpu_src_fmt),
    .dst_fmt_i(fpu_dst_fmt),
    .int_fmt_i(fpu_int_fmt),
    .vectorial_op_i(fpu_vectorial_op),
    .tag_i(fpu_tag_in),
    .simd_mask_i(fpu_simd_mask),
    .in_valid_i(fpu_in_valid),
    .in_ready_o(fpu_in_ready),
    .flush_i(fpu_flush),
    .result_o(fpu_result),
    .status_o(fpu_status),
    .tag_o(fpu_tag_out),
    .out_valid_o(fpu_out_valid),
    .out_ready_i(fpu_out_ready),
    .busy_o(fpu_busy)
);

endmodule
