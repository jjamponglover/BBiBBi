`timescale 1ns / 1ps

module clock_usec(
    input clk, reset_p,
    output clk_usec);
    
    reg [6:0] cnt_sysclk; //basys 10ns, cora 8ns
    wire cp_usec;
    
    always @(negedge clk or posedge reset_p)begin
        if (reset_p) cnt_sysclk = 0;
        else if (cnt_sysclk >=124) cnt_sysclk=0;    //basys cnt_sysclk >=99
        else    cnt_sysclk = cnt_sysclk+1;
    end
    
    assign cp_usec = cnt_sysclk < 63 ? 0 : 1;   //basys cnt_sysclk < 50
    
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(cp_usec), .n_edge(clk_usec));
    
endmodule

module clock_div_10(
    input clk, reset_p,
    input clk_source,
    output clk_div_10);

    integer cnt_clk_source;
    reg cp_div_10;
    
    always @(posedge clk or posedge reset_p)begin
        if (reset_p)begin
            cnt_clk_source = 0;
            cp_div_10 = 0;
        end
        else if (clk_source) begin
            if (cnt_clk_source >=4) begin
                cnt_clk_source = 0;
                cp_div_10 = ~cp_div_10;
            end
            else cnt_clk_source = cnt_clk_source+1;
        end
    end

    //assign cp_msec = cnt_clk_source >= 499 ? 1 : 0 ;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(cp_div_10), .n_edge(clk_div_10));

endmodule
    
module clock_div_1000(
    input clk, reset_p,
    input clk_source,
    output clk_div_1000);

    reg [8:0] cnt_clk_source;
    reg cp_div_1000;
    
    always @(posedge clk or posedge reset_p)begin
        if (reset_p)begin
            cnt_clk_source = 0;
            cp_div_1000 = 0;
        end
        else if (clk_source) begin
            if (cnt_clk_source >=499) begin
                cnt_clk_source = 0;
                cp_div_1000 = ~cp_div_1000;
            end
            else cnt_clk_source = cnt_clk_source+1;
        end
    end

    //assign cp_msec = cnt_clk_source >= 499 ? 1 : 0 ;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(cp_div_1000), .n_edge(clk_div_1000));

endmodule
      
module clk_set(
    input clk, reset_p,
    output clk_msec, clk_csec, clk_sec, clk_min);
    
    clock_usec usec_clk(clk, reset_p, clk_usec);
    clock_div_1000 msec_clk(clk, reset_p, clk_usec, clk_msec);
    clock_div_10 csec_clk(clk, reset_p, clk_msec, clk_csec);
    clock_div_1000 sec_clk(clk, reset_p, clk_msec, clk_sec);
    clock_min min_clk(clk, reset_p, clk_sec, clk_min);
      
endmodule

module clock_min(
    input clk, reset_p,
    input clk_sec,
    output clk_min);

    reg [4:0] cnt_sec;
    reg cp_min;
    
    always @(posedge clk or posedge reset_p)begin
        if (reset_p)begin
            cnt_sec = 0;
            cp_min = 0;
        end
        else if (clk_sec) begin
            if (cnt_sec >= 29) begin
                cnt_sec = 0;
                cp_min = ~cp_min;
            end
            else cnt_sec = cnt_sec+1;
        end
    end

    //assign cp_msec = cnt_clk_source >= 499 ? 1 : 0 ;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(cp_min), .n_edge(clk_min));

endmodule

module counter_dec_60(
    input clk, reset_p,
    input clk_time,
    output reg [3:0] dec1, dec10
    );
    
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            dec1=0;
            dec10=0;
            
        end
        else begin
            if(clk_time) begin
                if(dec1 >=9) begin
                     dec1 = 0;
                     if (dec10>=5) dec10 =0;
                     else dec10 = dec10 + 1;
                end     
                else dec1 = dec1 +1;
            end            
        end
    end
endmodule

module counter_dec_100(
    input clk, reset_p,
    input clk_time,
    output reg [3:0] dec1, dec10
    );
    
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            dec1=0;
            dec10=0;
            
        end
        else begin
            if(clk_time) begin
                if(dec1 >=9) begin
                     dec1 = 0;
                     if (dec10>=9) dec10 =0;
                     else dec10 = dec10 + 1;
                end     
                else dec1 = dec1 +1;
            end            
        end
    end
endmodule

module loadable_counter_dec_60(
    input clk, reset_p,
    input clk_time,
    input load_enable,
    input [3:0] set_value1, set_value10,
    output reg [3:0] dec1, dec10);
    
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            dec1 = 0;
            dec10 = 0;
        end
        else begin
            if(load_enable)begin
                dec1 = set_value1;
                dec10 = set_value10;
            end
            else if (clk_time) begin
                if(dec1 >= 9)begin
                    dec1 = 0;
                    if (dec10 >= 5) dec10 = 0;
                    else dec10 = dec10 + 1;
                end
                else dec1 = dec1 +1;
            end
        end    
    end

endmodule

module loadable_down_counter_dec_60(
    input clk, reset_p,
    input clk_time,
    input load_enable,
    input [3:0] set_value1, set_value10,
    output reg [3:0] dec1, dec10,
    output reg dec_clk);
    
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            dec1 = 0;
            dec10 = 0;
        end
        else begin
            if(load_enable)begin
                dec1 = set_value1;
                dec10 = set_value10;
            end
            else if (clk_time) begin
                if(dec1 == 0)begin
                    dec1 = 9;
                    if (dec10 == 0) begin
                        dec10 = 5;
                        dec_clk = 1;
                    end    
                    else dec10 = dec10 - 1;
                end
                else dec1 = dec1 - 1;
            end
            else dec_clk = 0;
        end    
    end

endmodule

module sr04_div58(
    input clk, reset_p,
    input clk_usec, cnt_e,
    output reg [11:0] cm);

    integer cnt;
    
    always @(posedge clk or posedge reset_p)begin
        if (reset_p)begin
            cm = 0;
            cnt = 0;
        end
        else begin
            if(cnt_e)begin
                if(clk_usec)begin
                    cnt = cnt + 1;
                    if(cnt >= 58)begin
                        cnt = 0;
                        cm = cm +1;
                    end
                end
            end
            else begin
                cnt = 0;
                cm = 0;
            end
        end
    end

endmodule






