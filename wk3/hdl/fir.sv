module fir_15 #
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

 
  localparam NUM_COEFFS = 15;
  logic signed [7:0] coeffs [NUM_COEFFS-1 : 0];
  logic signed [C_M00_AXIS_TDATA_WIDTH-1:0] intmdt_term [NUM_COEFFS-1 : 0];
  logic valids [NUM_COEFFS-1 : 0];
  logic lasts [NUM_COEFFS-1 : 0];

  logic signed [C_M00_AXIS_TDATA_WIDTH-1:0] data_in;

  always_comb begin
      if (s00_axis_tvalid) begin
          data_in = s00_axis_tdata;
      end else begin
          data_in = 0;
      end
  end


  fir_tap #(
      .C_S00_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH),
      .C_M00_AXIS_TDATA_WIDTH(C_M00_AXIS_TDATA_WIDTH))
      first_tap (
          .clk(s00_axis_aclk),
          .rst_in(~s00_axis_aresetn),
          .ready(m00_axis_tready),
          .valid_in(s00_axis_tvalid),
          .last_in(s00_axis_tlast),
          .coeff_in(coeffs[0]),
          .data_in(data_in),
          .prev_in(0),
          .data_out(intmdt_term[0]),
          .valid_out(valids[0]),
          .last_out(lasts[0])
          );

  genvar i;
  generate
    for (i=1; i<=NUM_COEFFS-1; i=i+1) begin : generate_block_identifier // <-- example block name
        fir_tap #(
          .C_S00_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH),
          .C_M00_AXIS_TDATA_WIDTH(C_M00_AXIS_TDATA_WIDTH))
        tap (
          .clk(s00_axis_aclk),
          .rst_in(~s00_axis_aresetn),
          .ready(m00_axis_tready),
          .valid_in(valids[i-1]),
          .last_in(lasts[i-1]),
          .coeff_in(coeffs[i]),
          .data_in(data_in),
          .prev_in(intmdt_term[i-1]),
          .data_out(intmdt_term[i]),
          .valid_out(valids[i]),
          .last_out(lasts[i])
          );
    end
  endgenerate

  assign m00_axis_tlast = lasts[NUM_COEFFS-1];
  assign m00_axis_tvalid = valids[NUM_COEFFS-1];
  assign m00_axis_tdata = intmdt_term[NUM_COEFFS-1];
  assign m00_axis_tstrb = s00_axis_tstrb;

  assign s00_axis_tready = m00_axis_tready && s00_axis_aresetn;

  //initializing values
  initial begin //updated you coefficients
    coeffs[0] = -2;
    coeffs[1] = -3;
    coeffs[2] = -4;
    coeffs[3] = 0;
    coeffs[4] = 9;
    coeffs[5] = 21;
    coeffs[6] = 32;
    coeffs[7] = 36;
    coeffs[8] = 32;
    coeffs[9] = 21;
    coeffs[10] = 9;
    coeffs[11] = 0;
    coeffs[12] = -4;
    coeffs[13] = -3;
    coeffs[14] = -2;

  //  for(int i=0; i<NUM_COEFFS; i++)begin
  //    intmdt_term[i] = 0;
  //  end
    $display("DONE!");
  end

  
/*
  always_ff @(posedge s00_axis_aclk) begin
    if (s00_axis_aresetn==0) begin
        for(int i=0; i<NUM_COEFFS; i++)begin
          intmdt_term[i] = 0;
        end
        s00_axis_tready <= 0;
        m00_axis_tvalid <= 0;
        m00_axis_tlast <= 0;
        m00_axis_tdata <= 0;
        m00_axis_tstrb <= 0;
    end else begin
        case (state)
            RUNNING: begin
                if (ready) begin
                    intmdt_term[0] <= coeffs[NUM_COEFFS-1]*s00_axis_tdata;
                    for(int i=1; i<NUM_COEFFS; i++)begin
                        intmdt_term[i] <= coeffs[NUM_COEFFS-1-i]*s00_axis_tdata + intmdt_term[i-1];
                    end
                end
            end
            STALLING: begin

            end
        endcase

    end

  end
  */
endmodule
