module split_square_sum #
	(
		parameter integer C_S00_AXIS_TDATA_WIDTH	= 32,
		parameter integer C_M00_AXIS_TDATA_WIDTH	= 32
	)
	(
		// Ports of Axi Slave Bus Interface S00_AXIS
		input wire  s00_axis_aclk, s00_axis_aresetn,
		input wire  s00_axis_tlast, s00_axis_tvalid,
		input wire signed [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
		input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1: 0] s00_axis_tstrb,
		output logic  s00_axis_tready,
 
		// Ports of Axi Master Bus Interface M00_AXIS
		input wire  m00_axis_aclk, m00_axis_aresetn,
		input wire  m00_axis_tready,
		output logic  m00_axis_tvalid, m00_axis_tlast,
		output logic [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
		output logic [(C_M00_AXIS_TDATA_WIDTH/8)-1: 0] m00_axis_tstrb
	);

  logic signed [15:0] upper_data;
  logic signed [15:0] lower_data;
  assign s00_axis_tready = m00_axis_tready;

  assign upper_data = s00_axis_tdata[31:16];
  assign lower_data = s00_axis_tdata[15:0];

  logic [(C_S00_AXIS_TDATA_WIDTH/8)-1: 0] strb_pass;
  logic tlast_pass;
  logic tvalid_pass;
  logic signed [C_S00_AXIS_TDATA_WIDTH-1 : 0] upper_squared;
  logic signed [C_S00_AXIS_TDATA_WIDTH-1 : 0] lower_squared;

  always_ff @(posedge s00_axis_aclk) begin
    if (s00_axis_aresetn == 0) begin
      tlast_pass <= 0;
      tvalid_pass <= 0;
      upper_squared <= 0;
      lower_squared <= 0;
      strb_pass <= 0;
      m00_axis_tvalid <= 0;
      m00_axis_tstrb <= 0;
      m00_axis_tdata <= 0;
      m00_axis_tlast <= 0;
    end else begin
      if (m00_axis_tready) begin
          if (s00_axis_tvalid) begin
            upper_squared <= upper_data*upper_data;//s00_axis_tdata[31:16] * s00_axis_tdata[31:16];
            lower_squared <= lower_data*lower_data;//s00_axis_tdata[15:0] * s00_axis_tdata[15:0];
            tlast_pass <= s00_axis_tlast;
            tvalid_pass <= 1'b1;
            strb_pass <= s00_axis_tstrb;
          end else begin
              tvalid_pass <= 0;
          end
          if (tvalid_pass) begin
              m00_axis_tvalid <= 1'b1;
              m00_axis_tdata <= upper_squared+lower_squared;
              m00_axis_tlast <= tlast_pass;
              m00_axis_tstrb <= strb_pass;
          end else begin
              m00_axis_tvalid <= 1'b0;
          end
      end else begin
         m00_axis_tvalid <= 0;
     end 
    end
  end
endmodule
