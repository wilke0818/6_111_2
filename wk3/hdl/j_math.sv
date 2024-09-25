module j_math #
	(
		parameter integer C_S00_AXIS_TDATA_WIDTH	= 32,
		parameter integer C_M00_AXIS_TDATA_WIDTH	= 32
	)
	(
		// Ports of Axi Slave Bus Interface S00_AXIS
		input wire  s00_axis_aclk, s00_axis_aresetn,
		input wire  s00_axis_tlast, s00_axis_tvalid,
		input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
		input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1: 0] s00_axis_tstrb,
		output logic  s00_axis_tready,
 
		// Ports of Axi Master Bus Interface M00_AXIS
		input wire  m00_axis_aclk, m00_axis_aresetn,
		input wire  m00_axis_tready,
		output logic  m00_axis_tvalid, m00_axis_tlast,
		output logic [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
		output logic [(C_M00_AXIS_TDATA_WIDTH/8)-1: 0] m00_axis_tstrb
	);
 
  logic m00_axis_tvalid_reg, m00_axis_tlast_reg;
  logic [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata_reg;
  logic [(C_M00_AXIS_TDATA_WIDTH/8)-1: 0] m00_axis_tstrb_reg;
 
  assign m00_axis_tvalid = m00_axis_tvalid_reg;
  assign m00_axis_tlast = m00_axis_tlast_reg;
  assign m00_axis_tdata = m00_axis_tdata_reg;
  assign m00_axis_tstrb = m00_axis_tstrb_reg;
  //change...only if there is a slot for new data to go into:
  //this should avoid deadlock.
  assign s00_axis_tready = m00_axis_tready || ~m00_axis_tvalid;
 
  always_ff @(posedge s00_axis_aclk)begin
    if (s00_axis_aresetn==0)begin
      m00_axis_tvalid_reg <= 0;
      m00_axis_tlast_reg <= 0;
      m00_axis_tdata_reg <= 0;
      m00_axis_tstrb_reg <= 0;
    end else begin
      //only if there is room in either our registers...
      //or downstream consumer/slave do we update.
      if (s00_axis_tready)begin
        m00_axis_tvalid_reg <= s00_axis_tvalid;
        m00_axis_tlast_reg <= s00_axis_tlast;
        m00_axis_tdata_reg <=3*s00_axis_tdata+10000;
        m00_axis_tstrb_reg <= s00_axis_tstrb;
      end
    end
  end
endmodule
