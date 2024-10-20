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


from demodulator_tester import Tester

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
    tester = Tester(dut)
#    tester.start()
    cocotb.start_soon(Clock(dut.s00_axis_aclk, 10, units="ns").start())
    await set_ready(dut,1)
    await reset(dut.s00_axis_aclk, dut.s00_axis_aresetn,2,0)
    #feed the driver:
    #for i in range(50):
    #  data = {'type':'single', "contents":{"data": random.randint(1,2**31),"last":0,"strb":15}}
    #  tester.input_driver.append(data)
    #data = {'type':'burst', "contents":{"data": np.array(20*[0]+[1]+30*[0]+[-2]+59*[0])}}
    #data = {'type':'burst', "contents":{"data": np.array(list(range(100)))}}

    fs = 100e6 #sampling frequency
    n = 1024  #number of samples
    T = n*1.0/fs #total time
    fc = 10e6 #carrier frequency
    cps = 8 #cycles per symbol
    sps = fs/fc*cps #samples per symbol
    t = np.linspace(0, T, n, endpoint=False) #time vector in seconds
    ns = np.linspace(0,fs,n,endpoint=False) #sample vector
    phase_noise = np.arange(len(t))/len(t) * 6.28 #phase ranges from 0 to 2pi over the duration
    general_noise = np.random.randn(len(t))*0
    samples = 500*np.cos(10e6*2*np.pi*t+phase_noise +0) + general_noise
    samples = samples.astype(np.int32)

    print(samples, type(samples))  
    data = {'type':'burst', "contents":{"data": samples}}
    tester.input_driver.append(data)
    await ClockCycles(dut.s00_axis_aclk, 2000)
    await set_ready(dut,0)
    await ClockCycles(dut.s00_axis_aclk, 300)
    await set_ready(dut,1)
    await ClockCycles(dut.s00_axis_aclk, 10)
    await set_ready(dut,0)
    await ClockCycles(dut.s00_axis_aclk, 10)
    await set_ready(dut,1)
    await ClockCycles(dut.s00_axis_aclk, 500)
#    print(tester.output_mon.seen, len(tester.output_mon.seen))
#    print(tester.input_mon.seen, len(tester.input_mon.seen))
    # access internal elements as needed (or do them inside of the class)
    tester.plot_result(1024)
#    print(tester.input_mon.transactions)
#    print(tester.output_mon.transactions)
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
    sources = [proj_path / "hdl" / "demodulator.sv",
               proj_path / "hdl" / "mixer.sv",
               proj_path / "hdl" / "fir.sv",
               proj_path / "hdl" / "fir_tap.sv",
               proj_path / "hdl" / "sine_generator.sv",] #grow/modify this as needed.
    build_test_args = ["-Wall"]#,"COCOTB_RESOLVE_X=ZEROS"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="demodulator",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="demodulator",
        test_module="test_demodulator",
        test_args=run_test_args,
        waves=True,
        plusargs=[]
    )
 
if __name__ == "__main__":
    counter_runner()
