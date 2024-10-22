`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module button_cntr(
    input clk, reset_p,
    input btn,
    output btn_pe, btn_ne);

    reg [16:0] clk_div;
    wire clk_div_16;
    reg debounced_btn;
        
    always @(posedge clk) clk_div = clk_div + 1;
    
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .p_edge(clk_div_16));
    
    always @(posedge clk, posedge reset_p)begin
        if(reset_p) debounced_btn = 0;
        else if(clk_div_16) debounced_btn = btn;
    end
    
    edge_detector_n ed0(.clk(clk), .reset_p(reset_p), .cp(debounced_btn), .p_edge(btn_pe), .n_edge(btn_ne));
endmodule


module fnd_4digit_cntr(
    input clk, reset_p,
    input [15:0] hex_value,
    input radix,
    output [7:0] seg_7_an,seg_7_ca,
    output [3:0] com);
    
    reg [3:0] decoder_value;
    wire [15:0] bcd_value;

    ring_counter_fnd rc(.clk(clk), .reset_p(reset_p), .com(com));

    always @(posedge clk)begin 
        case(com)
            4'b0111: begin
                if(radix)decoder_value = bcd_value[15:12];
                else decoder_value = hex_value[15:12];
            end
            4'b1011: begin
                if(radix)decoder_value = bcd_value[11:8];
                else decoder_value = hex_value[11:8];
            end
            4'b1101: begin
                if(radix)decoder_value = bcd_value[7:4];
                else decoder_value = hex_value[7:4];
            end
            4'b1110: begin
                if(radix)decoder_value = bcd_value[3:0];
                else decoder_value = hex_value[3:0];
            end    
        endcase    
    end
    
    bin_to_dec b2d(.bin(hex_value[11:0]), .bcd(bcd_value));
    
    decoder_7seg fnd (.hex_value(decoder_value), .seg_7(seg_7_an));
    assign seg_7_ca=~seg_7_an;
endmodule


module key_pad_cntr(
    input clk, reset_p,
    input [3:0] row,
    output reg [3:0] col,
    output reg [3:0] key_value,
    output reg key_valid
    );
    
    reg [19:0] clk_div;
    
    always @(posedge clk) clk_div = clk_div+1;
    wire clk_8msec;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[19]), .p_edge(clk_8msec_p), .n_edge(clk_8msec_n));

    always @(posedge clk or posedge reset_p)begin
        if (reset_p) col=4'b0001;
        else if(clk_8msec_p && !key_valid)begin
            case(col)
                4'b0001: col = 4'b0010;
                4'b0010: col = 4'b0100;
                4'b0100: col = 4'b1000;
                4'b1000: col = 4'b0001;
                default: col = 4'b0001;
            endcase 
        end
    end             
    
    always @(posedge clk, posedge reset_p)begin
        if (reset_p) begin
            key_value=0;
            key_valid=0;
        end
        else begin
            if(clk_8msec_n)begin
                if (row)begin
                    key_valid =1;
                    case({col,row})
                        8'b0001_0001: key_value = 4'h7;
                        8'b0001_0010: key_value = 4'h8;
                        8'b0001_0100: key_value = 4'h9;                                        
                        8'b0001_1000: key_value = 4'hA;
                        8'b0010_0001: key_value = 4'h4;
                        8'b0010_0010: key_value = 4'h5;
                        8'b0010_0100: key_value = 4'h6;                                        
                        8'b0010_1000: key_value = 4'hb;
                        8'b0100_0001: key_value = 4'h1;
                        8'b0100_0010: key_value = 4'h2;
                        8'b0100_0100: key_value = 4'h3;                                        
                        8'b0100_1000: key_value = 4'hE;
                        8'b1000_0001: key_value = 4'hC;
                        8'b1000_0010: key_value = 4'h0;
                        8'b1000_0100: key_value = 4'hF;                                        
                        8'b1000_1000: key_value = 4'hd;
                    endcase
                end
                else begin
                   key_valid=0; 
                   key_value=0;
                end
            end
        end    
    end
       
endmodule

module keypad_cntr_FSM(
    input clk, reset_p,
    input [3:0] row,
    output reg [3:0] col,
    output reg [3:0] key_value,
    output reg key_valid);

    parameter SCAN_0 = 1;
    parameter SCAN_1 = 2;
    parameter SCAN_2 = 3;        
    parameter SCAN_3 = 4;
    parameter KEY_PROCESS = 5;
    
    reg [2:0] state, next_state;
    
    always @* begin
        case(state)
            SCAN_0: begin
                if(row)next_state = KEY_PROCESS;
                else next_state= SCAN_1;
            end
            SCAN_1: begin
                if(row)next_state = KEY_PROCESS;
                else next_state= SCAN_2;
            end
            SCAN_2: begin
                if(row)next_state = KEY_PROCESS;
                else next_state= SCAN_3;
            end
            SCAN_3: begin
                if(row)next_state = KEY_PROCESS;
                else next_state= SCAN_0;
            end
            KEY_PROCESS: begin
                if(row) next_state = KEY_PROCESS;
                else next_state=SCAN_0;
            end
        endcase
    end
    
    reg [19:0] clk_div;
    always @(posedge clk)clk_div=clk_div + 1;
    wire clk_8msec;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[19]), .p_edge(clk_8msec));

    always @(posedge clk or posedge reset_p)begin
        if(reset_p)state = SCAN_0;
        else if (clk_8msec) state = next_state;
     end
        
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            key_value = 0;
            key_valid = 0;
            col = 4'b0000;
        end
        else begin
            case(state) 
                SCAN_0:begin col = 4'b0001; key_valid =0;end
                SCAN_1:begin col = 4'b0010; key_valid =0;end
                SCAN_2:begin col = 4'b0100; key_valid =0;end
                SCAN_3:begin col = 4'b1000; key_valid =0;end
                KEY_PROCESS:begin
                    key_valid = 1;
                    case({col,row})
                        8'b0001_0001: key_value = 4'h7;
                        8'b0001_0010: key_value = 4'h8;
                        8'b0001_0100: key_value = 4'h9;                                        
                        8'b0001_1000: key_value = 4'hA;
                        8'b0010_0001: key_value = 4'h4;
                        8'b0010_0010: key_value = 4'h5;
                        8'b0010_0100: key_value = 4'h6;                                        
                        8'b0010_1000: key_value = 4'hb;
                        8'b0100_0001: key_value = 4'h1;
                        8'b0100_0010: key_value = 4'h2;
                        8'b0100_0100: key_value = 4'h3;                                        
                        8'b0100_1000: key_value = 4'hE;
                        8'b1000_0001: key_value = 4'hC;
                        8'b1000_0010: key_value = 4'h0;
                        8'b1000_0100: key_value = 4'hF;                                        
                        8'b1000_1000: key_value = 4'hd;
                    endcase
                end    
            endcase
        end
    end    
        
endmodule

module rgb_test(
    input [3:0] btn,
    output [3:0] led
);
assign led=btn;
endmodule

module dht11(
    input clk, reset_p,
    inout dht11_data,
    output reg [7:0] humidity, temperature,
    output [7:0] led_bar, data_counter);

    parameter S_IDLE = 6'b000001;
    parameter S_LOW_18MS = 6'b000010;
    parameter S_HIGH_20US = 6'b000100;
    parameter S_LOW_80US = 6'b001000;
    parameter S_HIGH_80US = 6'b010000;
    parameter S_READ_DATA = 6'b100000;
    
    parameter S_WAIT_PEDGE = 2'b01;
    parameter S_WAIT_NEDGE = 2'b10;
    
    reg [21:0] count_usec;
    wire clk_usec;
    reg count_usec_e;
    clock_usec usec_clk(clk, reset_p, clk_usec);
    
    always @(negedge clk or posedge reset_p)begin
        if(reset_p) count_usec = 0;
        else begin
            if(clk_usec && count_usec_e) count_usec = count_usec +1;
            else if(!count_usec_e) count_usec = 0;
        end
    end
    wire dht_pedge, dht_nedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(dht11_data), .p_edge(dht_pedge), .n_edge(dht_nedge));
    
    reg [5:0] state, next_state;
    reg [1:0] read_state;
    
    assign led_bar[5:0] = state;
    
    
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) state = S_IDLE;
        else state = next_state;
    end
    
    reg [39:0] temp_data;
    reg [5:0] data_count;
    assign data_counter = {2'b00,data_count};
    reg dht11_buffer;
    assign dht11_data = dht11_buffer;
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            count_usec_e = 0;
            next_state = S_IDLE;
            dht11_buffer = 1'bz;
            read_state = S_WAIT_PEDGE;
            data_count = 0;
        end
        else begin
            case(state)
                S_IDLE:begin
                    if(count_usec < 22'd1_000)begin
                        count_usec_e = 1;
                        dht11_buffer = 1'bz;
                    end
                    else begin
                        next_state = S_LOW_18MS;
                        count_usec_e = 0;
                    end
                end
                S_LOW_18MS:begin
                    if(count_usec < 22'd20_000)begin
                        count_usec_e = 1;
                        dht11_buffer = 0;
                    end
                    else begin
                        count_usec_e = 0;
                        next_state = S_HIGH_20US;
                        dht11_buffer = 1'bz;
                    end
                end
                S_HIGH_20US:begin
                    count_usec_e = 1;
                    if(dht_nedge)begin
                        next_state = S_LOW_80US;
                        count_usec_e = 0;
                    end
                    if(count_usec > 22'd20_000)begin
                        next_state = S_IDLE;
                        count_usec_e = 0;
                    end
                end
                S_LOW_80US:begin
                    count_usec_e = 1;
                    if(dht_pedge)begin
                        next_state = S_HIGH_80US;
                        count_usec_e = 0;
                    end
                    if(count_usec > 22'd20_000)begin
                        next_state = S_IDLE;
                        count_usec_e = 0;
                    end
                end
                S_HIGH_80US:begin
                    count_usec_e = 1;
                    if(dht_nedge)begin
                        next_state = S_READ_DATA;
                        count_usec_e = 0;
                    end
                    if(count_usec > 22'd20_000)begin
                        next_state = S_IDLE;
                        count_usec_e = 0;
                    end
                end
                S_READ_DATA:begin
                    case(read_state)
                        S_WAIT_PEDGE:begin
                            if(dht_pedge)begin
                                read_state = S_WAIT_NEDGE;
                            end
                            count_usec_e = 0;
                        end
                        S_WAIT_NEDGE:begin
                            if(dht_nedge)begin
                                if(count_usec < 45)begin
                                    temp_data = {temp_data[38:0], 1'b0};
                                end
                                else begin
                                    temp_data = {temp_data[38:0], 1'b1};
                                end
                                data_count = data_count + 1;
                                read_state = S_WAIT_PEDGE;
                            end
                            else begin
                                count_usec_e = 1;
                            end
                        end
                    endcase
                    if(data_count >= 40)begin
                        data_count = 0;
                        next_state = S_IDLE;
                        humidity = temp_data[39:32];
                        temperature = temp_data[23:16];
                    end
                    if(count_usec > 22'd50_000) begin
                        data_count = 0;
                        next_state = S_IDLE;
                        count_usec_e = 0;
                    end
                end
                default : next_state = S_IDLE;
            endcase
        end
    end

endmodule

module ultrasonic(
    input clk, reset_p, echo,
    output reg trig,
    output reg [11:0] distance,
    output [7:0] led_bar);

    parameter S_IDLE = 3'b001;
    parameter S_Trig_10US = 3'b010;
    parameter S_Read_Data = 3'b100;

    reg [21:0] count_usec;
    wire clk_usec;
    reg count_usec_e;
    clock_usec usec_clk(clk, reset_p, clk_usec);
    
    always @(negedge clk or posedge reset_p)begin
        if(reset_p) count_usec = 0;
        else begin
            if(clk_usec && count_usec_e) count_usec = count_usec +1;
            else if(!count_usec_e) count_usec = 0;
        end
    end
    wire echo_pedge, echo_nedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(echo), .p_edge(echo_pedge), .n_edge(echo_nedge));
    
    reg [2:0] state, next_state;
    
    assign led_bar[7:0] = {5'b00000,state};
    
    
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) state = S_IDLE;
        else state = next_state;
    end
    
//    reg [11:0] echo_time;
    reg cnt_e;
    wire [11:0] cm;
    sr04_div58 div58(clk, reset_p, clk_usec, cnt_e, cm);
    
    //네거티브 슬랙을 없애기 위해 clk을 clk_usec로 바꾸면된다.
    //디테일하게 보면 비동기지만 동기로 볼 수도 있다.
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            count_usec_e = 0;
            next_state = S_IDLE;
            trig = 0;
        end
        else begin
            case(state)
                S_IDLE:begin
                    if(count_usec < 22'd1000_000)begin
                        count_usec_e = 1;
                    end
                    else begin
                        next_state = S_Trig_10US;
                        count_usec_e = 0;
                    end
                end
                S_Trig_10US:begin
                    if(count_usec <= 22'd10)begin
                        count_usec_e = 1;
                       
                        trig = 1;
                    end
                    else begin
                        count_usec_e = 0;
                        next_state = S_Read_Data;
                        trig = 0;
                    end
                end
                S_Read_Data:begin
                    if(echo_pedge)begin
                        cnt_e = 1;
                    end
                    else if(echo_nedge)begin
                        next_state = S_IDLE;
                        distance = cm;
                        cnt_e = 0;
                    end
                end
                default : next_state = S_IDLE;
            endcase
        end
    end
    

//무식한 방법
//    always @(posedge clk or posedge reset_p)begin
//        if(reset_p)distance = 0;
//        else begin
//            distance = echo_time/58; 
//            if(echo_time < 58) distance = 0;
//            else if(echo_time < 116) distance = 1;
//            else if(echo_time < 174) distance = 2;
//            else if(echo_time < 232) distance = 3;
//            else if(echo_time < 290) distance = 4;
//            else if(echo_time < 348) distance = 5;
//            else if(echo_time < 406) distance = 6;
//            else if(echo_time < 464) distance = 7;
//            else if(echo_time < 522) distance = 8;
//            else if(echo_time < 580) distance = 9;
//            else if(echo_time < 638) distance = 10;
//            else if(echo_time < 696) distance = 11;
//            else if(echo_time < 754) distance = 12;
//            else if(echo_time < 812) distance = 13;
//            else if(echo_time < 870) distance = 14;
//            else if(echo_time < 928) distance = 15;
//            else if(echo_time < 986) distance = 16;
//            else if(echo_time < 1044) distance = 17;
//            else if(echo_time < 1102) distance = 18;
//            else if(echo_time < 1160) distance = 19;
//            else if(echo_time < 1218) distance = 20;
//            else if(echo_time < 1276) distance = 21;
//            else if(echo_time < 1334) distance = 22;
//            else if(echo_time < 1392) distance = 23;
//            else if(echo_time < 1450) distance = 24;
//            else if(echo_time < 1508) distance = 25;
//            else if(echo_time < 1566) distance = 26;
//            else if(echo_time < 1624) distance = 27;
//            else if(echo_time < 1682) distance = 28;
//            else if(echo_time < 1740) distance = 29;
//            else if(echo_time < 1798) distance = 30;
//            else distance = 31;
//        end
//    end

endmodule

module pwm_128step(
    input clk, reset_p,
    input [6:0] duty,
    input [13:0] pwm_freq,
    output reg pwm_128);

    parameter sys_clk_freq = 125_000_000;   //100_000_000 basys
    
    reg[26:0] cnt;
    reg pwm_freqX128;
    
    wire [26:0] temp;
    assign temp = sys_clk_freq / pwm_freq ;
    
//    integer cnt_sysclk;
//    always @(posedge clk or posedge reset_p)begin
//        if(reset_p)cnt_sysclk = 0;
//        else if(cnt_sysclk >= pwm_freq - 1)begin
//            cnt_sysclk = 0;
//            temp = temp + 1;
//        end
//        else cnt_sysclk = cnt_sysclk + 1;
//    end
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            pwm_freqX128 = 0;
            cnt = 0;
        end
        else begin
            if(cnt >= temp[26:7] - 1)cnt = 0;   //temp[26:7] = sys_clk_freq / pwm_freq / 128
            else cnt = cnt + 1;
            
            //temp[26:7] = sys_clk_freq / pwm_freq / 128 / 2
            if(cnt < temp[26:8]) pwm_freqX128 = 0;
            else pwm_freqX128 = 1;
        end
    end
    
    wire pwm_freqX128_nedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(pwm_freqX128), .n_edge(pwm_freqX128_nedge));

    reg [6:0] cnt_duty;
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            cnt_duty = 0;
            pwm_128 = 0;
        end
        else begin
            if(pwm_freqX128_nedge)begin
                cnt_duty = cnt_duty + 1;
                if(cnt_duty < duty)pwm_128 = 1;
                else pwm_128 = 0;
            end
        end
    end

endmodule

module pwm_512step(
    input clk, reset_p,
    input [8:0] duty,
    input [13:0] pwm_freq,
    output reg pwm_512);

    parameter sys_clk_freq = 125_000_000;   //100_000_000 basys
    
    reg[26:0] cnt;
    reg pwm_freqX512;
    
    wire [26:0] temp;
    assign temp = sys_clk_freq / pwm_freq ;
    
//    integer cnt_sysclk;
//    always @(posedge clk or posedge reset_p)begin
//        if(reset_p)cnt_sysclk = 0;
//        else if(cnt_sysclk >= pwm_freq - 1)begin
//            cnt_sysclk = 0;
//            temp = temp + 1;
//        end
//        else cnt_sysclk = cnt_sysclk + 1;
//    end
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            pwm_freqX512 = 0;
            cnt = 0;
        end
        else begin
            if(cnt >= temp[26:9] - 1)cnt = 0;   //temp[26:7] = sys_clk_freq / pwm_freq / 128
            else cnt = cnt + 1;
            
            //temp[26:7] = sys_clk_freq / pwm_freq / 128 / 2
            if(cnt < temp[26:10]) pwm_freqX512 = 0;
            else pwm_freqX512 = 1;
        end
    end
    
    wire pwm_freqX512_nedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(pwm_freqX512), .n_edge(pwm_freqX512_nedge));

    reg [8:0] cnt_duty;
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            cnt_duty = 0;
            pwm_512 = 0;
        end
        else begin
            if(pwm_freqX512_nedge)begin
                cnt_duty = cnt_duty + 1;
                if(cnt_duty < duty)pwm_512 = 1;
                else pwm_512 = 0;
            end
        end
    end

endmodule

module pwm_1024step(
    input clk, reset_p,
    input [10:0] duty,
    input [13:0] pwm_freq,
    output reg pwm_1024);

    parameter sys_clk_freq = 125_000_000;   //100_000_000 basys
    
    reg[26:0] cnt;
    reg pwm_freqX1024;
    
    wire [26:0] temp;
    assign temp = sys_clk_freq / pwm_freq ;
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            pwm_freqX1024 = 0;
            cnt = 0;
        end
        else begin
            if(cnt >= temp[26:10] - 1)cnt = 0;   //temp[26:7] = sys_clk_freq / pwm_freq / 128
            else cnt = cnt + 1;
            
            //temp[26:7] = sys_clk_freq / pwm_freq / 128 / 2
            if(cnt < temp[26:11]) pwm_freqX1024 = 0;
            else pwm_freqX1024 = 1;
        end
    end
    
    wire pwm_freqX1025_nedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(pwm_freqX1024), .n_edge(pwm_freqX1024_nedge));

    reg [8:0] cnt_duty;
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            cnt_duty = 0;
            pwm_1024 = 0;
        end
        else begin
            if(pwm_freqX1024_nedge)begin
                cnt_duty = cnt_duty + 1;
                if(cnt_duty < duty)pwm_1024 = 1;
                else pwm_1024 = 0;
            end
        end
    end

endmodule

module pwm_512_period(
    input clk, reset_p,
    input [20:0] duty,
    input [21:0] pwm_period,
    output reg pwm_512);
       
    reg [20:0] cnt_duty;
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            cnt_duty = 0;
            pwm_512 = 0;
        end
        else begin
            if(cnt_duty >= pwm_period)cnt_duty = 0;
            else cnt_duty = cnt_duty + 1;
            
            if(cnt_duty < duty)pwm_512 = 1;
            else pwm_512 = 0;
        end
    end
    
endmodule

module I2C_mster(
    input clk, reset_p,
    input rd_wr,
    input [6:0] addr,
    input [7:0] data,
    input valid,
    output reg sda,
    output reg scl);

    parameter IDLE =        7'b000_0001;
    parameter COMM_START =  7'b000_0010;
    parameter SND_ADDR =    7'b000_0100;
    parameter RD_ACK =      7'b000_1000;
    parameter SND_DATA =    7'b001_0000;
    parameter SCL_STOP =    7'b010_0000;
    parameter COMM_STOP =   7'b100_0000;
    
    wire [7:0] addr_rw;
    assign addr_rw = {addr, rd_wr};
    
    wire clk_usec;
    clock_usec usec_clk(clk, reset_p, clk_usec);
    
    reg [2:0] count_usec5;
    reg scl_toggle_e;
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            count_usec5 = 0;
            scl = 1;
        end
        else if(scl_toggle_e)begin
            if(clk_usec)begin
                if(count_usec5 >= 4)begin
                    count_usec5 = 0;
                    scl = ~scl;
                end
                else count_usec5 = count_usec5 + 1;
            end
        end
        else if(scl_toggle_e == 0) count_usec5 = 0;
    end
    
    wire scl_nedge, scl_pedge;
    edge_detector_n ed_scl(.clk(clk), .reset_p(reset_p), . cp(scl),
                .n_edge(scl_nedge), .p_edge(scl_pedge));
    
    wire valid_pedge;
    edge_detector_n ed_valid(.clk(clk), .reset_p(reset_p), . cp(valid), .p_edge(valid_pedge));
    
    reg [6:0] state, next_state;
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)state = IDLE;
        else state = next_state;
    end
    
    reg [2:0] cnt_bit;
    reg stop_data;
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            sda = 1;
            next_state = IDLE;
            scl_toggle_e = 0;
            cnt_bit = 7;
            stop_data = 0;
        end
        else begin
            case(state)
                IDLE:begin
                    if(valid_pedge)next_state = COMM_START;
                end
                COMM_START:begin
                    sda = 0;
                    scl_toggle_e = 1;
                    next_state = SND_ADDR;
                end
                SND_ADDR:begin
                    if(scl_nedge)sda = addr_rw[cnt_bit];
                    else if(scl_pedge)begin
                        if(cnt_bit == 0)begin
                            cnt_bit = 7;
                            next_state = RD_ACK;
                        end
                        else cnt_bit = cnt_bit - 1;
                    end
                end
                RD_ACK:begin
                    if(scl_nedge)sda = 'bz;
                    else if(scl_pedge)begin
                        if(stop_data)begin
                            stop_data = 0;
                            next_state = SCL_STOP;
                        end
                        else begin
                            next_state = SND_DATA;
                        end
                    end
                end
                SND_DATA:begin
                    if(scl_nedge)sda = data[cnt_bit];
                    else if(scl_pedge)begin
                        if(cnt_bit == 0)begin
                            cnt_bit = 7;
                            next_state = RD_ACK;
                            stop_data = 1;
                        end
                        else cnt_bit = cnt_bit - 1;
                    end
                end
                SCL_STOP:begin
                    if(scl_nedge)begin
                        sda = 0;
                    end
                    else if(scl_pedge) next_state = COMM_STOP;
                end
                COMM_STOP:begin
                    if(count_usec5 >= 3)begin
                        sda = 1;
                        scl_toggle_e = 0;
                        next_state = IDLE;
                    end
                end
            endcase
        end
    end

endmodule

module i2c_lcd_send_byte(
    input clk, reset_p,
    input [6:0] addr,
    input [7:0] send_buffer,
    input send, rs,
    output scl, sda,
    output reg busy);
    
    parameter IDLE                      = 6'b000001;
    parameter SEND_HIGH_NIBBLE_DISABLE  = 6'b000010;
    parameter SEND_HIGH_NIBBLE_ENABLE   = 6'b000100;
    parameter SEND_LOW_NIBBLE_DISABLE   = 6'b001000;
    parameter SEND_LOW_NIBBLE_ENABLE    = 6'b010000;
    parameter SEND_DISABLE              = 6'b100000;
    
    reg [7:0] data;
    reg valid;
    
    wire send_pedge;
    edge_detector_n ed_valid(.clk(clk), .reset_p(reset_p), . cp(send), .p_edge(send_pedge));
    
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

    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            next_state = IDLE;
            busy = 0;
        end
        else begin
            case(state)
                IDLE:begin
                    if(send_pedge)begin
                        next_state = SEND_HIGH_NIBBLE_DISABLE;
                        busy = 1;
                    end
                end
                SEND_HIGH_NIBBLE_DISABLE:begin
                    if(count_usec <= 22'd200)begin
                        data = {send_buffer[7:4], 3'b100, rs};  //[d7 d6 d5 d4] [BL EN RW] RS
                        valid = 1;
                        count_usec_e = 1;
                    end
                    else begin
                        next_state = SEND_HIGH_NIBBLE_ENABLE;
                        count_usec_e = 0;
                        valid = 0;
                    end
                end
                SEND_HIGH_NIBBLE_ENABLE:begin
                    if(count_usec <= 22'd200)begin
                        data = {send_buffer[7:4], 3'b110, rs};  //[d7 d6 d5 d4] [BL EN RW] RS
                        valid = 1;
                        count_usec_e = 1;
                    end
                    else begin
                        next_state = SEND_LOW_NIBBLE_DISABLE;
                        count_usec_e = 0;
                        valid = 0;
                    end
                end
                SEND_LOW_NIBBLE_DISABLE:begin
                    if(count_usec <= 22'd200)begin
                        data = {send_buffer[3:0], 3'b100, rs};  //[d7 d6 d5 d4] [BL EN RW] RS
                        valid = 1;
                        count_usec_e = 1;
                    end
                    else begin
                        next_state = SEND_LOW_NIBBLE_ENABLE;
                        count_usec_e = 0;
                        valid = 0;
                    end
                end
                SEND_LOW_NIBBLE_ENABLE:begin
                    if(count_usec <= 22'd200)begin
                        data = {send_buffer[3:0], 3'b110, rs};  //[d7 d6 d5 d4] [BL EN RW] RS
                        valid = 1;
                        count_usec_e = 1;
                    end
                    else begin
                        next_state = SEND_DISABLE ;
                        count_usec_e = 0;
                        valid = 0;
                    end
                end
                SEND_DISABLE :begin
                    if(count_usec <= 22'd200)begin
                        data = {send_buffer[3:0], 3'b100, rs};  //[d7 d6 d5 d4] [BL EN RW] RS
                        valid = 1;
                        count_usec_e = 1;
                    end
                    else begin
                        next_state = IDLE;
                        count_usec_e = 0;
                        valid = 0;
                        busy = 0;
                    end
                end
            endcase
        end
    end
    
    I2C_mster master(.clk(clk), .reset_p(reset_p), .rd_wr(0), .addr(addr), 
                .data(data), .valid(valid), .sda(sda), .scl(scl));

endmodule

module i2c_lcd_tx_string (
	input clk, reset_p,
	input [127:0] string, // 16 x 8bit(ascii)
	input data_in_signal,        // 문자 전송 신호
	output reg busy_flag,		// busy flag
	output scl, sda);

	localparam S_IDLE         = 3'b001;
	localparam S_PARSING      = 3'b010;
	localparam S_SEND_CHAR	  = 3'b100;
    
    wire clk_usec;
	clock_usec clk_us(clk, reset_p, clk_usec);

	// ms 카운터
	reg [20:0] cnt_us;
	reg cnt_us_e;
	always @(negedge clk, posedge reset_p) begin
		if (reset_p) begin
			cnt_us <= 20'b0;
		end
		else begin
			if (cnt_us_e) begin
				if (clk_usec) begin
					cnt_us <= cnt_us + 1;
				end
			end
			else begin
				cnt_us <= 20'b0;
			end
		end
	end
    
	wire data_in_signal_p;
	edge_detector_n edge_send(clk, reset_p, data_in_signal, data_in_signal_p);
	
    reg [2:0] data_signal;
    reg [7:0] data;
    
    i2c_txtlcd_fan txtlcd(clk, reset_p, data_signal, //001이면 send (010, 100) 줄 이동
                    data, scl, sda);
	
	// 문자열 파싱 배열
	reg [7:0] char_parse[15:0];
	reg [5:0] i;
	wire char_num = 16;
	reg [2:0] state, next_state;
	
	always @(negedge clk, posedge reset_p) begin
		if (reset_p) begin
			state <= S_IDLE;
		end
		else begin
			state <= next_state;
		end
	end
	
	always @(posedge clk, posedge reset_p) begin
		if (reset_p) begin
			i <= 0;
			cnt_us_e <= 0;
			data_signal <= 0;
			data <= 8'b0;
			busy_flag <= 0;
			next_state <= S_IDLE;
			char_parse[0]  <= 8'b0;           
			char_parse[1]  <= 8'b0;           
			char_parse[2]  <= 8'b0;           
			char_parse[3]  <= 8'b0;           
			char_parse[4]  <= 8'b0;           
			char_parse[5]  <= 8'b0;           
			char_parse[6]  <= 8'b0;           
			char_parse[7]  <= 8'b0;           
			char_parse[8]  <= 8'b0;           
			char_parse[9]  <= 8'b0;           
			char_parse[10] <= 8'b0;           
			char_parse[11] <= 8'b0;           
			char_parse[12] <= 8'b0;           
			char_parse[13] <= 8'b0;           
			char_parse[14] <= 8'b0;           
			char_parse[15] <= 8'b0;           
		end
		else begin
			case(state) 
				S_IDLE : begin
					if (data_in_signal_p) begin
						next_state <= S_PARSING;
						busy_flag <= 1;
					end
				end

				S_PARSING : begin
					char_parse[ 0]  <= string[  7:  0];
					char_parse[ 1]  <= string[ 15:  8];
					char_parse[ 2]  <= string[ 23: 16];
					char_parse[ 3]  <= string[ 31: 24];
					char_parse[ 4]  <= string[ 39: 32];
					char_parse[ 5]  <= string[ 47: 40];
					char_parse[ 6]  <= string[ 55: 48];
					char_parse[ 7]  <= string[ 63: 56];
					char_parse[ 8]  <= string[ 71: 64];
					char_parse[ 9]  <= string[ 79: 72];
					char_parse[10]  <= string[ 87: 80];
					char_parse[11]  <= string[ 95: 88];
					char_parse[12]  <= string[103: 96];
					char_parse[13]  <= string[111:104];
					char_parse[14]  <= string[119:112];
					char_parse[15]  <= string[127:120];
					next_state <= S_SEND_CHAR;
				end

				S_SEND_CHAR : begin // char_num이 8이면 7까지 돌리면 됨
					if (i < char_num) begin // 문자열 길이만큼 반복
						if (cnt_us < 2000) begin // 500us 동안
							cnt_us_e <= 1; // 카운터 시작
							data <= char_parse[char_num-i-1]; //n-1부터 시작
							data_signal <= 3'b001; // 문자 전송
						end
						else begin
							cnt_us_e <= 0; // 카운터 초기화
							data_signal <= 0;
							i <= i + 1; // 다음 문자로 이동
						end
					end
					else begin //모든 문자 전송 후 대기 상태로
						next_state <= S_IDLE;
						busy_flag <= 0;
						i <= 0;						
					end
				end
			endcase
		end
	end

endmodule













