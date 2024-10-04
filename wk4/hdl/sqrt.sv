module sqrt #
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
		output logic signed [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
		output logic [(C_M00_AXIS_TDATA_WIDTH/8)-1: 0] m00_axis_tstrb
	);


  logic [15 : 0] left_pipelined [15:0];
  logic [15 : 0] right_pipelined [15:0];
  logic [15 : 0] mid_pipelined [15:0];
  logic [31 : 0] mid_squared_pipelined [15:0];
  logic [C_M00_AXIS_TDATA_WIDTH-1 : 0] search_for_pipelined [15:0];
  logic valid_pipelined [15:0];
  logic last_pipelined [15:0];

  assign s00_axis_tready = m00_axis_tready;
  always_comb begin
      if (mid_squared_pipelined[15] == search_for_pipelined[15]) begin
          m00_axis_tdata = mid_pipelined[15];
      end else begin
          m00_axis_tdata = right_pipelined[15];
      end
  end
  assign m00_axis_tstrb = s00_axis_tstrb;
  assign m00_axis_tlast = last_pipelined[15];
  assign m00_axis_tvalid = valid_pipelined[15];

  always_ff @(posedge s00_axis_aclk) begin
      if (s00_axis_aresetn == 0) begin
          for (int j = 0; j < 16; j++) begin
              valid_pipelined[j] = 0;
              last_pipelined[j] = 0;
              search_for_pipelined[j] = 0;
              mid_squared_pipelined[j] = 0;
              mid_pipelined[j] = 0;
              right_pipelined[j] = 0;
              left_pipelined[j] = 0;
          end
      end else begin
          if (m00_axis_tready) begin
              left_pipelined[0] <= 1;
              right_pipelined[0] <= 16'hffff;
              mid_pipelined[0] <= 16'h8000;
              mid_squared_pipelined[0] <= 32'h4000_0000;
              search_for_pipelined[0] <= s00_axis_tdata;
              valid_pipelined[0] <= s00_axis_tvalid;
              last_pipelined[0] <= s00_axis_tlast;
              for (int i = 1; i < 16; i++) begin
                  if (left_pipelined[i-1] <= right_pipelined[i-1]) begin
                    if (search_for_pipelined[i-1] > mid_squared_pipelined[i-1]) begin
                        left_pipelined[i] <= mid_pipelined[i-1]+1;
                        right_pipelined[i] <= right_pipelined[i-1];
                        mid_pipelined[i] <= (mid_pipelined[i-1]+1) + ((right_pipelined[i-1] - (mid_pipelined[i-1]+1))>>1);
                        mid_squared_pipelined[i] <= ((mid_pipelined[i-1]+1) + ((right_pipelined[i-1] - (mid_pipelined[i-1]+1))>>1))*((mid_pipelined[i-1]+1) + ((right_pipelined[i-1] - (mid_pipelined[i-1]+1))>>1));
                    end else if (search_for_pipelined[i-1] < mid_squared_pipelined[i-1]) begin
                        left_pipelined[i] <= left_pipelined[i-1];
                        right_pipelined[i] <= mid_pipelined[i-1]-1;
                        mid_pipelined[i] <= left_pipelined[i-1] + (((mid_pipelined[i-1]-1) - left_pipelined[i-1])>>1);
                        mid_squared_pipelined[i] <= (left_pipelined[i-1] + (((mid_pipelined[i-1]-1) - left_pipelined[i-1])>>1))*(left_pipelined[i-1] + (((mid_pipelined[i-1]-1) - left_pipelined[i-1])>>1)); 
                    end else begin
                        mid_squared_pipelined[i] <= mid_squared_pipelined[i-1];
                        left_pipelined[i] <= left_pipelined[i-1];
                        right_pipelined[i] <= mid_pipelined[i-1];
                        mid_pipelined[i] <= mid_pipelined[i-1];
                    end 
                  end else begin
                    right_pipelined[i] <= right_pipelined[i-1];
                  end
                  search_for_pipelined[i] <= search_for_pipelined[i-1];
                  last_pipelined[i] <= last_pipelined[i-1];
                  valid_pipelined[i] <= valid_pipelined[i-1];
              end
          end
      end
  end
 
endmodule
