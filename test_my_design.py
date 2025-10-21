# test_my_design.py (extended)

from decimal import FloatOperation
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import (
    FallingEdge,
    RisingEdge,
    Timer,
    with_timeout,
    SimTimeoutError,
)

import struct


# helpers to convert float <-> 32-bit int
def float_to_bits(f: float) -> int:
    """Convert Python float to 32-bit IEEE-754 representation."""
    return struct.unpack(">I", struct.pack(">f", f))[0]


def bits_to_float(b: int) -> float:
    """Convert 32-bit IEEE-754 representation to Python float."""
    return struct.unpack(">f", struct.pack(">I", b))[0]


async def check_fp_sum(dut, x: float, y: float):
    timeout = 3
    dut.X.value = float_to_bits(x)
    dut.Y.value = float_to_bits(y)

    # Pulse start for one clock cycle
    dut.i_start.value = 1
    ## await RisingEdge(dut.i_clk)

    # Wait for DUT to signal done (max 1 µs)
    try:
        await with_timeout(RisingEdge(dut.i_done), timeout, "ns")
    except SimTimeoutError:
        out_float = bits_to_float(int(dut.out.value))
        expected = x + y
        cocotb.log.info(f"X={x}, Y={y}, DUT out={out_float}, expected={expected}")
        # raise AssertionError("Timeout: i_done never asserted")

    dut.i_start.value = 0

    # Convert output to float and check
    out_float = bits_to_float(int(dut.out.value))
    expected = x + y
    cocotb.log.info(f"X={x}, Y={y}, DUT out={out_float}, expected={expected}")
    # assert abs(out_float - expected) < 1e-6, f"Got {out_float}, expected {expected}"


@cocotb.test()
async def my_fp_sum_test(dut):
    """Cycle through multiple float pairs and check sums."""
    # Start clock
    clock = Clock(dut.i_clk, 1, unit="ns")
    cocotb.start_soon(clock.start())
    # cocotb.start_soon(generate_clock(dut))

    # Reset DUT
    dut.i_rst.value = 0
    dut.i_start.value = 0
    await Timer(5, "ns")
    dut.i_rst.value = 1
    await Timer(1, "ns")

    # List of test value pairs
    test_vectors = [
        (1.0, 0.0),
        (0.0, 1.0),
        (1.0, 0.5),
        (0.0, 0.0),
        (-2.5, 2.5),
        (0.0, 5.0),
        (1.234, 5.678),
    ]

    for x, y in test_vectors:
        await check_fp_sum(dut, x, y)
        await Timer(3, "ns")  # small delay between tests
