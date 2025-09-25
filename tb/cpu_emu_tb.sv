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

  // x interface
  reg_addr_t              raddr;
  reg_addr_t              waddr;
  data_t                  wdata;
  logic                   wren;
  data_t                  rdata;
  logic                   rvalid;

  // writeback x interface
  reg_addr_t wb_waddr;
  data_t wb_wdata;
  logic wb_wren;

  // forwarded data from CPU
  data_t                  fwd_data;
  logic                   fwd_valid;

  data_t      x [31];

  data_t      tableau_mem [(M*(N-1))];

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

  instr_t instr_if, instr_dc, instr_ex, instr_wb;

  instr_type_t type_if, type_dc, type_ex, type_wb;

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
    clk = 1;
    forever #5 clk = ~clk;  // 100MHz clock
  end

  // Reset generation
  initial begin
    rst_n = 0;
    #20;
    rst_n = 1;
  end



  initial begin : regfile_init
    for (int i = 0; i < 32; i++) begin
      x[i] = '0;
    end
  end

  initial begin
    tableau_mem[0:3] = '{
        32'h41500000,
        32'h40c00000,
        32'h40500000,
        32'h3f400000
        //32'h3f800000 // not actually stored in mem
    };  //  13.000,  6.000,  3.250,  0.750, 1.000
    tableau_mem[4:7] = '{
        32'hc1980000,
        32'hc0000000,
        32'hc1140000,
        32'hbfe00000
        //32'h00000000
    };  // -19.000, -2.000, -9.250, -1.750, 0.000
    tableau_mem[8:11] = '{
        32'hc1980000,
        32'h41100000,
        32'hc0d80000,
        32'hbfa00000
        //32'h00000000
    };  // -19.000,  9.000, -6.750, -1.250, 0.000
    tableau_mem[12:15] = '{
        32'hc0000000,
        32'h00000000,
        32'hbfe00000,
        32'hbe800000
        //32'h00000000
    };  // -2.000,   0.000, -1.750, -0.250, 0.000
  end


  int w, i, j, k;
  logic r;
  logic first_i_row;
  data_t m, n, p, q, x_s, width;

  // Test sequence
  initial begin : decode_stage
    type_if = INVALID;
    type_dc = INVALID;
    type_ex = INVALID;
    type_wb = INVALID;

    // Wait for reset deassertion
    @(posedge rst_n);
    #10;

    x[1] = W;
    x[2] = M;
    x[3] = N;
    x[4] = P;
    x[5] = Q;
    x[6] = XS;

    width = x[1];
    m = x[2];
    n = x[3];
    p = x[4];
    q = x[5];
    x_s = x[6];
    @(posedge clk);
    @(posedge clk);

    // issue/decode:

    // load a_pq into x[7]
    instr_dc.mem = '{
        addr: 5'd7,
        data: n*p+q,
        read: 1
    };
    type_dc = MEM;
    @(posedge clk);
    type_dc = INVALID;
    @(posedge clk);
    @(posedge clk);


    // calculate 1/a_pq
    instr_dc.acc = '{
        operation: '{fpu_operation: DIV},
        acc_op: 1'b0,  // FPU operation
        op_mod_i: 1'b0,
        op0: 32'h3F800000,
        op1: x[7],
        op2: 32'h00000000,  // Not used
        rd: 5'd7  // Destination register
    };
    type_dc = ACC;

    @(posedge clk);
    instr_dc = '0;
    type_dc  = INVALID;
    @(negedge busy);

    @(posedge clk);

    // prepiv
    instr_dc.acc = '{
        operation: '{acc_operation: OPERATION_PREPIV},
        acc_op: 1'b1,  // ACC operation
        op_mod_i: 1'b0,
        op0: x_s,
        op1: m,
        op2: n,
        rd: 5'd0  // Destination register
    };
    type_dc = ACC;
    @(posedge clk);

    // pivot
    instr_dc.acc = '{
        operation: '{acc_operation: OPERATION_PIV},
        acc_op: 1'b1,  // ACC operation
        op_mod_i: 1'b0,
        op0: p,
        op1: q,
        op2: x[7],  // a_pq_inv
        rd: 5'd0  // Destination register
    };
    type_dc = ACC;
    @(posedge clk);

    // LOADS AND STORES
    for (
        r = 0, i = 0, j = 0, k = 0 , first_i_row = 1; k * width < n; k++
    ) begin : band_loop
      for (w = 0, j = k * width; w < width && j < n; w++, j++) begin : piv_row
        //if(j == q) continue;
        if (k > 0) begin
          // store previous partial pivot row
          instr_dc.mem = '{
              addr: p * n + j - i,
              data: x_s + w,
              read: 0
          };
          type_dc = MEM;
          @(posedge clk);
        end
        if(j == n - 1 /* N-1 */) begin
          // immediate load extra column (not in mem)
          instr_dc.mem = '{
              addr: 0,
              data: 32'h3f800000,
              read: 1
          };
          type_dc = IMM;
          @(posedge clk);
        end else begin
          // load A[p,j]
          instr_dc.mem = '{
              addr: x_s + w,
              data: p * n + j - i,
              read: 1
          };
          type_dc = MEM;
          @(posedge clk);
        end
      end

      for (i = 0; i < m; i++, w = 0, j = k * width) begin : other_rows
        if (i == p) continue; // skip pivot row

        // load piv col element
        instr_dc.mem = '{
            addr: 0,
            data: i * n + q - i,  //A[i,q]
            read: 1
        };
        type_dc = MEM;

        @(posedge clk);

        for (j = k * width; w < width && j < n; w++, j++) begin : row_i
          if (j == q) continue; // skip pivot col
          if (w > (1 + (w > (q - k * width))) || !(i == (p == 0))) begin // TODO: fix for W <= N
            if (j == k*width + (q == k*width)) begin // TODO: R != 2
              // first non-pivot column of band
              instr_dc.mem = '{
                  addr: ((k + 1)*width < n)
                          ? (i - 1) * n + (k+1)*width - ((k+1)*width - 1 == q || (k+1)*width - 2 == q) - i - 1
                          : i * n - i - 1 -(n-2 == q),
                  data: x_s+width+r,
                  read: 0
              };
              type_dc = MEM;
              @(posedge clk);
            end else if (j == k*width + 1 + (q == k*width || q == k*width + 1)) begin
              // second non-pivot column of band
              instr_dc.mem = '{
                  addr: ((k + 1)*width < n)
                          ? (i - 1) * n + (k+1)*width - ((k+1)*width - 1 == q) - i
                          : (i - 1) * n + q - i + 1,
                  data: x_s+width+r,
                  read: 0
              };
              type_dc = MEM;
              @(posedge clk);
            end else begin
              // all other columns
              instr_dc.mem = '{
                  addr: i * n + j - 2 - (j - 2 == q || j - 1 == q ) - i,
                  data: x_s+width+r,
                  read: 0
              };
              type_dc = MEM;
              @(posedge clk);
            end
          end

          if (j == n - 1) begin
            instr_dc.mem = '{
                addr: 0,
                data: 32'h00000000,
                read: 1
            };
            type_dc = IMM;
            @(posedge clk);
          end else begin
            instr_dc.mem = '{
                addr: x_s + width + r,
                data: i * n + j - i,
                read: 1
            };
            type_dc = MEM;
            @(posedge clk);
          end

          r = ~r;
        end
        first_i_row = 0;
      end

      instr_dc.mem = '{
          addr: ((k + 1)*width < n)
                  ? (i - 1) * n + (k+1)*width - ((k+1)*width - 1 == q || (k+1)*width - 2 == q) - i - 1
                  : i * n - i - 1 -(n-2 == q),
          data: x_s+width+r,
          read: 0
      };
      type_dc = MEM;
      @(posedge clk);
      type_dc = INVALID;
      r=~r;
      @(posedge clk);
      instr_dc.mem = '{
          addr: ((k + 1)*width < n)
                  ? (i - 1) * n + (k+1)*width - ((k+1)*width - 1 == q) - i
                  : (i - 1) * n + q - i + 1,
          data: x_s+width+r,
          read: 0
      };
      type_dc = MEM;
      @(posedge clk);
    end

    for (w = 0, i = p, j = (k - 1) * width; w < width && j < n; j++, w++) begin : store_last_partial_piv_row
      if(j == q) continue;
      if(j == n - 1 /* N-1 */) begin
        // store extra element to piv element
        instr_dc.mem = '{
            addr: i * n + q - i,
            data: x_s+w,
            read: 0
        };
        type_dc = MEM;
        @(posedge clk);
      end else begin
        // store all other elements
        instr_dc.mem = '{
            addr: i * n + j - i,
            data: x_s+w,
            read: 0
        };
        type_dc = MEM;
        @(posedge clk);
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
    if(type_dc == MEM && !instr_dc.mem.read)begin
      instr_ex.mem.addr <= instr_dc.mem.addr;
      instr_ex.mem.data <= x[instr_dc.mem.data];
      instr_ex.mem.read <= 0;
    end else begin
      instr_ex <= instr_dc;
    end

    instr_wb <= instr_ex;

    //instr_dc <= instr_if;

    type_wb  <= type_ex;
    type_ex  <= type_dc;
    //type_dc  <= type_if;

    if(type_wb == MEM && !instr_wb.mem.read) begin
      tableau_mem[instr_wb.mem.addr] <= instr_wb.mem.data;
    end
  end

  always_comb begin
      acc_instr = instr_ex.acc;
      acc_instr_valid = 0;
      fwd_data  = '0;
      fwd_valid = 0;
      wb_waddr = '0;
      wb_wdata = '0;
      wb_wren = 0;
      acc_instr_valid = (type_ex == ACC);
      // if (type_ex == ACC) begin
      //   acc_instr = instr_ex.acc;
      //   acc_instr_valid = 1;
      // end else begin
      //   acc_instr = '0;
      //   acc_instr_valid = 0;
      // end

      if (type_wb == MEM) begin
        if (instr_wb.mem.read) begin
          fwd_data  = tableau_mem[instr_wb.mem.data];
          fwd_valid = 1;
          // wb_wren = 1;
          // wb_waddr = instr_wb.mem.addr;
          // wb_wdata = tableau_mem[instr_wb.mem.data];
        end
      end

      if(type_wb == IMM) begin
        wb_waddr = instr_wb.mem.addr;
        wb_wdata = instr_wb.mem.data;
        wb_wren = 1;
        if (instr_wb.mem.read) begin
          fwd_data  = instr_wb.mem.data;
          fwd_valid = 1;
        end
      end
  end
  initial begin: timeout
    forever @ (posedge clk) if (type_wb == INVALID) begin
      invalids++;
      if (invalids > 50) begin
        $display("Timeout! \n");
        for (int i = 0; i < m; i++) begin
          for (int j = 0; j < n; j++) begin
            $display("%h, ", tableau_mem[i*n+j]);
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
      x[waddr] <= wdata;
      // TODO check result vs expected
    end

    if (wb_wren && wb_waddr != 0)begin
      x[wb_waddr] <= wb_wdata;
    end

  end

  always_comb begin
    rdata  = x[raddr];
    rvalid = raddr != 0;
  end



  // always_comb begin : regfile_reads
  //   rdata  = x[raddr];
  //   rvalid = raddr != 0;
  // end


endmodule
