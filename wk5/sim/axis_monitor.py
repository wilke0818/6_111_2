from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly,with_timeout, First, Join
from cocotb_bus.monitors import Monitor
from cocotb_bus.monitors import BusMonitor

class AXISMonitor(BusMonitor):
    """
    monitors axi streaming bus
    """
    transactions = 0
    def __init__(self, dut, name, clk, callback=None, event=None):
        self._signals = ['axis_tvalid','axis_tready','axis_tlast','axis_tdata','axis_tstrb']
        BusMonitor.__init__(self, dut, name, clk,callback=callback,event=event)
        self.clock = clk
        self.transactions = 0
        self.seen = []


    async def _monitor_recv(self):
        """
        Monitor receiver
        """
        rising_edge = RisingEdge(self.clock) # make these coroutines once and reuse
        falling_edge = FallingEdge(self.clock)
        read_only = ReadOnly() #This is
        while True:
            await rising_edge
            await falling_edge #sometimes see in AXI shit
            await read_only  #readonly (the postline)
            valid = self.bus.axis_tvalid.value
            ready = self.bus.axis_tready.value
            last = self.bus.axis_tlast.value
            data = self.bus.axis_tdata.value
            #print(data, type(data))
            #self.seen.append(data.signed_integer)
            if valid and ready:
              self.seen.append(data)
              self.transactions += 1
              thing = dict(data=data,last=last,name=self.name,count=self.transactions)
#              print(thing)
              self._recv(thing)
