module acc_ctl
    import acc_pkg::*;
    import fpnew_pkg::*;
(
    input logic rst_ni,
    input logic clk_i,

    // CPU signals
    input  acc_instr_t       cpu_acc_instr_i,
    input  logic             cpu_acc_instr_valid_i,
    output logic             cpu_busy_o,
    output logic             cpu_ready_o,
    output reg_addr_t  [2:0] cpu_raddr_o,
    output reg_addr_t        cpu_waddr_o,
    output data_t            cpu_wdata_o,
    output logic             cpu_wren_o,
    input  data_t      [2:0] cpu_rdata_i,
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

enum logic[1:0] {
    S_FPU,
    S_PIV_ROW_P,
    S_PIV_CHANGE_ROW,
    S_PIV_ROW_I
} state, next_state;

reg_addr_t x_s, next_x_s;
data_t M, N, p, q, a_pq_inv, next_M, next_N, next_p, next_q, next_a_pq_inv;
counter_t i, j, k, next_i, next_j, next_k;

fpu_req_t fpu_req;

logic cpu_raddr;
logic fpu_in_valid;

assign cpu_raddr_o = cpu_raddr;
assign fpu_in_valid_o = fpu_in_valid;


assign cpu_busy_o = fpu_busy_i;
assign cpu_ready_o = !fpu_busy_i && !cpu_acc_instr_valid_i; // ?

assign fpu_req_o = fpu_req;

assign fpu_flush_o = 0; // no flush support yet

// FPU output handling
assign fpu_out_ready_o = 1; // always ready to accept output
assign cpu_wren_o = fpu_out_valid_i;
assign cpu_wdata_o = fpu_resp_i.result;
assign cpu_waddr_o = fpu_resp_i.tag;


always_ff @(clk_i) begin
    if (rst_ni) begin
        state <= S_FPU;
        x_s <= 0;
        M <= 0;
        N <= 0;
        p <= 0;
        q <= 0;
        a_pq_inv <= 0;
        i <= 0;
        j <= 0;
        k <= 0;
    end else begin
        state <= next_state;
        x_s <= next_x_s;
        M <= next_M;
        N <= next_N;
        p <= next_p;
        q <= next_q;
        a_pq_inv <= next_a_pq_inv;
        i <= next_i;
        j <= next_j;
        k <= next_k;
    end
end


always_comb begin : acc_state_machine
    // defaults
    next_state = state;
    next_x_s = x_s;
    next_M = M;
    next_N = N;
    next_i = i;
    next_j = j;
    next_k = k;
    fpu_in_valid = 0;
    cpu_raddr = 0;
    fpu_req.simd_mask = '0; // default to no lanes active

    unique case (state)
        S_FPU: begin
            if (cpu_acc_instr_valid_i) begin
                // decode
                if (cpu_acc_instr_i.acc_op) begin
                    // Accelerator operation

                    unique case (cpu_acc_instr_i.operation.acc_operation)
                        OPERATION_PREPIV: begin
                            next_x_s = cpu_acc_instr_i.op0;
                            next_M = cpu_acc_instr_i.op1;
                            next_N = cpu_acc_instr_i.op2;
                        end
                        OPERATION_PIV: begin
                            next_i = 0;
                            next_j = 0;
                            next_k = 0;
                            next_state = S_PIV_ROW_P;
                        end
                    endcase

                end else begin
                    // Vanilla FPU operation

                    fpu_req.tag = cpu_acc_instr_i.rd; // use destination reg as tag

                    fpu_req.op = cpu_acc_instr_i.operation.fpu_operation;
                    fpu_req.op_mod = cpu_acc_instr_i.op_mod_i;

                    fpu_req.operands[0] = cpu_acc_instr_i.op0;
                    fpu_req.operands[1] = cpu_acc_instr_i.op1;
                    fpu_req.operands[2] = cpu_acc_instr_i.op2;

                    fpu_in_valid = 1;

                end
            end

        end
        S_PIV_ROW_P: begin
        end
        S_PIV_CHANGE_ROW: begin
        end
        S_PIV_ROW_I: begin
        end
    endcase
end

endmodule
