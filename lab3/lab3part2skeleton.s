	AREA	lib, CODE, READWRITE	
	EXPORT lab3
	EXPORT pin_connect_block_setup_for_uart0
	EXPORT uart_init
	
U0LSR EQU 0x14	; UART0 Line Status Register
U0IER EQU 0x4	; UART0 Interrupt Enable Register
U0LCR EQU 0xC 	; UART0 Line Control Register
THRE EQU 0x20
	
		; You'll want to define more constants to make your code easier 
		; to read and debug
	   
		; Memory allocated for user-entered strings

prompt1 = "\f ----------------------MEAN AND REMAINDER CALCULATOR---------------------------\r\n\r\nPlease  follow the following step: ",0 
prompt2 = "\r\n1. Enter 1 to 15 numbers from -9999 to +9999 with the sign + or -\r\n2. Press the key [Enter] every time after you input the number", 0
prompt3 = "\r\n3. enter q when you are finished entering numbers\r\n               Example: Enter a number: +36(press Enter)",0
prompt4 = "\r\n               -20(press Enter)\r\n               q\r\n\r\nEnter a number: ",0
mean = "\r\nThe mean is :  ",0
remainder = "\r\nThe remainder is: ",0
buffer1 = "\0\0\0\0\0\0\0\0\0\0\0\0",0
buffer2 = "\0\0\0\0\0\0\0\0\0\0\0\0",0
		; Additional strings may be defined here

	ALIGN

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
	
	

lab3
	; Main code
	STMFD SP!,{lr}	; Store register lr on stack
	;Instantiations for output of prompt and instruction
	LDR r1, =0xE000C014
	LDR r3, =0xE000C000	
	LDR r4, =prompt1	; Sets the r4 equal to prompt which is to be printed
	MOV r9, #0	;intialize dividend
	MOV r5, #0	;intialize divisor
	
	BL output_string	;This branch will print out the UI /prompt for the user
	LDR r4, =prompt2
	BL output_string
	LDR r4, =prompt3
	BL output_string
	LDR r4, =prompt4
	BL output_string
	
	BL read_string	;reads in strings of numbers 
	
	MOV r0, #0xA ; printing new line
	BL output_character
	MOV r0, #0xD ; printing carriage return
	BL output_character
	
	BL div_mod
	;Convert the mean to string then prints out the result 
	MOV r6, r5 ;stores the remainder into r6 for later use 
	LDR r4, =buffer1
	BL convert_to_string
	LDR r4, =mean
	BL output_string 
	LDR r4, =buffer1
	BL output_string
	;Ends of mean conversion
	
	
	;This block of code converts the remainder to string then prints it out
	MOV r9, r6
	LDR r4, =buffer2
	BL convert_to_string ;Converts the mean and average to strings
	LDR r4, =remainder
	BL output_string
	LDR r4, =buffer2
	BL output_string
	;
	
	LDMFD sp!, {lr}
	BX lr
	;end of main code
	
;/////////////////////////////////////////////////////////	
	
read_character

	LDR r2, [r1] ;Pulls the bits out from the line status register to r2
	AND	r2, r2, #1 ;Compares r2 to a bit mask to isolate the first bit
	CMP r2, #0 ;When the first bit is 0 there is character in the recieving bufffer
	
	BEQ read_character
	
	LDR r0, [r3]	;Read byte from receive register
	
	BX lr
	
;/////////////////////////////////////////////////////////	
	
output_character

	LDR r2, [r1]
	AND r2, r2, #THRE ; Isolates the THRE bit of the status register and stores result to r5
	CMP r2, #THRE ; Compares mask to isolated THRE bit
	
	BNE output_character ; If the isolated bit isn't equal to the mask goes back to loop
	
	STR r0, [r3] ; Stores character to the transmit register
	
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
	
	MOV r6, #0
	
read_string_begin
	BL read_character ;read inputed character
	CMP r0, #0x71 ;checking for q
	BEQ read_string_exit ;Branches to exit of read string loop
	
	CMP r0, #0xD; checking for enter
	BEQ read_string_enter
	
		;record +
	CMP r0, #0x2B ;Compares the character to hexadecimal of '+' if it matches branches to + portion of read string
	BNE notplus_continue
	MOV r8, #0 ;r8 keeps track of sign 0 for positive and 1 for negative
	BL output_character
	B read_string_begin
	
notplus_continue	
	
		;record -
	CMP r0, #0x2D
	BNE neither_continue ; branches to the label where character is a number
	MOV r8, #1 ;r8 keeps track of sign 0 for positive and 1 for negative 
	BL output_character
	B read_string_begin
	
neither_continue	
	BL output_character

	;					r6 = interger value of  one string
	;					r7 = temp for calculating
	;					r8 = sign recorder + -
	;					r9 = The sum of the 		
	
	; Conversion from string to decimal via shifting
	SUB r0, r0, #48 ;subtracts string to integer number 0-9
	MOV r7, r6, LSL #3 ;multiplies by r6 by 8 then stores in r7
	ADD r7, r7, r6 ; adds to r7 r6
	ADD r7, r7, r6 ; adds to r7 r6 which is equivalent to r6 * 10
	ADD r7, r7, r0
	; end of conversion from hexadecimal to decimal 
	
	MOV r6, r7 ; moves the decimal value of string to r6 
	
	
	B read_string_begin
	
read_string_enter
	
	MOV r7, #0 ; sets r7 which is a temp register back to 0
	CMP r8, #1 ; compares register 8 to 1 or 0. 0 is positive 1 is negative
	BNE Posi_number ;uses the sign to choose addition or subtraction
	SUB r6, r7, r6	
Posi_number
	
	ADD r5, r5, #1 ; Increments counter which keeps track of how many number was entered
	ADD r9, r9, r6 ; This adds the converted number to the running sum
	;unsigned number is positive

	MOV r0, #0xA ; printing new line
	BL output_character
	MOV r0, #0xD ; printing carriage return
	BL output_character
	MOV r6, #0 ; resets the value of r6 back to 0 for repetition of the loop
	B read_string_begin
	
read_string_exit
	BL output_character
	
	LDMFD sp!, {lr} ;load return address of lr
	BX lr	;branches back to main code
	
;/////////////////////////////////////////////////////////
div_mod
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
	
	BX lr
;/////////////////////////////////////////////////////////
	;this subroutine will compare the quotient and remainder to 1000 ,100 ,10 ,1 
convert_to_string
	STMFD SP!,{lr} 
	;r5 divisor where we will use 1000, 100, 10, 1
	
	CMP r9, #0 ;when it is just 0 
	BEQ convert_to_string_begin
	
	CMP r9, #0 ;compares r9 to 0
	BGT Posi_string 
	MOV r5, #45 ;Negative number inserts the negative sign as the first character of the string
	STRB r5, [r4]
	ADD r4, r4, #1 ;increments by 1
	
	MOV r5, #0
	SUB r9, r5, r9 ;Set the num to be positive for calculation purposes
	B convert_to_string_begin
	
Posi_string
	MOV r5, #43
	STRB r5, [r4]
	ADD r4, r4, #1 ;insert + at the beginning of the string
	
convert_to_string_begin
	
	CMP r9, #1000 ;compares the number in r9 to 1000 if it greater divide by 1000 get character
	BLT compare_100
	MOV r5, #1000 ;divisor becomes 1000
	B converting

compare_100
	CMP r9, #100 ;compares the number in r9 to 100 if it greater divide by 1000 get character
	BLT compare_10
	MOV r5, #100 ;divisor becomes 100
	B converting

compare_10
	CMP r9, #10 ;compares the number in r9 to 10 if it greater divide by 1000 get character
	BLT one
	MOV r5, #10 ;divisor becomes 10
	B converting

one
	MOV r5, #1 ;divisor becomes 1
converting
	BL div_mod ;returns remainder to r5 and quotient r9
	ADD r9, r9, #48 ;The quotient will be in decimal by adding #48 it becomes a integer character
	STRB r9, [r4] ;Stores character to string 
	ADD r4, r4, #1 ; Increments string
	MOV r9, r5 ; makes the remainder the dividend 
	CMP r5,#0 ; Repeats until remainder is 0
	BNE convert_to_string_begin

	LDMFD sp!, {lr}
	BX lr


;/////////////////////////////////////////////////////////
pin_connect_block_setup_for_uart0
	STMFD sp!, {r0, r1, lr}
	LDR r0, =0xE002C000  ; PINSEL0
	LDR r1, [r0]
	ORR r1, r1, #5
	BIC r1, r1, #0xA
	STR r1, [r0]
	LDMFD sp!, {r0, r1, lr}
	BX lr



	END
