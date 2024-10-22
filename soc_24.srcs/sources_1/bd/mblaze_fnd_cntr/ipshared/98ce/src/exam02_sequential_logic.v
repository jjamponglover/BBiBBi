`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module d_flip_flop_n(
    input d, clk, reset,
    output reg q);
    
    always @(negedge clk or posedge reset) begin
        if(reset) q=0;
        else q=d;
    end
endmodule

module d_flip_flop_p(
    input d, clk, reset,
    output reg q);
    
    always @(posedge clk or posedge reset) begin
        if(reset) q=0;
        else q=d;
    end
endmodule

module T_flip_flop_p(
    input clk, reset_p, t,
    output reg q);
    
//    wire qbar;
//    reg d;
//    assign qbar = ~q;
//    always @(*)begin    //*의 의미는 입력값이 변할때 동작한다
//        if (t) d=qbar;
//        else d=q;
//    end
    
    always @(posedge clk or posedge reset_p)begin
        if (reset_p) begin q=0; end
        else begin
            if(t) q=~q;
            else q=q;
        end
    end
    
endmodule

module T_flip_flop_n(
    input clk, reset_p,
    input t,
    output reg q);
    
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) begin q = 0; end
        else begin 
            if(t) q = ~q;
            else q = q;
        end
    end

endmodule

module up_counter_asyc(
    input clk, reset_p,
    output [3:0] count);
    
    T_flip_flop_n T0(.clk(clk), .reset_p(reset_p), .t(1), .q(count[0]));
    T_flip_flop_n T1(.clk(count[0]), .reset_p(reset_p), .t(1), .q(count[1]));
    T_flip_flop_n T2(.clk(count[1]), .reset_p(reset_p), .t(1), .q(count[2]));
    T_flip_flop_n T3(.clk(count[2]), .reset_p(reset_p), .t(1), .q(count[3]));
    
endmodule

module down_counter_asyc(
    input clk, reset_p,
    output [3:0] count);
    
    T_flip_flop_n T0(.clk(clk), .reset_p(reset_p), .t(1), .q(count[0]));
    T_flip_flop_n T1(.clk(count[0]), .reset_p(reset_p), .t(1), .q(count[1]));
    T_flip_flop_n T2(.clk(count[1]), .reset_p(reset_p), .t(1), .q(count[2]));
    T_flip_flop_n T3(.clk(count[2]), .reset_p(reset_p), .t(1), .q(count[3]));
    
endmodule

module up_counter_p(
    input clk, reset_p,
    output reg [15:0] count);
    
    always @(posedge clk or posedge reset_p)begin
        if (reset_p) count=0;
            else count=count+1;
        end

endmodule

module up_counter_test_top(
    input clk, reset_p,
    output [15:0] count,
    output [7:0] seg_7,
    output [3:0] com);
    
    reg [31:0] count_32;
    
    always @(posedge clk or posedge reset_p)begin
        if (reset_p) count_32=0;
            else count_32=count_32+1;
        end

    assign count=count_32[31:16];

    ring_counter_fnd rc (.clk(clk), .reset_p(reset_p), .com(com));
    
    reg [3:0] value;
    
    always @(posedge clk)begin
        case(com)
            4'b0111: value = count_32[31:28];
            4'b1011: value = count_32[27:24];
            4'b1101: value = count_32[23:20];
            4'b1110: value = count_32[19:16];
        endcase
    end
    
    decoder_7seg fnd (.hex_value(value), .seg_7(seg_7));
    
endmodule

module down_counter_Nbit_p #(parameter N = 8)(
    input clk, reset_p, enable,
    output reg [N-1:0] count);
    
    always @(posedge clk or posedge reset_p)begin
        if (reset_p) count=0;
        else begin 
            if (enable) count=count-1;
            else count=count;
        end
    end

endmodule

module bcd_up_counter_p(
    input clk, reset_p,
    output reg [3:0] count);
    
    always @(posedge clk or posedge reset_p)begin
        if (reset_p) count=0;
        else begin
            count=count+1;
            if (count==10) count=0;
        end 
    end

endmodule

module up_down_count(
    input clk, reset_p,down_up,
    output reg [3:0] count);
    
    always @(posedge clk or posedge reset_p)begin
        if (reset_p) count=0;
        else begin
            if (down_up) count=count-1;
            else count=count+1;
        end
    end

endmodule

module bcd_up_down_count(
    input clk, reset_p,down_up,
    output reg [3:0] count);
    
    always @(posedge clk or posedge reset_p)begin
        if (reset_p) count=0;
        else begin
            if (down_up)
                if (count==4'b1111) count=9;
                else count=count-1;
            else
                if(count==10) count=0;            
                else count=count+1;
        end
    end

endmodule

module ring_counter(
    input clk, reset_p,
    output  reg [3:0] q);
    
    always @(posedge clk or posedge reset_p)begin
        if (reset_p) q=4'b0001;
        else begin
            if(q==4'b0001) q=4'b1000;
            else if (q==4'b1000) q=4'b0100;
            else if (q==4'b0100) q=4'b0010;
            else                 q=4'b0001;
            
//            case(q)
//                4'b0001:q=4'b1000;
//                4'b1000:q=4'b0100;
//                4'b0100:q=4'b0010;
//                4'b0010:q=4'b0001;
//                default:q=4'b0001
//            endcase
        end
    end
    
endmodule

module ring_counter_fnd(
    input clk, reset_p,
    output  reg [3:0] com);
    
    reg [31:0] clk_div;
    wire clk_div_16;
    
    always @(posedge clk) clk_div = clk_div +1;
    
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .p_edge(clk_div_16));

    
    always @(posedge clk or posedge reset_p)begin
        if (reset_p) com=4'b1110;
        else if(clk_div_16)begin
            case(com)
                4'b1110:com=4'b1101;
                4'b1101:com=4'b1011;
                4'b1011:com=4'b0111;
                4'b0111:com=4'b1110;
                default:com=4'b1110;
            endcase
        end
    end
endmodule

module ring_counter_led(
    input clk, reset_p,
    output reg [7:0] count);
    
    reg [24:0] clk_div;
    wire posedge_clk_div_20;
    
    edge_detector_n ed(.clk(clk), .cp(clk_div[24]), .reset_p(reset_p), 
                        .p_edge(posedge_clk_div_20));
    
    always @(posedge clk or posedge reset_p)begin
        if (reset_p) clk_div = 0;
        else clk_div=clk_div+1;
    end
    
    always @(posedge clk or posedge reset_p)begin
        if (reset_p) begin
            count=8'b1111_1110;
            end
        else begin
            if(posedge_clk_div_20) count = {count[6:0], count[7]};
//            case(count)
//                16'b1:count=16'b10;
//                16'b10:count=16'b100;
//                16'b100:count=16'b1000;
//                16'b1000:count=16'b10000;
//                16'b10000:count=16'b100000;
//                16'b100000:count=16'b1000000;
//                16'b1000000:count=16'b10000000;
//                16'b10000000:count=16'b100000000;
//                16'b100000000:count=16'b1000000000;
//                16'b1000000000:count=16'b10000000000;
//                16'b10000000000:count=16'b100000000000;
//                16'b100000000000:count=16'b1000000000000;
//                16'b1000000000000:count=16'b10000000000000;
//                16'b10000000000000:count=16'b100000000000000;
//                16'b100000000000000:count=16'b1000000000000000;
//                16'b1000000000000000:count=16'b1;
//                default:count=16'b1;
//            endcase
        end
    end
endmodule

module edge_detector_n(
    input clk, reset_p, cp,
    output p_edge, n_edge);

    reg ff_cur, ff_old;
    
    always @(negedge clk or posedge reset_p) begin
        if (reset_p)begin 
            ff_cur = 0;
            ff_old = 0;
        end
        else begin
            ff_cur <= cp;       //'<=' non-blocking 병렬연결
            ff_old <= ff_cur;   //'=' blocking 직렬연결
        end
    end
    
    assign p_edge = ({ff_cur,ff_old} == 2'b10)?1:0;
    assign n_edge = ({ff_cur,ff_old} == 2'b01)?1:0; 
endmodule

module edge_detector_p(
    input clk, reset_p, cp,
    output p_edge, n_edge);

    reg ff_cur, ff_old;
    
    always @(posedge clk or posedge reset_p) begin
        if (reset_p)begin 
            ff_cur = 0;
            ff_old = 0;
        end
        else begin
            ff_cur <= cp;       //'<=' non-blocking 병렬연결
            ff_old <= ff_cur;   //'=' blocking 직렬연결
        end
    end
    
    assign p_edge = ({ff_cur,ff_old} == 2'b10)?1:0;
    assign n_edge = ({ff_cur,ff_old} == 2'b01)?1:0; 
endmodule

module shift_register_SISO_n(
    input clk,reset_p,    
    input d,
    output q);
   
   reg [3:0] siso_reg;
   
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) siso_reg <= 0;
        else begin
            siso_reg[3] <= d;
            siso_reg[2] <= siso_reg[3];
            siso_reg[1] <= siso_reg[2];
            siso_reg[0] <= siso_reg[1];
        end
    end
    assign q = siso_reg[0];
endmodule

module shift_register_SIPO_n(
    input clk,reset_p,
    input d, rd_en,
    output [3:0]q);

    reg [3:0]sipo_reg;

    always @(negedge clk or posedge reset_p) begin
           if(reset_p) sipo_reg <= 0;
           else begin
               sipo_reg = {d,sipo_reg[3:1]};
           end
       end
    
    assign q= rd_en ? sipo_reg : 4'bz;
//    bufif1 (q[0], sipo_ret, re_en);    
//    bufif1 (q[1], sipo_ret, re_en);    
//    bufif1 (q[2], sipo_ret, re_en);    
//    bufif1 (q[3], sipo_ret, re_en);    

endmodule

module shift_register_PISO_n(
    input clk,reset_p,
    input [3:0]d,
    input shift_load,
    output q);
    
    reg [3:0] piso_reg;
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p) piso_reg=0;
        else begin
            if(shift_load) piso_reg={1'b0,piso_reg[3:1]};
            else piso_reg = d;
        end
    end
    
    assign q=piso_reg[0];
    
endmodule

module register_Nbit_p #(parameter N=8)(
    input clk, reset_p,
    input [N-1:0] d,
    input wr_en, rd_en,
    output [N-1:0] q);

    reg [N-1:0] register;
    always @(posedge clk or posedge reset_p)begin
        if(reset_p) register = 0;
        else if(wr_en) register = d;
    end
    assign q = rd_en ? register:'bz;

endmodule

module sram_8bit_1024(
    input clk,
    input rd_en, wr_en,
    input [9:0] addr,
    inout [7:0] data);
    
    reg [7:0] mem [0:1023];
    always @(posedge clk)begin
        if(wr_en) mem[addr] <= data;
    end
    
    assign data = rd_en ? mem[addr] : 'bz;

endmodule










