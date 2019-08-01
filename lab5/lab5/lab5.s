	AREA interrupts, CODE, READWRITE
	EXPORT lab5
	EXPORT FIQ_Handler
	EXPORT interrupt_init
	EXTERN setup
	EXTERN output_string
	EXTERN read_string
	EXTERN read_character
	EXTERN output_character
	EXTERN display_digit_on_7_seg
	
IO0DIR EQU 0xE0028008
U0IIR EQU 0xE000C008 ;  UART0 Interrupt Identification Register
U0IER EQU 0xE000C004 ; UART0 interrupt enable register
EXTINT EQU 0xE01FC140 ;  External Interrupt Flag Register

prompt = "Welcome to lab #5",0
prompt1 = "Interrupt",0

;/////////////////////////////////////////////////////////////////////////
;function 3 strings
seg1 = "\fEnter a character from 0-9 A-F. \n\r\n\r      In uppercase with A representing 10 and F representing 15 respectively.\n\r", 0
seg2 = "\n\r      The number will be displayed on the seven segment display as hexadecimal.\n\r\n\rCaution: When the 7 segment is turned on for the first time, only the g segment should be turned on\n\r", 0
seg3 = "\n\r\n\rPress q to exit at any time.\n\r\n\r", 0
;/////////////////////////////////////////////////////////////////////////

exit = "\f\n\r                  We are done Boyyyyyy",0
	
    ALIGN

lab5	 	
	STMFD sp!, {lr}

	MOV r7, #1
	MOV r6, #0
	
	BL setup


;This block prints instructions for the program
function_seg
	LDR r1, =seg1
	BL output_string
	LDR r1, =seg2
	BL output_string
	LDR r1, =seg3
	BL output_string
; End of priting instructions
	
	
loop_begin

	B loop_begin ;Infinite loop
	

interrupt_init       
		STMFD SP!, {r0-r2, lr}   ; Save registers 
		
		
		; Push button setup		 
		LDR r0, =0xE002C000
		LDR r1, [r0]
		ORR r1, r1, #0x20000000
		BIC r1, r1, #0x10000000
		STR r1, [r0]  ; PINSEL0 bits 29:28 = 10

		; Classify sources as IRQ or FIQ
		LDR r0, =0xFFFFF000
		LDR r1, [r0, #0xC]
		LDR r2, =0x8040 ;Classifies UART0 and Push button as FIQ
		ORR r1, r1, r2
		STR r1, [r0, #0xC]

		; Enable Interrupts
		LDR r0, =0xFFFFF000
		LDR r1, [r0, #0x10] 
		LDR r2, =0x8040 ;Enables UART0 and Push button interrupts
		ORR r1, r1 ,r2
		STR r1, [r0, #0x10]
		
		;Enable UART0 interrupts
		LDR r0, =U0IER 
		LDR r1, [r0]
		ORR r1, r1, #1 ; Enables UART0 interrupts
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

		LDMFD SP!, {r0-r2, lr} ; Restore registers
		BX lr             	   ; Return



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
		BNE FIQ_Exit
		B uart0_case

push_case
		STMFD SP!, {r0-r3, lr}   ; Save registers 
	
		SUB r7, r6, r7 ; Changes sign of r7 (corresponds to on off) positive off, negative on
		MOV r0, r4 ; Loads previous state to be turned on
		BL display_digit_on_7_seg

		LDMFD SP!, {r0-r3, lr}   ; Restore registers
		
		ORR r1, r1, #2		; Clear Interrupt
		STR r1, [r0]
		B FIQ_Exit
		
uart0_case
		STMFD SP!, {r0-r3, lr}   ; Save registers 
		
		LDR r1, =0xE000C000
		LDR r0, [r1] ; Reads character from recieve register
		BL output_character ; Echoes back to putty
		
		CMP r0, #0x71 ; If read character is q terminate program, otherwise display on 7 segment
		BEQ menu_exit
		
		BL display_digit_on_7_seg 
		
		LDMFD SP!, {r0-r3, lr}
		B FIQ_Exit
		
FIQ_Exit
		LDMFD SP!, {r0-r3, lr}
		SUBS pc, lr, #4
		
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