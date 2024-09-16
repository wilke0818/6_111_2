`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
module spi_tx
       #(   parameter DATA_WIDTH = 8,
            parameter DATA_CLK_PERIOD = 100
        )
        ( input wire clk_in,
          input wire rst_in,
          input wire [DATA_WIDTH-1:0] data_in,
          input wire trigger_in,
          output logic busy_out,
          output logic chip_data_out,
          output logic chip_clk_out,
          output logic chip_sel_out
        );
        parameter WAITING = 0;
        parameter SENDING_CLK_DOWN = 1;
        parameter SENDING_CLK_UP = 2;


        logic [1:0] state;
        logic [DATA_WIDTH-1:0] copy_data_in;
        logic [$clog2(DATA_WIDTH):0] out_count;
        
        parameter DATA_CLK_HALF = DATA_CLK_PERIOD >> 1;
        logic [$clog2(DATA_CLK_HALF):0] count;

        always_ff @(posedge clk_in) begin
            if (rst_in) begin
                state <= WAITING;
                count <= 0;
                busy_out <= 0;
                chip_sel_out <= 1'b1;
                out_count <= 0;
            end else begin
                case (state)
                    WAITING : begin
                        if (trigger_in) begin
                            state <= SENDING_CLK_DOWN;
                            count <= 0;
                            busy_out <= 1'b1;
                            chip_sel_out <= 0;
                            chip_clk_out <= 0;
                            copy_data_in <= data_in;
                            chip_data_out <= data_in[DATA_WIDTH-1];
                            out_count <= DATA_WIDTH;
                        end
                    end
                    SENDING_CLK_DOWN : begin
                        if (count == DATA_CLK_HALF-1) begin
                            chip_clk_out <= 1'b1;
                            count <= 0;
                            state <= SENDING_CLK_UP;
                            out_count <= out_count - 1;
                        end else begin
                            count <= count + 1;
                        end
                    end
                    SENDING_CLK_UP : begin
                        if (count < DATA_CLK_HALF-1) begin
                            count <= count + 1;
                        end else begin
                            if (out_count == 0) begin
                                chip_sel_out <= 1'b1;
                                busy_out <= 0;
                                state <= WAITING;
                                count <= 0;
                            end else begin
                                chip_clk_out <= 0;
                                chip_data_out <= copy_data_in[out_count-1];
                                state <= SENDING_CLK_DOWN;
                                count <= 0;
                            end
                        end
                    end
                endcase
            end
        end
  // your code here
endmodule
`default_nettype wire // prevents system from inferring an undeclared logic (good practice)
