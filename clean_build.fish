#!/usr/bin/fish
veryl clean \
    && rm -rf ./obj_dir \
    && veryl build \
    && verilator --binary -f hello.f --top-module hello_fp_testbench -Wno-SHORTREAL -Wno-WIDTHTRUNC \
    && ./obj_dir/Vhello_fp_testbench
