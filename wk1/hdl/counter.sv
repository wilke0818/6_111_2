module counter(     input wire clk_in,
                    input wire rst_in,
                    input wire [31:0] period_in,
                    output logic [31:0] count_out
              );
    logic [31:0] old_period;
    always_ff @(posedge clk_in)begin
        old_period <= period_in; //remember for comparisons.
        if (rst_in)begin
            count_out <= 0;
        end else if (period_in != old_period)begin
                count_out <= 0; //reset to prevent possible overflow bug
        end else if (count_out+1 == period_in)begin
            count_out <= 0;
        end else begin
            count_out <= count_out + 1;
        end
    end
endmodule
