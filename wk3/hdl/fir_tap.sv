module fir_tap #
  (
    parameter integer C_S00_AXIS_TDATA_WIDTH  = 32,
    parameter integer C_M00_AXIS_TDATA_WIDTH  = 32
  )
  (
  input wire clk,
  input wire rst_in,
  input wire ready,
  input wire valid_in,
  input wire last_in,
  input wire signed [7:0] coeff_in,

  input wire signed [C_S00_AXIS_TDATA_WIDTH-1 : 0] data_in,
  input wire signed [C_S00_AXIS_TDATA_WIDTH-1 : 0] prev_in,

  output logic signed [C_S00_AXIS_TDATA_WIDTH-1 : 0] data_out,
  output logic valid_out,
  output logic last_out
  );
 

  logic signed [7:0] coeff;
  enum {RESTING, STALLING, RUNNING} state;

  assign coeff = coeff_in;

  always_ff @(posedge clk) begin
    if (rst_in) begin
        state <= RESTING;
        valid_out <= 0;
        last_out <= 0;
        data_out <= 0;
    end else begin
        case (state)
            RESTING: begin
                if (valid_in && ready) begin
                    state <= RUNNING;
                    data_out <= coeff * data_in + prev_in;
                    valid_out <= valid_in;
                    last_out <= last_in;
                end else if (~ready) begin
                    state <= STALLING;
                    valid_out <= 0;
                    last_out <= 0;
                    data_out <= 0;
                end else begin //ready but not valid_in
                    data_out <= 0;
                    valid_out <= valid_in;
                    last_out <= last_in;
                    state <= RESTING;
                end
            end
            STALLING: begin
                if (valid_in && ready) begin
                    state <= RUNNING;
                    data_out <= coeff * data_in + prev_in;
                    valid_out <= valid_in;
                    last_out <= last_in;
                end else if (ready) begin
                    state <= RESTING;
                    data_out <= 0;
                    valid_out <= valid_in;
                    last_out <= last_in;
                end else begin
                    state <= STALLING;
                    data_out <= 0;
                    valid_out <= 0;
                    last_out <= 0;
                end
            end
            RUNNING: begin
                if (valid_in && ready) begin
                    data_out <= coeff * data_in + prev_in;
                    valid_out <= 1;
                    last_out <= last_in;
                    if (last_in) begin
                        state <= RESTING;
                    end
                end else if (~ready) begin
                    state <= STALLING;
                    data_out <= 0;
                    last_out <= last_in;
                    valid_out <= 0;
                end else begin
                    state <= RESTING;
                    valid_out <= valid_in;
                    last_out <= last_in;
                    data_out <= 0;
                end

            end
        endcase

    end

  end

endmodule
