package acc_pkg;
  import fpnew_pkg::*;

  localparam integer DATA_WIDTH = 32;
  localparam integer ADDR_WIDTH = 32;
  localparam integer REG_ADDR_WIDTH = 5;

  typedef logic [DATA_WIDTH-1:0] data_t;
  typedef logic [ADDR_WIDTH-1:0] addr_t;
  typedef logic [REG_ADDR_WIDTH-1:0] reg_addr_t;
  typedef logic [DATA_WIDTH-1:0] data_counter_t;
  typedef logic [ADDR_WIDTH-1:0] tag_t;
  typedef logic mask_t;

  typedef enum logic [1:0] {
    OPERATION_PREPIV,
    OPERATION_PIV,
    OPERATION_SET_W
    // TODO: add more accelerator-specific operations?
  } acc_operation_e;

  typedef union packed {
    acc_operation_e acc_operation;
    fpnew_pkg::operation_e fpu_operation;
  } operation_t;

  typedef struct packed {
    operation_t operation;
    logic acc_op;
    logic op_mod_i;
    data_t op0;
    data_t op1;
    data_t op2;
    reg_addr_t rd;
  } acc_instr_t;

  typedef struct packed {
    logic [2:0][DATA_WIDTH-1:0] operands;
    fpnew_pkg::roundmode_e      rnd_mode;
    fpnew_pkg::operation_e      op;
    logic                       op_mod;
    fpnew_pkg::fp_format_e      src_fmt;
    fpnew_pkg::fp_format_e      dst_fmt;
    fpnew_pkg::int_format_e     int_fmt;
    logic                       vectorial_op;
    tag_t                       tag;
    mask_t                      simd_mask;
  } fpu_req_t;

  typedef struct packed {
    logic [DATA_WIDTH-1:0] result;
    fpnew_pkg::status_t    status;
    tag_t                  tag;
  } fpu_resp_t;

endpackage : acc_pkg
