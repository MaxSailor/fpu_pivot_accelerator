verilator --binary --timing --clk clk --timescale-override 1ns/1ps --relative-includes --trace --trace-structs\
  -Wno-UNUSEDSIGNAL \
  -Wno-UNUSEDPARAM \
  -Wno-PINCONNECTEMPTY \
  -Wno-ASCRANGE \
  -Wno-WIDTHEXPAND \
  -Wno-IMPORTSTAR \
  -Wno-VARHIDDEN \
  -Wno-UNDRIVEN \
  -Wno-WIDTHTRUNC \
  -Wno-GENUNNAMED \
  -Wno-SELRANGE \
  -Wno-LITENDIAN \
  -Wno-WIDTH \
  -Wno-UNPACKED \
  -Wno-CASEINCOMPLETE \
  -Wno-UNOPTFLAT \
  -Wno-fatal          \
  -Wno-PINCONNECTEMPTY\
  -Wno-ASSIGNDLY      \
  -Wno-DECLFILENAME   \
  -Wno-UNUSED         \
  -Wno-UNOPTFLAT      \
  -Wno-BLKANDNBLK     \
  -Wno-UNSIGNED \
  -Wno-style\
  -fno-dfg-peephole \
  +incdir+src/cvfpu/src/common_cells/include \
  src/cvfpu/src/fpu_div_sqrt_mvp/hdl/defs_div_sqrt_mvp.sv \
  src/cvfpu/src/fpu_div_sqrt_mvp/hdl/div_sqrt_top_mvp.sv \
  src/cvfpu/src/common_cells/src/cf_math_pkg.sv \
  src/cvfpu/src/common_cells/src/lzc.sv \
  src/cvfpu/src/common_cells/src/rr_arb_tree.sv \
  src/cvfpu/src/fpnew_pkg.sv \
  src/cvfpu/src/fpnew_classifier.sv \
  src/cvfpu/src/fpnew_rounding.sv \
  src/cvfpu/src/fpnew_fma.sv \
  src/cvfpu/src/fpnew_fma_multi.sv \
  src/cvfpu/src/fpnew_cast_multi.sv \
  src/cvfpu/src/fpnew_opgroup_fmt_slice.sv \
  src/cvfpu/src/fpnew_opgroup_multifmt_slice.sv \
  src/cvfpu/src/fpnew_opgroup_block.sv \
  src/cvfpu/src/fpnew_top.sv \
  src/acc_pkg.sv \
  src/acc_top.sv \
  src/acc_ctl.sv \
  tb/cpu_emu_tb.sv \
  -y src/cvfpu/src \
  -y src/cvfpu/src/common_cells/include \
  -y src/cvfpu/src/common_cells/src \
  -y src/cvfpu/src/common_cells/src/deprecated \
  -y src/cvfpu/src/fpu_div_sqrt_mvp/hdl \
  -y tb \
  --top-module cpu_emu_tb
./obj_dir/Vcpu_emu_tb