	AREA	GPIO, CODE, READWRITE	
	EXPORT lab4
	EXTERN output_string
	EXTERN read_string
	EXTERN illuminate_led
	EXTERN read_character
	EXTERN output_character
	EXTERN read_from_push_btns
	EXTERN convert_to_string
	EXTERN display_digit_on_7_seg
	EXTERN illuminate_RGB_LED
	
PIODATA EQU 0x8 ; Offset to parallel I/O data register
IO1DIR EQU 0xE0028018	
IO1PIN EQU 0xE0028010
IO1CLR EQU 0xE002801C
IO1SET EQU 0xE0028014
IO0DIR EQU 0xE0028008
IO0SET EQU 0xE0028000
IO0CLR EQU 0xE002800C
PINSEL0 EQU 0xE002C000
	
;Digits
Hex_g EQU 0x8000
	
RGB_white EQU 0x260000
;Menu strings
prompt	= "\fWelcome to lab #4  ",0	
prompt1	= "\n\rPress 1 to illuminate led.",0   	; Text to be sent to PuTTy
prompt2	= "\n\rPress 2 to read from push buttons.",0
prompt3	= "\n\rPress 3 to play with the 7 segment display.",0
prompt4	= "\n\rPress 4 to change the RGB LED color.",0
promptq	= "\n\rPress q to end the program.\n\r",0
buffer = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\\0\0\0\0\0\0\0\0\0\\0\0\0\0\0\0\0\0\0\\0\0\0\0\0\0\0\0\0\\0\0\0\0\0\0\0\0\0\0", 0
;/////////////////////////////////////////////////////////////////////////
;function 1 strings

exit = "\f\n\r                  We are done Boyyyyyy",0

;/////////////////////////////////////////////////////////////////////////
;function 1 strings
led1 = "\fEnter a character from 0-9 A-F. \n\r\n\r      In uppercase with A representing 10 and F representing 15 respectively.\n\r", 0
led2 = "\n\r      The number will turn the LED lights on in its binary value.\n\r\n\r      A lit led represents a 1 and off represents 0.", 0
led3 = "\n\r\n\rPress q to return to main menu.\n\r\n\r", 0
;/////////////////////////////////////////////////////////////////////////
;function 2 strings
push1 = "\fHold the momentary push buttons you want pressed before entering character 'a'\n\rto display its decimal value on putty.\n\rThe decimal value is: ", 0 
push2 = "\n\r\n\rPress any key to run it again.\n\rPress 'q' to go back to main menu. \n\r\n\r", 0

;/////////////////////////////////////////////////////////////////////////
;function 3 strings
seg1 = "\fEnter a character from 0-9 A-F. \n\r\n\r      In uppercase with A representing 10 and F representing 15 respectively.\n\r", 0
seg2 = "\n\r      The number will be displayed on the seven segment display as hexadecimal.\n\r", 0
seg3 = "\n\r\n\rPress q to return to main menu.\n\r\n\r", 0

;/////////////////////////////////////////////////////////////////////////
;function 4 strings
rgb1 = "\fEnter a character from 1-7 to change RGB LED color\n\r\n\r      1 = Red\n\r      2 = blue\n\r      3 = green.\n\r      4 = yellow\n\r", 0
rgb2 = "      5 = purple\n\r      6 = cyan\n\r      7 = white\n\r", 0
rgb3 = "\n\r\n\rPress q to return to main menu.\n\r\n\r", 0

	ALIGN
digits_SET	
		DCD 0x00003780  ; 0
 		DCD 0x00000300  ; 1 
						; Place other display values here
		DCD 0x00003880  ; F

	ALIGN
lab4
	STMFD SP!,{lr}	; Store register lr on stack
	
	BL setup
	
menu_begin
	;Prints out the strings that holds instructions for the menu
	LDR r4, =prompt
	BL output_string
	LDR r4, =prompt1
	BL output_string
	LDR r4, =prompt2
	BL output_string
	LDR r4, =prompt3
	BL output_string
	LDR r4, =prompt4
	BL output_string
	LDR r4, =promptq
	BL output_string
	; end of printing instruction
	
	BL read_character ;reads a character from putty the branches to corresponding functionality associated with # 1-4
	CMP r0, #0x71 ;Reading in 'q' ends the whole program
	BEQ menu_exit
	
	CMP r0, #0x31 ;If 1 is read branch to function led
	BEQ function_led
	
	CMP r0, #0x32 ;If 2 is read branch to function push button
	BEQ function_push
	
	CMP r0, #0x33 ;If 3 is read branch to function 7 segment
	BEQ function_seg
	
	CMP r0, #0x34 ;If 4 is read branch to function RGB LED
	BEQ function_RGB 
	
	B menu_begin ;If anything else is read branches back to main menu 
	
;////////////////////////////////////////////////////////
function_led
	
	;Prints out strings associated with instructions on how to use illuminate_led
	LDR r4, =led1
	BL output_string
	LDR r4, =led2
	BL output_string
	LDR r4, =led3
	BL output_string
	;end of printing string
	
	BL read_character ;reads a character from putty to determine whether to branch back to main menu
	CMP r0, #0x71 ;Branches back to main menu if 'q' is read
	BEQ menu_begin
	
	BL output_character 
	BL illuminate_led ;Otherwise run illuminate led
	
	B function_led ;repeatedly run this functionality until q is read
	
;////////////////////////////////////////////////////////	
function_push 
	
	;Prints out strings associated with instructions on how to use read_from_push_btns
	LDR r4, =push1
	BL output_string ;Printing out string for instructions
	;
	
	BL read_from_push_btns ;push buttom function
	
	LDR r4, =push2
	BL output_string ;prints string on how and run this functionality again
	
	BL read_character ;reads character from putty 
	CMP r0, #0x71 ;if 'q' is read branches back to main menu
	BEQ menu_begin
	
	B function_push
	
;////////////////////////////////////////////////////////	
function_seg

	;This block prints instructions for the display digit on 7 seg subroutine
	LDR r4, =seg1
	BL output_string
	LDR r4, =seg2
	BL output_string
	LDR r4, =seg3
	BL output_string
	;
	
	BL read_character ;reads character to be used for display on 7 seg
	CMP r0, #0x71 ;if 'q' is read branches back to main menu
	BEQ menu_begin
	
	BL output_character ;echos character back 
	
	BL display_digit_on_7_seg
	
	B function_seg ;branches back to this functionality to run again

function_RGB

	;This block prints instructions on how to use the subroutine illuminate RGB LED 
	LDR r4, =rgb1
	BL output_string
	LDR r4, =rgb2
	BL output_string
	LDR r4, =rgb3
	BL output_string
	;
	
	BL read_character ;reads in character to be used for illuminate RGB LED or to end this functionality 
	CMP r0, #0x71 ;reading in 'q' ends this functionality and branches back to the main menu
	BEQ menu_begin	
	
	BL illuminate_RGB_LED
	
	B function_RGB ;branches back to this functionality to do this subroutine again
	
	
;///////////////////////////////////////////////////////////////////////	
setup
	;This subroutine sets up IO0DIR and IO1DIR for illuminate led, read from push buttons, display on 7 segment, and RGB LED
	;Also sets the board to its beginning state. 
	
	STMFD sp!,{r0,lr}

	LDR r1, =IO0DIR 
	LDR r2, =0x26B7A0
	STR r2, [r1] ;sets up the IO0DIR 
	LDR r1, =IO1DIR
	LDR r2, =0xF0000 
	STR r2, [r1] ;sets up IO1DIR
	
	
	MOV r0, #70 
	BL illuminate_led ;Turns all led on this is the beginning state 
	MOV r0, #55
	BL illuminate_RGB_LED ;Turns on RGB LED to white 
	MOV r0, #71
    BL display_digit_on_7_seg ;Turns on only the G segment of the 7 segment display 

	LDMFD sp!,{r0,lr}
	BX lr
;///////////////////////////////////////////////////////////////////////
menu_exit
	LDR r4, =exit
	BL output_string
	
	LDMFD SP!, {lr}	; Restore register lr from stack	
	BX LR
	
	
	END
