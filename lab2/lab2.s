	AREA	LAB2, CODE, READWRITE	
	EXPORT	div_and_mod
	
div_and_mod
	STMFD r13!, {r2-r12, r14}

      ;r0 = Divisor
      ;r1 = Dividend
      ;r2 = Counter
      ;r3 = Quotient
      ;r4 = Remainder
	  ;r5 = +- counter

			MOV r3, #0
			MOV r5, #0
			
					;Divisor > 0?
			CMP r0, #0
			BGT A_POSITIVE
					;NO, Divisor < 0, get it positive
			SUB r0, r3, r0
			ADD r5, r5, #1
			
					;Now Divisor > 0
					;Dividend > 0?
A_POSITIVE	CMP r1, #0
			BGT B_POSITIVE
					;NO, Dividend < 0, get it positive
			SUB r1, r3, r1
			SUB r5, r5, #1
					;Now Divisor > 0 and Dividend > 0


B_POSITIVE	MOV r2, #16                                     
			MOV r3, #0                                      
			MOV r0, r0, LSL #16                            
			MOV r4, r1 
		
		
		

			
			
			
			

			B DIV_BEGIN
		
L_START		SUB r2, r2, #1
DIV_BEGIN	SUB r4, r4, r0
		
			CMP r4, #0
			BLT YES
		
					;when Remainder is >= 0
			MOV r3, r3, LSL #1
			ADD r3, r3, #1		
			B	END_B
		
					;when Remainder < 0
YES			ADD r4, r4, r0
			MOV r3, r3, LSL #1
	
END_B		MOV r0, r0, LSR #1

					;when Counter > 0, go in LOOP_START
			CMP r2, #0
			BGT L_START
	
					;when Counter <= 0    STOP LOOP
	
					;Set r0 = remainder
			MOV r0, r4
	
					;if r5 == 0 then quotient should be positive
			CMP r5, #0
			BEQ P_FINAL
			
			
			MOV r5, #0
			SUB r3, r5, r3
		
					;Set r1 = quotient
					
					
P_FINAL		MOV r1, r3
			
	
		
			
	
	
					;END
	LDMFD r13!, {r2-r12, r14}
	BX lr      ; Return to the C program	

				;21,-4718
	END

	