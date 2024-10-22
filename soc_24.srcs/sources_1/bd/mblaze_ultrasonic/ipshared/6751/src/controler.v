module ultrasonic(
    input clk, reset_p, echo,
    output reg trig,
    output reg [11:0] distance);

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
    
endmodule

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