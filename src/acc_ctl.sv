module acc_ctl
    import acc_pkg::*;
    import fpnew_pkg::*;
#(
    parameter integer DEFAULT_W = 8,
    parameter integer MAX_W = 32,
    parameter integer R = 2
) (
    input logic rst_ni,
    input logic clk_i,

    // CPU signals
    input  acc_instr_t       cpu_acc_instr_i,
    input  logic             cpu_acc_instr_valid_i,
    output logic             cpu_busy_o,
    output logic             cpu_ready_o,
    output reg_addr_t        cpu_raddr_o,
    output reg_addr_t        cpu_waddr_o,
    output data_t            cpu_wdata_o,
    output logic             cpu_wren_o,
    input  data_t            cpu_rdata_i,
    input  data_t            cpu_fwd_data_i,
    input  logic             cpu_fwd_valid_i,
    input  logic             cpu_rvalid_i,

    // FPU signals

    // Input Handshake
    output logic             fpu_in_valid_o,
    input  logic             fpu_in_ready_i, // unused for now
    output logic             fpu_flush_o,
    // Output handshake
    input  logic             fpu_out_valid_i,
    output logic             fpu_out_ready_o,
    // Indication of valid data in flight
    input  logic             fpu_busy_i,
    // FPU interface
    output fpu_req_t         fpu_req_o,
    input  fpu_resp_t        fpu_resp_i
);

// types
typedef logic [$clog2(R)-1:0] curr_reg_counter_t;
typedef logic [$clog2(MAX_W)-1:0] piv_reg_counter_t;

typedef enum logic[1:0] {
    S_FPU,
    S_PIV_ROW_P,
    S_PIV_CHANGE_ROW,
    S_PIV_ROW_I
} state_t;

// registers
state_t            state,    next_state;    // FSM state
reg_addr_t         x_s,      next_x_s;      // regfile reg where first matrix element is stored
reg_addr_t         W,        next_W;        // band width = nbr of regfile regs used to store partial pivot row
data_t             M,        next_M;        // num matrix rows
data_t             N,        next_N;        // num matrix cols
data_t             p,        next_p;        // pivot row index
data_t             q,        next_q;        // pivot col index
data_t             a_pq_inv, next_a_pq_inv; // reciprocal pivot element 1/A[p,q]
data_t             a_iq,     next_a_iq;     // current row pivot col element
data_counter_t     i,        next_i;        // row index
data_counter_t     j,        next_j;        // col index
data_counter_t     k,        next_k;        // band index
piv_reg_counter_t  w,        next_w;        // pivot row regfile index offset from x_s (x_(s+w))
curr_reg_counter_t r,        next_r;        // current row regfile index offset from x_(s+W) (x_(s+W+r))


assign cpu_busy_o = fpu_busy_i;
assign cpu_ready_o = !fpu_busy_i && !cpu_acc_instr_valid_i; // TODO: ?
assign fpu_flush_o = 0; // TODO: no flush support yet
assign fpu_req_o.simd_mask = '0; // no simd support

// FPU output handling
assign fpu_out_ready_o = 1; // always ready to accept output
assign cpu_wren_o = fpu_out_valid_i;
assign cpu_wdata_o = fpu_resp_i.result;
assign cpu_waddr_o = fpu_resp_i.tag;


always_ff @(clk_i) begin
    if (!rst_ni) begin
        state <= S_FPU;
        x_s <= 0;
        W <= DEFAULT_W;
        M <= 0;
        N <= 0;
        p <= 0;
        q <= 0;
        a_pq_inv <= 0;
        a_iq <= 0;
        i <= 0;
        j <= 0;
        k <= 0;
    end else begin
        state <= next_state;
        x_s <= next_x_s;
        W <= next_W;
        M <= next_M;
        N <= next_N;
        p <= next_p;
        q <= next_q;
        a_pq_inv <= next_a_pq_inv;
        a_iq <= next_a_iq;
        i <= next_i;
        j <= next_j;
        k <= next_k;
    end
end


always_comb begin : acc_state_machine
    // defaults
    next_state = state;
    next_x_s = x_s;
    next_W = W;
    next_M = M;
    next_N = N;
    next_i = i;
    next_j = j;
    next_k = k;
    next_r = r;
    next_w = w;
    next_a_pq_inv = a_pq_inv;
    next_a_iq = a_iq;
    next_p = p;
    next_q = q;
    fpu_req_o = '0;
    fpu_in_valid_o = 0;

    unique case (state)
        S_FPU: begin
            if (cpu_acc_instr_valid_i) begin
                // decode
                if (cpu_acc_instr_i.acc_op) begin
                    // Accelerator operation

                    unique case (cpu_acc_instr_i.operation.acc_operation)
                        OPERATION_SET_W: next_W = cpu_acc_instr_i.op0;
                        OPERATION_PREPIV: begin
                            next_x_s = cpu_acc_instr_i.op0;
                            next_M = cpu_acc_instr_i.op1;
                            next_N = cpu_acc_instr_i.op2;
                        end
                        OPERATION_PIV: begin
                            next_i = 0;
                            next_j = 0;
                            next_k = 0;
                            next_p = cpu_acc_instr_i.op0;
                            next_q = cpu_acc_instr_i.op1;
                            next_a_pq_inv = cpu_acc_instr_i.op2;
                            next_state = S_PIV_ROW_P;
                        end
                    endcase

                end else begin
                    // Vanilla FPU operation

                    fpu_req_o.tag = cpu_acc_instr_i.rd; // use destination reg as tag

                    fpu_req_o.op = cpu_acc_instr_i.operation.fpu_operation;
                    fpu_req_o.op_mod = cpu_acc_instr_i.op_mod_i;

                    fpu_req_o.operands[0] = cpu_acc_instr_i.op0;
                    fpu_req_o.operands[1] = cpu_acc_instr_i.op1;
                    fpu_req_o.operands[2] = cpu_acc_instr_i.op2;

                    fpu_in_valid_o = 1;

                end
            end

        end
        S_PIV_ROW_P: begin
            if (cpu_fwd_valid_i) begin
                fpu_req_o.tag = x_s + w;
                fpu_req_o.op = MUL;
                fpu_req_o.op_mod = 0;
                fpu_req_o.operands[0] = cpu_fwd_data_i; // A[p,j]
                fpu_req_o.operands[1] = a_pq_inv;
                fpu_req_o.operands[2] = 0;
                fpu_in_valid_o = 1;
                next_state = S_PIV_CHANGE_ROW;
                if (j < k * W) begin
                    next_j = j + 1;
                    next_w = w + 1;
                end else begin
                    next_j = k * W;
                    next_w = 0;
                    next_state = S_PIV_CHANGE_ROW;
                end
            end
        end
        S_PIV_CHANGE_ROW: begin
            if (cpu_fwd_valid_i) begin
                next_a_iq = cpu_fwd_data_i;
                next_state = S_PIV_ROW_I;
            end
        end
        S_PIV_ROW_I: begin
            cpu_raddr_o = x_s + w;
            if (cpu_rvalid_i && cpu_fwd_valid_i) begin
                fpu_req_o.tag = x_s + w;
                fpu_req_o.op = FNMSUB;
                fpu_req_o.op_mod = 0;
                fpu_req_o.operands[0] = a_iq; // A[p,j]
                fpu_req_o.operands[1] = cpu_rdata_i;
                fpu_req_o.operands[2] = cpu_fwd_data_i;
                fpu_in_valid_o = 1;
                if (j + (j+1 == q) < (W * (k + 1))) begin
                    next_j = j + 1 + (j+1 == q);
                    next_w = w + 1 + (j+1 == q);
                    next_r = ~r;
                end else if (i + (i + 1 == p) < M) begin
                    next_i = i + 1 + (i + 1 == p);
                    next_j = k * W;
                    next_w = 0;
                    next_r = ~r; // TODO: IS THIS RIGHT OR SHOULD IT BE 0? Also if R > 2?
                end else begin
                    next_i = 0;
                    next_j = k * W;
                    next_w = 0;
                    next_r = ~r; // TODO: fix if R > 2
                    next_k = k + 1;
                    next_state = S_PIV_ROW_P;
                end
            end
        end
    endcase
end

endmodule
