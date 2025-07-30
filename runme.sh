cd sims
verilator --binary --trace --timing -Wno-fatal ../tb/tb_tpu_top.sv ../rtl/*.sv
./obj_dir/Vtb_tpu_top
cd ..