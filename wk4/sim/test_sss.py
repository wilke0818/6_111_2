import cocotb
import os
import random
import sys
import logging
from pathlib import Path
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly,with_timeout, First, Join
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner
from cocotb.clock import Clock

from cocotb_bus.bus import Bus
from cocotb_bus.drivers import BusDriver
from cocotb_bus.monitors import Monitor
from cocotb_bus.monitors import BusMonitor
import numpy as np

from axis_monitor import AXISMonitor
from axis_driver import AXISDriver


from sss_tester import SSSTester

async def reset(clk, rst_in, cycles, value):
    await RisingEdge(clk)
    await FallingEdge(clk)
    rst_in.value = value
    await ClockCycles(clk, cycles)
    rst_in.value = ~value

async def set_ready(dut, val):
    await FallingEdge(dut.s00_axis_aclk)
    dut.m00_axis_tready.value = val


@cocotb.test()
async def test_a(dut):
    """cocotb test for square rooter"""
    tester = SSSTester(dut)
#    tester.start()
    cocotb.start_soon(Clock(dut.s00_axis_aclk, 10, units="ns").start())
    await set_ready(dut,1)
    await reset(dut.s00_axis_aclk, dut.s00_axis_aresetn,2,0)
    #feed the driver:
    for i in range(50):
      data = {'type':'single', "contents":{"data": random.randint(1,2**31),"last":0,"strb":15}}
      tester.input_driver.append(data)
    data = {'type':'burst', "contents":{"data": np.array(20*[0]+[1]+30*[0]+[-2]+59*[0])}}
    #data = {'type':'burst', "contents":{"data": np.array(list(range(100)))}}
    tester.input_driver.append(data)
    await ClockCycles(dut.s00_axis_aclk, 500)
    await set_ready(dut,0)
    await ClockCycles(dut.s00_axis_aclk, 300)
    await set_ready(dut,1)
    await ClockCycles(dut.s00_axis_aclk, 10)
    await set_ready(dut,0)
    await ClockCycles(dut.s00_axis_aclk, 10)
    await set_ready(dut,1)
    await ClockCycles(dut.s00_axis_aclk, 300)
    # access internal elements as needed (or do them inside of the class)
    assert tester.input_mon.transactions==tester.output_mon.transactions, f"Transaction Count doesn't match! :/"
    raise tester.scoreboard.result


"""the code below should largely remain unchanged in structure, though the specific files and things
specified should get updated for different simulations.
"""
 
def counter_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "split_square_sum.sv"] #grow/modify this as needed.
    build_test_args = ["-Wall"]#,"COCOTB_RESOLVE_X=ZEROS"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="split_square_sum",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="split_square_sum",
        test_module="test_sss",
        test_args=run_test_args,
        waves=True,
        plusargs=[]
    )
 
if __name__ == "__main__":
    counter_runner()
