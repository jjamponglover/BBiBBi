`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module project_1(
    input clk, reset_p,echo,
    input [3:0] btn,
    output [7:0] led_bar,
    output pwm, led, sg90,
    output trig,
    output [3:0] com,
    output [7:0] seg_7
    );
    
    wire [7:0] fan_led, timer_led;
    wire [19:0] cur_time;
    assign led_bar = {fan_led[4:1], timer_led[3:0]};
    wire fan_en, run_e, sencer;
    
    fan_controller #(125, 12) (clk, reset_p, btn[0], fan_en, fan_led, pwm, run_e);
    led_controller (clk, reset_p, btn[1], led);
    fan_timer (clk, reset_p, btn[2], run_e, alarm, timeout_pedge, cur_time, timer_led);
    motor_rotation (clk, reset_p, btn[3], run_e, sg90);
    ultrasonic_fan sonic (clk, reset_p, echo, trig, sencer);
    
    assign fan_en = timeout_pedge ? 0 : sencer ? 0 : 1;
       
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(cur_time[15:0]), .seg_7_ca(seg_7), .com(com));
    
endmodule


module fan_controller #(SYS_FREQ = 125, N = 12) (
    input clk, reset_p,
    input btn,              // ��ư �Է�
    input fan_en,           // �� ���� enable ��ȣ
    output [7:0] led_bar, // ���� ���� state ǥ��
    output pwm, 
    output reg run_e);         // ��� PWM ��ȣ

    //state ����
    localparam S_IDLE = 8'b0000_0001;
    localparam S_1    = 8'b0000_0010;
    localparam S_2    = 8'b0000_0100;
    localparam S_3    = 8'b0000_1000;
    localparam S_4    = 8'b0001_0000;
    localparam S_5    = 8'b0010_0000;
    localparam S_6    = 8'b0100_0000;
    localparam S_7    = 8'b1000_0000;

    // ��ư �Էº� ��Ʈ�ѷ�
    wire btn_p;
    button_cntr btn0(clk, reset_p, btn, btn_p);
        
    // FSM 
    reg [7:0] next_state, state;
    always @(negedge clk, posedge reset_p) begin
        if(reset_p) begin
            state <= S_IDLE;
        end
        else begin
            state <= next_state;
        end
    end

    assign led_bar = state;

    // btn �Է¿� ���� state ���� ����
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin
            next_state <= S_IDLE;
        end
        else begin
            if (fan_en) begin // fan_en�� Ȱ��ȭ �Ǿ��� ���� ����
                if (btn_p) begin
                    next_state <= {state[6:0], state[7]}; // state�� 1��Ʈ�� shift�Ͽ� ���� state�� �̵�
                end 
            end
            else begin // fan_en�� 0�� ��� IDLE ���·� �̵�- fan ����
                next_state <= S_IDLE;
            end
        end
    end

    // state �� ��Ƽ ����
    reg [N-1:0] fan_duty;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            fan_duty <= 0;
        end
        else begin
            case (state)
                S_IDLE : begin
                    fan_duty <= 0;
                    run_e = 0;
                end

                S_1 : begin
                    fan_duty <= 1023;
                    run_e = 1;
                end

                S_2 : begin
                    fan_duty <= 1535;
                end

                S_3 : begin
                    fan_duty <= 2047;
                end

                S_4 : begin
                    fan_duty <= 2559;
                end

                S_5 : begin
                    fan_duty <= 3071;
                end

                S_6 : begin
                    fan_duty <= 3583;
                end

                S_7 : begin
                    fan_duty <= 4095;
                end
            endcase
        end
    end

    //PWM ��� ���
    //200Hz 0~4095 ��Ƽ
    pwm_controller #(SYS_FREQ, N) (.clk(clk),
                                   .reset_p(reset_p),
                                   .duty(fan_duty), //0~4095
                                   .pwm_freq(200),
                                   .pwm(pwm)
                                   );
endmodule

module pwm_controller #(
    parameter SYS_FREQ = 125, //125MHz
    parameter N = 12 // 2^7 = 128�ܰ�
    )(
    input clk, reset_p,
    input [N-1:0] duty, //N��Ʈ�� duty��Ʈ
    input [13:0] pwm_freq,
    output reg pwm    );

    localparam REAL_SYS_FREQ = SYS_FREQ * 1000 * 1000;

    reg [26:0] cnt;
    reg pwm_clk_nbit; // 
    
    //clock�� ���� ���� �κ��̹Ƿ� �������� ����ص� negative slack�� �߻����� ����
    //ó���� �������� ����ϴµ��� �� pdt �ð� ���� ������ �߻� ���ɼ� ����
    wire [26:0] temp;
    assign temp = (REAL_SYS_FREQ /pwm_freq);

    always @(posedge reset_p, posedge clk) begin
        if (reset_p) begin
            pwm_clk_nbit <= 0;
            cnt <= 0;
        end
        else begin
            // 128�ܰ� ���� -> 2^7�� �����Ƿ� �콬��Ʈ �������� ��ü ����
            if (cnt >= temp[26:N] - 1) begin
            // 100�ܰ� ����
            // if (cnt >= REAL_SYS_FREQ /pwm_freq /100 - 1) begin
                cnt <= 0;
                pwm_clk_nbit <= 1'b1;
            end
            else begin
                pwm_clk_nbit <= 1'b0;
            end
            cnt = cnt + 1;

        end
    end

    reg [N-1:0] cnt_duty;
    always @(posedge reset_p, posedge clk) begin
        if (reset_p) begin
            pwm <= 1'b0;
            cnt_duty <= 0;
        end
        else begin
            if (pwm_clk_nbit) begin
                //2^N�ܰ�� ����
                cnt_duty <= cnt_duty + 1;
                if(cnt_duty < duty) pwm <= 1'b1;
                else pwm <= 1'b0;
            end           
        end
    end
endmodule

module fan_timer(
    input clk, reset_p,
    input btn,
    input run_e,
    output reg alarm, 
    output timeout_pedge,
    output [19:0] cur_time,
    output [3:0] led_bar);
    
    parameter OFF          = 4'b0001;
    parameter ONE          = 4'b0010;
    parameter THREE        = 4'b0100;
    parameter FIVE         = 4'b1000;
    
    wire btn_pedge, btn_nedge;
    button_cntr ed0(.clk(clk), .reset_p(reset_p), .btn(btn), .btn_pe(btn_pedge), .btn_ne(btn_nedge));
    
    reg [3:0] state, next_state;
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)state = OFF;
        else state = next_state;
    end
    
    assign led_bar = state;
    
    reg clk_en;
    reg [3:0] set_value;
    assign clk_start = clk_en ? clk : 0;
    
    down_timer down(.clk(clk_start), .reset_p(reset_p), .load_enable(btn_nedge), .set_value(set_value), .cur_time(cur_time));
    
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin
            next_state <= OFF;
        end
        else begin
            if (run_e) begin // fan_en�� Ȱ��ȭ �Ǿ��� ���� ����
                if (btn_pedge) begin
                    next_state <= {state[2:0], state[3]}; // state�� 1��Ʈ�� shift�Ͽ� ���� state�� �̵�
                end 
            end
            else begin // fan_en�� 0�� ��� IDLE ���·� �̵�- fan ����
                next_state <= OFF;
            end
        end
    end
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            clk_en = 0;
        end
        else begin
            case(state)
            OFF:begin
                clk_en = 0;
            end
            ONE:begin
                clk_en = 1;
                set_value = 1;
            end
            THREE:begin
                set_value = 3;
            end
            FIVE:begin
                set_value = 5;
            end
            endcase
        end
    end

    always @(posedge clk or posedge reset_p)begin
        if(reset_p) alarm = 0;
        else begin
            if(cur_time==0) alarm = 1;
            else alarm = 0;
        end
    end

    edge_detector_n ed_timeout(.clk(clk), .reset_p(reset_p), .cp(alarm), .p_edge(timeout_pedge));

endmodule

module down_timer(
    input clk, reset_p,
    input load_enable,
    input [3:0] set_value,
    output [19:0] cur_time);
    
    wire clk_sec, clk_sec10, clk_min1, clk_min10, clk_hour;
    wire [3:0] cur_sec1, cur_sec10, cur_min1, cur_min10, cur_hour;

    clk_set(clk, reset_p, clk_msec, clk_csec, clk_sec, clk_min);
    
    load_count_ud_N #(10) sec1(.clk(clk), .reset_p(reset_p), .clk_dn(clk_sec),
        .data_load(load_enable), .set_value(0), .digit(cur_sec1), .clk_under_flow(clk_sec10));
    load_count_ud_N #(6) sec10(.clk(clk), .reset_p(reset_p), .clk_dn(clk_sec10),
        .data_load(load_enable), .set_value(set_value), .digit(cur_sec10), .clk_under_flow(clk_min1));
    load_count_ud_N #(10) min1(.clk(clk), .reset_p(reset_p), .clk_dn(clk_min1),
        .data_load(load_enable), .set_value(0), .digit(cur_min1), .clk_under_flow(clk_min10));
    load_count_ud_N #(6) min10(.clk(clk), .reset_p(reset_p), .clk_dn(clk_min10),
        .data_load(load_enable), .set_value(0), .digit(cur_min10), .clk_under_flow(clk_hour));
    load_count_ud_N #(10) hour(.clk(clk), .reset_p(reset_p), .clk_dn(clk_hour),
        .data_load(load_enable), .set_value(0), .digit(cur_hour), .clk_under_flow());
    
    assign cur_time = {cur_hour, cur_min10, cur_min1, cur_sec10, cur_sec1};
        
endmodule

module load_count_ud_N #(
    parameter N = 10 )(
    input clk, reset_p,
    input clk_up,
    input clk_dn,
    input data_load,
    input [3:0] set_value,
    output reg [3:0] digit,
    output reg clk_over_flow,
    output reg clk_under_flow);

    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            digit = 0;
            clk_over_flow = 0;
            clk_under_flow = 0;
        end
        else begin
            if (data_load) begin
                digit = set_value;
            end
            else if (clk_up) begin
                if (digit >= (N-1)) begin 
                    digit = 0; 
                    clk_over_flow = 1;
                end
                else begin digit = digit + 1;
                end
            end
            else if (clk_dn) begin
                digit = digit - 1;
                if (digit > (N-1)) begin
                    digit = (N-1);
                    clk_under_flow = 1;
                end
            end
            else begin 
                clk_over_flow = 0;
                clk_under_flow = 0;
            end
        end
    end
endmodule

module led_controller(
    input clk, reset_p,
    input btn,
    output led);
    
    parameter IDLE      = 4'b0001;      // OFF
    parameter LED_1STEP = 4'b0010;      // 1�ܰ�
    parameter LED_2STEP = 4'b0100;      // 2�ܰ�
    parameter LED_3STEP = 4'b1000;      // 3�ܰ�
    
    wire btn_pedge;
    button_cntr btn_ctrl(.clk(clk), .reset_p(reset_p), .btn(btn), .btn_pe(btn_pedge));
    
    reg [6:0] duty;    
    reg [3:0] state;      // led_ringcounter
    always @(posedge clk, posedge reset_p) begin
        if(reset_p)begin
            state = IDLE;
            duty = 0;
        end
        else if(btn_pedge)begin
            if(state == IDLE)begin
                state = LED_1STEP;
                duty = 13;
            end
            else if(state == LED_1STEP)begin
                state = LED_2STEP;
                duty = 38;
            end
            else if(state == LED_2STEP)begin
                state = LED_3STEP;
                duty = 64;
            end
            else begin
                state = IDLE;
                duty = 0;
            end
        end
    end
    
    pwm_controller #(125, 9) (.clk(clk),
                              .reset_p(reset_p),
                              .duty(duty),
                              .pwm_freq(100),
                              .pwm(led)
                              );    
endmodule

module motor_rotation(
    input clk, reset_p,
    input btn,
    input run_e,
    output pwm);
    
    localparam MOTOR_STOP    = 2'b01;
    localparam MOTOR_START   = 2'b10;
    
    localparam RIGHT_MAX    = 75_000;      // 90
    localparam CENTER       = 200_000;
    localparam LEFT_MAX     = 325_000;      // -90    
    
    wire btn_pedge;
    button_cntr btn_ctrl0(.clk(clk), .reset_p(reset_p), .btn(btn), .btn_pe(btn_pedge));   // ���� ���� ����
    
    reg [31:0] clk_div;     // ������ ���ϴ� �ӵ��� �����ϱ� ����
    always @(posedge clk) clk_div <= clk_div + 1;
    
    wire clk_div_pedge;                                 // ���� Ŀ������ ������
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[10]), .p_edge(clk_div_pedge));
    
    reg [1:0] state, next_state;
    reg stop;
    
    always @(negedge clk or posedge reset_p)begin
        if(reset_p) state <= MOTOR_STOP;
        else state <= next_state;
    end
    
    assign pwm = stop ? 0 : sub_pwm;
    
    reg [21:0] duty;
    reg up_down;
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin
            duty <= CENTER;
            up_down <= 1;
            next_state <= MOTOR_STOP;
        end
        else begin
            case(state)
                MOTOR_STOP: begin
                    if(run_e&&btn_pedge) begin
                        next_state <= MOTOR_START;
                    end
                    else begin
                        duty <= duty;
                        stop <= 1;
                    end
                end
                MOTOR_START: begin
                    stop <= 0;
                    if(run_e)begin
                        if(btn_pedge) begin
                            next_state <= MOTOR_STOP;
                            up_down <= ~up_down;
                        end
                        else if(clk_div_pedge) begin
                            if(duty > LEFT_MAX) up_down <= 0;
                            else if(duty < RIGHT_MAX) up_down <= 1;
                            
                            if(up_down) duty <= duty + 1;
                            else duty <= duty - 1;
                        end
                    end
                    else next_state <= MOTOR_STOP;
                end                
            endcase
        end
    end
        
    pwm_512_period servo1(.clk(clk), .reset_p(reset_p), .duty(duty), .pwm_period(2_500_000), .pwm_512(sub_pwm));

endmodule


module fan_lcd(
    input clk, reset_p,
    input [1:0] btn,
    output sda, scl);

    wire clk_usec, clk_msec, clk_sec;
	clock_usec usec (clk, reset_p, clk_usec);
    clock_div_1000     msec (clk, reset_p, clk_usec, clk_msec);
    clock_div_1000      sec (clk, reset_p, clk_msec, clk_sec);
    
    reg [2:0] fan_speed;
    wire [7:0] temp_10, temp_1;
	wire [7:0] humi_10, humi_1;
    reg [7:0] time_h_1, time_m_10, time_m_1, time_s_10, time_s_1;
	reg [(7*8)-1:0] fan_speed_display;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
			fan_speed   <= 0;
			fan_speed_display <= 56'b0;
			time_h_1    <= 0;
            time_m_10   <= 0;
            time_m_1    <= 0;
            time_s_10   <= 0;
            time_s_1    <= 0;
        end
        else begin
            if (clk_sec) begin
                time_s_1 = time_s_1 + 1;
                if (time_s_1 == 10) begin
                    time_s_1 = 0;
                    time_s_10 = time_s_10 + 1;
                end
                if (time_s_10 == 6) begin
                    time_s_10 = 0;
                    time_m_1 = time_m_1 + 1;
                end
                if (time_m_1 == 10) begin
                    time_m_1 = 0;
                    time_m_10 = time_m_10 + 1;
                end
                if (time_m_10 == 6) begin
                    time_m_10 = 0;
                end
            end
        end
    end
            
    wire [2:0] bar;
    reg [127:0] string;
    wire btn_p, busy_flag;
    
    button_cntr btn0(clk, reset_p, btn[0], btn_p);
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p) string = 0;
        else string = {"RUNNING         "};
    end

    i2c_lcd_tx_string (.clk(clk), .reset_p(reset_p), .string(string), // 16 x 8bit(ascii)
	 .char_num(16),        // �Է� ���� ���ڿ��� ����
	 .data_in_signal(btn_p),        // ���� ���� ��ȣ
	 .data_signal(send),				 // ���� ���� ��ȣ
	 .busy_flag(busy_flag),		// busy flag
	 .scl(scl), .sda(sda),
	 .led_bar(bar));
	 

    parameter IDLE          = 5'b00001;
    parameter SAND_LINE_ONE = 5'b00010;
    parameter GO_LINE_TWO   = 5'b00100;
    parameter SAND_LINE_TWO = 5'b01000;
    parameter GO_LINE_ONE   = 5'b10000;
    
    reg [4:0] state, next_state;
    always @(negedge clk, posedge reset_p) begin
		if (reset_p) begin
			state = IDLE;
		end
		else begin
			state = next_state;
		end
	end
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            next_state = IDLE;
        end
        else begin
            case(state)
                IDLE: begin
                
                end
                
            
            endcase
        end
    end

endmodule 

module ultrasonic_fan(
    input clk, reset_p, echo,
    output reg trig,
    output reg sencer);

    parameter S_IDLE = 3'b001;
    parameter S_Trig_10US = 3'b010;
    parameter S_Read_Data = 3'b100;

    reg [11:0] distance;
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
    
    
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)sencer = 0;
        else if(distance < 12'h5)sencer = 1;
        else sencer = 0;
    end
    
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) state = S_IDLE;
        else state = next_state;
    end
    
//    reg [11:0] echo_time;
    reg cnt_e;
    wire [11:0] cm;
    sr04_div58 div58(clk, reset_p, clk_usec, cnt_e, cm);
    
    //�װ�Ƽ�� ������ ���ֱ� ���� clk�� clk_usec�� �ٲٸ�ȴ�.
    //�������ϰ� ���� �񵿱����� ����� �� ���� �ִ�.
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















