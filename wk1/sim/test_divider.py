import cocotb
import os
import random
import sys
import logging
from pathlib import Path
from cocotb.triggers import Timer
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner

import numpy as np
def divider_model(dividend:int, divisor:int):
    x = np.uint32(dividend)
    y = np.uint32(divisor)
    return dict(quotient=x//y, remainder=x%y)

def generate_random():
    # generates [0, high) so will be 0 to 2**32-1
    return np.random.randint(2**32)


async def generate_clock(clock_wire):
	while True: # repeat forever
		clock_wire.value = 0
		await Timer(5,units="ns")
		clock_wire.value = 1
		await Timer(5,units="ns")

@cocotb.test()
async def first_test(dut):
    """First cocotb test?"""
    await cocotb.start( generate_clock( dut.clk_in ) ) #launches clock
    dut.rst_in.value = 1;
    
    await Timer(5, "ns")
    await Timer(5, "ns")
    dut.rst_in.value = 0; #rst is off...let it run
    for i in range(100):
        dividend = generate_random()
        divisor = generate_random()
        #...inside a larger looping test where dividend and divisor are being fed
        expected = divider_model(dividend, divisor)
        dut.dividend_in.value = dividend
        dut.divisor_in.value = divisor
        dut.data_valid_in.value = 1

        await Timer(10, 'ns')
        dut.data_valid_in.value = 0

        while not dut.data_valid_out.value:
            await Timer(10, 'ns')

        # some stuff to figure out....wait.....
        eq = expected['quotient']
        er = expected['remainder']
        aq = dut.quotient_out.value.integer
        ar = dut.remainder_out.value.integer

        dut._log.info(f"Input: {dividend},{divisor}. Expected: {eq}, {er}. Actual {aq}, {ar}")
        assert eq==aq and er==ar, f"Error! at Input: {dividend},{divisor}. Expected: {eq}, {er}. Actual {aq}, {ar}"
 
        # continue with test
        await Timer(10, 'ns')
    dut._log.info(f"Done")

"""the code below should largely remain unchanged in structure, though the specific files and things
specified should get updated for different simulations.
"""
 
def divider_runner():
    """Simulate the divider using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "divider.sv"] #grow/modify this as needed.
    build_test_args = ["-Wall"]#,"COCOTB_RESOLVE_X=ZEROS"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="divider",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="divider",
        test_module="test_divider",
        test_args=run_test_args,
        waves=True
    )
 
if __name__ == "__main__":
    divider_runner()
