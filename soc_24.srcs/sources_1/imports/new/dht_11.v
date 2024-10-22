`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/13 15:46:02
// Design Name: 
// Module Name: dht_11
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module ultra_sonic_jh(
    input clk, reset_p,
    input echo,
    output reg trig,
    output [11:0] distance,
    output [7:0] led_bar    );

    parameter S_IDLE      = 4'b0001;
    parameter S_TRIG      = 4'b0010;
    parameter S_WAIT_ECHO_PEDGE = 4'b0100;
    parameter S_WAIT_ECHO_NEDGE = 4'b1000;

    //state ����
    reg [3:0]state, next_state;
    always @(negedge clk, posedge reset_p) begin
        if(reset_p) begin
            state = S_IDLE;
        end
        else begin
            state = next_state;
        end
    end
    
    //�ð� ������ Ÿ�̸�
    wire clk_usec;
    clock_usec clk_us0(clk, reset_p, clk_usec);
    
    //edge detect
    wire echo_p, echo_n;
    edge_detector_n ed0(clk, reset_p, echo, echo_p, echo_n);

    reg count_usec_e;
    reg [20:0] count_usec;
    always @(negedge clk, posedge reset_p) begin
        if(reset_p) count_usec = 0;
        else begin
            if(clk_usec && count_usec_e) count_usec = count_usec + 1;
            else if(!count_usec_e) count_usec = 0;
        end
    end


    //state ó��
    reg cnt_e;
    sr04_cnt58 dis_cnt(clk, reset_p, clk_usec, cnt_e, distance);

    always @(posedge clk, posedge reset_p) begin 
    // clk -> clk_usec ���� �ٲٸ� required time�� 1us�� �þ
    // always���� ��� ���� Ŭ���� ������� �ʰ� �ǹǷ� �񵿱� ȸ����
    // ��� clk_usec���� ����ϰų� ��� clk�� ����ؾ� ��
        if (reset_p) begin
            next_state <= S_IDLE;
            cnt_e <= 0;
            count_usec_e <= 0;
            trig <= 0;
        end
        else begin
            case (state) 

                //200ms ���� ��ȣ �߻�
                S_IDLE : begin
                    if (count_usec < 200_000) begin
                        count_usec_e <= 1;
                    end
                    else begin
                        next_state <= S_TRIG;
                        count_usec_e <= 0;
                    end
                end

                //TRIG 10us �߻�
                S_TRIG : begin
                    if (count_usec < 10) begin
                        count_usec_e <= 1;
                        trig <= 1'b1;
                    end
                    else begin
                        next_state <= S_WAIT_ECHO_PEDGE;
                        trig <= 1'b0;
                        count_usec_e <= 0;
                    end
                end

                S_WAIT_ECHO_PEDGE : begin
                    if (echo_p) begin 
                        next_state <= S_WAIT_ECHO_NEDGE;
                        count_usec_e <= 0;
                        cnt_e <= 1; // echo �ð� ���� ����
                    end
                    else begin
                        if (count_usec >= 10_000) begin // 10ms �̻� �ȵ�����
                            next_state <= S_IDLE;
                            count_usec_e <= 0;
                        end
                        else count_usec_e <= 1;
                    end
                end

                S_WAIT_ECHO_NEDGE : begin 
                    if (echo_n) begin
                        cnt_e <= 0;
                        count_usec_e <= 0;
                        next_state <= S_IDLE;
                    end
                    else begin
                        if (count_usec >= 20_000) begin // 20ms �̻� �ȵ�����
                            next_state <= S_IDLE;
                            count_usec_e <= 0;
                            cnt_e <= 0;
                        end             
                        else count_usec_e <= 1;           
                    end
                end
            endcase
        end
    end

    assign led_bar = {cnt_e, count_usec_e, 1'b0, 1'b0, state};
endmodule

module sr04_cnt58(
    input clk, reset_p,
    input clk_usec,
    input clk_e,
    output reg [11:0] distance);


    reg [6:0] cnt;
    reg [11:0] distance_cnt;
    always @(posedge reset_p, posedge clk) begin
        if(reset_p) begin
            cnt <= 0;
            distance <= 0;
            distance_cnt <= 0;
        end 
        else begin
            if (clk_e) begin
                if (clk_usec) begin
                    if (cnt >= 58) begin
                        cnt <= 0;
                        distance_cnt <= distance_cnt + 1;
                    end
                    else begin
                        cnt <= cnt + 1;
                    end
                end
            end 
            else begin
                distance <= distance_cnt;
                cnt <= 0;
            end
        end
    end
endmodule


module ultra_sonic_top_jh (
    input clk, reset_p,
    input echo,
    output trig,
    output [7:0] seg_7,
    output [3:0] com,
    output [7:0] led_bar    );

    wire [11:0] distance;
    ultra_sonic_jh us (clk, reset_p, echo, trig, distance, led_bar);

    // BCD ��ȯ
    wire [15:0] value;
    bin_to_dec dis(.bin(distance),
                   .bcd(value)          );

    fnd_4digit_cntr fnd(.clk(clk),
                         .reset_p(reset_p),
                         .value(value),
                         .seg_7_ca(seg_7),
                         .com(com)             );
endmodule



module dht11_fan(
    input clk, reset_p,
    inout dht11_data,   //InOut Input���ǰ� Output�� �ǰ�
    output reg [7:0] humidity, temperature,
    output [7:0] led_bar);

    parameter S_IDLE        = 6'b000001;
    parameter S_LOW_18MS    = 6'b000010;
    parameter S_HIGH_20US   = 6'b000100;
    parameter S_LOW_80US    = 6'b001000;
    parameter S_HIGH_80US   = 6'b010000;
    parameter S_READ_DATA   = 6'b100000;

    parameter S_WAIT_PEDGE = 2'b01;
    parameter S_WAIT_NEDGE = 2'b10;

    reg [21:0] count_usec;
    wire clk_usec;
    reg count_usec_e;
    clock_usec_jh usec_clk(clk, reset_p, clk_usec);

    //negedge��� ����
    //posedge���� 1Ŭ�� ������ �Ǿ� count �ʱ�ȭ �ȵǾ� �����߻�
    always @(negedge clk, posedge reset_p) begin
        if(reset_p) count_usec = 0;
        else begin
            if(clk_usec && count_usec_e) count_usec = count_usec + 1;
            else if(!count_usec_e) count_usec = 0;
        end
    end

    wire dht_pedge, dht_nedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(dht11_data),
        .p_edge(dht_pedge), .n_edge(dht_nedge));

    reg [5:0] state, next_state;
    reg [1:0] read_state;
    assign led_bar[5:0] = state;

    always @(negedge clk, posedge reset_p) begin
        if(reset_p) state = S_IDLE;
        else state = next_state;
    end

    reg [39:0] temp_data; //temporally
    reg [5:0] data_count;
    reg dht11_buffer;
    assign dht11_data = dht11_buffer;

    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin
            count_usec_e = 0;
            next_state = S_IDLE;
            dht11_buffer = 1'bz; //���Ǵ��� ���� , pullup���׶����� �����ͼ��� HIGH�� ��
            //InOut�� �ݵ�� ���Ǵ������¸� �����
            read_state = S_WAIT_PEDGE;
            data_count = 0;
        end
        else begin
            case(state)

                S_IDLE : begin
                    if(count_usec <= 22'd3_000_000) begin //3_000_000 3�ʰ� ������ ������
                        count_usec_e = 1;   //usec count�� ��� ����
                        dht11_buffer = 1'bz; //1�� �����Ǿ� ������
                        // ȸ�ΰ� pullup�̱� ������ ���Ǵ���������� �����ָ� �˾Ƽ� 1�̵ȴ�
                    end
                    else begin  //3�ʰ� ������
                        next_state = S_LOW_18MS; //�������� LOW18ms�� �Ѿ��
                        count_usec_e = 0;   //usec count�� 0���� �ʱ�ȭ
                    end
                end

                S_LOW_18MS : begin
                    if(count_usec <= 22'd20_000) begin //(�ּ�18ms) 20ms�� ������ ������
                        count_usec_e = 1;
                        dht11_buffer = 0;   //LOW(0)
                    end
                    else begin
                        count_usec_e = 0;
                        next_state = S_HIGH_20US;
                        dht11_buffer = 1'bz;    //��� �о���ϱ⶧���� ���Ǵ���������� ���������
                    end
                end

                S_HIGH_20US : begin
                    if(dht_nedge) begin  //�������� ���� ��ȣ�� negedge�� ������
                        next_state = S_LOW_80US; //�������·� �Ѿ��
                        count_usec_e = 0; //usec count�ʱ�ȭ
                    end
                    else begin                     //nedge�� ��ٸ�
                        count_usec_e = 1;          //ī���� Ȱ��ȭ
                        if (count_usec > 20) begin //20us �̻� ���� S_IDLE�� 
                            count_usec_e = 0;      //ī���� �ʱ�ȭ
                            next_state = S_IDLE; 
                        end
                    end
                end

                S_LOW_80US : begin //������ �������ִ� ��ȣ �д� �ð�
                    if(dht_pedge) begin  //�������� ���� ��ȣ�� pegedge�� ������
                        next_state = S_HIGH_80US; //�������·� �Ѿ��
                        count_usec_e = 0; //usec count�ʱ�ȭ
                    end
                    else begin 
                        count_usec_e = 1;           //ī���� Ȱ��ȭ
                        if (count_usec > 100) begin //100us �̻� ���� S_IDLE�� 
                            count_usec_e = 0;       //ī���� �ʱ�ȭ
                            next_state = S_IDLE; 
                        end
                    end
                end

                S_HIGH_80US : begin//������ �������ִ� ��ȣ �д� �ð�
                    if(dht_nedge) begin  //�������� ���� ��ȣ�� negedge�� ������
                        next_state = S_READ_DATA; //�������·� �Ѿ��
                        count_usec_e = 0; //usec count�ʱ�ȭ
                    end
                    else begin 
                        count_usec_e = 1;           //ī���� Ȱ��ȭ
                        if (count_usec > 100) begin //100us �̻� ���� S_IDLE�� 
                            count_usec_e = 0;       //ī���� �ʱ�ȭ
                            next_state = S_IDLE; 
                        end
                    end
                end

                S_READ_DATA : begin
                    case (read_state)
                        // ������ ������ ��  50us low level ���
                        S_WAIT_PEDGE : begin //���� ��ȣ�� pedge�� ��ٸ��� �ð�
                            if(dht_pedge) begin   //pedge�� ��� ����
                                count_usec_e = 0;
                                read_state = S_WAIT_NEDGE; //�������·� �Ѿ��
                            end
                            else begin
                                count_usec_e = 1;
                                if (count_usec > 60) begin //60us �̻� �����Ǹ� S_IDLE���·�
                                    count_usec_e = 0;
                                    next_state = S_IDLE;
                                end
                            end
                        end

                        S_WAIT_NEDGE : begin//���� ��ȣ�� nedge�� ��ٸ��鼭 �����͵��� �д� �ð�
                            if (dht_nedge) begin //nedge�� ��� ����
                                if (count_usec < 50) begin //��ٸ� �ð��� 50us �̸��̸� 0���� �Ǵ�
                                    temp_data = {temp_data[38:0], 1'b0}; //�ֻ��� ��Ʈ ������ �������� 0
                                end
                                else if (count_usec < 100)begin //50~100us �̸� 1�� �Ǵ�
                                    temp_data = {temp_data[38:0], 1'b1}; //��������Ʈ�� 1
                                end
                                else begin //100us �̻� ���� �ʱ�ȭ �� IDLE
                                    temp_data = 40'b0;
                                    next_state = S_IDLE;
                                end
                                count_usec_e = 0;
                                data_count = data_count + 1; //������ �ϳ� �о����ϴ� ǥ��
                                read_state = S_WAIT_PEDGE;
                            end
                            else begin  //nedge�� ������ ��������
                                count_usec_e = 1; //�ð��� ī��Ʈ �ϰ�
                            end
                        end
                    endcase

                    if (data_count >= 40) begin //������ 40�� �� ����
                        data_count = 0; //����count 0���� �ʱ�ȭ�ϰ�
                        next_state = S_IDLE; //�������´� IDLE����
                        humidity = temp_data[39:32];//tempdata�� �ֻ��� 8��Ʈ�� ����
                        temperature = temp_data[23:16];//23:16�� 8��Ʈ�� �µ�
                    end
                end
                default : next_state = S_IDLE;
            endcase
        end
    end
endmodule
// ���� �⺻���� ȸ�θ� ���� �� ���� ��Ȳ�� ���� �ڵ带 �ۼ� �ϴ� ���� ����뿡 �����
// �ѹ��� �ۼ��ϸ� ����� ���� �þ ������� ���� ����


module dht11_top_fan (
    input clk, reset_p,
    inout dht11_data,
    output [3:0] bcd_humi_10,
    output [3:0] bcd_humi_1,
    output [3:0] bcd_temp_10,
    output [3:0] bcd_temp_1
    );

    wire [7:0] humidity, temperature;
    dht11_fan dht(  .clk        (clk),
                .reset_p    (reset_p),
                .dht11_data (dht11_data),
                .humidity   (humidity),
                .temperature(temperature),
                .led_bar    (led_bar) );

    wire [15:0] bcd_humi, bcd_tmpr;
    bin_to_dec humi(.bin({4'b0000,humidity}),
                    .bcd(bcd_humi)          );
    bin_to_dec tmpr(.bin({4'b0000,temperature}),
                    .bcd(bcd_tmpr)          );

    assign bcd_humi_10 = bcd_humi[7:4];
    assign bcd_humi_1  = bcd_humi[3:0];
    assign bcd_temp_10 = bcd_tmpr[7:4];
    assign bcd_temp_1  = bcd_tmpr[3:0];
    
endmodule

/*
HD44780 - LCD Controller

RS (Register Select) : �������͸� �����ϴ� DEMUX ��ȣ
RS: 0 -> ��ɾ� �������Ϳ� �ۼ�
RS: 1 -> ������ �������Ϳ� �ۼ�

R/W^ : �б�/���� ���� ��ȣ
R/W^: 0 -> �б�, 1 -> ����

EN �� 1�� �Ǿ�� �������Ϳ� �����Ͱ� ������ (Level trigger)
�����͸� ���� �� EN�� 1 �־����

32ĭ x 2�� �޸� ���� ����

ȭ���� 16x2 �� ��µ�

��Ʈ �����ʹ� ���ο� �̹� ����Ǿ� ����

0011_0001 �� �Է��ϸ� ���� 1�� ����� -> ASCII�ڵ�� ����

Clear Display : ȭ�� �ʱ�ȭ
Return Home : Ŀ���� Ȩ���� �̵�
Entry Mode Set : Ŀ���� �̵� ���� ����
				- S : 1�̸� Ŀ�� �̵��� ȭ���� �̵�
	            - I/D : Ŀ�� �̵� ���� ���� (1�̸� ���������� �̵�)
Display On/Off Control : ȭ�� ǥ�� ����
				- D : 1�̸� ȭ�� ǥ��
				- C : 1�̸� Ŀ�� ǥ��
				- B : 1�̸� Ŀ�� ������


*/

/*
I2C

CLK�� LOW�϶� �����͸� �ٲٰ� HIGH�϶� �д´�

CLK�� HIGH�϶� falling edge -> start bit
CLK�� HIGH�϶� rising edge -> stop bit
MSB���� ���� (�ֻ���)
ACK : slave�� ������ �����ȣ. 0�̸� �����͸� �޾Ҵٴ� �ǹ�

		shift register
	  [ | | | | | | | ]

		->  ->  shift
SDA-  [7|6|5|4|3|2|1|0]  LSB���� 8���� �����Ͱ� ����
SCL-  clock 

 D7 |D6 |D5 |D4 |BT |EN |RW | RS
[ 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 ]

PC8574�� ADRESS : 0x27<<1 = 0x4E

*/

module i2c_master (
	input clk, reset_p,
	input rw,   //�б�/���� ���� R:1  W:0
	input [6:0] addr, //slave �ּ�
	input [7:0] data_in, //�Է� ������
	input valid, //���� ��ȣ
	output reg sda,
	output reg scl );

	localparam S_IDLE      		 = 7'b000_0001;
	localparam S_COMM_START		 = 7'b000_0010;
	localparam S_SEND_ADDR 		 = 7'b000_0100;
	localparam S_RD_ACK    		 = 7'b000_1000;
	localparam S_SEND_DATA 		 = 7'b001_0000;
	localparam S_SCL_STOP  		 = 7'b010_0000;
	localparam S_COMM_STOP 		 = 7'b100_0000;

	//�ּҿ� r/w ��ȣ ��ġ��
	wire [7:0] addr_rw;
	assign addr_rw = {addr, rw};

	// scl Ŭ�� 
	wire clock_usec;
	clock_usec_jh # (125) clk_us(clk, reset_p, clock_usec);

	//5us���� scl ����Ͽ� 10us �ֱ�� scl ����
	reg [2:0] cnt_usec_5;
	reg scl_toggle_e;
	always @(posedge clk, posedge reset_p) begin
		if (reset_p) begin
			cnt_usec_5 = 3'b000;
			scl = 1'b1;
		end
		else begin
			if (scl_toggle_e) begin
				if (clock_usec) begin
					if(cnt_usec_5 >= 4) begin
						cnt_usec_5 = 0;
						scl = ~scl;
					end
					else begin
						cnt_usec_5 = cnt_usec_5 + 1;
					end
				end
			end
			else begin // scl_toggle_e == 0 �϶� ī���� �ʱ�ȭ, scl 1�� ����
				cnt_usec_5 = 3'b000;
				scl = 1'b1;
			end
		end
	end

	// ���� ��ȣ edge detector
	wire valid_p;
	edge_detector_n edge_valid(clk, reset_p, valid, valid_p);

	//scl edge detector
	wire scl_p, scl_n;
	edge_detector_n edge_scl(clk, reset_p, scl, scl_p, scl_n);

	// finite state machine
	// negedge ���� ���� �ٲ� ����
	reg [6:0] state, next_state;
	always @(negedge clk, posedge reset_p)begin
		if(reset_p) begin
			state <= S_IDLE;
		end else 
		begin
			state <= next_state;
		end
	end

	reg [7:0] data_out;
	reg [2:0] d_out_cnt;
	reg send_data_done_flag;
	reg [2:0] cnt_stop;
	always @(posedge clk or posedge reset_p)begin
		if(reset_p) begin
			sda <= 1'b1;
			next_state <= S_IDLE;
			scl_toggle_e <= 1'b0;
			d_out_cnt <= 7;
			send_data_done_flag <= 1'b0;
			cnt_stop <= 0;
		end else 
		begin
			if (1) begin
				case (state)
					S_IDLE : begin 
						if(valid_p) begin //�ܺο��� ��ȣ�� ������ IDLE���¿��� START�� ��ȯ
							next_state <= S_COMM_START;
						end
						else begin // IDLE ���·� ���
							next_state <= S_IDLE;
							d_out_cnt <= 7;
						end
					end

					S_COMM_START : begin
						sda <= 1'b0; //start bit�� ����
						scl_toggle_e <= 1'b1; // scl ��� ���� 
						next_state <= S_SEND_ADDR; // ���� ���·�
					end

					S_SEND_ADDR : begin // �ֻ�����Ʈ���� ���� ����
						if(scl_n) sda = addr_rw[d_out_cnt];
						else if (scl_p) begin
							if (d_out_cnt == 0) begin
								d_out_cnt <= 7;
								next_state <= S_RD_ACK;
							end
							else d_out_cnt <= d_out_cnt - 1;
						end
					end
					
					S_RD_ACK : begin
						if(scl_n) begin 
							sda <= 'bz; // Z���·� ACK�� ��ٸ�
						end
						else if(scl_p) begin
							if(send_data_done_flag) begin // ������ ������ ���� ��� �ּ��������� ���������� �Ǵ��Ͽ� �������� ��ȯ 
								next_state <= S_SCL_STOP; 
							end
							else begin
								next_state <= S_SEND_DATA;
							end
							send_data_done_flag <= 0;
						end
					end

					S_SEND_DATA : begin // �ֻ�����Ʈ���� ���� ����
						if(scl_n) sda <= data_in[d_out_cnt];
						else if (scl_p) begin
							if (d_out_cnt == 0) begin
								d_out_cnt <= 7;
								next_state <= S_RD_ACK;
								send_data_done_flag <= 1;
							end
							else d_out_cnt <= d_out_cnt - 1;
						end
					end

					S_SCL_STOP : begin
						if (scl_n) begin
							sda <= 1'b0;
						end
						else if (scl_p) begin
							scl_toggle_e <= 1'b0; // scl ��� ����
							next_state <= S_COMM_STOP;
						end
					end

					S_COMM_STOP : begin
						if(clock_usec) begin
							cnt_stop <= cnt_stop + 1;
							if(cnt_stop >= 3) begin
								sda <= 1'b1;
								cnt_stop <= 0;
								next_state <= S_IDLE;
							end
						end
					end
				endcase
			end
		end
	end

endmodule

module i2c_txt_lcd_top (
    input clk, reset_p,
    input rs, // 0: command, 1: data
    input line, //���� �ѹ� 0, 1 -> 1���� 2����
    input [6:0] pos, // x��ǥ
    input [(16*8)-1:0] string, // 16 x 8bit(ascii)
    input [4:0] char_num,        // �Է� ���� ���ڿ��� ����
    input send, //���� ��ȣ
	output reg init_flag,
    output scl, sda);

    localparam ADDR = 7'h27;

    localparam IDLE         = 6'b00_0001;
    localparam WAIT         = 6'b00_0010;
    localparam INIT         = 6'b00_0100;
    localparam SEND_DATA    = 6'b00_1000;
    localparam SEND_CMD_XY  = 6'b01_0000;

    localparam RS_DATA = 1'b1;
    localparam RS_CMD  = 1'b0;
    localparam EN_0    = 1'b0;
    localparam EN_1    = 1'b1;

                                        // 01 + ddram address -> cursor position
    localparam SET_DDRAM_ADDR_LINE1     = 8'b10_00_0000; // line 1 first address
    localparam SET_DDRAM_ADDR_LINE2     = 8'b11_00_0000; // line 2 first address
    
    localparam SHIFT_DIPLAY_RIGHT = 8'b0001_1100;
    localparam SHIFT_DIPLAY_LEFT  = 8'b0001_1000;
    localparam SHIFT_CURSOR_RIGHT = 8'b0001_0100;
    localparam SHIFT_CURSOR_LEFT  = 8'b0001_0000;


    reg [7:0] send_buffer;

    edge_detector_n ed_send(.clk(clk), .reset_p(reset_p), .cp(send), .p_edge(send_p) );

    wire clk_usec;
	clock_usec_jh # (125) clk_us(clk, reset_p, clk_usec);

	// ms ī����
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

	// FSM
	reg [5:0]state, next_state;
	always @(negedge clk, posedge reset_p) begin
		if (reset_p) begin
			state <= IDLE;
		end
		else begin
			state <= next_state;
		end
	end

    reg send_e;
    reg [7:0] data_out;
    reg [7:0] cmd_out;
    reg [7:0] char_parse[15:0];
    reg [5:0] i;
    always @(posedge clk, posedge reset_p) begin
		if (reset_p) begin
            i <= 0;
            data_out <= 8'b0;
            cmd_out <= 8'b0;
			next_state <= IDLE;
            send_buffer <= 8'b0;
            send_e <= 1'b0;
            init_flag <= 1'b0;
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
			case (state)
                IDLE : begin
                    if (init_flag == 1) begin //rs = 1�̸� ������ ���� 0�̸� ��ǥ�̵����
                        if(send_p) begin
                            if (rs) begin
                                next_state <= SEND_DATA;
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
                            end
                            else begin
                                next_state <= SEND_CMD_XY;
                            end
                        end
                        else next_state <= IDLE;
                    end
                    else next_state <= WAIT;
                end
                
                WAIT : begin // 40ms ����ϰ�
                    if (cnt_us <= 20'd40_000) begin
                            cnt_us_e <= 1'b1;
                        end
                    else begin // 40ms�� ������ INIT ����
                        next_state = INIT;
                        cnt_us_e <= 1'b0; //Ÿ�̸Ӹ� �ʱ�ȭ
                    end
                end
                /*
                 N : 0�̸� 1��, 1�̸� 2��
                 F : 0�̸� 5x8, 1�̸� 5x10
                 I/D : 0�̸� Ŀ�� ��������, 1�̸� ���������� ����
                */
                INIT : begin 
                    // BL, EN, RW, RS
                    cnt_us_e = 1'b1;

                    // 3 3 3 2 2 8 0 c 0 1 0 6
                    // CMD FUNCTION SET  - EN 0����
                    if      (cnt_us <= 20'd100) send_buffer = {4'b0011, 4'b0000};
                    else if (cnt_us <= 20'd200) send_e      = 1'b1;
                    else if (cnt_us <= 20'd300) send_e      = 1'b0;

                    // CMD FUNCTION SET - 0011 ����
                    else if (cnt_us <= 20'd4500) send_buffer = {4'b0011, 4'b0100};
                    else if (cnt_us <= 20'd4600) send_e      = 1'b1;
                    else if (cnt_us <= 20'd4700) send_e      = 1'b0;
                    else if (cnt_us <= 20'd4800) send_buffer = {4'b0011, 4'b0000};
                    else if (cnt_us <= 20'd4900) send_e      = 1'b1;
                    else if (cnt_us <= 20'd5000) send_e      = 1'b0;

                    // CMD FUNCTION SET - 4ms ���� 0011 ����
                    else if (cnt_us <= 20'd9000) send_buffer = {4'b0011, 4'b0100};
                    else if (cnt_us <= 20'd9100) send_e      = 1'b1;
                    else if (cnt_us <= 20'd9200) send_e      = 1'b0;
                    else if (cnt_us <= 20'd9300) send_buffer = {4'b0011, 4'b0000};
                    else if (cnt_us <= 20'd9400) send_e      = 1'b1;
                    else if (cnt_us <= 20'd9500) send_e      = 1'b0;

                    // CMD FUNCTION SET - 4ms ���� 0011 ����
                    else if (cnt_us <= 20'd14000) send_buffer = {4'b0011, 4'b0100};
                    else if (cnt_us <= 20'd14100) send_e      = 1'b1;
                    else if (cnt_us <= 20'd14200) send_e      = 1'b0;
                    else if (cnt_us <= 20'd14300) send_buffer = {4'b0011, 4'b0000};
                    else if (cnt_us <= 20'd14400) send_e      = 1'b1;
                    else if (cnt_us <= 20'd14500) send_e      = 1'b0;

                    // 4ms ���� 0010 ����
                    else if (cnt_us <= 20'd18000) send_buffer = {4'b0010, 4'b0100};
                    else if (cnt_us <= 20'd18100) send_e      = 1'b1;
                    else if (cnt_us <= 20'd18200) send_e      = 1'b0;
                    else if (cnt_us <= 20'd18300) send_buffer = {4'b0010, 4'b0000};
                    else if (cnt_us <= 20'd18400) send_e      = 1'b1;
                    else if (cnt_us <= 20'd18500) send_e      = 1'b0;

                    // 100us ���� 0010_1000
                    else if (cnt_us <= 20'd19000) send_buffer = {4'b0010, 4'b0100};
                    else if (cnt_us <= 20'd19100) send_e      = 1'b1;
                    else if (cnt_us <= 20'd19200) send_e      = 1'b0;
                    else if (cnt_us <= 20'd19300) send_buffer = {4'b0010, 4'b0000};
                    else if (cnt_us <= 20'd19400) send_e      = 1'b1;
                    else if (cnt_us <= 20'd19500) send_e      = 1'b0;
                    else if (cnt_us <= 20'd19600) send_buffer = {4'b1000, 4'b0100};
                    else if (cnt_us <= 20'd19700) send_e      = 1'b1;
                    else if (cnt_us <= 20'd19800) send_e      = 1'b0;
                    else if (cnt_us <= 20'd19900) send_buffer = {4'b1000, 4'b0000};
                    else if (cnt_us <= 20'd20000) send_e      = 1'b1;
                    else if (cnt_us <= 20'd20100) send_e      = 1'b0;

                    // 100us ���� 0000_1110
                    else if (cnt_us <= 20'd20200) send_buffer = {4'b0000, 4'b0100};
                    else if (cnt_us <= 20'd20300) send_e      = 1'b1;
                    else if (cnt_us <= 20'd20400) send_e      = 1'b0;
                    else if (cnt_us <= 20'd20500) send_buffer = {4'b0000, 4'b0000};
                    else if (cnt_us <= 20'd20600) send_e      = 1'b1;
                    else if (cnt_us <= 20'd20700) send_e      = 1'b0;
                    else if (cnt_us <= 20'd20800) send_buffer = {4'b1100, 4'b0100};
                    else if (cnt_us <= 20'd20900) send_e      = 1'b1;
                    else if (cnt_us <= 20'd21000) send_e      = 1'b0;
                    else if (cnt_us <= 20'd21100) send_buffer = {4'b1100, 4'b0000};
                    else if (cnt_us <= 20'd21200) send_e      = 1'b1;
                    else if (cnt_us <= 20'd21300) send_e      = 1'b0;

                    // 100us ���� 0000_0001
                    else if (cnt_us <= 20'd21400) send_buffer = {4'b0000, 4'b0100};
                    else if (cnt_us <= 20'd21500) send_e      = 1'b1;
                    else if (cnt_us <= 20'd21600) send_e      = 1'b0;
                    else if (cnt_us <= 20'd21700) send_buffer = {4'b0000, 4'b0000};
                    else if (cnt_us <= 20'd21800) send_e      = 1'b1;
                    else if (cnt_us <= 20'd21900) send_e      = 1'b0;
                    else if (cnt_us <= 20'd22000) send_buffer = {4'b0001, 4'b0100};
                    else if (cnt_us <= 20'd22100) send_e      = 1'b1;
                    else if (cnt_us <= 20'd22200) send_e      = 1'b0;
                    else if (cnt_us <= 20'd22300) send_buffer = {4'b0001, 4'b0000};
                    else if (cnt_us <= 20'd22400) send_e      = 1'b1;
                    else if (cnt_us <= 20'd22500) send_e      = 1'b0;

                    // 2ms ���� 0000_0110
                    else if (cnt_us <= 20'd22600) send_buffer = {4'b0000, 4'b0100};
                    else if (cnt_us <= 20'd22700) send_e      = 1'b1;
                    else if (cnt_us <= 20'd22800) send_e      = 1'b0;
                    else if (cnt_us <= 20'd22900) send_buffer = {4'b0000, 4'b0000};
                    else if (cnt_us <= 20'd23000) send_e      = 1'b1;
                    else if (cnt_us <= 20'd23100) send_e      = 1'b0;
                    else if (cnt_us <= 20'd23200) send_buffer = {4'b0110, 4'b0100};
                    else if (cnt_us <= 20'd23300) send_e      = 1'b1;
                    else if (cnt_us <= 20'd23400) send_e      = 1'b0;
                    else if (cnt_us <= 20'd23500) send_buffer = {4'b0110, 4'b1000};
                    else if (cnt_us <= 20'd23600) send_e      = 1'b1;
                    else if (cnt_us <= 20'd23700) send_e      = 1'b0;

                    // ����
                    else if (cnt_us <= 20'd23800) begin
                        init_flag <= 1'b1;
                        next_state <= IDLE;
                        cnt_us_e = 1'b0;
                    end
                end

                SEND_CMD_XY : begin

                    cnt_us_e = 1'b1;

                    cmd_out = line ? (SET_DDRAM_ADDR_LINE2+pos) : (SET_DDRAM_ADDR_LINE1+pos) ;

                    if      (cnt_us <= 20'd100) send_buffer  = {cmd_out[7:4], 1'b1, EN_1, 1'b0, RS_CMD};
                    else if (cnt_us <= 20'd200) send_e       = 1'b1;
                    else if (cnt_us <= 20'd300) send_e       = 1'b0;
 
                    else if (cnt_us <= 20'd400) send_buffer  = {cmd_out[7:4], 1'b1, EN_0, 1'b0, RS_CMD};
                    else if (cnt_us <= 20'd500) send_e       = 1'b1;
                    else if (cnt_us <= 20'd600) send_e       = 1'b0;

                    else if (cnt_us <= 20'd700) send_buffer = {cmd_out[3:0], 1'b1, EN_1, 1'b0, RS_CMD};
                    else if (cnt_us <= 20'd800) send_e      = 1'b1;
                    else if (cnt_us <= 20'd900) send_e      = 1'b0;

                    else if (cnt_us <= 20'd1000) send_buffer = {cmd_out[3:0], 1'b1, EN_0, 1'b0, RS_CMD};
                    else if (cnt_us <= 20'd1100) send_e      = 1'b1;
                    else if (cnt_us <= 20'd1200) send_e      = 1'b0;

                    // ����
                    else if (cnt_us <= 20'd1300) begin
                        next_state <= IDLE;
                        cnt_us_e = 1'b0;
                    end
                end

                SEND_DATA : begin
                    
                    cnt_us_e = 1'b1;                    
                    data_out = char_parse[char_num-1-i];
                    if      (cnt_us <= 20'd100) send_buffer  = {data_out[7:4], 1'b1, EN_1, 1'b0, RS_DATA};
                    else if (cnt_us <= 20'd200) send_e       = 1'b1;
                    else if (cnt_us <= 20'd300) send_e       = 1'b0;
 
                    else if (cnt_us <= 20'd400) send_buffer  = {data_out[7:4], 1'b1, EN_0, 1'b0, RS_DATA};
                    else if (cnt_us <= 20'd500) send_e       = 1'b1;
                    else if (cnt_us <= 20'd600) send_e       = 1'b0;

                    else if (cnt_us <= 20'd700) send_buffer = {data_out[3:0], 1'b1, EN_1, 1'b0, RS_DATA};
                    else if (cnt_us <= 20'd800) send_e      = 1'b1;
                    else if (cnt_us <= 20'd900) send_e      = 1'b0;

                    else if (cnt_us <= 20'd1000) send_buffer = {data_out[3:0], 1'b1, EN_0, 1'b0, RS_DATA};
                    else if (cnt_us <= 20'd1100) send_e      = 1'b1;
                    else if (cnt_us <= 20'd1200) send_e      = 1'b0;

                    // ����
                    else if (cnt_us <= 20'd1300) begin
                        i = i + 1;
                        cnt_us_e = 1'b0;
                        if (i == char_num) begin
                            next_state <= IDLE;
                            i = 0;
                        end
                        else begin
                            next_state <= SEND_DATA;
                        end
                    end
                end

            endcase
 		end
	end

    i2c_master i2c( .clk(clk),
                    .reset_p(reset_p),
                    .rw(1'b0),
                    .addr(ADDR),
                    .data_in(send_buffer),
                    .valid(send_e),
                    .sda(sda),
                    .scl(scl) );
endmodule

module fan_info( 
    input clk, reset_p,
    input [3:0] btn,
	inout dht11_data,
	output [7:0] led_bar,
    output scl, sda );
    
    localparam GOTO_LINE1    = 10'b00_0000_0001;
    localparam SEND_LINE1    = 10'b00_0000_0010;
    localparam GOTO_LINE2    = 10'b00_0000_0100;
    localparam SEND_LINE2    = 10'b00_0000_1000;
    // localparam REMAING_TIME = 10'b00_0001_0000;
    // localparam GOTO_BAT     = 10'b00_1000_0000;
    // localparam REMAING_BAT  = 10'b01_0000_0000;

    wire init_flag;
    
    wire clk_usec, clk_msec, clk_sec;
	clock_usec_jh # (125) usec (clk, reset_p, clk_usec);
    clock_div_1000     msec (clk, reset_p, clk_usec, clk_msec);
    clock_div_1000      sec (clk, reset_p, clk_msec, clk_sec);

    wire [3:0] btn_p;
    button_cntr btn_0(clk, reset_p, btn[0], btn_p[0]);

	reg [20:0] cnt_ms;
	reg toggle_var;
	always @(negedge clk, posedge reset_p) begin
		if (reset_p) begin
			cnt_ms <= 20'b0;
			toggle_var <= 1'b0;
		end
		else begin
			if (clk_msec) begin
				cnt_ms <= cnt_ms + 1;
				if (cnt_ms > 500)begin
					toggle_var <= ~toggle_var;
					cnt_ms <= 20'b0;
				end
			end
		end
	end
    assign led_bar = {7'b0, toggle_var};
    

	// ms ī����
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

	// FSM
	reg [9:0]state, next_state;
	always @(negedge clk, posedge reset_p) begin
		if (reset_p) begin
			state <= GOTO_LINE1;
		end
		else begin
			state <= next_state;
		end
	end

	reg [2:0] fan_speed;
    wire [7:0] temp_10, temp_1;
	wire [7:0] humi_10, humi_1;
    reg [7:0] time_h_1, time_m_10, time_m_1, time_s_10, time_s_1;
	reg [(7*8)-1:0] fan_speed_display;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
			fan_speed   <= 0;
			fan_speed_display <= 56'b0;
            // temp_10     <= 0;
            // temp_1      <= 0;
			// humi_10     <= 0;
			// humi_1      <= 0;
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

            if (btn_p[0]) begin
				fan_speed = fan_speed + 1;              
            end
			
			if (toggle_var) begin
				case (fan_speed)
					0 : fan_speed_display       = "       ";
					1 : fan_speed_display       = "+      ";
					2 : fan_speed_display       = "+*     ";
					3 : fan_speed_display       = "+*+    ";
					4 : fan_speed_display       = "+*+*   ";
					5 : fan_speed_display       = "+*+*+  ";
					6 : fan_speed_display       = "+*+*+* ";
					7 : fan_speed_display       = "+*+*+*+";
					default : fan_speed_display = "       ";
				endcase 
			end
			else begin
				case (fan_speed)
					0 : fan_speed_display       = "       ";
					1 : fan_speed_display       = "*      ";
					2 : fan_speed_display       = "*+     ";
					3 : fan_speed_display       = "*+*    ";
					4 : fan_speed_display       = "*+*+   ";
					5 : fan_speed_display       = "*+*+*  ";
					6 : fan_speed_display       = "*+*+*+ ";
					7 : fan_speed_display       = "*+*+*+*";
					default : fan_speed_display = "       ";
				endcase 
			end
        end
    end

    reg rs;
    reg line;
    reg [6:0] pos;
    reg [(16*8)-1:0] string;
    reg [4:0] char_num;
    reg send;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            rs = 0;
            line = 0;
            pos = 0;
            string = 128'b0;
            char_num = 0;
            send = 0;
            cnt_us_e = 0;
            next_state = GOTO_LINE1;
        end
        else if (init_flag) begin
            case (state)

                GOTO_LINE1 : begin // temp�� Ŀ�� �̵�
                    if (cnt_us < 50_000) begin
                        cnt_us_e = 1;
                        line = 0;
                        pos = 0;
                        rs = 0;
                        send = 1;
                    end
                    else begin
                        send = 0;
                        cnt_us_e = 0;
                        next_state = SEND_LINE1;
                    end
                end

                SEND_LINE1 : begin
                    if (cnt_us < 50_000) begin //3ms
                        cnt_us_e = 1;
						// fan_speed, humi, temp
                        string = {fan_speed_display, " ", humi_10+8'h30, humi_1+8'h30, "% ", temp_10+8'h30, temp_1+8'h30, 8'b1101_1111,"C"}; // "TEMP : 20'C"
                        char_num = 16;
                        rs = 1;
                        send = 1;
                    end
                    else begin
                        send = 0;
                        cnt_us_e = 0;
                        next_state = GOTO_LINE2;                        
                    end
                end

                GOTO_LINE2: begin
                    if (cnt_us < 50_000) begin
                        cnt_us_e = 1;
                        line = 1;
                        pos = 0;
                        rs = 0;
                        send = 1;
                    end
                    else begin
                        send = 0;
                        cnt_us_e = 0;
                        next_state = SEND_LINE2;
                    end
                end

                SEND_LINE2 : begin
                    if (cnt_us < 50_000) begin //3ms
                        cnt_us_e = 1;
						if ({fan_speed} == 0) begin
							string = "    STOPPED!    ";
						end
						else begin
							string = {"RUNNING ", time_h_1+8'h30, "h", time_m_10+8'h30, time_m_1+8'h30, "m", time_s_10+8'h30, time_s_1+8'h30, "s"};
						end
                        char_num = 16;
                        rs = 1;
                        send = 1;
                    end
                    else begin
                        send = 0;
                        cnt_us_e = 0;
                        next_state = GOTO_LINE1;                        
                    end
                end
            endcase
        end
    end

	dht11_top_fan dht(.clk            (clk),
					.reset_p        (reset_p),
					.dht11_data     (dht11_data),
                    .bcd_humi_10    (humi_10),
                    .bcd_humi_1     (humi_1),
                    .bcd_temp_10    (temp_10),
                    .bcd_temp_1     (temp_1)  );

    i2c_txt_lcd_top str(.clk        (clk),
                        .reset_p    (reset_p),
                        .rs         (rs),
                        .line       (line),
                        .pos        (pos),
                        .string     (string),
                        .char_num   (char_num),
                        .send       (send),
                        .init_flag  (init_flag),
                        .scl        (scl),
                        .sda        (sda) );
endmodule

module clock_usec_jh # (
	parameter freq = 125 //Mhz
	)(
	input clk, reset_p,
	output clock_usec );
	
	localparam half_freq = freq/2;
	
	reg [6:0] cnt_sysclk; //1clk = 8ns
	wire cp_usec; // ���⵿ֱ�� 0, ���⵿ֱ�� 1

	always @(posedge clk, posedge reset_p) begin
		if (reset_p) cnt_sysclk =0;
		else if (cnt_sysclk >= freq-1) cnt_sysclk = 0;
		else cnt_sysclk = cnt_sysclk + 1;
	end

	//0.5us�� ��¿��� �߻�, 1us�� �ϰ����� �߻�
	//cp_usec
	// ___________----------__________---------________
	// 0        0.5us      1us      1.5us     2us
	assign cp_usec = (cnt_sysclk < half_freq) ? 0 : 1;

	//1us Ŭ�� ���� ���� �޽� ���
	//clock_usec
	// _____________________-__________________-______
	// 0                 1us+(clk/2)        2us+(clk/2)
	edge_detector_n ed1 (
		.clk(clk),
		.reset_p(reset_p),
		.cp(cp_usec),
		.n_edge(clock_usec)
	);
endmodule