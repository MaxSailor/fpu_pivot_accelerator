`timescale 1ns / 1ps

import fpnew_pkg::*;
import acc_pkg::*;

module cpu_emu_tb;


  localparam data_t W = 32'd8;
  localparam data_t M = 32'd4;
  localparam data_t N = 32'd5;
  localparam data_t P = 32'd0;
  localparam data_t Q = 32'd0;
  localparam data_t XS = 32'd8;

  logic                   clk;
  logic                   rst_n;

  // CPU EX interface
  acc_instr_t             acc_instr;
  logic                   acc_instr_valid;
  logic                   busy;
  logic                   ready;

  // regfile interface
  reg_addr_t              raddr;
  reg_addr_t              waddr;
  data_t                  wdata;
  logic                   wren;
  data_t                  rdata;
  logic                   rvalid;

  // writeback regfile interface
  reg_addr_t wb_waddr;
  data_t wb_wdata;
  logic wb_wren;

  // forwarded data from CPU
  data_t                  fwd_data;
  logic                   fwd_valid;

  data_t      [     31:0] regfile;

  data_t      [(M*N)-1:0] tableau_mem;

  typedef struct packed {
    addr_t addr;
    data_t data;
    logic  read;
  } mem_instr_t;

  typedef union packed {
    mem_instr_t mem;
    acc_instr_t acc;
  } instr_t;

  typedef enum logic [1:0] {
    MEM,
    ACC,
    IMM,
    INVALID
  } instr_type_t;

  instr_t instr_dc, instr_ex, instr_wb;

  instr_type_t type_dc, type_ex, type_wb;

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



  initial begin : regfile_init
    for (int i = 0; i < 32; i++) begin
      regfile[i] = '0;
    end
  end

  initial begin //TODO: läs in rätt
    tableau_mem[4:0] = '{
        32'h41500000,
        32'h40c00000,
        32'h40500000,
        32'h3f400000,
        32'h3f800000
    };  //  13.000,  6.000,  3.250,  0.750, 1.000
    tableau_mem[5:9] = '{
        32'hc1980000,
        32'hc0000000,
        32'hc1140000,
        32'hbfe00000,
        32'h00000000
    };  // -19.000, -2.000, -9.250, -1.750, 0.000
    tableau_mem[10:14] = '{
        32'hc1980000,
        32'h41100000,
        32'hc0d80000,
        32'hbfa00000,
        32'h00000000
    };  // -19.000,  9.000, -6.750, -1.250, 0.000
    tableau_mem[15:19] = '{
        32'hc0000000,
        32'h00000000,
        32'hbfe00000,
        32'hbe800000,
        32'h00000000
    };  // -2.000,   0.000, -1.750, -0.250, 0.000
  end

  integer test_count = 0;
  integer fail_count = 0;

  // tags for pipeline testing
  tag_t   tag_0;
  tag_t   tag_1;

  // Test sequence
  initial begin : decode_stage


    // Wait for reset deassertion
    @(posedge rst_n);
    #10;

    instr_dc.mem = '{
        addr: 5'd2,
        data: 32'd4,  //A[p,w]
        read: 0
    };
    type_dc = IMM;
    @(posedge clk);

    instr_dc.mem = '{
        addr: 5'd3,
        data: 32'd5,  //A[p,w]
        read: 0
    };
    type_dc = IMM;
    @(posedge clk);

    instr_dc.mem = '{
        addr: 5'd4,
        data: 32'd0,  //A[p,w]
        read: 0
    };
    type_dc = IMM;
    @(posedge clk);

    instr_dc.mem = '{
        addr: 5'd5,
        data: 32'd0,  //A[p,w]
        read: 0
    };
    type_dc = IMM;
    @(posedge clk);

    instr_dc.mem = '{
        addr: 5'd6,
        data: 32'd8,  //A[p,w]
        read: 0
    };
    type_dc = IMM;
    @(posedge clk);
    type_dc = INVALID;

    @(posedge clk);
    @(posedge clk);
    @(posedge clk);

    instr_dc.mem = '{
        addr: 5'd7,
        data: regfile[3]*regfile[4]+regfile[5],  //A[p,w]
        read: 1
    };
    type_dc = MEM;
    @(posedge clk);


    instr_dc.acc = '{
        operation: '{fpu_operation: DIV},
        acc_op: 1'b0,  // FPU operation
        op_mod_i: 1'b0,
        op0: 32'h00000000,  // Not used
        op1: 32'h3F800000,  // b = 1.0 (FP32)
        op2: regfile[7],  // c = 2.0 (FP32)
        rd: 5'd7  // Destination register
    };
    type_dc = ACC;

    @(posedge clk);
    instr_dc = '0;
    type_dc  = INVALID;
    wait (!busy);

    @(posedge clk);

    // Issue prepiv
    instr_dc.acc = '{
        operation: '{acc_operation: OPERATION_PREPIV},
        acc_op: 1'b1,  // ACC operation
        op_mod_i: 1'b0,
        op0: regfile[6],  // x_s
        op1: regfile[2],  // m
        op2: regfile[3],  // n
        rd: 5'd0  // Destination register
    };
    type_dc = ACC;
    @(posedge clk);

    // Issue pivot
    instr_dc.acc = '{
        operation: '{acc_operation: OPERATION_PIV},
        acc_op: 1'b1,  // ACC operation
        op_mod_i: 1'b0,
        op0: regfile[4],  // p
        op1: regfile[5],  // q
        op2: regfile[7],  // a_pq_inv
        rd: 5'd0  // Destination register
    };
    type_dc = ACC;
    @(posedge clk);

    //LOADS AND STORES
    for (
        int w = 0, logic r = 0, int i = 0, int j = 0, int k = 0; k * W < regfile[3]; k++
    ) begin : main_loop
      for (w = 0, j = k * W; w < W && j < regfile[3]; w++, j++) begin : piv_row
        //TODO: handle case wheen n < w and k never not 0
        if (k > 0) begin
          instr_dc.mem = '{
              addr: regfile[4] * regfile[3] + j,
              data: regfile[regfile[6]+w],  //A[p,w]
              read: 0
          };
          type_dc = MEM;
          @(posedge clk);
        end

        instr_dc.mem = '{
            addr: regfile[6] + w,
            data: regfile[4] * regfile[3] + j,  //A[p,w]
            read: 1
        };
        type_dc = MEM;
        @(posedge clk);
      end

      for (int i = 0; i < regfile[2]; i++) begin : other_rows
        if (i == regfile[4]) continue;
        instr_dc.mem = '{
            addr: 0,
            data: i * regfile[3] + regfile[5],  //A[i,q]
            read: 1
        };
        type_dc = MEM;
        @(posedge clk);

        for (w = 0, r = 0, j = k * W; w < W && j < regfile[3]; w++, r = ~r) begin : row_i
          if (j == regfile[5]) continue;

          if (w > 2) begin
            instr_dc.mem = '{
                addr: i * regfile[3] + j,
                data: regfile[regfile[6]+W+r],  //A[p,w]
                read: 0
            };
            type_dc = MEM;
            @(posedge clk);
          end

          instr_dc.mem = '{
              addr: regfile[6] + W + r,
              data: regfile[i] * regfile[3] + w,  //A[p,w]
              read: 1
          };
          type_dc = MEM;
          @(posedge clk);
        end
      end
    end

    type_dc = INVALID;
  end

  integer invalids = 0;


  initial begin : pipeline
    $dumpfile("cpu_emu_tb.vcd");
    $dumpvars();
  end

  always_ff @(posedge clk) begin
    instr_wb <= instr_ex;
    instr_ex <= instr_dc;

    type_wb  <= type_ex;
    type_ex  <= type_dc;

    if(type_wb == MEM && !instr_wb.mem.read) begin
      tableau_mem[instr_wb.mem.addr] <= instr_wb.mem.data;
    end

  end

  always_comb begin
      acc_instr = '0;
      acc_instr_valid = 0;
      fwd_data  = '0;
      fwd_valid = 0;
      wb_waddr = '0;
      wb_wdata = '0;
      wb_wren = 0;

      if (type_ex == ACC) begin
        acc_instr = instr_ex.acc;
        acc_instr_valid = 1;
      end else begin
        acc_instr = '0;
        acc_instr_valid = 0;
      end

      if (type_wb == MEM) begin
        if (instr_wb.mem.read) begin
          fwd_data  = tableau_mem[instr_wb.mem.data];
          fwd_valid = 1;
          wb_wren = 1;
          wb_waddr = instr_wb.mem.addr;
          wb_wdata = tableau_mem[instr_wb.mem.data];
        end
      end

      if(type_wb == IMM) begin
        wb_waddr = instr_wb.mem.addr;
        wb_wdata = instr_wb.mem.data;
        wb_wren = 1;
      end
  end
  initial begin
    forever @ (posedge clk) if (type_wb == INVALID) begin
      invalids++;
      if (invalids > 50) begin
        $display("Timeout! \n");
        for (int i = 0; i < regfile[2]; i++) begin
          for (int j = 0; j < regfile[3]; j++) begin
            $display("%h, ", tableau_mem[i*regfile[3]+j]);
          end
          $display("\n");
        end
        $finish;
      end
    end
  end

  // Wait for the accelerator to produce output

    always_ff@(negedge clk) begin
      if (wren && waddr != 0) begin
        regfile[waddr] <= wdata;
        // TODO check result vs expected
      end

      if (wb_wren && wb_waddr != 0)begin
        regfile[wb_waddr] <= wb_wdata;
      end

    end

    always_comb begin
      rdata  = regfile[raddr];
      rvalid = raddr != 0;
    end



  // always_comb begin : regfile_reads
  //   rdata  = regfile[raddr];
  //   rvalid = raddr != 0;
  // end


endmodule
