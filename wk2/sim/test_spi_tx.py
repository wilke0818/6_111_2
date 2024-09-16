import cocotb
import os
import random
import sys
import logging
from pathlib import Path
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly,with_timeout, First, Join
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner
 
 
async def generate_clock(clock_wire):
	while True: # repeat forever
		clock_wire.value = 0
		await Timer(5,units="ns")
		clock_wire.value = 1
		await Timer(5,units="ns")


async def drive_data_in(dut, value):
    while dut.busy_out.value != 0:
        await RisingEdge(dut.clk_in)
    dut.trigger_in.value = 1
    dut.data_in.value = value
    await ClockCycles(dut.clk_in, 1)
    dut.trigger_in.value = 0

async def drive_reset(dut):
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 2)
    dut.rst_in.value = 0

async def model_spi_device(dut, received_messages):
    while True:
        await FallingEdge(dut.chip_sel_out)
        tmp = ''
        clk_count = 0

        while dut.chip_sel_out.value == 0:
            finish = RisingEdge(dut.chip_sel_out)
            one_clk = RisingEdge(dut.chip_clk_out)
            triggered = await First(finish, one_clk)
            if triggered == one_clk:
              clk_count += 1
              tmp += str(dut.chip_data_out.value)
        received_messages.append(tmp)
        assert clk_count == dut.DATA_WIDTH.value

async def assert_spi_clock(dut):
    
    while True:
        
        await FallingEdge(dut.chip_sel_out)
        while dut.chip_sel_out == 0:
            await RisingEdge(dut.chip_clk_out)
            start_clk = gst('ns')
            await RisingEdge(dut.chip_clk_out)
            if dut.rst_in.value == 0:
                new_clk = gst('ns')
                assert int(new_clk) - int(start_clk) == 10*dut.DATA_CLK_PERIOD.value


@cocotb.test()
async def first_test(dut):
    """First cocotb test?"""
    await cocotb.start( generate_clock( dut.clk_in ) ) #launches clock
    await drive_reset(dut)
    messages = []
    cocotb.start_soon(model_spi_device(dut,messages))
    cocotb.start_soon(assert_spi_clock(dut))
   
    await drive_data_in(dut, 24)
    await FallingEdge(dut.busy_out)
    await ClockCycles(dut.clk_in, 5)

    print(messages)
    assert len(messages) == 1, f"messages was {messages} and expected at least one value"
    assert messages[0] == '00011000', f"messages was {messages} and expected first value to be binary 24"



@cocotb.test()
async def multi_test(dut):
    """First cocotb test?"""
    await cocotb.start( generate_clock( dut.clk_in ) ) #launches clock
    await drive_reset(dut)
    messages = []
    cocotb.start_soon(model_spi_device(dut,messages))
    cocotb.start_soon(assert_spi_clock(dut))
   
    await drive_data_in(dut, 24)
    await FallingEdge(dut.busy_out)
    await drive_data_in(dut, 25)
    await FallingEdge(dut.busy_out)
    await drive_data_in(dut, 26)
    await FallingEdge(dut.busy_out)
    await drive_data_in(dut, 27)
    await FallingEdge(dut.busy_out)
    await ClockCycles(dut.clk_in, 5)

    print(messages)
    assert len(messages) == 4, f"messages was {messages} and expected at least one value"
    assert messages[0] == '00011000'
    assert messages[1] == '00011001'
    assert messages[2] == '00011010'
    assert messages[3] == '00011011'





"""the code below should largely remain unchanged in structure, though the specific files and things
specified should get updated for different simulations.
"""
 
def counter_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "spi_tx.sv"] #grow/modify this as needed.
    build_test_args = ["-Wall"]#,"COCOTB_RESOLVE_X=ZEROS"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="spi_tx",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="spi_tx",
        test_module="test_spi_tx",
        test_args=run_test_args,
        waves=True
    )
 
if __name__ == "__main__":
    counter_runner()
