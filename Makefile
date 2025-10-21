# Makefile

# defaults
TOPLEVEL_LANG ?= verilog
SIM ?= verilator

EXTRA_ARGS += -Wno-UNOPTFLAT -Wno-REALCVT  -Wno-SHORTREAL -Wno-UNUSED -Wno-WIDTHEXPAND

VERILOG_SOURCES += $(PWD)/target/hello.sv
# use VHDL_SOURCES for VHDL files

# COCOTB_TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
COCOTB_TOPLEVEL = hello_fp_unit

# COCOTB_TEST_MODULES is the basename of the Python test file(s)
COCOTB_TEST_MODULES = test_my_design

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
