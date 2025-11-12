# test_my_design.py (extended)

from decimal import FloatOperation
import cocotb
import numpy as np
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


async def check_fp_mul(dut, x: float, y: float):
    # TODO: this is a lazy copy of sum func
    timeout = 3
    dut.X.value = float_to_bits(x)
    dut.Y.value = float_to_bits(y)

    # Start signal pulse
    dut.i_start.value = 1
    await RisingEdge(dut.i_clk)
    dut.i_start.value = 0

    # Wait for done
    try:
        await with_timeout(RisingEdge(dut.o_done), timeout, "ns")
    except SimTimeoutError:
        out_float = bits_to_float(int(dut.out.value))
        expected = np.float32(x) * np.float32(y)
        cocotb.log.info(
            f"Timeout: X={x}, Y={y}, DUT out={out_float}, expected={expected}"
        )
        raise AssertionError("Timeout: o_done never asserted")

    # Compare results
    out_float = bits_to_float(int(dut.out.value))
    expected = np.float32(x) * np.float32(y)
    cocotb.log.info(f"X={x}, Y={y}, DUT out={out_float}, expected={expected}")

    # Handle inf / nan safely
    if np.isnan(expected):
        assert np.isnan(out_float), f"Expected NaN, got {out_float}"
    elif np.isinf(expected):
        assert np.isinf(out_float) and np.sign(out_float) == np.sign(expected), (
            f"Expected {expected}, got {out_float}"
        )
    else:
        assert abs(out_float - expected) == 0.0, (
            f"XXXXX\nGot {out_float}, expected {expected}"
        )


async def check_fp_sum(dut, x: float, y: float):
    timeout = 3
    dut.X.value = float_to_bits(x)
    dut.Y.value = float_to_bits(y)

    # Start signal pulse
    dut.i_start.value = 1
    await RisingEdge(dut.i_clk)
    dut.i_start.value = 0

    # Wait for done
    try:
        await with_timeout(RisingEdge(dut.o_done), timeout, "ns")
    except SimTimeoutError:
        out_float = bits_to_float(int(dut.out.value))
        expected = np.float32(x) + np.float32(y)
        cocotb.log.info(
            f"Timeout: X={x}, Y={y}, DUT out={out_float}, expected={expected}"
        )
        raise AssertionError("Timeout: o_done never asserted")

    # Compare results
    out_float = bits_to_float(int(dut.out.value))
    expected = np.float32(x) + np.float32(y)
    cocotb.log.info(f"X={x}, Y={y}, DUT out={out_float}, expected={expected}")

    # Handle inf / nan safely
    if np.isnan(expected):
        assert np.isnan(out_float), f"Expected NaN, got {out_float}"
    elif np.isinf(expected):
        assert np.isinf(out_float) and np.sign(out_float) == np.sign(expected), (
            f"Expected {expected}, got {out_float}"
        )
    else:
        assert abs(out_float - expected) == 0.0, (
            f"XXXXX\nGot {out_float}, expected {expected}"
        )


test_vectors = [
    # Core arithmetic
    (1.0, 0.0),
    (0.0, 1.0),
    (0.0, 0.0),
    (1.0, 1.0),
    (2.0, 2.0),
    (1.0, -1.0),
    (-1.0, 1.0),
    (-1.0, -1.0),
    (1.0, 0.5),
    (0.5, 0.25),
    (1.5, 0.5),
    # Exponent alignment
    (1.0, 1e-10),
    (1e-10, 1.0),
    (1e10, 1.0),
    (1.0, 1e10),
    (3.14e-20, 2.71e20),
    # Sign edge cases
    (-2.5, 2.5),
    (2.5, -2.5),
    (-5.0, 3.0),
    (3.0, -5.0),
    (-0.0, 1.0),
    (1.0, -0.0),
    (-1.0, 0.0),
    (0.0, -1.0),
    # Overflow / underflow / subnormals
    (3.4e38, 3.4e38),
    (-3.4e38, -3.4e38),
    (1e-38, 1e-38),
    (1e-45, 1e-45),
    (1e-45, -1e-45),
    # Precision / rounding
    (1.0000001, 1.0000001),
    (1.0000001, -1.0000000),
    (0.9999999, 0.0000001),
    (16777216.0, 1.0),
    (1.234, 5.678),
    (-1234.567, 1234.567),
    # Exact cancellation / large magnitude diff
    (1.234e20, -1.234e20),
    (3.4e38, -3.4e38),
    # Infinity / NaN behavior
    (float("inf"), 1.0),
    (-float("inf"), 1.0),
    (float("inf"), -float("inf")),
    (float("nan"), 1.0),
    (1.0, float("nan")),
    (float("nan"), float("nan")),
]


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

    dut.i_sel.value = 1
    dut.i_rst.value = 1  # rst is active low!
    await Timer(5, "ns")

    for x, y in test_vectors:
        await check_fp_sum(dut, x, y)
        await Timer(5, "ns")  # small delay between tests


@cocotb.test()
async def my_fp_mul_test(dut):
    # Start clock
    clock = Clock(dut.i_clk, 1, unit="ns")
    cocotb.start_soon(clock.start())
    # cocotb.start_soon(generate_clock(dut))

    # Reset DUT
    dut.i_rst.value = 0
    dut.i_start.value = 0
    await Timer(5, "ns")

    dut.i_sel.value = 2
    dut.i_rst.value = 1  # rst is active low!
    await Timer(5, "ns")

    for x, y in test_vectors:
        await check_fp_mul(dut, x, y)
        await Timer(5, "ns")  # small delay between tests
