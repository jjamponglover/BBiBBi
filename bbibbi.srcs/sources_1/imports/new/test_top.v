`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module led_bar_top(
    input clk, reset_p,
    output [7:0]count);
    
    reg [28:0] clk_div;
    always @(posedge clk) clk_div = clk_div +1;
    
    assign count = ~clk_div[28:21];
endmodule


module button_test_top(
    input clk, reset_p,
    input [3:0]btn,
    output [7:0] seg_7,
    output [3:0] com);

    reg [15:0] btn_counter;
    reg [3:0] value;
    wire [3:0]btn_pedge;
    
//    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
//    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1]));
//    button_cntr btn_cntr2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));
//    button_cntr btn_cntr3(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pe(btn_pedge[3]));
    
    genvar i;
    generate
        for (i=0;i<4;i=i+1)begin:btn_cntr
            button_cntr (.clk(clk), .reset_p(reset_p), .btn(btn[i]), .btn_pe(btn_pedge[i]));
        end
    endgenerate
    
    always @(posedge clk, posedge reset_p)begin // 시스템반도체의 경우: always문 괄호 안에는 clk. reset, enable 밖에 못들어간다. 문법적으로 안되는게 아니라 시스템반도체상 안되는거임.
        if(reset_p)btn_counter = 0;
            else if(btn_pedge[0]) btn_counter = btn_counter + 1;
            else if(btn_pedge[1]) btn_counter=btn_counter-1;
            else if(btn_pedge[2]) btn_counter = {btn_counter[14:0],btn_counter[15]};
            else if(btn_pedge[3]) btn_counter = {btn_counter[0],btn_counter[15:1]};
        end
      
fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(btn_counter), .seg_7_ca(seg_7), .com(com));
endmodule


module button_ledbar_top(
    input clk, reset_p,
    input [3:0]btn,
    output [7:0] seg_7,
    output [3:0]com);

    reg [7:0] btn_counter;
    wire [3:0]btn_pedge;

    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1]));
    button_cntr btn_cntr2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));
    button_cntr btn_cntr3(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pe(btn_pedge[3]));

    always @(posedge clk, posedge reset_p)begin // 시스템반도체의 경우: always문 괄호 안에는 clk. reset, enable 밖에 못들어간다. 문법적으로 안되는게 아니라 시스템반도체상 안되는거임.
        if(reset_p)btn_counter = 0;
        else if(btn_pedge[0]) btn_counter = btn_counter + 1;
        else if(btn_pedge[1]) btn_counter=btn_counter-1;
        else if(btn_pedge[2]) btn_counter = {btn_counter[6:0],btn_counter[7]};
        else if(btn_pedge[3]) btn_counter = {btn_counter[0],btn_counter[7:1]};
    end
    
    assign seg_7 = ~btn_counter,com=4'b0000;
endmodule


module button_fnd_top(
    input clk, reset_p,
    input [3:0]btn,
    output [7:0] seg_7);

    reg [7:0] btn_counter;
    wire [3:0]btn_pedge;
    reg [16:0] clk_div;
    wire clk_div_16;
    
    always @(posedge clk) clk_div = clk_div + 1;
    
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .p_edge(clk_div_16));
    
    reg [3:0]debounced_btn;
    
    always @(posedge clk, posedge reset_p)begin
        if(reset_p) debounced_btn = 0;
        else if(clk_div_16) debounced_btn = btn;   //clk_div_16(1ms) 주기로  btnU를 받겠음
    end
    
    edge_detector_n ed0(.clk(clk), .reset_p(reset_p), .cp(debounced_btn[0]), .p_edge(btn_pedge[0]));
    edge_detector_n ed1(.clk(clk), .reset_p(reset_p), .cp(debounced_btn[1]), .p_edge(btn_pedge[1]));
    edge_detector_n ed2(.clk(clk), .reset_p(reset_p), .cp(debounced_btn[2]), .p_edge(btn_pedge[2]));
    edge_detector_n ed3(.clk(clk), .reset_p(reset_p), .cp(debounced_btn[3]), .p_edge(btn_pedge[3]));
    
    always @(posedge clk, posedge reset_p)begin // 시스템반도체의 경우: always문 괄호 안에는 clk. reset, enable 밖에 못들어간다. 문법적으로 안되는게 아니라 시스템반도체상 안되는거임.
        if(reset_p)btn_counter = 0;
        else if(btn_pedge[0]) btn_counter = btn_counter + 1;
        else if(btn_pedge[1]) btn_counter=btn_counter-1;
        else if(btn_pedge[2]) btn_counter = {btn_counter[6:0],btn_counter[7]};
        else if(btn_pedge[3]) btn_counter = {btn_counter[0],btn_counter[7:1]};
    end

    wire [7:0] seg7_bar;
    
    decoder_7seg seg(.hex_value(btn_counter[3:0]),.seg_7(seg7_bar));
    assign seg_7=~seg7_bar;
endmodule


module keypad_test_top(
    input clk, reset_p,
    input [3:0] row,
    output [3:0] col,
    output [7:0] seg_7,
    output [3:0] com);
    
    wire [3:0] key_value;
    reg [15:0] counter;
    keypad_cntr_FSM(.clk(clk), .reset_p(reset_p), .row(row), .col(col), .key_value(key_value), .key_valid(key_valid));
    
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(key_valid), .p_edge(key_valid_pe));
    
    always @(posedge clk, posedge reset_p)begin
        if(reset_p) counter = 0;
        else if(key_valid_pe)begin
            if (key_value == 4'h1) counter=counter+1;
            else if (key_value == 4'h2) counter=counter-1;
        end
    end
    
    fnd_4digit_cntr(.clk(clk), .reset_p(reset_p), .value(counter), .seg_7_ca(seg_7), .com(com));

endmodule

module watch_top(
    input clk, reset_p, 
    input [2:0] btn,
    output [3:0] com,
    output [7:0] seg_7);

    wire clk_usec, clk_msec, clk_sec, clk_min;
    reg sec,min;
    
    clock_usec usec_clk(clk, reset_p, clk_usec);
    clock_div_1000 msec_clk(clk, reset_p, clk_usec, clk_msec);
    clock_div_1000 sec_clk(clk, reset_p, clk_msec, clk_sec);
    clock_min min_clk(clk, reset_p, sec, clk_min);
    
    wire [3:0] sec1, sec10, min1, min10;
    
    wire [2:0]btn_pedge;

    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1]));
    button_cntr btn_cntr2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));
    
    wire set_mode;
    T_flip_flop_p tff_setmode (clk, reset_p, btn_pedge[0],set_mode);
    
    //assign sec_edge = set_mode ? btn_pedge[1] : clk_sec;
    //assign min_edge = set_mode ? btn_pedge[2] : clk_min;
     
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p) begin sec=0; min=0; end
        else begin
            if (set_mode) begin
                sec=btn_pedge[1];
                min=btn_pedge[2];
            end
            else begin
                sec=clk_sec;
                min=clk_min;
            end
        end
    end
    
    counter_dec_60 counter_sec(clk, reset_p,sec, sec1, sec10);
    counter_dec_60 counter_min(clk, reset_p,min, min1, min10);
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value({min10,min1,sec10,sec1}),
    .seg_7_ca(seg_7), .com(com));

endmodule

module loadable_watch(
    input clk, reset_p,
    input [2:0] btn_pedge,
    output [15:0] value);
    
    wire clk_usec, clk_msec, clk_sec, clk_min;
    wire sec_edge, min_edge;
    wire set_mode;
    wire cur_time_load_en, set_time_load_en;
    wire [3:0] cur_sec1, cur_sec10, set_sec1, set_sec10;
    wire [3:0] cur_min1, cur_min10, set_min1, set_min10;
    wire [15:0] cur_time, set_time;
    
    clk_set(clk, reset_p, clk_msec, clk_csec, clk_sec);
    clock_min min_clk(clk, reset_p, sec_edge, clk_min);

    loadable_counter_dec_60 cur_time_sec (.clk(clk), .reset_p(reset_p), .clk_time(clk_sec), 
        .load_enable(cur_time_load_en), .set_value1(set_sec1), .set_value10(set_sec10), 
        .dec1(cur_sec1), .dec10(cur_sec10));
    loadable_counter_dec_60 cur_time_min (.clk(clk), .reset_p(reset_p), .clk_time(clk_min), 
        .load_enable(cur_time_load_en), .set_value1(set_min1), .set_value10(set_min10),
        .dec1(cur_min1), .dec10(cur_min10));

    loadable_counter_dec_60 set_time_sec(.clk(clk), .reset_p(reset_p), .clk_time(btn_pedge[1]), 
        .load_enable(set_time_load_en), .set_value1(cur_sec1), .set_value10(cur_sec10),
        .dec1(set_sec1), .dec10(set_sec10));
    loadable_counter_dec_60 set_time_min(.clk(clk), .reset_p(reset_p), .clk_time(btn_pedge[2]), 
        .load_enable(set_time_load_en), .set_value1(cur_min1), .set_value10(cur_min10),
        .dec1(set_min1), .dec10(set_min10));

    assign cur_time = {cur_min10, cur_min1, cur_sec10, cur_sec1};
    assign set_time = {set_min10, set_min1, set_sec10, set_sec1};
    assign value = set_mode ? set_time : cur_time;
    
    T_flip_flop_p tff_setmode (clk, reset_p, btn_pedge[0], set_mode);
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(set_mode), .p_edge(set_time_load_en), .n_edge(cur_time_load_en));
    
    assign sec_edge = set_mode ? btn_pedge[1] : clk_sec;
    assign min_edge = set_mode ? btn_pedge[2] : clk_min;

endmodule

module loadable_watch_top(
    input clk, reset_p,
    input [2:0] btn,
    output [3:0] com,
    output [7:0] seg_7);
    
    wire [2:0]btn_pedge;
    wire [15:0] value;

    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1]));
    button_cntr btn_cntr2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));
    
    loadable_watch(clk, reset_p, btn_pedge, value);

    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(value), .seg_7_ca(seg_7), .com(com));

endmodule










module loadable_watch_cancel_top( //취소기능 만들기
    input clk, reset_p, 
    input [3:0] btn,
    output [3:0] com,
    output [7:0] seg_7);

    wire clk_usec, clk_msec, clk_sec, clk_min;
    wire sec_edge, min_edge;
    wire [3:0]btn_pedge;
    wire set, set_mode, un_set;
    wire cur_time_load_en, set_time_load_en;
    wire [3:0] cur_sec1, cur_sec10, set_sec1, set_sec10;
    wire [3:0] cur_min1, cur_min10, set_min1, set_min10;
    wire [15:0] value, cur_time, set_time;
    
    clock_usec usec_clk(clk, reset_p, clk_usec);
    clock_div_1000 msec_clk(clk, reset_p, clk_usec, clk_msec);
    clock_div_1000 sec_clk(clk, reset_p, clk_msec, clk_sec);
    clock_min min_clk(clk, reset_p, sec_edge, clk_min);
        
    loadable_counter_dec_60 cur_time_sec (.clk(clk), .reset_p(reset_p), .clk_time(clk_sec), 
        .load_enable(cur_time_load_en), .set_value1(set_sec1), .set_value10(set_sec10), 
        .dec1(cur_sec1), .dec10(cur_sec10));
    loadable_counter_dec_60 cur_time_min (.clk(clk), .reset_p(reset_p), .clk_time(clk_min), 
        .load_enable(cur_time_load_en), .set_value1(set_min1), .set_value10(set_min10),
        .dec1(cur_min1), .dec10(cur_min10));

    loadable_counter_dec_60 set_time_sec(.clk(clk), .reset_p(reset_p), .clk_time(btn_pedge[1]), 
        .load_enable(set_time_load_en), .set_value1(cur_sec1), .set_value10(cur_sec10),
        .dec1(set_sec1), .dec10(set_sec10));
    loadable_counter_dec_60 set_time_min(.clk(clk), .reset_p(reset_p), .clk_time(btn_pedge[2]), 
        .load_enable(set_time_load_en), .set_value1(cur_min1), .set_value10(cur_min10),
        .dec1(set_min1), .dec10(set_min10));

    assign cur_time = {cur_min10, cur_min1, cur_sec10, cur_sec1};
    assign set_time = {set_min10, set_min1, set_sec10, set_sec1};
    //assign value = set_mode ? (btn_pedge[3] ? {cur_min10, cur_min1, cur_sec10, cur_sec1} : {set_min10, set_min1, set_sec10, set_sec1}) : {cur_min10, cur_min1, cur_sec10, cur_sec1};
    assign value = set_mode ? set_time : cur_time;
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(value), .seg_7_ca(seg_7), .com(com));
    
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1]));
    button_cntr btn_cntr2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));
    button_cntr btn_cntr3(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pe(btn_pedge[3]));
    
    assign set=set_mode&~btn_pedge[3];
    
    T_flip_flop_p tff_setmode (clk, reset_p, set, set_mode);
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(set_mode), .p_edge(set_time_load_en), .n_edge(cur_time_load_en));

    assign sec_edge = set_mode ? btn_pedge[1] : clk_sec;
    assign min_edge = set_mode ? btn_pedge[2] : clk_min;
    
 //   and (cur_time_load_en, ~btn_pedge[3], un_set);
    
  //  assign set_mode=btn_pedge[3]?0:set?1:0;
    
//    always @(posedge clk, posedge btn_pedge[3])begin
//        if(set) begin
//            set_mode=1;
//            if (set_mode && btn_pedge[3]) begin
//                set_mode=0;
//            end
//        end
//        else set_mode=0;
//    end
    
   // assign btn_pedge[0] = btn_pedge[3] ? 1 : 0;
  //  assign value = btn_pedge[3] ? {cur_min10, cur_min1, cur_sec10, cur_sec1} : {set_min10, set_min1, set_sec10, set_sec1};
//    assign set_sec10 = btn_pedge[3] ? cur_sec10 : set_sec10;
//    assign backup_min1 = btn_pedge[3] ? cur_min1 : set_min1;
//    assign set_min10 = btn_pedge[3] ? cur_min10 : set_min10;

endmodule










module stop_watch_top(
    input clk, reset_p, 
    input [1:0] btn,
    output [3:0] com,
    output [7:0] seg_7);

    wire clk_sec, clk_min;
    wire [1:0] btn_pedge;
    wire start_stop;
    wire clk_start;
    wire [15:0] value, cur_time;
    wire lap_swatch, lap_load;
    wire [3:0] sec1, sec10, min1, min10;
    reg [15:0] lap_time;
    
    clk_set(clk, reset_p, clk_msec, clk_csec, clk_sec, clk_min);
    
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1]));
    
    T_flip_flop_p tff_start (clk, reset_p, btn_pedge[0], start_stop);
   
    assign clk_start = start_stop ? clk : 0;
    
    counter_dec_60 counter_sec(clk, reset_p, clk_sec, sec1, sec10);
    counter_dec_60 counter_min(clk, reset_p, clk_min, min1, min10);
    
    T_flip_flop_p tff_lap (clk, reset_p, btn_pedge[1], lap_swatch);
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(lap_swatch), .p_edge(lap_load));
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p) lap_time = 0;
        else if(lap_load)begin
            lap_time = {min10, min1, sec10, sec1};
        end
    end
    
    assign cur_time = {min10, min1, sec10, sec1};
    assign value = lap_swatch ? lap_time : cur_time;
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(value),
    .seg_7_ca(seg_7), .com(com));
    
endmodule

module stop_watch_csec(
    input clk, reset_p, 
    input [1:0] btn_pedge,
    output [15:0] value);

    wire clk_sec, clk_csec;
    wire start_stop;
    wire clk_start;
    wire lap_swatch, lap_load;
    wire [3:0] sec1, sec10, msec1, msec10;
    wire [15:0] cur_time;
    reg [15:0] lap_time;
    
    clk_set clock(clk, reset_p, clk_msec, clk_csec, clk_sec, clk_min);
        
    T_flip_flop_p tff_start (clk, reset_p, btn_pedge[0], start_stop);
   
    assign clk_start = start_stop ? clk : 0;

    counter_dec_60 counter_sec(clk, reset_p, clk_sec, sec1, sec10);
    counter_dec_100 counter_msec(clk, reset_p, clk_csec, msec1, msec10);
    
    T_flip_flop_p tff_lap (clk, reset_p, btn_pedge[1], lap_swatch);
    
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(lap_swatch), .p_edge(lap_load));
    
    assign cur_time = {sec10, sec1, msec10, msec1};
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p) lap_time = 0;
        else if(lap_load) begin
            lap_time = {sec10, sec1, msec10, msec1};
        end
    end
    
    assign value = lap_swatch ? lap_time : cur_time;
        
endmodule

module stop_watch_csec_top(
    input clk, reset_p, 
    input [1:0] btn,
    output [3:0] com,
    output [7:0] seg_7);

    wire [1:0] btn_pedge;
    wire [15:0] value;

    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1])); 
    
    stop_watch_csec stop_watch(clk, reset_p, btn_pedge, value);
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(value),
    .seg_7_ca(seg_7), .com(com));
    
endmodule

module cook_timer(
    input clk, reset_p, 
    input [3:0] btn_pedge,
    output [15:0] value,
    output [5:0] led,
    output buzz_clk);
    
    wire clk_msec, clk_sec;
    wire btn_start, inc_sec, inc_min, alarm_off;
    wire [3:0] set_sec1, set_sec10, set_min1, set_min10;
    wire [3:0] cur_sec1, cur_sec10, cur_min1, cur_min10;
    wire load_enable, dec_clk, clk_start;    
    wire [15:0] cur_time, set_time;
    wire timeout_pedge;
    reg start_stop;
    reg alarm;
    
    reg [25:0] clk_div = 0;
    always @(posedge clk) clk_div = clk_div + 1;
    
    assign {alarm_off, inc_min, inc_sec, btn_start} = btn_pedge;

    assign led[5] = start_stop;
    
    assign clk_start = start_stop ? clk : 0 ;
    clk_set(clk, reset_p, clk_msec, clk_csec, clk_sec, clk_min);

    counter_dec_60 set_sec(clk, reset_p, inc_sec, set_sec1, set_sec10);
    counter_dec_60 set_min(clk, reset_p, inc_min, set_min1, set_min10);

    loadable_down_counter_dec_60 cur_sec(clk, reset_p, clk_sec, load_enable,
        set_sec1, set_sec10, cur_sec1, cur_sec10, dec_clk);
    loadable_down_counter_dec_60 cur_min(clk, reset_p, dec_clk, load_enable,
        set_min1, set_min10, cur_min1, cur_min10);
        
    //T_flip_flop_p tff_start (clk, reset_p, btn_start, start_stop);
    always @(posedge clk or posedge reset_p)begin
        if (reset_p) begin start_stop=0; end
        else begin
            if(btn_start) start_stop = ~start_stop;
            else if (timeout_pedge) start_stop = 0;
        end
    end
    
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(start_stop), .p_edge(load_enable));
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p) alarm = 0;
        else begin
            if(start_stop && clk_msec && cur_time == 0) alarm=1;
            else if (alarm && alarm_off) alarm = 0;
        end
    end

    edge_detector_n ed_timeout(.clk(clk), .reset_p(reset_p), .cp(alarm), .p_edge(timeout_pedge));
    
    assign led[0] = alarm ? clk_div[25] : 0;
    assign led[2] = alarm ? ~clk_div[25] : 0;
    
    assign cur_time = {cur_min10, cur_min1, cur_sec10, cur_sec1};
    assign set_time = {set_min10, set_min1, set_sec10, set_sec1};
    assign value = start_stop ? cur_time : set_time;
    
    assign buzz_clk = alarm ? clk_div[14] : 0;
    
endmodule


module cook_timer_top(
    input clk, reset_p, 
    input [3:0] btn,
    output [3:0] com,
    output [7:0] seg_7,
    output [5:0]led,
    output buzz_clk);
    
    wire [3:0]btn_pedge;
    wire [15:0] value;
   
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1]));
    button_cntr btn_cntr2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));
    button_cntr btn_cntr3(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pe(btn_pedge[3]));
    
    cook_timer cook(clk, reset_p, btn_pedge, value, led, buzz_clk);
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(value), .seg_7_ca(seg_7), .com(com));

endmodule



module three_mode_watch(
    input clk, reset_p,
    input [4:0] btn,
    output reg [7:0] seg_7,
    output reg [3:0] com,
    output [5:0] led,
    output buzz_clk);
    
    wire [3:0] q;
    wire btn_pedge;
    wire [3:0] com1, com2, com3;
    wire [7:0] seg_71, seg_72, seg_73;
    reg [3:0] btn1, btn2, btn3;

    button_cntr btn_cntr4(.clk(clk), .reset_p(reset_p), .btn(btn[4]), .btn_pe(btn_pedge));
    
    ring_counter mode(.clk(btn_pedge), .reset_p(reset_p), .q(q));

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            com=4'b0000;
            seg_7=8'b00000000;
        end
        else if (q==4'b0001) begin
            com=4'b0000;
            seg_7=8'b1100_1011;
        end
        else if (q==4'b0010) begin
            com=com3;
            seg_7=seg_73;
            btn3=btn;
        end
        else if (q==4'b0100) begin
            com=com2;
            seg_7=seg_72;
            btn2=btn;
        end
        else if (q==4'b1000) begin
            com=com1;
            seg_7=seg_71;
            btn1=btn;
        end
    end
    
    watch_top (clk, reset_p, btn1, com1, seg_71);
    stop_watch_top (clk, reset_p,  btn2, com2, seg_72);
    cook_timer(clk, reset_p, btn3, com3, seg_73,led, buzz_clk);

endmodule

module multy_purpose_watch(
    input clk, reset_p,
    input [4:0] btn,
    output [3:0] com,
    output [7:0] seg_7,
    output buzz_clk);
    
    parameter watch_mode        = 3'b001;
    parameter stop_watch_mode   = 3'b010;
    parameter cook_timer_mode   = 3'b100;
    
    wire [2:0] watch_btn, stopw_btn;
    wire [3:0] cook_btn;
    wire [15:0] watch_value, stop_watch_value, cook_timer_value, value;
    reg [2:0] mode;
    wire btn_mode;
    wire [3:0] btn_pedge;
    
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1]));
    button_cntr btn_cntr2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));
    button_cntr btn_cntr3(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pe(btn_pedge[3]));
    button_cntr btn_cntr4(.clk(clk), .reset_p(reset_p), .btn(btn[4]), .btn_pe(btn_mode));
    
    always @(posedge clk or posedge reset_p)begin
        if (reset_p) mode = watch_mode;
        else if (btn_mode) begin
            case(mode)
                watch_mode : mode = stop_watch_mode;
                stop_watch_mode : mode = cook_timer_mode;
                cook_timer_mode : mode = watch_mode;
                default : mode = watch_mode;
            endcase
        end
    end
    
    assign {cook_btn, stopw_btn, watch_btn} = (mode == watch_mode) ? {7'b0, btn_pedge[2:0]} :
                                              (mode == stop_watch_mode) ? {4'b0, btn_pedge[2:0], 3'b0} :
                                              {btn_pedge[3:0], 6'b0};
    
    loadable_watch(clk, reset_p, watch_btn, watch_value);
    stop_watch_csec stop_watch(clk, reset_p, stopw_btn, stop_watch_value);
    cook_timer cook(clk, reset_p, cook_btn, cook_timer_value, led, buzz_clk);

    assign value = (mode == cook_timer_mode) ? cook_timer_value :
                   (mode == stop_watch_mode) ? stop_watch_value :
                   watch_value;
                                             
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(value), .seg_7_ca(seg_7), .com(com));
    
endmodule

module dht11_top(
    input clk, reset_p,
    inout dht11_data,
    output [3:0] com,
    output [7:0] seg_7, led_bar);
    
    wire [7:0] humidity, temperature, data_counter;
    
    dht11 dht(clk, reset_p, dht11_data, humidity, temperature, led_bar, data_counter);
    
    wire [15:0] bcd_humi, bcd_tmpr;
    bin_to_dec humi(.bin({4'b0000, humidity}), .bcd(bcd_humi));
    bin_to_dec tmpr(.bin({4'b0000, temperature}), .bcd(bcd_tmpr));
    
    wire [15:0] value;
    assign value = {bcd_humi[7:0], bcd_tmpr[7:0]};
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(value), .seg_7_ca(seg_7), .com(com));

endmodule

module ultrasonic_top(
    input clk, reset_p, echo,
    output trig,
    output [3:0] com,
    output [7:0] seg_7, 
    output [7:0] led_bar);
    
    wire [11:0] distance;
    reg sonic_sencer;
    
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)sonic_sencer = 0;
        else if(distance < 12'h5)sonic_sencer = 1;
        else sonic_sencer = 0;
    end
        
    ultrasonic sonic(clk, reset_p, echo, trig, distance, led_bar);
    
    wire [15:0] bcd_dis;
    bin_to_dec humi(.bin(distance), .bcd(bcd_dis));
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(distance), .seg_7_ca(seg_7), .com(com));

endmodule

module led_pwm_top(
    input clk, reset_p,
    output [3:0] led_pwm);
    
    reg [27:0] clk_div;
    always @(posedge clk) clk_div = clk_div + 1;
    
    pwm_128step pwm_led_r(.clk(clk), .reset_p(reset_p), 
            .duty(clk_div[27:21]), .pwm_freq(10000), .pwm_128(led_pwm[0]));
//    pwm_128step pwm_led_g(.clk(clk), .reset_p(reset_p), 
//            .duty(clk_div[26:20]), .pwm_freq(10000), .pwm_128(led_pwm[1]));
//    pwm_128step pwm_led_b(.clk(clk), .reset_p(reset_p), 
//            .duty(clk_div[25:19]), .pwm_freq(10000), .pwm_128(led_pwm[2]));
//    pwm_128step pwm_led(.clk(clk), .reset_p(reset_p), 
//            .duty(clk_div[27:21]), .pwm_freq(10000), .pwm_128(led_pwm[3]));
    
endmodule

module dc_motor_pwm_top(
    input clk, reset_p,
    output motor_pwm);
    
    reg [30:0] clk_div;
    always @(posedge clk)clk_div = clk_div + 1;
    
    pwm_128step pwm_led_r(.clk(clk), .reset_p(reset_p), 
            .duty(clk_div[30:27]), .pwm_freq(50), .pwm_128(motor_pwm));

endmodule

module sub_motor_pwm_top(
    input clk, reset_p,
    input [3:0] btn,
    output sg90,
    output [3:0] com,
    output [7:0] seg_7);
    
    wire [3:0] btn_pedge;
    reg [7:0] duty;
    reg flag = 1;
    
    button_cntr ed0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr ed1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1]));
    button_cntr ed2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));
    button_cntr ed3(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pe(btn_pedge[3]));

    always @(posedge clk or posedge reset_p)begin
        if(reset_p)duty = 32;
        else if(btn_pedge[0])duty = 32;
        else if(btn_pedge[1])duty = 80;
        else if(btn_pedge[2])duty = 128;
        else if(btn_pedge[3])begin
            if(flag)duty = duty + 1;
            else duty = duty - 1;
        end
        else if(duty==128)flag = 0;
        else if(duty==32)flag = 1;
    end

    pwm_1024step pwm_0(.clk(clk), .reset_p(reset_p), 
            .duty(duty), .pwm_freq(50), .pwm_1024(sg90));
            
    wire [15:0] bcd_dis;
    bin_to_dec humi(.bin({4'b0,duty}), .bcd(bcd_dis));
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(bcd_dis), .seg_7_ca(seg_7), .com(com));

endmodule

module servo_sg90(
    input clk, reset_p,
    input [2:0] btn,
    output sg90,
    output [3:0] com,
    output [7:0] seg_7);

    wire [2:0] btn_pedge;
    
    button_cntr ed0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr ed1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1]));
    button_cntr ed2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));

    reg [31:0] clk_div;
    always @(posedge clk)clk_div = clk_div +1;
    
    wire clk_div_pedge;
    edge_detector_n ed_timeout(.clk(clk), .reset_p(reset_p), .cp(clk_div[17]), .p_edge(clk_div_pedge));
    
    reg [20:0] duty;
    reg up_down;
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
           duty = 75000;
           up_down = 1;
        end
        else if(btn_pedge[0])begin
            if(up_down)up_down = 0;
            else up_down = 1;
        end
        else if(btn_pedge[1])begin
            duty = 75000;
        end
        else if(btn_pedge[2])begin
            duty = 312000;
        end
        else if(clk_div_pedge)begin
            if(duty >= 312000)up_down = 0;
            else if(duty <= 75000)up_down = 1;
            
            if(up_down)duty = duty + 100;
            else duty = duty - 100;
        end 
    end 
    
    pwm_512_period pwm_motot(.clk(clk), .reset_p(reset_p), 
            .duty(duty), .pwm_period(2500000), .pwm_512(sg90));

    wire [15:0] bcd_duty;
    bin_to_dec humi(.bin(duty[20:9]), .bcd(bcd_duty));
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(bcd_duty), .seg_7_ca(seg_7), .com(com));

endmodule

module adc_top(
    input clk,reset_p,
    input vauxp6, vauxn6,
    output [3:0] com,
    output [7:0] seg_7,
    output led_pwm);

    wire [4:0] channel_out;
    wire eoc_out;
    wire [15:0] do_out;
    
    xadc_wiz_0 adc_ch6
        (
        .daddr_in({2'b0, channel_out}),
        .dclk_in(clk),
        .den_in(eoc_out),
//        di_in,
//        dwe_in,
        .reset_in(reset_p),
        .vauxp6(vauxp6),
        .vauxn6(vauxn6),
//        busy_out,
        .channel_out(channel_out),
        .do_out(do_out),
//        drdy_out,
        .eoc_out(eoc_out)
//        eos_out,
//        alarm_out,
//        vp_in,
//        vn_in
        );
        
    wire eoc_out_pedge;
    edge_detector_n ed_timeout(.clk(clk), .reset_p(reset_p), .cp(eoc_out), .p_edge(eoc_out_pedge));
    
    reg [11:0] adc_value;
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)adc_value = 0;
        else if(eoc_out_pedge)adc_value = {4'b0, do_out[15:8]};
    end
    
    wire [15:0] bcd_value;
    bin_to_dec adc_bcd(.bin(adc_value), .bcd(bcd_value));
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(bcd_value), .seg_7_ca(seg_7), .com(com));
    
    pwm_128step pwm_led_r(.clk(clk), .reset_p(reset_p), 
            .duty(do_out[15:9]), .pwm_freq(10000), .pwm_128(led_pwm));

endmodule

module adc_sequence2_top(
    input clk, reset_p,
    input vauxp6, vauxn6,
    input vauxp15, vauxn15,
    output led_r, led_g, led_r_b, led_g_b,
    output [3:0] com,
    output [7:0] seg_7);
    
    wire eoc_out, eoc_out_pedge, eos_out_pedge;
    wire [4:0] channel_out;
    wire [15:0] do_out;
    
    adc_ch6_ch15 adc_seq2
    (
          .daddr_in({2'b0, channel_out}),            // Address bus for the dynamic reconfiguration port
          .dclk_in(clk),             // Clock input for the dynamic reconfiguration port
          .den_in(eoc_out),              // Enable Signal for the dynamic reconfiguration port
          .reset_in(reset_p),            // Reset signal for the System Monitor control logic
          .vauxp6(vauxp6),              // Auxiliary channel 6
          .vauxn6(vauxn6),
          .vauxp15(vauxp15),             // Auxiliary channel 15
          .vauxn15(vauxn15),
          .channel_out(channel_out),         // Channel Selection Outputs
          .do_out(do_out),              // Output data bus for dynamic reconfiguration port
          .eoc_out(eoc_out),             // End of Conversion Signal
          .eos_out(eos_out)              // End of Sequence Signal
    );
    
    edge_detector_n ed_eoc(.clk(clk), .reset_p(reset_p), .cp(eoc_out), .p_edge(eoc_out_pedge));
    edge_detector_n ed_eos(.clk(clk), .reset_p(reset_p), .cp(eos_out), .p_edge(eos_out_pedge));

    reg [11:0] adc_value_x, adc_value_y;
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            adc_value_x = 0;
            adc_value_y = 0;
        end
        else if(eoc_out_pedge)begin
            case(channel_out[3:0])
                6: adc_value_x = {4'b0, do_out[15:10]};
                15: adc_value_y = {4'b0, do_out[15:10]};
            endcase
        end
    end
    
    wire [15:0] bcd_value_x, bcd_value_y;
    bin_to_dec adc_x_bcd(.bin(adc_value_x), .bcd(bcd_value_x));
    bin_to_dec adc_y_bcd(.bin(adc_value_y), .bcd(bcd_value_y));
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value({bcd_value_x[7:0], bcd_value_y[7:0]}), .seg_7_ca(seg_7), .com(com));
    
    reg [6:0] duty_x, duty_y;
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            duty_x = 0;
            duty_y = 0;
        end
        else if(eos_out_pedge)begin
            duty_x = adc_value_x[6:0];
            duty_y = adc_value_y[6:0];
        end
    end
    
    pwm_128step pwm_led_r(.clk(clk), .reset_p(reset_p), 
            .duty(duty_x), .pwm_freq(10000), .pwm_128(led_r));
    pwm_128step pwm_led_g(.clk(clk), .reset_p(reset_p), 
            .duty(duty_y), .pwm_freq(10000), .pwm_128(led_g));
    
    wire led_r_b, led_g_b;
    assign led_r_b = led_r;
    assign led_g_b = led_g;

endmodule

module I2C_master_top(
    input clk, reset_p,
    input [1:0] btn,
    output sda, scl
);
    
    reg[7:0] data;
    reg valid;
    
    I2C_mster master(.clk(clk), .reset_p(reset_p), .rd_wr(0), .addr(7'h27), 
                .data(data), .valid(valid), .sda(sda), .scl(scl));
    
    wire [1:0] btn_pedge, btn_nedge;
    button_cntr ed0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), 
        .btn_pe(btn_pedge[0]), .btn_ne(btn_nedge[0]));
    button_cntr ed1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), 
        .btn_pe(btn_pedge[1]), .btn_ne(btn_nedge[1]));

    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            data = 0;
            valid = 0;
        end
        else begin
            if(btn_pedge[0])begin
                data = 8'b00000000;
                valid = 1;
            end
            else if(btn_nedge[0])valid = 0;
            else if(btn_pedge[1])begin
                data = 8'b00001000;
                valid = 1;
            end
            else if(btn_nedge[1])valid = 0;
        end
    end
    
endmodule

module i2c_txtlcd_top(
    input clk, reset_p,
    input [2:0] btn,
    output scl, sda);
    
    parameter IDLE          = 6'b000001;
    parameter INIT          = 6'b000010;
    parameter SEND          = 6'b000100;
    parameter MOVE_CURSOR   = 6'b001000;
    parameter SHIFT_DISPLAY = 6'b010000;
    
    parameter SAMPLE_DATA = "A";
    
    wire [2:0] btn_pedge;
    button_cntr ed0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr ed1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1]));
    button_cntr ed2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));

    
    reg [7:0] send_buffer;
    reg send_e, rs;
    //wire busy;
    
    i2c_lcd_send_byte send_byte(.clk(clk), .reset_p(reset_p), .addr(7'h27),
        .send_buffer(send_buffer), .send(send_e), .rs(rs), .scl(scl), .sda(sda), .busy(busy));
    
    reg [21:0] count_usec;
    reg count_usec_e;
    wire clk_usec;
    clock_usec usec_clk(clk, reset_p, clk_usec);
    
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)begin
            count_usec = 0;
        end
        else begin
            if(clk_usec&&count_usec_e)count_usec = count_usec + 1;
            else if(!count_usec_e)count_usec = 0;
        end
    end
    
    reg [5:0] state, next_state;
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)state = IDLE;
        else state = next_state;
    end
    
    reg init_flag;
    reg [3:0] cnt_data;
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            next_state = IDLE;
            send_buffer = 0;
            send_e = 0;
            rs = 0;
            init_flag = 0;
            cnt_data = 0;
        end
        else begin
            case(state)
                IDLE:begin
                    if(init_flag)begin
                        if(btn_pedge[0])next_state = SEND;
                        else if(btn_pedge[1])next_state = MOVE_CURSOR;
                        else if(btn_pedge[2])next_state = SHIFT_DISPLAY;
                    end
                    else begin
                        if(count_usec <= 22'd40000)begin
                            count_usec_e = 1;
                        end
                        else begin
                            next_state = INIT;
                            count_usec_e = 0;
                        end
                    end
                end
                INIT:begin
                    if(count_usec <= 22'd1000)begin
                        send_buffer = 8'h33;
                        send_e = 1;
                        count_usec_e = 1;
                    end
                    else if(count_usec <= 22'd1010)send_e = 0;
                    else if(count_usec <= 22'd2010)begin
                        send_buffer = 8'h32;
                        send_e = 1;
                        count_usec_e = 1;
                    end
                    else if(count_usec <= 22'd2020)send_e = 0;
                    else if(count_usec <= 22'd3020)begin
                        send_buffer = 8'h28;
                        send_e = 1;
                        count_usec_e = 1;
                    end
                    else if(count_usec <= 22'd3030)send_e = 0;
                    else if(count_usec <= 22'd4030)begin
                        send_buffer = 8'h0f;
                        send_e = 1;
                        count_usec_e = 1;
                    end
                    else if(count_usec <= 22'd4040)send_e = 0;
                    else if(count_usec <= 22'd5040)begin
                        send_buffer = 8'h01;
                        send_e = 1;
                        count_usec_e = 1;
                    end
                    else if(count_usec <= 22'd5050)send_e = 0;
                    else if(count_usec <= 22'd6050)begin
                        send_buffer = 8'h06;
                        send_e = 1;
                        count_usec_e = 1;
                    end
                    else if(count_usec <= 22'd6060)send_e = 0;
                    else begin
                        next_state = IDLE;
                        init_flag = 1;
                        count_usec_e = 0;
                    end
                end
                SEND:begin
                    if(busy)begin
                        next_state = IDLE;
                        send_e = 0;
                        cnt_data = cnt_data + 1;
                    end
                    else begin
                        send_buffer = SAMPLE_DATA + cnt_data;                    
                        rs = 1;
                        send_e = 1;
                    end
                end
                MOVE_CURSOR:begin
                    if(busy)begin
                        next_state = IDLE;
                        send_e = 0;
                    end
                    else begin
                        send_buffer = 8'hc0;                    
                        rs = 0;
                        send_e = 1;
                    end
                end
                SHIFT_DISPLAY:begin
                    if(busy)begin
                        next_state = IDLE;
                        send_e = 0;
                    end
                    else begin
                        send_buffer = 8'h1c;                    
                        rs = 0;
                        send_e = 1;
                    end
                end
            endcase
        end
    end
    
endmodule

module i2c_txtlcd_fan(
    input clk, reset_p,
    input [2:0] data_signal,         //1이면 send 2면 아래로 이동 4면 위로 이동
    input [7:0] data,
    output scl, sda);
    
    parameter IDLE               = 6'b000001;
    parameter INIT               = 6'b000010;
    parameter SEND               = 6'b000100;
    parameter MOVE_CURSOR_DOWN   = 6'b001000;
    parameter MOVE_CURSOR_UP     = 6'b010000;
        
    reg [7:0] send_buffer;
    reg send_e, rs;
    wire busy;
    
    i2c_lcd_send_byte send_byte(.clk(clk), .reset_p(reset_p), .addr(7'h27),
        .send_buffer(send_buffer), .send(send_e), .rs(rs), .scl(scl), .sda(sda), .busy(busy));
    
    reg [21:0] count_usec;
    reg count_usec_e;
    wire clk_usec;
    clock_usec usec_clk(clk, reset_p, clk_usec);
    
    wire [2:0] data_signal_pedge;
    edge_detector_n ed0(.clk(clk), .reset_p(reset_p), .cp(data_signal[0]), .p_edge(data_signal_pedge[0]));
    edge_detector_n ed1(.clk(clk), .reset_p(reset_p), .cp(data_signal[1]), .p_edge(data_signal_pedge[1]));
    edge_detector_n ed2(.clk(clk), .reset_p(reset_p), .cp(data_signal[2]), .p_edge(data_signal_pedge[2]));

    always @(negedge clk or posedge reset_p)begin
        if(reset_p)begin
            count_usec = 0;
        end
        else begin
            if(clk_usec&&count_usec_e)count_usec = count_usec + 1;
            else if(!count_usec_e)count_usec = 0;
        end
    end
    
    reg [5:0] state, next_state;
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)state = IDLE;
        else state = next_state;
    end
    
    reg init_flag;
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            next_state = IDLE;
            send_buffer = 0;
            send_e = 0;
            rs = 0;
            init_flag = 0;
        end
        else begin
            case(state)
                IDLE:begin
                    if(init_flag)begin
                        if(data_signal_pedge[0])next_state = SEND;
                        else if(data_signal_pedge[1])next_state = MOVE_CURSOR_DOWN;
                        else if(data_signal_pedge[2])next_state = MOVE_CURSOR_UP;
                    end
                    else begin
                        if(count_usec <= 22'd40000)begin
                            count_usec_e = 1;
                        end
                        else begin
                            next_state = INIT;
                            count_usec_e = 0;
                        end
                    end
                end
                INIT:begin
                    if(count_usec <= 22'd1000)begin
                        send_buffer = 8'h33;
                        send_e = 1;
                        count_usec_e = 1;
                    end
                    else if(count_usec <= 22'd1010)send_e = 0;
                    else if(count_usec <= 22'd2010)begin
                        send_buffer = 8'h32;
                        send_e = 1;
                        count_usec_e = 1;
                    end
                    else if(count_usec <= 22'd2020)send_e = 0;
                    else if(count_usec <= 22'd3020)begin
                        send_buffer = 8'h28;
                        send_e = 1;
                        count_usec_e = 1;
                    end
                    else if(count_usec <= 22'd3030)send_e = 0;
                    else if(count_usec <= 22'd4030)begin
                        send_buffer = 8'h0f;
                        send_e = 1;
                        count_usec_e = 1;
                    end
                    else if(count_usec <= 22'd4040)send_e = 0;
                    else if(count_usec <= 22'd5040)begin
                        send_buffer = 8'h01;
                        send_e = 1;
                        count_usec_e = 1;
                    end
                    else if(count_usec <= 22'd5050)send_e = 0;
                    else if(count_usec <= 22'd6050)begin
                        send_buffer = 8'h06;
                        send_e = 1;
                        count_usec_e = 1;
                    end
                    else if(count_usec <= 22'd6060)send_e = 0;
                    else begin
                        next_state = IDLE;
                        init_flag = 1;
                        count_usec_e = 0;
                    end
                end
                SEND:begin
                    if(busy)begin
                        next_state = IDLE;
                        send_e = 0;
                    end
                    else begin
                        send_buffer = data;                    
                        rs = 1;
                        send_e = 1;
                    end
                end
                MOVE_CURSOR_DOWN:begin
                    if(busy)begin
                        next_state = IDLE;
                        send_e = 0;
                    end
                    else begin
                        send_buffer = 8'hc0;                    
                        rs = 0;
                        send_e = 1;
                    end
                end
                MOVE_CURSOR_UP:begin
                    if(busy)begin
                        next_state = IDLE;
                        send_e = 0;
                    end
                    else begin
                        send_buffer = 8'h80;                    
                        rs = 0;
                        send_e = 1;
                    end
                end
            endcase
        end
    end
    
endmodule











