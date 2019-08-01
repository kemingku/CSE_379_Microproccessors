	AREA	lib, CODE, READWRITE	
	EXPORT read_character
	EXPORT output_character
	EXPORT output_string
	EXPORT read_string
	EXPORT pin_connect_block_setup_for_uart0
	EXPORT uart_init
	EXPORT display_digit_on_7_seg
	EXPORT setup
	
	
	
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
Hex_off EQU 0xB7A0



		
buffer = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0",0
prompt1 = "Interrupt",0

	ALIGN



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

	STMFD SP!,{r2,r3,r5,lr}
	
	LDR r2, =IO0SET ;Set register
	LDR r3, =IO0CLR ;Port 0 clear register 
	
	CMP r7, #0 ; This blocks turns on the led if r7 is negative, off when r7 is positive
	LDR r5, =Hex_off 
	BGT off_seg
	
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
	
	CMP r0, #72
	LDR r5, =Hex_off
	BEQ off_seg 

display
	STR r5, [r2]; stores the hexadecimal to IO0SET register
	B seg_store
	
off_seg
	STR r5, [r3]
	LDR r3, =Hex_off 
	
	CMP r0, #71 ;This allows g segment to be turned on at the start, lets it be stored 
	BEQ seg_store 
	
	CMP r5, r3 ;This comparison prevents the off state to be stored as previous state
	BEQ seg_exit
	
seg_store

	MOV r4, r0 ;stores current state

seg_exit

	LDMFD SP!,{r2,r3,r5,lr}
	BX lr


;/////////////////////////////////////////////////////////	

uart_init
	STMFD SP!,{r0-r1,lr}
	LDR r0, =0xE000C000 ;Base address 0xE000C000
	
	MOV r1, #0x83 ;Loads the bit 10000011 to the U0LCR
	STRB r1, [r0, #U0LCR]
	
	MOV r1, #0x78 ;Loads the bit 11110000 to the Base address
	STRB r1, [r0]
	
	MOV r1, #0x0 ;Loads the bit 00000000 to the U0IER
	STRB r1, [r0, #U0IER]
	
	MOV r1, #0x3 ;Loads the bit 00000011 to the U0LCR
	STRB r1, [r0, #U0LCR]
	
	LDMFD sp!, {r0-r1,lr}
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
	LDRB r0, [r1]
	CMP r0, #0 ; comparing for null
	BEQ output_string_exit	;If character is null branch to the exit of output string
	
	ADD r1, r1, #1 ;Increments index of the string to be printed
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
	
	STR r0, [r1]
	ADD r1, r1, #1 ;Increments index of the string buffer
	BL output_character ;Echos read character
	B read_string_begin ;branch to the beginning 
	
read_string_exit
	MOV r0, #0
	STR r0, [r1]
	
	MOV r0, #0xA ; printing new line
	BL output_character
	MOV r0, #0xD ; printing carriage return
	BL output_character

	LDMFD sp!, {lr} ;load return address of lr
	BX lr	;branches back to main code	



;///////////////////////////////////////////////////////////////////////	
setup
	;This subroutine sets up IO0DIR display on 7 segment
	
	STMFD sp!,{r0,r2,r3,lr}

	LDR r2, =IO0DIR 
	LDR r3, =0xB7A0
	STR r3, [r2] ;sets up the IO0DIR
	
	MOV r0, #71
    BL display_digit_on_7_seg ;Turns on only the G segment of the 7 segment display 

	LDMFD sp!,{r0,r2,r3,lr}
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