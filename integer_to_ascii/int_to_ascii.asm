	print_number:

		xor ecx, ecx                
		xor edx, edx
		xor edi, edi
		xor esi, esi
			
    	mov ebx, 10
		mov edi, buffer   		   ; <- load our buffer into ebx
    	                 
		; if the number is positive, then jump to immediately converting it
		cmp eax, 0
		jnl .loop_push_stack

		; if not positive, make it positve as the rest of the code only works with positve integers, then
		; add a '-' at the start of the string, because the number is meant to be negative
		neg eax
		mov [edi], '-'
		inc edi

		.loop_push_stack:

		    xor edx, edx    	   ; clear it after we store it or we blow up
			div ebx    	           ; divide eax by 10
			push edx    		   ; push into the stack the leftover which is in edx	   
			   
			inc ecx    	           ; <- increment the counter
	
			cmp eax, 0    	       ; <- compare the result of the division to 0		
			jne .loop_push_stack    ; <- if its not zero, continue
			
	    mov esi, ecx               ; <- save our counter into a general porpuse register for printing

		mov edx, [is_positive]
		cmp edx, FALSE
		jne .loop_pop_stack
		
		inc esi
		  
		.loop_pop_stack:
		    
			pop edx    			   ; <- pop our data back from the stack
			    
			add edx, '0'           ; <- convert to ascii    
			mov byte [edi], dl     ; <- puts the converted digit into the buffer at the ebx position
			
			inc edi    		       ; <- increment the position of the buffer, (so we put the next converted number there)
			dec ecx                ; <- decrement the loop counter
			
			jne .loop_pop_stack     ; <- checks the zero flag of the instruction before it, if not equal (to zero), continue

		; adds a null terminator at the end	
		inc edi
		mov [edi], 0

		inc esi                    ; <- needed because we can have the additional '-' char at the start, so we need to account for it
	    mov ecx, buffer    		   ; <- move our buffer to ecx so we can print it
	    print_str ecx, esi

	ret
