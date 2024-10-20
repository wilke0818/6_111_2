`default_nettype none // prevents system from inferring an undeclared logic (good practice)
 
//Sine Wave Generator
module sine_generator (
  input wire clk_in,
  input wire rst_in, //clock and reset
  input wire step_in, //trigger a phase step (rate at which you run sine generator)
  output logic signed [15:0] amp_out); //output phase in 2's complement
  parameter STEP_FREQ = 100_000_000; //Hz
  parameter FREQUENCY = 10_000_000; //Hz
  parameter PHASE = 90; //degrees
  localparam CLKS_PER_CYCLE = STEP_FREQ/FREQUENCY; //ok to be non integer
  localparam PHASE_INCR = int'(32'hFFFF_FFFF/CLKS_PER_CYCLE);
  localparam PHASE_OFFSET = int'(1.0*PHASE/360*32'hFFFF_FFFF);
  //parameter PHASE_INCR = 32'b1000_0000_0000_0000_0000_0000_0000_0000>>3; //1/16th of 12 khz is 750 Hz
  logic [31:0] phase;
  logic [31:0] lu_phase;
  logic [15:0] amp;
  logic [15:0] amp_pre;
  assign amp_pre = ({~amp[15],amp[14:0]}); //2's comp output (if not scaling)
  assign amp_out = amp_pre; //decrease volume so it isn't too loud!
  sine_lut lut_1(.clk_in(clk_in), .rst_in(rst_in), .phase_in(lu_phase[31:26]), .amp_out(amp));
 
  always_ff @(posedge clk_in)begin
    lu_phase <= phase + PHASE_OFFSET;
    if (rst_in)begin
      phase <= 32'b0;
    end else if (step_in)begin
      phase <= phase+PHASE_INCR;
    end
  end
endmodule
 
//6bit sine lookup, 8bit depth
module sine_lut(input wire [5:0] phase_in, input wire clk_in, input wire rst_in, output logic[15:0] amp_out);
  always_ff @(posedge clk_in)begin
    if (rst_in)begin
      amp_out <= 0;
    end else begin
      case(phase_in)
       6'd0: amp_out<=32768;
       6'd1: amp_out<=35979;
       6'd2: amp_out<=39160;
       6'd3: amp_out<=42279;
       6'd4: amp_out<=45307;
       6'd5: amp_out<=48214;
       6'd6: amp_out<=50972;
       6'd7: amp_out<=53555;
       6'd8: amp_out<=55938;
       6'd9: amp_out<=58097;
       6'd10: amp_out<=60013;
       6'd11: amp_out<=61666;
       6'd12: amp_out<=63041;
       6'd13: amp_out<=64124;
       6'd14: amp_out<=64905;
       6'd15: amp_out<=65377;
       6'd16: amp_out<=65535;
       6'd17: amp_out<=65377;
       6'd18: amp_out<=64905;
       6'd19: amp_out<=64124;
       6'd20: amp_out<=63041;
       6'd21: amp_out<=61666;
       6'd22: amp_out<=60013;
       6'd23: amp_out<=58097;
       6'd24: amp_out<=55938;
       6'd25: amp_out<=53555;
       6'd26: amp_out<=50972;
       6'd27: amp_out<=48214;
       6'd28: amp_out<=45307;
       6'd29: amp_out<=42279;
       6'd30: amp_out<=39160;
       6'd31: amp_out<=35979;
       6'd32: amp_out<=32768;
       6'd33: amp_out<=29556;
       6'd34: amp_out<=26375;
       6'd35: amp_out<=23256;
       6'd36: amp_out<=20228;
       6'd37: amp_out<=17321;
       6'd38: amp_out<=14563;
       6'd39: amp_out<=11980;
       6'd40: amp_out<=9597;
       6'd41: amp_out<=7438;
       6'd42: amp_out<=5522;
       6'd43: amp_out<=3869;
       6'd44: amp_out<=2494;
       6'd45: amp_out<=1411;
       6'd46: amp_out<=630;
       6'd47: amp_out<=158;
       6'd48: amp_out<=0;
       6'd49: amp_out<=158;
       6'd50: amp_out<=630;
       6'd51: amp_out<=1411;
       6'd52: amp_out<=2494;
       6'd53: amp_out<=3869;
       6'd54: amp_out<=5522;
       6'd55: amp_out<=7438;
       6'd56: amp_out<=9597;
       6'd57: amp_out<=11980;
       6'd58: amp_out<=14563;
       6'd59: amp_out<=17321;
       6'd60: amp_out<=20228;
       6'd61: amp_out<=23256;
       6'd62: amp_out<=26375;
       6'd63: amp_out<=29556;
     endcase
   end
  end
endmodule
`default_nettype wire
