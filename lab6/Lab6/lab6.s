	AREA interrupts, CODE, READWRITE
	EXPORT lab6
	EXPORT FIQ_Handler
	EXPORT interrupt_init
	EXTERN setup
	EXTERN output_string
	EXTERN read_string
	EXTERN read_character
	EXTERN output_character
	EXTERN display_digit_on_7_seg
	EXTERN clear_string
	EXTERN uart_init
	
IO0DIR EQU 0xE0028008
U0IIR EQU 0xE000C008 ;  UART0 Interrupt Identification Register
U0IER EQU 0xE000C004 ; UART0 interrupt enable register
EXTINT EQU 0xE01FC140 ;  External Interrupt Flag Register
T0TCR EQU 0xE0004004
MR1 EQU 0xE000401C
T0MCR EQU 0xE0004014
T0IR EQU 0xE0004000

prompt = "Welcome to lab #5",0
timerbuffer = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0",0
storebuffer1 = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0",0

;/////////////////////////////////////////////////////////////////////////
;function 3 strings
seg1 = "\fEnter a 4 digit hexadecimal number using characters 0-9 A-F. \n\r\n\rIn uppercase with A representing 10 and F representing 15 respectively.\n\r", 0
seg2 = "\n\rThe number will be displayed on the seven segment display.\n\r", 0
seg3 = "\n\r\n\rPress q to return to main menu.\n\r\n\r", 0
invalid = "\n\rInvalid input. Please try again.\n\r" , 0
;/////////////////////////////////////////////////////////////////////////

exit = "\f\n\r                  We are done Boyyyyyy",0
	
    ALIGN

lab6	 	
	STMFD sp!, {lr}

	MOV r7, #1 ;r7 holds the state of the 7 seg display 1 is off, -1 is on
	MOV r6, #0 ;Holds which display to display the number. 0 is leftmost display 3 is rightmost display
	
	BL setup 
	BL uart_init
	BL interrupt_init


;This block prints instructions for the program
function_seg
	LDR r1, =seg1
	BL output_string
	LDR r1, =seg2
	BL output_string
	LDR r1, =seg3
	BL output_string
; End of priting instructions
	LDR r4, =timerbuffer ;timerbuffer with what is displayed
	LDR r5, =storebuffer1 ;Loads temporary timerbuffer which stores input
	
loop_begin
	B loop_begin ;Infinite loop

;///////////////////////////////////////////////////////////////////////	
;Interrupt init initializes all interrupts used in this case external interrupt 1, uart0 interrupt, and timer0 interrupt

interrupt_init       
		STMFD SP!, {r0-r3, lr}   ; Save registers 
		
		
		; Push button setup		 
		LDR r0, =0xE002C000
		LDR r1, [r0]
		ORR r1, r1, #0x20000000
		BIC r1, r1, #0x10000000
		STR r1, [r0]  ; PINSEL0 bits 29:28 = 10

		; Classify sources as IRQ or FIQ
		LDR r0, =0xFFFFF000
		LDR r1, [r0, #0xC]
		LDR r2, =0x8050 ;Classifies UART0,Push button, and timer0 as FIQ
		ORR r1, r1, r2
		STR r1, [r0, #0xC]

		; Enable Interrupts
		LDR r0, =0xFFFFF000
		LDR r1, [r0, #0x10] 
		LDR r2, =0x8050 ;Enables UART0,Push button, and timer0 interrupts
		ORR r1, r1 ,r2
		STR r1, [r0, #0x10]
		
		;Enable UART0 interrupts
		LDR r0, =U0IER 
		LDR r1, [r0]
		ORR r1, r1, #1 ; Enables UART0 interrupts
		STR r1, [r0]
		
		;Enables timer0, allows it to interrupt
		LDR r0, =T0TCR 
		LDR r1, [r0]
		LDR r2, =0x1
		ORR r1, r1, r2
		STR r1, [r0]
		
		;Sets up T0MCR0, MR1
		LDR r0, =MR1
		LDR r3, =0x9000 ;Sets frequency to 60-1000hz
		STR r3, [r0]
		LDR r0, =T0MCR
		LDR r1, [r0]
		LDR r2, =0x18
		ORR r1, r1, r2
		STR r1, [r0]

		; External Interrupt 1 setup for edge sensitive
		LDR r0, =0xE01FC148
		LDR r1, [r0]
		ORR r1, r1, #2  ; EINT1 = Edge Sensitive
		STR r1, [r0]

		; Enable FIQ's, Disable IRQ's
		MRS r0, CPSR
		BIC r0, r0, #0x40
		ORR r0, r0, #0x80
		MSR CPSR_c, r0

		LDMFD SP!, {r0-r3, lr} ; Restore registers
		BX lr             	   ; Return

;///////////////////////////////////////////////////////////////////////	

;FIQ handler handles each type of interrupt, external interrupt 1, uart0 interrupt and timer0 interrupt

FIQ_Handler
		STMFD SP!, {r0-r3, lr}   ; Save registers 

EINT1			; Check for EINT1 interrupt
		LDR r0, =0xE01FC140
		LDR r1, [r0]
		TST r1, #2; paired up: branch to push_case , not paired up jump FIQ_Exit
		BEQ UART0
		B push_case
		
UART0			; Check for UART0 interrupt by lookiing at bit 0 of U0IIR, 1 no interrupt, 0 pending interrupt 
		LDR r0, =U0IIR
		LDR r1, [r0]
		TST r1, #1; Paired up: branch to FIQ_exit, not paired up branch to uart0_case 
		BNE TIMER0
		B uart0_case
		
TIMER0			; Checks for timer0 interrupt by checking bit 1 of T0IR
		LDR r0, =T0IR
		LDR r1, [r0]
		TST r1, #2; paired up: branch to push_case , not paired up jump FIQ_Exit
		BEQ FIQ_Exit
		B timer0_case

push_case
		STMFD SP!, {r0-r3, lr}   ; Save registers 
		
		MOV r2, #0
		SUB r7, r2, r7 ; Changes sign of r7 (corresponds to on off) positive off, negative on

		LDMFD SP!, {r0-r3, lr}   ; Restore registers
		
		ORR r1, r1, #2		; Clear Interrupt
		STR r1, [r0]
		B FIQ_Exit
		
uart0_case
;uart0 interrupt is handled by building the number to be displayed as a string
		STMFD SP!, {r0-r3, lr}   ; Save registers 
		
		LDR r1, =0xE000C000
		LDR r0, [r1] ; Reads character from recieve register
		BL output_character ; Echoes back to putty
		
		BL uart0_comparisons 
		
		LDMFD SP!, {r0-r3, lr}
		
		B FIQ_Exit
		
timer0_case
;timer interrupt is handled by repeatedly strobing 
		STMFD SP!, {r0-r3, lr}
		
		BL strobing 
		
		LDMFD SP!, {r0-r3, lr}
		
		ORR r1, r1, #2		; Clear timer interrupt
		STR r1, [r0]
		B FIQ_Exit
		
FIQ_Exit
		LDMFD SP!, {r0-r3, lr}
		SUBS pc, lr, #4

;///////////////////////////////////////////////////////////////////////	

uart0_comparisons
;uart0_comparisons limits available inputs and test inputs 
;q to exit
;enter as indication number is done being entered
;limits inputs to 0-9 and A-F
		STMFD SP!, {r2,r4,r9,lr} 
		MOV r2, #0 ;temp used for subtracting 
		
		CMP r0, #0x71 ; If read character is q terminate program, otherwise display on 7 segment
		BEQ menu_exit
		
		CMP r0, #0xD ; If read character is enter terminate add null to string and then display on 7 segment
		BEQ enter_case
		
		CMP r0, #0x2F ; If read character is less than or equal to #47 invalid input
		BLE invalid_case
		
		CMP r0, #0x39 ; If read character is greater than #47 less than or equal to #57 valid input
		BLE valid_number
		
		CMP r0, #0x40 ; If read character is less than or equal to #64 invalid input
		BLE invalid_case
		
		CMP r0, #0x46 ; If read character is greater than #64 and less than or equal to #70 valid input 
		BLE valid_number
		
		B invalid_case
		
valid_number
		
		STRB r0, [r5], #1 ;If character is 0-9 A-F store it into storebuffer1
		
		B comparison_exit
		
enter_case
		
		LDR r9, =timerbuffer 
		LDRB r0, [r9]
		CMP r0, #0x0 ;test first character of timerbuffer if it is null, first time running turn display on
		BNE not_firsttime ;If first character of timer buffer is non null add 
		CMP r7, #0
		BLT not_firsttime
		SUB r7, r2, r7
		
not_firsttime

		LDR r0, =0x0 ;When enter is read stores null to determine end of string 
		STRB r0, [r5], #1
		MOV r0, #0xA
		BL output_character ;outputs new line in putty 
		BL move_string ;Moves the content of storebuffer1 to timerbuffer1
		LDR r5, =storebuffer1 ;reloads storebuffer1 to r5 resets it
		
		B comparison_exit
		
invalid_case
		
		LDR r4, =storebuffer1 ;loads storebuffer1 to r4 to be cleared
		BL clear_string ;Clears r4 buffer
		LDR r1, =invalid ;displays invalid output string
		BL output_string
	
		B comparison_exit
		
comparison_exit
	
		LDMFD SP!, {r2,r4,r9,lr}
		BX lr

;///////////////////////////////////////////////////////////////////////	

strobing
;Strobing increments r0 the display number, and r4 which contains address to timerbuffer.
;Using these two registers it display the respective digit in the string to the respective 7 segment display
;leftmost display is r0 = 0, it displays character at the 0th position of the buffer etc 
		STMFD SP!, {r0-r3,lr} 
		LDR r0, =IO0DIR
		
		CMP r6, #0 ;compares r0 to 0 
		BEQ first_digit
		
		CMP r6, #1 ;compares r0 to 1
		BEQ second_digit
		
		CMP r6, #2;compares r0 to 2 
		BEQ third_digit
		
		CMP r6, #3;compares r0 to 3
		BEQ fourth_digit
		
first_digit 
		LDR r1, [r0] ;Turns on the left most 7 segment display 
		BIC r1, #0x3C
		ORR r1, #0x4
		STR r1, [r0]
		
		LDRB r0, [r4] ;loads character at the 0th position of timerbuffer 
		
		BL display_digit_on_7_seg ;displays it on the 7 segment display 
		
		ADD r6, r6, #1 ;increments r0 by 1 to prepare to display next number on next 7 segment display 
		ADD r4, r4, #1 ;increments the position of the string by 1
		
		B strobing_exit
second_digit
		LDR r1, [r0] ;Turns on the next 2nd digit 7 segment display 
		BIC r1, #0x3C
		ORR r1, #0x8
		STR r1, [r0]
		
		LDRB r0, [r4] ;loads second digit of the entered number 
		
		BL display_digit_on_7_seg ;displays second digit of entered number on 7 segment display
		
		ADD r6, r6, #1 ;increments r0 by 1
		ADD r4, r4, #1 ;increments position of string by 1 
		
		B strobing_exit
third_digit
		LDR r1, [r0] ;turns on the 3rd digit 7 segment display 
		BIC r1, #0x3C
		ORR r1, #0x10
		STR r1, [r0]
		
		LDRB r0, [r4] ;loads third digit of entered number 
		
		BL display_digit_on_7_seg ;display the 3rd digit on the 7 segment display 
		
		ADD r6, r6, #1 ;increments r0 by 1
		ADD r4, r4, #1 ;increments position of string by 1 
		
		B strobing_exit
fourth_digit
		LDR r1, [r0] ;loads 4th digit, also the rightmost display
		BIC r1, #0x3C
		ORR r1, #0x20
		STR r1, [r0]
		
		LDRB r0, [r4] ;loads last digit of entered number 
		
		BL display_digit_on_7_seg ;displays last digit on 7 segment display 
		
		MOV r6, #0 ;resets r6 to 0 which makes next number be displayed on leftmost display 
		LDR r4, =timerbuffer ;resets the timerbuffer which starts the process of strobing all over again
		
		B strobing_exit
		
strobing_exit
		
		LDMFD SP!, {r0-r3,lr}
		BX lr
		
;///////////////////////////////////////////////////////////////////////	

;Move string moves content of storebuffer1 to timerbuffer and clears storebuffer1

move_string
	STMFD SP!, {r0-r5,lr}
	
	LDR r4, =timerbuffer ;loads timerbuffer to be cleared
	BL clear_string ;clears timerbuffer 
	LDR r4, =timerbuffer ;reloads timerbuffer
	LDR r5, =storebuffer1 ;loads storebuffer1 

switch_loop

	LDRB r0, [r5] ;loads character from storebuffer1 
	STRB r0, [r4] ;stores loaded character to timerbuffer equivalent to moving charcter to timerbuffer
	ADD r4, r4, #1 ;increments buffer
	ADD r5, r5, #1 ;increments buffer
	
	CMP r0, #0x0 ;ends when the read character is null
	BNE switch_loop 
	
	LDR r4, =storebuffer1 ;loads storebuffer1 to be cleared
	BL clear_string ;clears storebuffer1 
	
	LDMFD sp!, {r0-r5, lr} 
	BX lr	
	
;///////////////////////////////////////////////////////////////////////	
menu_exit
	LDR r1, =exit
	BL output_string
	
	CMP r7, #0 ;turns off 7 segment if it is currently on when program ends
	BGT exit_program
	SUB r7, r6, r7
	BL display_digit_on_7_seg
	
exit_program
	
	LDMFD SP!, {lr}	; Restore register lr from stack	
	BX LR

	END