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

  initial begin //TODO: läs in rätt
    tableau_mem[0:3] = '{
        32'h41500000,
        32'h40c00000,
        32'h40500000,
        32'h3f400000
        //32'h3f800000
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

  integer test_count = 0;
  integer fail_count = 0;

  // tags for pipeline testing
  tag_t   tag_0;
  tag_t   tag_1;

  int w, i, j, k;
  logic r;
  logic first_i_row;

  // Test sequence
  initial begin : decode_stage
    type_if = INVALID;
    type_dc = INVALID;
    type_ex = INVALID;
    type_wb = INVALID;

    // Wait for reset deassertion
    @(posedge rst_n);
    #10;

    // instr_if.mem = '{
    //     addr: 5'd1,
    //     data: 32'd8,  //A[p,w]
    //     read: 0
    // };
    // type_if = IMM;
    // @(posedge clk);

    // instr_if.mem = '{
    //     addr: 5'd2,
    //     data: 32'd4,  //A[p,w]
    //     read: 0
    // };
    // type_if = IMM;
    // @(posedge clk);

    // instr_if.mem = '{
    //     addr: 5'd3,
    //     data: 32'd5,  //A[p,w]
    //     read: 0
    // };
    // type_if = IMM;
    // @(posedge clk);

    // instr_if.mem = '{
    //     addr: 5'd4,
    //     data: 32'd0,  //A[p,w]
    //     read: 0
    // };
    // type_if = IMM;
    // @(posedge clk);

    // instr_if.mem = '{
    //     addr: 5'd5,
    //     data: 32'd0,  //A[p,w]
    //     read: 0
    // };
    // type_if = IMM;
    // @(posedge clk);

    // instr_if.mem = '{
    //     addr: 5'd6,
    //     data: 32'd8,  //A[p,w]
    //     read: 0
    // };
    // type_if = IMM;
    // @(posedge clk);
    // type_if = INVALID;

    // @(posedge clk);
    // @(posedge clk);
    // @(posedge clk);

    // instr_if.mem = '{
    //     addr: 5'd7,
    //     data: x[3]*x[4]+x[5],  //A[p,w]
    //     read: 1
    // };
    // type_if = MEM;
    // @(posedge clk);
    // type_if = INVALID;
    // @(posedge clk);
    // @(posedge clk);

    x[1] = W;
    x[2] = M;
    x[3] = N;
    x[4] = P;
    x[5] = Q;
    x[6] = XS;
    x[7] = 32'h41500000; // 13.0
    @(posedge clk);



    instr_dc.acc = '{
        operation: '{fpu_operation: DIV},
        acc_op: 1'b0,  // FPU operation
        op_mod_i: 1'b0,
        op2: 32'h00000000,  // Not used
        op1: x[7],  // b = 1.0 (FP32)
        op0: 32'h3F800000,  // c = 2.0 (FP32)
        rd: 5'd7  // Destination register
    };
    type_dc = ACC;

    @(posedge clk);
    instr_dc = '0;
    type_dc  = INVALID;
    @(negedge busy);

    @(posedge clk);

    // Issue prepiv
    instr_dc.acc = '{
        operation: '{acc_operation: OPERATION_PREPIV},
        acc_op: 1'b1,  // ACC operation
        op_mod_i: 1'b0,
        op0: x[6],  // x_s
        op1: x[2],  // m
        op2: x[3],  // n
        rd: 5'd0  // Destination register
    };
    type_dc = ACC;
    @(posedge clk);

    // Issue pivot
    instr_dc.acc = '{
        operation: '{acc_operation: OPERATION_PIV},
        acc_op: 1'b1,  // ACC operation
        op_mod_i: 1'b0,
        op0: x[4],  // p
        op1: x[5],  // q
        op2: x[7],  // a_pq_inv
        rd: 5'd0  // Destination register
    };
    type_dc = ACC;
    @(posedge clk);

    //LOADS AND STORES
    for (
        w = 0, r = 0, i = 0, j = 0, k = 0 , first_i_row = 1; k * x[1] < x[3]; k++
    ) begin : main_loop
      for (w = 0, j = k * x[1]; w < x[1] && j < x[3]; w++, j++) begin : piv_row
        //TODO: handle case wheen n < w and k never not 0
        //if(j == x[5]) continue;
        if (k > 0) begin
          instr_dc.mem = '{
              addr: x[4] * x[3] + j - i,
              data: x[6] + w,  //A[p,w]
              read: 0
          };
          type_dc = MEM;
          @(posedge clk);
        end
        if(j == x[3] - 1) begin
          instr_dc.mem = '{
              addr: 0,
              data: 32'h3f800000,  //A[p,w]
              read: 1
          };
          type_dc = IMM;
          @(posedge clk);
        end else begin
          instr_dc.mem = '{
              addr: x[6] + w,
              data: x[4] * x[3] + j - i,  //A[p,w]
              read: 1
          };
          type_dc = MEM;
          @(posedge clk);
        end
      end

      for (i = 0; i < x[2]; i++, w = 0, j = k * x[1]) begin : other_rows
        if (i == x[4]) continue;
        instr_dc.mem = '{
            addr: 0,
            data: i * x[3] + x[5] - i,  //A[i,q]
            read: 1
        };
        type_dc = MEM;
        @(posedge clk);
        for (j = k * x[1]; w < x[1] && j < x[3]; w++, j++, r = ~r) begin : row_i
          if (j == x[5])begin
            r = ~r;
            continue;
          end
          if (w > (1 + (j > x[5])) || !first_i_row) begin
            if(j == k*x[1] + (x[5] == k*x[1])) begin
              instr_dc.mem = '{
                  addr: ((k + 1)*x[1] < x[3]) ?(i - 1) * x[3] + (k+1)*x[1] - ((k+1)*x[1] - 1 == x[5] || (k+1)*x[1] - 2 == x[5]) - i - 1: i * x[3] - i - 1 -(x[3]-2 == x[5]),
                  data: x[6]+x[1]+r,  //A[p,w]
                  read: 0
              };
              type_dc = MEM;
              @(posedge clk);
            end else if(j == k*x[1] + 1 + (x[5] == k*x[1] || x[5] == k*x[1] + 1))begin
              instr_dc.mem = '{
                  addr: ((k + 1)*x[1] < x[3]) ? (i - 1) * x[3] + (k+1)*x[1] - ((k+1)*x[1] - 1 == x[5]) - i: (i - 1) * x[3] + x[5] - i + 1,
                  data: x[6]+x[1]+r,  //A[p,w]
                  read: 0
              };
              type_dc = MEM;
              @(posedge clk);
            end else begin
              instr_dc.mem = '{
                  addr: i * x[3] + j - 2 - (j - 2 == x[5] || j - 1 == x[5] || j - 2 + x[3] == x[5]) - i,
                  data: x[6]+x[1]+r,  //A[p,w]
                  read: 0
              };
              type_dc = MEM;
              @(posedge clk);
            end
          end

          if(j == x[3] - 1)begin
            instr_dc.mem = '{
                addr: 0,
                data: 32'h00000000,  //A[p,w]
                read: 1
            };
            type_dc = IMM;
            @(posedge clk);
          end else begin
            instr_dc.mem = '{
                addr: x[6] + x[1] + r,
                data: i * x[3] + j - i,  //A[p,w]
                read: 1
            };
            type_dc = MEM;
            @(posedge clk);
          end
        end
        first_i_row = 0;
      end

      instr_dc.mem = '{
          addr: ((k + 1)*x[1] < x[3]) ?(i - 1) * x[3] + (k+1)*x[1] - ((k+1)*x[1] - 1 == x[5] || (k+1)*x[1] - 2 == x[5]) - i - 1: i * x[3] - i - 1 -(x[3]-2 == x[5]),
          data: x[6]+x[1]+r,  //A[p,w]
          read: 0
      };
      type_dc = MEM;
      @(posedge clk);
      type_dc = INVALID;
      r=~r;
      @(posedge clk);
      instr_dc.mem = '{
          addr: ((k + 1)*x[1] < x[3]) ? (i - 1) * x[3] + (k+1)*x[1] - ((k+1)*x[1] - 1 == x[5]) - i: (i - 1) * x[3] + x[5] - i + 1,
          data: x[6]+x[1]+r,  //A[p,w]
          read: 0
      };
      type_dc = MEM;
      @(posedge clk);
    end

    for(w = 0, i = x[4], j = (k - 1) * x[1]; w < x[1] && j < x[3]; j++, w++)begin
      if(j == x[5]) continue;
      if(j == x[3] - 1) begin
        instr_dc.mem = '{
            addr: i * x[3] + x[5] - i,
            data: x[6]+w,  //A[p,w]
            read: 0
        };
        type_dc = MEM;
        @(posedge clk);
      end else begin
        instr_dc.mem = '{
            addr: i * x[3] + j - i,
            data: x[6]+w,  //A[p,w]
            read: 0
        };
        type_dc = MEM;
        @(posedge clk);
      end
    end

    // for(i = 0; i < x[2]; i++)begin
    //   instr_dc.mem = '{
    //       addr: (i + 1) * x[3] - 1 - i,
    //       data: 0,  //A[p,w]
    //       read: 0
    //   };
    //   type_dc = MEM;
    //   @(posedge clk);
    // end
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
        for (int i = 0; i < x[2]; i++) begin
          for (int j = 0; j < x[3]; j++) begin
            $display("%h, ", tableau_mem[i*x[3]+j]);
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
