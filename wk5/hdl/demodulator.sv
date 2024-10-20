module demodulator #
  (
    parameter integer C_S00_AXIS_TDATA_WIDTH  = 32,
    parameter integer C_M00_AXIS_TDATA_WIDTH  = 32
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

  
  logic i_mixer_ready_out, i_fir_ready_out;
  logic signed [C_M00_AXIS_TDATA_WIDTH-1 : 0] i_fir_data_in;
  logic signed [C_M00_AXIS_TDATA_WIDTH-1:0] i_fir_data_out;
  logic [(C_M00_AXIS_TDATA_WIDTH/8)-1: 0] i_fir_strb_in;
  logic [(C_M00_AXIS_TDATA_WIDTH/8)-1: 0] i_fir_strb_out;
  logic i_fir_valid_in, i_fir_last_in;
  logic i_fir_valid_out, i_fir_last_out;

  logic q_mixer_ready_out, q_fir_ready_out;
  logic signed [C_M00_AXIS_TDATA_WIDTH-1 : 0] q_fir_data_in;
  logic signed [C_M00_AXIS_TDATA_WIDTH-1:0] q_fir_data_out;
  logic [(C_M00_AXIS_TDATA_WIDTH/8)-1: 0] q_fir_strb_in;
  logic [(C_M00_AXIS_TDATA_WIDTH/8)-1: 0] q_fir_strb_out;
  logic q_fir_valid_in, q_fir_last_in;
  logic q_fir_valid_out, q_fir_last_out;

  assign s00_axis_tready = m00_axis_tready;


  assign m00_axis_tdata = {i_fir_data_out[31:16], q_fir_data_out[31:16]};
  assign m00_axis_tlast = q_fir_last_out;
  assign m00_axis_tvalid = q_fir_valid_out;
  assign m00_axis_tstrb = q_fir_strb_out;
  //assign s00_axis_tready = q_mixer_ready_out;

  mixer 
  #(.C_S00_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH),
      .C_M00_AXIS_TDATA_WIDTH(C_M00_AXIS_TDATA_WIDTH),
      .IS_Q_NOT_I(0))
  i_mixer
  (
  // Ports of Axi Slave Bus Interface S00_AXIS
  .s00_axis_aclk(s00_axis_aclk),
  .s00_axis_aresetn(s00_axis_aresetn),
  .s00_axis_tlast(s00_axis_tlast), 
  .s00_axis_tvalid(s00_axis_tvalid),
  .s00_axis_tdata(s00_axis_tdata),
  .s00_axis_tstrb(s00_axis_tstrb),
  .s00_axis_tready(i_mixer_ready_out),

  // Ports of Axi Master Bus Interface M00_AXIS
  .m00_axis_aclk(m00_axis_aclk),
  .m00_axis_aresetn(m00_axis_aresetn),
  .m00_axis_tready(m00_axis_tready),
  .m00_axis_tvalid(i_fir_valid_in), 
  .m00_axis_tlast(i_fir_last_in),
  .m00_axis_tdata(i_fir_data_in),
  .m00_axis_tstrb(i_fir_strb_in)
  );


  fir_15 #
  (
    .C_S00_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH),
    .C_M00_AXIS_TDATA_WIDTH(C_M00_AXIS_TDATA_WIDTH)
  )
  i_fir
  (
  // Ports of Axi Slave Bus Interface S00_AXIS
  .s00_axis_aclk(s00_axis_aclk),
  .s00_axis_aresetn(s00_axis_aresetn),
  .s00_axis_tlast(i_fir_last_in), 
  .s00_axis_tvalid(i_fir_valid_in),
  .s00_axis_tdata(i_fir_data_in),
  .s00_axis_tstrb(i_fir_strb_in),
  .s00_axis_tready(i_fir_ready_out),

  // Ports of Axi Master Bus Interface M00_AXIS
  .m00_axis_aclk(m00_axis_aclk),
  .m00_axis_aresetn(m00_axis_aresetn),
  .m00_axis_tready(m00_axis_tready),
  .m00_axis_tvalid(i_fir_valid_out), 
  .m00_axis_tlast(i_fir_last_out),
  .m00_axis_tdata(i_fir_data_out),
  .m00_axis_tstrb(i_fir_strb_out)
  );


  mixer #
  (
      .C_S00_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH),
      .C_M00_AXIS_TDATA_WIDTH(C_M00_AXIS_TDATA_WIDTH),
      .IS_Q_NOT_I(1)
  )
  q_mixer
  (
  // Ports of Axi Slave Bus Interface S00_AXIS
  .s00_axis_aclk(s00_axis_aclk),
  .s00_axis_aresetn(s00_axis_aresetn),
  .s00_axis_tlast(s00_axis_tlast), 
  .s00_axis_tvalid(s00_axis_tvalid),
  .s00_axis_tdata(s00_axis_tdata),
  .s00_axis_tstrb(s00_axis_tstrb),
  .s00_axis_tready(q_mixer_ready_out),

  // Ports of Axi Master Bus Interface M00_AXIS
  .m00_axis_aclk(m00_axis_aclk),
  .m00_axis_aresetn(m00_axis_aresetn),
  .m00_axis_tready(m00_axis_tready),
  .m00_axis_tvalid(q_fir_valid_in), 
  .m00_axis_tlast(q_fir_last_in),
  .m00_axis_tdata(q_fir_data_in),
  .m00_axis_tstrb(q_fir_strb_in)
  );


  fir_15 #
  (
    .C_S00_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH),
    .C_M00_AXIS_TDATA_WIDTH(C_M00_AXIS_TDATA_WIDTH)
  )
  q_fir
  (
  // Ports of Axi Slave Bus Interface S00_AXIS
  .s00_axis_aclk(s00_axis_aclk),
  .s00_axis_aresetn(s00_axis_aresetn),
  .s00_axis_tlast(q_fir_last_in), 
  .s00_axis_tvalid(q_fir_valid_in),
  .s00_axis_tdata(q_fir_data_in),
  .s00_axis_tstrb(q_fir_strb_in),
  .s00_axis_tready(q_fir_ready_out),

  // Ports of Axi Master Bus Interface M00_AXIS
  .m00_axis_aclk(m00_axis_aclk),
  .m00_axis_aresetn(m00_axis_aresetn),
  .m00_axis_tready(m00_axis_tready),
  .m00_axis_tvalid(q_fir_valid_out), 
  .m00_axis_tlast(q_fir_last_out),
  .m00_axis_tdata(q_fir_data_out),
  .m00_axis_tstrb(q_fir_strb_out)
  );
 

endmodule
