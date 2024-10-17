module UART_RX
  #(parameter CLKS_PER_BIT = 100000000/9600)
  (
   input            reset_p,
   input            clk,
   input            i_RX_Serial,
   output reg [15:0] led,
   output reg       o_RX_DV       //RX Data Valid for one cycle 
   );
   
  localparam IDLE         = 3'b000;
  localparam RX_START_BIT = 3'b001;
  localparam RX_DATA_BITS = 3'b010;
  localparam RX_STOP_BIT  = 3'b011;
  localparam CLEANUP      = 3'b100;
  
  reg [7:0] o_RX_Byte;
  reg [7:0] data;
  reg [31:0] r_Clock_Count;
  reg [2:0] r_Bit_Index; //8 bits total
  reg [2:0] r_SM_Main;
  
  
  // Purpose: Control RX state machine
  always @(posedge clk or posedge reset_p)
  begin
    if (reset_p)
    begin
      r_SM_Main <= 3'b000;
      o_RX_DV   <= 1'b0;
    end
    else
    begin
      case (r_SM_Main)
      IDLE :
        begin
          o_RX_DV       <= 1'b0;
          r_Clock_Count <= 0;
          r_Bit_Index   <= 0;
          
          if (i_RX_Serial == 1'b0)          // Start bit detected
            r_SM_Main <= RX_START_BIT;
          else
            r_SM_Main <= IDLE;
        end
      
      // Check middle of start bit to make sure it's still low
      RX_START_BIT :begin
        if (r_Clock_Count == (CLKS_PER_BIT-1)/2)begin
            if (i_RX_Serial == 1'b0)begin
              r_Clock_Count <= 0;  // reset counter, found the middle
              r_Bit_Index <= 0;
              r_SM_Main     <= RX_DATA_BITS;
            end
            else begin
              r_SM_Main <= IDLE;
            end
        end
        else begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main     <= RX_START_BIT;
        end
      end // case: RX_START_BIT
      
      
      // Wait CLKS_PER_BIT-1 clock cycles to sample serial data
      RX_DATA_BITS :
        begin
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main     <= RX_DATA_BITS;
          end
          else
          begin
            r_Clock_Count          <= 0;
            o_RX_Byte[r_Bit_Index] <= i_RX_Serial;
            
            // Check if we have received all bits
            if (r_Bit_Index < 7)
            begin
              r_Bit_Index <= r_Bit_Index + 1;
              r_SM_Main   <= RX_DATA_BITS;
            end
            else
            begin
              r_Bit_Index <= 0;
              r_SM_Main   <= RX_STOP_BIT;
            end
          end
        end // case: RX_DATA_BITS
      
      
      // Receive Stop bit.  Stop bit = 1
      RX_STOP_BIT :
        begin
          // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main     <= RX_STOP_BIT;
          end
          else
          begin
            o_RX_DV       <= 1'b1;
            r_Clock_Count <= 0;
            data <= o_RX_Byte;
            r_SM_Main     <= CLEANUP;
          end
        end // case: RX_STOP_BIT
      
      
      // Stay here 1 clock
      CLEANUP :
        begin
          r_SM_Main <= IDLE;
          o_RX_DV   <= 1'b0;
        end
      
      default :
        r_SM_Main <= IDLE;
      
    endcase
    end // else: !if(~i_Rst_L)
  end // always @ (posedge i_Clock or negedge i_Rst_L)
  
  
  
    always @(posedge clk or posedge reset_p) begin
        if (reset_p)begin
            led <=16'h0000;
        end
//        else if (o_RX_Byte == "A") begin // 'A'를 수신하면
//            led <= o_RX_Byte;      // 모든 LED를 켭니다.
//        end 
//        else if (o_RX_Byte == "B") begin // 'B'를 수신하면
//            led <= 16'h0010;      // 모든 LED를 끕니다.
//        end
        else
        led <= {r_SM_Main,data};
    end
  
endmodule



module UART_TX 
  #(parameter CLKS_PER_BIT = 1000000/96)
  (
   input       reset_p,
   input       clk,
   input       i_TX_DV,         //TX Data Valid for one cycle
   input [7:0] i_TX_Byte, 
   output reg  o_TX_Active,
   output reg  o_TX_Serial,
   output reg  o_TX_Done
   );
 
  localparam IDLE         = 3'b000;
  localparam TX_START_BIT = 3'b001;
  localparam TX_DATA_BITS = 3'b010;
  localparam TX_STOP_BIT  = 3'b011;
  localparam CLEANUP      = 3'b100;
  
  reg [2:0] r_SM_Main;
  reg [$clog2(CLKS_PER_BIT):0] r_Clock_Count;
  reg [2:0] r_Bit_Index;
  reg [7:0] r_TX_Data;


  // Purpose: Control TX state machine
  always @(posedge clk or negedge reset_p)
  begin
    if (~reset_p)
    begin
      r_SM_Main <= 3'b000;
      o_TX_Done <= 1'b0;
    end
    else
    begin
      case (r_SM_Main)
      IDLE :
        begin
          o_TX_Serial   <= 1'b1;         // Drive Line High for Idle
          o_TX_Done     <= 1'b0;
          r_Clock_Count <= 0;
          r_Bit_Index   <= 0;
          
          if (i_TX_DV == 1'b1)
          begin
            o_TX_Active <= 1'b1;
            r_TX_Data   <= i_TX_Byte;
            r_SM_Main   <= TX_START_BIT;
          end
          else
            r_SM_Main <= IDLE;
        end // case: IDLE
      
      
      // Send out Start Bit. Start bit = 0
      TX_START_BIT :
        begin
          o_TX_Serial <= 1'b0;
          
          // Wait CLKS_PER_BIT-1 clock cycles for start bit to finish
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main     <= TX_START_BIT;
          end
          else
          begin
            r_Clock_Count <= 0;
            r_SM_Main     <= TX_DATA_BITS;
          end
        end // case: TX_START_BIT
      
      
      // Wait CLKS_PER_BIT-1 clock cycles for data bits to finish         
      TX_DATA_BITS :
        begin
          o_TX_Serial <= r_TX_Data[r_Bit_Index];
          
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main     <= TX_DATA_BITS;
          end
          else
          begin
            r_Clock_Count <= 0;
            
            // Check if we have sent out all bits
            if (r_Bit_Index < 7)
            begin
              r_Bit_Index <= r_Bit_Index + 1;
              r_SM_Main   <= TX_DATA_BITS;
            end
            else
            begin
              r_Bit_Index <= 0;
              r_SM_Main   <= TX_STOP_BIT;
            end
          end 
        end // case: TX_DATA_BITS
      
      
      // Send out Stop bit.  Stop bit = 1
      TX_STOP_BIT :
        begin
          o_TX_Serial <= 1'b1;
          
          // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main     <= TX_STOP_BIT;
          end
          else
          begin
            o_TX_Done     <= 1'b1;
            r_Clock_Count <= 0;
            r_SM_Main     <= CLEANUP;
            o_TX_Active   <= 1'b0;
          end 
        end // case: TX_STOP_BIT
      
      
      // Stay here 1 clock
      CLEANUP :
        begin
          r_SM_Main <= IDLE;
        end
      
      
      default :
        r_SM_Main <= IDLE;
      
    endcase
    end // else: !if(~i_Rst_L)
  end // always @ (posedge i_Clock or negedge i_Rst_L)

  
endmodule

module BluetoothControl(
    input clk,  // 시스템 클록
    input reset_p,
    input rx,   // RXD 핀 연결
//    output tx,
    output reg [15:0] led // LED 출력
);

    // UART 설정
    parameter CLK_FREQ = 100000000;  // 100 MHz
    parameter BAUD_RATE = 9600;      // HC-06의 기본 보드레이트
    localparam BAUD_VAL = CLK_FREQ / BAUD_RATE;
    
    // UART 수신 버퍼
    reg [7:0] rxBuf;
    reg [31:0] baud_counter;
    reg rx_sample;
    reg [3:0] bit_index;  // 데이터 비트 인덱스 (0-7)
    reg [9:0] rx_shift_reg;
    
    always @(posedge clk or posedge reset_p) begin
        if(reset_p)begin
        rxBuf = 0;
        baud_counter = 0;
        rx_sample = 0;
        bit_index = 0;  // 데이터 비트 인덱스 (0-7)
        rx_shift_reg = 0;
        end
        else if (baud_counter < BAUD_VAL) begin
            baud_counter <= baud_counter + 1;
        end 
        else begin
            baud_counter <= 0;
            rx_sample <= rx;
            rx_shift_reg <= {rx_sample, rx_shift_reg[9:1]};
            
            if (bit_index < 9) begin
                bit_index <= bit_index + 1;
            end else begin
                bit_index <= 0;
                rxBuf <= rx_shift_reg[8:1];  // 중앙 샘플링
            end
        end
    end

    // LED 제어
    always @(posedge clk) begin
        if (reset_p) begin // 'A'를 수신하면
            led <= 16'h0000;      // 모든 LED를 켭니다.
        end 
        else 
        led <= rxBuf;
    end

endmodule