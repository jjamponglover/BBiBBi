#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xil_exception.h"
#include "xiic.h"
#include "xuartlite.h"

#define IIC_ID 				XPAR_IIC_0_DEVICE_ID
#define KEYPAD_ADDR			XPAR_MYIP_KEYPAD_0_S00_AXI_BASEADDR
#define UART0_ID 			XPAR_AXI_UARTLITE_0_DEVICE_ID
//bluetooth
#define UART1_ID 			1U

void Iic_LCD_write_byte(u8 tx_data, u8 rs);
void Iic_LCD_init(void);
void Iic_movecursor(u8 row, u8 col);
void LCD_write_string(char *string);	//문자열 배열 -> 주소값으로 받아야함
void Iic_LCD_create_char(u8 location, u8 charmap[]);
char keypad_value1(u8 key_input);
char keypad_value2(u8 key_input);
char keypad_value3(u8 key_input);
char keypad_number(u8 key_input);
char keypad(u8 key_input);
//int mode_change();
int Num_mode();
void handle_backspace();
void SendHandler(void *CallBackRef, unsigned int EvetnData);
void RecvHandler(void *CallBackRef, unsigned int EvetnData);
void clear_lcd(int a);

XIic iic_device;
XUartLite uart_device;

#define MAX_LCD_CHAR        80  	// 한 줄에 40자, 두 줄이므로 총 80자
#define NUM_KEYS 			16		// key 16개

#define BL 3
#define EN 2
#define RW 1
#define RS 0

#define COMMAND 0
#define DATA 1

int lcd_count = 0;	//lcd 자리
int mode_count = 0;
int current_key = 0;
int key_count[NUM_KEYS] = {0};		// 각 키의 누른 횟수를 세는 배열

char lcd_string[MAX_LCD_CHAR + 1] 	= {0};  	// LCD에 입력된 문자열을 저장할 배열
volatile char Tx[MAX_LCD_CHAR + 1] 	= {0};		// 전송 시 LCD 문자열을 넘겨 받을 Tx 배열
volatile char Rx[MAX_LCD_CHAR + 1]  = {0};

int main()
{
	unsigned int *key_input = (volatile unsigned int *)KEYPAD_ADDR;
	u8 data = 0 ;
	u8 key_data = 0;
	u8 count_mode = 0;		// 영어 입력 3가지 모드 전환
	u8 heart[8] = {			// 꽉찬 하트
			        0b00000,
			        0b01010,
			        0b11111,
			        0b11111,
			        0b11111,
			        0b01110,
			        0b00100,
			        0b00000
			    	};
	u8 empty_heart[8] = {		// 빈 하트
					0b00000,
					0b01010,
					0b10101,
					0b10001,
					0b10001,
					0b01010,
					0b00100,
					0b00000
					};
	u8 smile[8] = {			// 'U'
					0b00000,
					0b01010,
					0b01010,
					0b00000,
					0b10001,
					0b01110,
					0b00000,
					0b00000
				    };
	u8 mr[8] = {			// 메롱
					0b00000,
					0b01010,
					0b01010,
					0b00000,
					0b11111,
					0b01010,
					0b01110,
					0b00000
					};
	u8 hat[8] = {			// 모자
					0b01110,
					0b01010,
					0b11111,
					0b00000,
					0b01010,
					0b01010,
					0b10001,
					0b01110
					};

	init_platform();

	XIic_Initialize(&iic_device, IIC_ID);
	XIic_Send(iic_device.BaseAddress, 0x27, &data, 1, XIIC_STOP);

	Iic_LCD_create_char(1, heart);
	Iic_LCD_create_char(2, empty_heart);
	Iic_LCD_create_char(3, smile);
	Iic_LCD_create_char(4, mr);
	Iic_LCD_create_char(5, hat);

	Iic_LCD_init();

	LCD_write_string("send:");
	Iic_movecursor(1, 0);
	LCD_write_string("recv:");
	Iic_movecursor(0, 5);

	XUartLite_Initialize(&uart_device, UART1_ID);

    print("Start!!\n\r");

    while(1)
    {
    	if(Rx){																//Rx 수신
			RecvHandler(&uart_device, &Rx);
		}

    	if(key_input[1] && (key_input[0] == 0xB)) {							//S12번 확인 버튼
    		MB_Sleep(500);
    		key_data == '\0';
//    		if(key_data=='\0'){		// '\0' : 문자열이 끝났음을 의미, NULL - 숫자 0 과 구분하기 위해 쓰임
//    			key_data=' ';
//    		}
    		if(lcd_count+6<16){		// lcd_count + 6 -> lcd에 send: 5글자 이미 출력해둔 상태이기 때문에 커서를 그 다음으로 두기 위해서
				Iic_movecursor(0, lcd_count+6);
				lcd_string[lcd_count] = key_data;  // 입력된 문자를 문자열 배열에 저장

				key_input[1] = 0;			// key_valid = 0, 키의 입력값 초기화
				lcd_count += 1;				// lcd_count 초기화
				key_data = 0;				// 키 값 초기화
				count_mode = 0;				// 영어 입력 모드 초기화

				for(int i = 0; i < NUM_KEYS; i++ ){		// 각 키의 누른 횟수를 초기화
				key_count[i] = 0;
				}
    		}
    	}

    	if(key_input[1] && (key_input[0] == 0xC)){						//S13번 : 숫자_문자 토글 버튼
    		MB_Sleep(500);
    		mode_count ^= 1;
    	}

		if(key_input[1] && (key_input[0] == 0xE)) {							//S15번 백스페이스 처리 함수 호출
			MB_Sleep(500);
			handle_backspace();
			key_input[1] = 0;
		}

		if(key_input[1] && (key_input[0] == 0xF)) {							//S16번 Tx에 string 할당
			MB_Sleep(500);
			for(int i = 0; i<=79; i++){
				Tx[i] = lcd_string[i];
			}
			key_input[1] = 0;
			Iic_movecursor(0, 5);
			SendHandler(&uart_device, &Tx);
		}

		if(key_input[1] && ( mode_count == 1 ) &&!(key_input[0] == 0xB || key_input[0] == 0xC || key_input[0] == 0xE || key_input[0] == 0xF) && (lcd_count < 11)){		//숫자 모드일 때 숫자 입력
			MB_Sleep(500);
			key_data = keypad_number(key_input[0]);
			Iic_LCD_write_byte(key_data, DATA);
			lcd_string[lcd_count] = key_data;
			key_input[1] = 0;
			lcd_count += 1;
			key_data = 0;
			}

		if(key_input[1] && ( mode_count == 0 ) && !(key_input[0] == 0xB || key_input[0] == 0xC || key_input[0] == 0xE || key_input[0] == 0xF) && lcd_count < 11){		// 영어 모드일 때 영어 입력

			MB_Sleep(100);			//디바운싱

			current_key = key_input[0];		// 현재 누른 키

			key_count[current_key]++;  // 현재 키의 누른 횟수 세기

			if(key_count[current_key] % 3 == 1){
				key_data = keypad_value1(key_input[0]);
			}
			else if(key_count[current_key] % 3 == 2){
				key_data = keypad_value2(key_input[0]);
			}
			else if(key_count[current_key] % 3 == 0){
				key_data = keypad_value3(key_input[0]);
			}

			MB_Sleep(100);			//디바운싱

			Iic_LCD_write_byte(key_data , DATA);
    		Iic_movecursor(0, lcd_count+5);
		}

    }
    return 0;
}

void clear_lcd(int a) {
    if(a==1){
    	Iic_movecursor(0, 5);
    	for (int i = 0; i < 12; i++) {
            lcd_string[i] = ' ';
            Iic_LCD_write_byte(' ', DATA);
        }
        lcd_count = 0;
    }
    if(a==2){
    	Iic_movecursor(1, 5);
    for (int i = 0; i < 12; i++) {
        //lcd_string[i] = ' ';
        Iic_LCD_write_byte(' ', DATA);
    	}
    }
}

void SendHandler(void *CallBackRef, unsigned int EventData){		//send하고 clear_lcd로 초기화 근데 clear_lcd 값 5~16 지워서 0~4값이 남음 // 수고종결
    XUartLite_Send(&uart_device, (u8 *)Tx, 11 );
    clear_lcd(1);
    Iic_movecursor(0, 5);
}

void RecvHandler(void *CallBackRef, unsigned int EventData){
    int numBytes = XUartLite_Recv(&uart_device, (u8 *)Rx, 11);
    if(numBytes){
    	clear_lcd(2);
    }
    if (numBytes > 0) {
        Rx[numBytes] = '\0'; // Null-terminate the received string
        Iic_movecursor(1, 5);
        LCD_write_string(Rx); // Display received string on LCD
        Iic_movecursor(0, lcd_count + 5);
    }
}

void handle_backspace() {						//S15 <- 문자 삭제 버튼
    if (lcd_count > 0) {
        // Move the cursor one position back
        lcd_count--;

        u8 col = lcd_count;

        // Move cursor to the current position
        Iic_movecursor(0, col+5);

        // Write a space to "delete" the character
        Iic_LCD_write_byte(' ', DATA);

        // Update lcd_string array
        lcd_string[lcd_count] = '\0';

        // Move cursor back to the position where the space was written
        Iic_movecursor(0, col+5);
    }
}



char keypad_value1(u8 key_input){	//모듈 R1에 col0 연결	//모듈 C1에 row0 연결	//xdc에서 row는 pulldown

	if (key_input == 0x0) 	   return 'A';
	else if (key_input == 0x1) return 'D';
	else if (key_input == 0x2) return 'G';
	else if (key_input == 0x3) return '.';
	else if (key_input == 0x4) return 'J';
	else if (key_input == 0x5) return 'M';
	else if (key_input == 0x6) return 'P';
	else if (key_input == 0x7) return '?';
	else if (key_input == 0x8) return 'S';
	else if (key_input == 0x9) return 'V';
	else if (key_input == 0xA) return 'Y';

	else if (key_input == 0xD) return 0x03;
	return;

}

char keypad_value2(u8 key_input){

	if (key_input == 0x0) 	       return 'B';
		else if (key_input == 0x1) return 'E';
		else if (key_input == 0x2) return 'H';
		else if (key_input == 0x3) return ',';
		else if (key_input == 0x4) return 'K';
		else if (key_input == 0x5) return 'N';
		else if (key_input == 0x6) return 'Q';
		else if (key_input == 0x7) return 0x01;
		else if (key_input == 0x8) return 'T';
		else if (key_input == 0x9) return 'W';
		else if (key_input == 0xA) return 'Z';

		else if (key_input == 0xD) return 0x04;
		return;

}

char keypad_value3(u8 key_input){

	if (key_input == 0x0) 	       return 'C';
		else if (key_input == 0x1) return 'F';
		else if (key_input == 0x2) return 'I';
		else if (key_input == 0x3) return '!';
		else if (key_input == 0x4) return 'L';
		else if (key_input == 0x5) return 'O';
		else if (key_input == 0x6) return 'R';
		else if (key_input == 0x7) return 0x02;
		else if (key_input == 0x8) return 'U';
		else if (key_input == 0x9) return 'X';
		else if (key_input == 0xA) return '@';

		else if (key_input == 0xD) return 0x05;
		return;

}

char keypad_number(u8 key_input){

	if (key_input == 0x0) 	   return '1';
	else if (key_input == 0x1) return '2';
	else if (key_input == 0x2) return '3';
	else if (key_input == 0x3) return '+';
	else if (key_input == 0x4) return '4';
	else if (key_input == 0x5) return '5';
	else if (key_input == 0x6) return '6';
	else if (key_input == 0x7) return '-';
	else if (key_input == 0x8) return '7';
	else if (key_input == 0x9) return '8';
	else if (key_input == 0xA) return '9';

	else if (key_input == 0xD) return '0';
	return;

}

//int Num_mode(){
//	if(mode_count > 0){
//		if(mode_count%2 == 0){
//			return 0;
//		}
//		else if(mode_count%2 == 1){
//			return 1;
//		}
//	}
//}

//int mode_change(){
//	mode_count += 1;
//	return mode_count;
//}

//void lcd_string_uart_output()				//저장된 lcd_string 확인용

////LCD
void Iic_LCD_write_byte(u8 tx_data, u8 rs){	// d7 d6 d5 d4 BL EN RW RS
	u8 data_t[4]= {0,};
	data_t[0] = (tx_data & 0xf0)| (1 << BL) | (rs & 1)| (1 << EN);
	data_t[1] = (tx_data & 0xf0)| (1 << BL) | (rs & 1)  ;
	data_t[2] = (tx_data << 4)| (1 << BL) | (rs & 1)| (1 << EN);
	data_t[3] = (tx_data << 4)| (1 << BL) | (rs & 1)  ;
    XIic_Send(iic_device.BaseAddress, 0x27, &data_t, 4, XIIC_STOP);
    return;
}

void Iic_LCD_init(void){	//왜 딜레이 없는가 -> 블럭 디자인에서 clk설정한것에 의해 딜레이 충족되어서
	MB_Sleep(15);
	Iic_LCD_write_byte(0x33, COMMAND);
	Iic_LCD_write_byte(0x32, COMMAND);
	Iic_LCD_write_byte(0x28, COMMAND);
	Iic_LCD_write_byte(0x0c, COMMAND);
	Iic_LCD_write_byte(0x01, COMMAND);
	Iic_LCD_write_byte(0x06, COMMAND);
	MB_Sleep(10);
	return;
}

void Iic_movecursor(u8 row, u8 col){
	row = row % 2;		// = 0 or 1 // carry에 의한 다른 명령어 수행을 막도록
	col = col % 40;		// 한 줄에 40자 // carry에 의한 다른 명령어 수행을 막도록
	Iic_LCD_write_byte(0x80 | (row << 6) | col, COMMAND);
	return;
}

void LCD_write_string(char *string){	//문자열은 마지막에 Null문자 포함	//null은 논리값 False
	for (int i = 0; string[i]; i++)
	{
		Iic_LCD_write_byte(string[i], DATA);
	}

	return;
}

void Iic_LCD_create_char(u8 location, u8 charmap[]) {
    location &= 0x7; // 우리는 0-7 사이의 8개 커스텀 문자만 가질 수 있음
    Iic_LCD_write_byte(0x40 | (location << 3), COMMAND);
    for (int i = 0; i < 8; i++) {
        Iic_LCD_write_byte(charmap[i], DATA);
    }
}
