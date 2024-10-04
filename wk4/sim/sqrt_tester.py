from cocotb.handle import SimHandleBase
import logging
from axis_monitor import AXISMonitor
from axis_driver import AXISDriver
from cocotb_bus.scoreboard import Scoreboard


class SqrtTester:
    """
    Checker of a split square sum instance
    Args
      dut_entity: handle to an instance of split-square-sum
    """
    def __init__(self, dut_entity: SimHandleBase, debug=False):
        self.dut = dut_entity
        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.ERROR)
        self.input_mon = AXISMonitor(self.dut,'s00',self.dut.s00_axis_aclk, callback=self.model)
        self.output_mon = AXISMonitor(self.dut,'m00',self.dut.s00_axis_aclk)
        self.input_driver = AXISDriver(self.dut,'s00',self.dut.s00_axis_aclk)
        self._checker = None
        self.calcs_sent = 0
        # Create a scoreboard on the stream_out bus
        self.expected_output = [] #contains list of expected outputs (Growing)
        self.scoreboard = Scoreboard(self.dut)#, fail_immediately=False)
        self.scoreboard.add_interface(self.output_mon, self.expected_output, compare_fn=self.compare)
 
    def start(self) -> None:
        """Starts everything"""
        if self._checker is not None:
            raise RuntimeError("Monitor already started")
        self.input_mon.start()
        self.output_mon.start()
        self.input_driver.start()
 
    def stop(self) -> None:
        """Stops everything"""
        if self._checker is None:
            raise RuntimeError("Monitor never started")
        self.input_mon.stop()
        self.output_mon.stop()
        self.input_driver.stop()
 
    def model(self, transaction):
      #define a model here
      result = transaction.copy()
      #data = transaction['data'].signed_integer#.to_bytes(4,byteorder='big', signed=True)
      
#      print('data', transaction['data'])
      #bottom = transaction['data'][16:31]
      #top = transaction['data'][0:15]
#      print(f"bottom {bottom} is {bottom.signed_integer}")
#      print(f"top {top} is {top.signed_integer}")
      #result['data'] = bottom.signed_integer**2 + top.signed_integer**2
      #(transaction['data']>>16)**2+((transaction['data']<<16)>>16)**2
      result['data'] = int(transaction['data']**0.5)
      self.expected_output.append(result)

    def compare(self,got):
#        print(got)
#        print(exp)
        for i, output in enumerate(self.expected_output):
            if output['count'] == got['count']:
                break
        exp = self.expected_output.pop(i)
        #exp = self.expected_output[-1]
        print(f"got {int(got['data'])} and expected {exp['data']}")
        assert abs(int(got['data']) -  exp['data']) <= 1, f"got {int(got['data'])} and expected {exp['data']}"
