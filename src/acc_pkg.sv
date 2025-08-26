localparam integer DATA_WIDTH = 32;
localparam integer ADDR_WIDTH = 32;
localparam integer REG_ADDR_WIDTH = 5;

typedef logic[DATA_WIDTH-1:0] data_t;
typedef logic[ADDR_WIDTH-1:0] addr_t;
typedef logic[REG_ADDR_WIDTH-1:0] reg_addr_t;

typedef enum logic[1:0] {
    OPERATION_ADD,
    OPERATION_SUB,
    OPERATION_MUL
} operation_e;

typedef struct packed {
    operation_e operation;
    data_t op0;
    data_t op1;
    data_t op2;
    reg_addr_t rd;
} acc_instr_t;
