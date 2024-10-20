module mixer #
  (
    parameter integer C_S00_AXIS_TDATA_WIDTH  = 32,
    parameter integer C_M00_AXIS_TDATA_WIDTH  = 32,
    parameter IS_Q_NOT_I = 0
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

  logic signed [15:0] sine_output;
  logic signed [31 : 0] mixed;

  logic signed [15:0] data_in;
  assign data_in = s00_axis_tdata[15:0];

  generate
    if (IS_Q_NOT_I) begin
      sine_generator sin_inst(
          .clk_in(s00_axis_aclk),
          .rst_in(~s00_axis_aresetn),
          .step_in(1'b1),
          .amp_out(sine_output)
      );
    end else begin
      sine_generator #(.PHASE(0)) sin_inst(
          .clk_in(s00_axis_aclk),
          .rst_in(~s00_axis_aresetn),
          .step_in(1'b1),
          .amp_out(sine_output)
      );
    end
  endgenerate

  //assign s00_axis_tready = m00_axis_tready;
  //assign m00_axis_tlast = s00_axis_tlast;
  //assign m00_axis_tvalid = s00_axis_tvalid;
  assign m00_axis_tstrb = 16'hFFFF;

  assign m00_axis_tdata = mixed;

  always_ff @(posedge s00_axis_aclk) begin
      if (s00_axis_aresetn == 0) begin
        mixed <= 0;
        m00_axis_tvalid <= 0;
        m00_axis_tlast <= 0;
        s00_axis_tready <= 0;
      end else begin
          if (m00_axis_tready && s00_axis_tvalid) begin
              mixed <= sine_output * data_in;
          end
          s00_axis_tready <= m00_axis_tready;
          m00_axis_tlast <= s00_axis_tlast;
          m00_axis_tvalid <= s00_axis_tvalid;
      end
  end

 endmodule
