module stop_watch_csec(
    input clk, reset_p,
    input start_stop,
    input lap_swatch,
    output [15:0] value);

    wire clk_sec, clk_csec;
    wire clk_start;
    wire lap_load;
    wire [3:0] sec1, sec10, csec1, csec10;
    wire [15:0] cur_time;
    reg [15:0] lap_time;
    
    clk_set clock(clk_start, reset_p, clk_msec, clk_csec, clk_sec, clk_min);
           
    assign clk_start = start_stop ? clk : 0;

    counter_dec_60 counter_sec(clk, reset_p, clk_sec, sec1, sec10);
    counter_dec_100 counter_csec(clk, reset_p, clk_csec, csec1, csec10);
        
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(lap_swatch), .p_edge(lap_load));
    
    assign cur_time = {sec10, sec1, csec10, csec1};
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p) lap_time = 0;
        else if(lap_load) begin
            lap_time = {sec10, sec1, csec10, csec1};
        end
    end
    
    assign value = lap_swatch ? lap_time : cur_time;
        
endmodule

module stop_watch_csec_top(
    input clk, reset_p, 
    input [1:0]swcr,            //stopwatch control register
    output [3:0] com,
    output [7:0] seg_7);

    wire [15:0] value;
    wire start_stop, lap_swatch;
    
    assign start_stop = swcr[0];
    assign lap_swatch = swcr[1];
        
    stop_watch_csec sw_csec(clk, reset_p, start_stop, lap_swatch, value);
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(value),
    .seg_7_an(seg_7), .com(com));
    
endmodule