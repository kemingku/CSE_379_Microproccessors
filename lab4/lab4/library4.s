	AREA	lib, CODE, READWRITE	
	EXPORT read_character
	EXPORT output_character
	EXPORT output_string
	EXPORT read_string
	EXPORT pin_connect_block_setup_for_uart0
	EXPORT uart_init
	EXPORT illuminate_led
	EXPORT reflect_number
	EXPORT read_from_push_btns
	EXPORT display_digit_on_7_seg
	EXPORT convert_to_string
	EXPORT illuminate_RGB_LED
	
	
	
U0LSR EQU 0x14	; UART0 Line Status Register
U0IER EQU 0x4	; UART0 Interrupt Enable Register
U0LCR EQU 0xC 	; UART0 Line Control Register
THRE EQU 0x20
IO1DIR EQU 0xE0028018	
IO1PIN EQU 0xE0028010
IO1CLR EQU 0xE002801C
IO1SET EQU 0xE0028014
IO0DIR EQU 0xE0028008
IO0SET EQU 0xE0028000
IO0CLR EQU 0xE002800C
PINSEL0 EQU 0xE002C000
	
;Hexdecimal hard code
Seg EQU 0xB7A0
Hex_g EQU 0x8000
Hex_0 EQU 0x3780
Hex_1 EQU 0x300
Hex_2 EQU 0x9580
Hex_3 EQU 0x8780
Hex_4 EQU 0xA300
Hex_5 EQU 0xA680
Hex_6 EQU 0xB680
Hex_7 EQU 0x0380
Hex_8 EQU 0xB780
Hex_9 EQU 0xA380
Hex_a EQU 0xB380
Hex_b EQU 0xB600
Hex_c EQU 0x3480
Hex_d EQU 0x9700
Hex_e EQU 0xB480
Hex_f EQU 0xB080

;RGB
RGB_white EQU 0x260000
RGB_red EQU 0x20000
RGB_blue EQU 0x40000
RGB_green EQU 0x200000
RGB_purple EQU 0x60000
RGB_yellow EQU 0x220000
RGB_cyan EQU 0x240000

		
buffer = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0",0
	
	ALIGN
;/////////////////////////////////////////////////////////

illuminate_RGB_LED
	;Our illuminate RGB LED operates by writing the hexadecimal needed to turn on the LED to the IO0 Clear register
	
	STMFD SP!,{r1,r2,r3,r4,r5,lr}
	
	LDR r3, =IO0CLR
	LDR r4, =IO0SET
	LDR r5, =RGB_white

	
	STR r5, [r4] ; First turns off the RGB LED first before turning on a color
	
	; Comparisons to test for which color to turn on
	CMP r0, #49 ;red
	LDR r5, =RGB_red
	BEQ turn_on
	
	CMP r0, #50 ;blue
	LDR r5, =RGB_blue
	BEQ turn_on
	
	CMP r0, #51 ;green
	LDR r5, =RGB_green
	BEQ turn_on
	
	CMP r0, #52 ;yellow
	LDR r5, =RGB_yellow
	BEQ turn_on
	
	CMP r0, #53 ;purple
	LDR r5, =RGB_purple
	BEQ turn_on
	
	CMP r0, #54 ;cyan
	LDR r5, =RGB_cyan
	BEQ turn_on
	
	CMP r0, #55 ;white
	LDR r5, =RGB_white
	BEQ turn_on
					
turn_on

	STR r5, [r3] ;stores the hexadecimal to clear register which turns the RGB LED on

	LDMFD SP!,{r1,r2,r3,r4,r5,lr}
	BX lr
;/////////////////////////////////////////////////////////

	;Our read from push buttons operates by pulling the value from IO1PIN after buttons are held
	;We then isolate the 20-23 bits and then shift it to be the first 4 bits
	;After bits are shifted we reflect the bits, and switch 1s to 0s and 0s to 1s to get the decimal value
	;We then converts this decimal value to characters which we then print on putty

read_from_push_btns
	STMFD SP!,{r1, r2, r5, r9, lr}
	LDR r1, =IO1DIR ;Port 0 DIR
	LDR r2, =IO1PIN

push_btns_begin
	BL read_character
	CMP r0, #0x61 ;press a after user pushes the button to display decimal value on putty
	BNE push_btns_begin
	
	LDR r4, [r2]
	AND r4, r4, #0x00F00000 ;Isolates bits 20 - 23
	
	MOV r4, r4, LSR #20 ;Shift 20 times to get the value from pin 20-23
	
	BL reflect_number ;Reflects the number 
	MOV r5, #15 ;Switches the 0 bits to 1 and 1 bits to 0
	SUB r4, r5, r4
	MOV r9, r4
	LDR r4, =buffer
	BL convert_to_string ;Converts the devimal value to a string 
	LDR r4, =buffer
	BL output_string ;Outputs string to putty 
	
	LDR r4, =buffer
	BL clear_string ; clear buffer

	
	LDMFD SP!,{r1, r2, r5 ,r9 ,lr}
	BX lr
	

;////////////////////////////////////////////////////////

	;This routine takes in a buffer which we then clear by changing every non null character to a null 
	;Terminates after the end of string is reach in other words a null character is reached

clear_string
	STMFD sp!,{lr, r0, r3}

clear	
	LDRB r0, [r4]
	CMP r0, #0 ; comparing for null
	BEQ clear_exit
	LDR r3, =0x0
	STR r3, [r4]
	ADD r4, r4, #1
	
	B clear
	
clear_exit
	LDMFD sp!,{lr, r0, r3}
	BX lr
	
;////////////////////////////////////////////////////////
display_digit_on_7_seg	;input=r0

	;Display subroutine works by writing a specific hexadecimal to IO0SET.
	;This hexadecmial specifies which segment to turn on.

	STMFD SP!,{r2,r3,r4,r5,lr}
	
	LDR r2, =IO0SET ;Set register
	LDR r3, =IO0CLR ;Port 0 clear register 
	
	
	CMP r0, #48
	LDR r5, =Hex_0 ;7 seg displays 0 
	BEQ display
	
	CMP r0, #49
	LDR r5, =Hex_1 ;7 seg displays 1 
	BEQ display
	
	CMP r0, #50
	LDR r5, =Hex_2 ;7 seg displays 2 etc...
	BEQ display
	
	CMP r0, #51
	LDR r5, =Hex_3
	BEQ display
	
	CMP r0, #52
	LDR r5, =Hex_4
	BEQ display
	
	CMP r0, #53
	LDR r5, =Hex_5
	BEQ display
	
	CMP r0, #54
	LDR r5, =Hex_6
	BEQ display
	
	CMP r0, #55
	LDR r5, =Hex_7
	BEQ display
	
	CMP r0, #56
	LDR r5, =Hex_8
	BEQ display
	
	CMP r0, #57
	LDR r5, =Hex_9
	BEQ display
	
	CMP r0, #65
	LDR r5, =Hex_a
	BEQ display
	
	CMP r0, #66
	LDR r5, =Hex_b
	BEQ display
	
	CMP r0, #67
	LDR r5, =Hex_c
	BEQ display
	
	CMP r0, #68
	LDR r5, =Hex_d
	BEQ display
	
	CMP r0, #69
	LDR r5, =Hex_e
	BEQ display
	
	CMP r0, #70
	LDR r5, =Hex_f
	BEQ display
	
	CMP r0, #71
	LDR r5, =Hex_g
	BEQ display


display
	STR r5, [r2]; stores the hexadecimal to IO0SET register
	
	LDMFD SP!,{r2,r3,r4,r5,lr}
	BX lr


;/////////////////////////////////////////////////////////	
illuminate_led
	STMFD SP!,{r0,r1,r2,r3,r4,lr}
	
	;Illuminate led operates by first turning all the leds off before turning them back on again
	;This is done by taking the number read from on putty, reflecting it before shifting it to the 16-19th bits.
	;This hexadecimal is then stored in to the IO1CLR register which turns the led on
	
	LDR r2, =IO1CLR	;Port 1 clear register
	LDR r3, =0xE0028014 ;Set register
	
	LDR r1, =0xF0000
	STR r1, [r3] ;set it off at the beginning
	
	
	CMP r0, #0x39 ;If read character is greater than '9' branches to A-F case
	BGT A_F
	SUB r4, r0, #48 ;If read character is less than or equal to 9 subtract #48 to make it a decimal value
	B light_led
A_F
	SUB r4, r0, #55 ;If read character is A-F subtracts #55 to convert it to decimal
light_led
	BL reflect_number ;Relects number to follow convention where 16th bit is the MSB 

	MOV r0, r4, LSL #16 ;Shift the number 16 bits to the left
	
	STR r0, [r2] ;Stores to clear register to turn led on
	
	LDMFD SP!,{r0,r1,r2,r3,r4,lr}
	BX lr 
;/////////////////////////////////////////////////////////	
reflect_number ; input r4

	;This routine reflects the bit of the number 

	STMFD SP!,{r5,lr}
	
	MOV r5, #0
	
	CMP r4, #8	;compare 8 Compares value to #8 if it is greater add 1 to r5
	BLT compare_4
	SUB r4, r4, #8 ;subtracts 8
	ADD r5, r5, #1
	
compare_4
	CMP r4, #4	;compare 4 Compares value to #4 if it is greater add 2 to r5
	BLT compare_2
	SUB r4, r4, #4 ;subtracts 4 
	ADD r5, r5, #2
	
compare_2
	CMP r4, #2	;compare 2 Compares value to #2 if it is greater add 4 to r5
	BLT compare_1
	SUB r4, r4, #2 ;subtracts 2 
	ADD r5, r5, #4
	
compare_1
	CMP r4, #1	;Compares value to #1 if it is greater add 8 to r5
	BLT reflect_exit
	ADD r5, r5, #8

reflect_exit

	MOV r4, r5

	LDMFD SP!,{r5,lr}
	BX lr 
;/////////////////////////////////////////////////////////	
uart_init
	STMFD SP!,{lr}
	LDR r0, =0xE000C000 ;Base address 0xE000C000
	
	MOV r1, #0x83 ;Loads the bit 10000011 to the U0LCR
	STRB r1, [r0, #U0LCR]
	
	MOV r1, #0x78 ;Loads the bit 11110000 to the Base address
	STRB r1, [r0]
	
	MOV r1, #0x0 ;Loads the bit 00000000 to the U0IER
	STRB r1, [r0, #U0IER]
	
	MOV r1, #0x3 ;Loads the bit 00000011 to the U0LCR
	STRB r1, [r0, #U0LCR]
	
	LDMFD sp!, {lr}
	BX lr
	
;/////////////////////////////////////////////////////////

read_character
	STMFD sp!,{r1,r2,r3,lr}

read_character_begin
	LDR r1, =0xE000C014
	LDR r3, =0xE000C000	
	
	LDRB r2, [r1] ;Pulls the bits out from the line status register to r2
	AND	r2, r2, #1 ;Compares r2 to a bit mask to isolate the first bit
	CMP r2, #0 ;When the first bit is 0 there is character in the recieving bufffer
	
	BEQ read_character_begin
	
	LDRB r0, [r3]	;Read byte from receive register

	LDMFD sp!, {r1,r2,r3,lr}
	BX lr
	
;/////////////////////////////////////////////////////////	
	
output_character
	STMFD sp!,{r1,r2,r3,lr}

output_character_begin	
	LDR r1, =0xE000C014
	LDR r3, =0xE000C000	

	LDRB r2, [r1]
	AND r2, r2, #THRE ; Isolates the THRE bit of the status register and stores result to r5
	CMP r2, #THRE ; Compares mask to isolated THRE bit
	
	BNE output_character_begin ; If the isolated bit isn't equal to the mask goes back to loop
	
	STRB r0, [r3] ; Stores character to the transmit register
	LDMFD sp!, {r1,r2,r3,lr}
	
	BX lr
	
;/////////////////////////////////////////////////////////

output_string
	STMFD SP!,{lr} 
output_string_begin
	LDRB r0, [r4]
	CMP r0, #0 ; comparing for null
	BEQ output_string_exit	;If character is null branch to the exit of output string
	
	ADD r4, r4, #1 ;Increments index of the string to be printed
	BL output_character 
	B output_string_begin ;branch to the beginning 
	
output_string_exit
	LDMFD sp!, {lr} ;load return address of lr
	BX lr	;branches back to main code
	
;/////////////////////////////////////////////////////////	
	
read_string
	STMFD SP!,{lr} 
read_string_begin
	BL read_character ;read inputed character
	CMP r0, #0xD; checking for enter
	BEQ read_string_exit
	
	STR r0, [r4]
	ADD r4, r4, #1 ;Increments index of the string buffer
	BL output_character ;Echos read character
	B read_string_begin ;branch to the beginning 
	
read_string_exit
	MOV r0, #0
	STR r0, [r4]
	
	MOV r0, #0xA ; printing new line
	BL output_character
	MOV r0, #0xD ; printing carriage return
	BL output_character

	LDMFD sp!, {lr} ;load return address of lr
	BX lr	;branches back to main code	

;/////////////////////////////////////////////////////////
div_mod
	STMFD sp!,{r10, r8, r11, r12,lr}
      ;r5 = Divisor
      ;r9 = Dividend
      ;r10 = Counter
      ;r11 = Quotient
      ;r12 = Remainder
      ;r8 = +- counter

     MOV r11, #0
     MOV r8, #0
        ;Divisor > 0?
     CMP r5, #0
     BGT divisor_positive
                          ;NO, Divisor < 0, get it positive
     SUB r5, r11, r5
     ADD r8, r8, #1
                                        ;Now Divisor > 0
                                        ;Dividend > 0?
divisor_positive      
	CMP r9, #0                    
	BGT both_positive
	;NO, Dividend < 0, get it positive
    SUB r9, r11, r9
	SUB r8, r8, #1
	;Now Divisor > 0 and Dividend > 0

both_positive
	MOV r10, #16
	MOV r11, #0
	MOV r5, r5, LSL #16
	MOV r12, r9
	B DIV_BEGIN

L_START
	SUB r10, r10, #1
DIV_BEGIN
	SUB r12, r12, r5
	
	CMP r12, #0
	BLT YES	;when Remainder is >= 0
	MOV r11, r11, LSL #1
	ADD r11, r11, #1
	B       END_B

YES  ;when Remainder < 0
	ADD r12, r12, r5
	MOV r11, r11, LSL #1

END_B
	MOV r5, r5, LSR #1	;when Counter > 0, go in LOOP_START
	CMP r10, #0
	BGT L_START	;when Counter <= 0    STOP LOOP
	MOV r5, r12 ;r5 is the remainder
	;if r8 == 0 then quotient should be positive
	CMP r8, #0
	BEQ P_FINAL
	MOV r8, #0
	SUB r11, r8, r11

P_FINAL
	MOV r9, r11	;r9 is the quotient	
	
	LDMFD sp!,{r10,r11,r8,r12,lr}
	BX lr
;/////////////////////////////////////////////////////////
	;this subroutine will compare the quotient and remainder to 1000 ,100 ,10 ,1 
convert_to_string
	STMFD SP!,{lr, r1, r9, r5} 
	;r5 divisor where we will use 1000, 100, 10, 1
	
	CMP r9, #1000 ;compares the number in r9 to 1000 if it greater divide by 1000 get character
	BLT compare_100
	MOV r1, #1000 ;divisor becomes 1000
	B converting

compare_100
	CMP r9, #100 ;compares the number in r9 to 100 if it greater divide by 1000 get character
	BLT compare_10
	MOV r1, #100 ;divisor becomes 100
	B converting

compare_10
	CMP r9, #10 ;compares the number in r9 to 10 if it greater divide by 1000 get character
	BLT one
	MOV r1, #10 ;divisor becomes 10
	B converting

one
	MOV r1, #1 ;divisor becomes 1
	B converting
	
loop_decrease_divisor_by10
	BL decrease_divisor_by10
converting
	MOV r5, r1
	BL div_mod ;returns remainder to r5 and quotient r9
	ADD r9, r9, #48 ;The quotient will be in decimal by adding #48 it becomes a integer character
	STRB r9, [r4] ;Stores character to string 
	ADD r4, r4, #1 ; Increments string
	MOV r9, r5 ; makes the remainder the dividend 
	CMP r1,#1 ; Repeats until remainder is 0
	BNE loop_decrease_divisor_by10

	LDMFD sp!, {lr, r1, r9, r5}
	BX lr

;/////////////////////////////////////////////////////////
decrease_divisor_by10
	STMFD sp!, {lr, r9, r5}

	MOV r9, r1
	MOV r5, #10
	BL div_mod
	MOV r1, r9
	
	LDMFD sp!, {lr, r9, r5}
	BX lr
;/////////////////////////////////////////////////////////	
pin_connect_block_setup_for_uart0
	STMFD sp!, {r0, r1, lr,r2}
	LDR r0, =0xE002C000  ; PINSEL0
	LDR r1, [r0]
	ORR r1, r1, #5
	BIC r1, r1, #0xA
	STR r1, [r0]
	LDMFD sp!, {r0, r1, lr,r2}
	BX lr
	
	END