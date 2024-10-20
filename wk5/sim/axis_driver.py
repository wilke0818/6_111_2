from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly,with_timeout, First, Join
from cocotb_bus.drivers import BusDriver

class AXISDriver(BusDriver):
  def __init__(self, dut, name, clk):
    self._signals = ['axis_tvalid', 'axis_tready', 'axis_tlast', 'axis_tdata','axis_tstrb']
    BusDriver.__init__(self, dut, name, clk)
    self.clock = clk
    self.bus.axis_tdata.value = 0
    self.bus.axis_tstrb.value = 0
    self.bus.axis_tlast.value = 0
    self.bus.axis_tvalid.value = 0

  async def _driver_send(self, value, sync=True):

    rising_edge = RisingEdge(self.clock) # make these coroutines once and reuse
    falling_edge = FallingEdge(self.clock)
    read_only = ReadOnly() #This is

      
#    await rising_edge
    await falling_edge
    if value['type'] == 'single':
        self.bus.axis_tdata.value = value['contents']['data']
        self.bus.axis_tlast.value = value['contents']['last']
        self.bus.axis_tstrb.value = value['contents']['strb']
        self.bus.axis_tvalid.value = 1
        await rising_edge
        while self.bus.axis_tready.value != 1:
            await ClockCycles(self.clock, 1)
        await falling_edge
        self.bus.axis_tvalid.value = 0
    elif value['type'] == 'burst':
        data_idx = 0
        data = value['contents']['data']
        amount_of_data = len(value['contents']['data'])

        while data_idx < amount_of_data:
            self.bus.axis_tdata.value = int(data[data_idx])
            self.bus.axis_tlast.value = int(data_idx == amount_of_data -1)
            self.bus.axis_tstrb.value = 15
            self.bus.axis_tvalid.value = 1
        #while data_idx < amount_of_data:
            await rising_edge
            while self.bus.axis_tready.value != 1:
                await ClockCycles(self.clock, 1)
            await falling_edge
            
            data_idx += 1
        self.bus.axis_tvalid.value = 0
    else:
        raise ValueError()
