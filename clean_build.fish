#!/usr/bin/fish
# OLD, PRE-COCOTB build script - could be useful later
# Set the top module name
set TOP_MODULE float_testbench
set BIN ./obj_dir/V"$TOP_MODULE"
# Build and run
veryl clean \
    && rm -rf ./obj_dir \
    && veryl build \
    && echo "/home/thebu/newhome/hello/src/testbench.sv" >>hello.f \
    && verilator --binary -f hello.f --top-module "$TOP_MODULE" \
    -Wno-SHORTREAL -Wno-WIDTHTRUNC -Wno-REALCVT -Wno-TIMESCALEMOD -I. \
    && "$BIN"
