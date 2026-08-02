%macro read_stdin 2 
	mov   eax, 3
    mov   ebx, 0
    mov   ecx, %1
    mov   edx, %2
    int   80h
%endmacro

%macro print_str 2 
	mov   eax, 4
    mov   ebx, 1
    mov   edx, %2
    mov   ecx, %1
    int   80h
%endmacro

%macro exit_program 0 
	mov   eax, 1
    xor   ebx, ebx
    int   80h
%endmacro

section .data

	str_welcome1 db 'Welcome to ASMC',0Ah,0Ah,'ASSEMBLY CALCULATOR ',0Ah,0
	str_welcome_len1 equ $ - str_welcome1

	str_input_not_number db 'Invalid input, try again!',0Ah,0
	str_input_not_number_len equ $ - str_input_not_number

	typed_nmbr_msg db 'The number you typed is: ',0
	typed_nmbr_msg_len equ $ - typed_nmbr_msg 


	is_positive db 1
	is_number db 0

	;num_of_conv_vals dd 0
	limit_to_convert db 2

	end_of_str_flag dd 0

	float_number dd 3.14
	int_part dd 0
	mul_value dd 10
	temp_number dd 0
	decimal_lenght dd 3
	decimal_threshold dd 0.000001

	TRUE equ 1
	FALSE equ 0

	buffer:    times 201 db 0
	inputed_nums: times 201 dd 0
	
	current_iteration db 0

	;welcome_msg_buffer_len equ (str_welcome_len1 + str_temperature_len + str_energia_len + str_com_qual_len + str_module_status_len) - 6

section .bss

	; 32 bits word to hold eax (converted u_str)
	u_n1 resd 1
	u_n2 resd 1

	counter resb 1
	unit resb 1

	ustr resb 200

	cw      resw 1
	digit   resd 1

section .text

	print_float:

		xor ecx, ecx                
		xor edx, edx
		xor edi, edi
		xor esi, esi
			
    	mov ebx, 10

		fld dword [float_number]
    	                 
		; if the number is positive, then jump to immediately converting it
		xor edx, edx
		mov [temp_number], edx
		
		fild dword [temp_number]
		fcomip st0, st1 ; compares the value to zero and pops the zero used in the comparasion
		jnl .end_negative

		mov [edi], '-'
		inc edi

		.end_negative:

		fist dword [int_part] ; store the trucated integer part
		fild dword [int_part] ; load it back
		fsubp st1, st0
		
		xor eax, eax
		xor edx, edx
		
		.loop_push_decimal:


			fild dword [mul_value] ; mul value = 10 
			fmulp st1, st0; our mul_value gets popped
			fisttp dword [temp_number]
			fild dword [temp_number]
			
			mov edx, dword [temp_number]
			push edx
			
			inc ecx
			inc eax
			
			xor edx, edx
			mov [temp_number], edx
			
			fsubp st1, st0
			fabs
			;fild dword [decimal_lenght] ; now its 0
			;fcomip st0, st1 ; compares the value to zero and pops the zero used in the comparasion
			cmp eax, [decimal_lenght]
			jl .loop_push_decimal

			xor eax, eax

			xor edx, edx
			mov edx, -2
			push edx
			inc ecx

			mov eax, dword [int_part]
		
		.loop_push_integer:

		    xor edx, edx    	   ; clear it after we store it or we blow up
			div ebx    	           ; divide eax by 10
			push edx    		   ; push into the stack the leftover which is in edx	   
			   
			inc ecx    	           ; <- increment the counter
	
			cmp eax, 0    	       ; <- compare the result of the division to 0		
			jne .loop_push_integer    ; <- if its not zero, continue

		; this will push -2 along with the other digits, -2 + 48 = 46 and in ascii thats
		; the period separating the integer from the decimal part
					
	    mov esi, ecx               ; <- save our counter into a general porpuse register for printing

		mov edi, buffer
		inc esi
		 
		.loop_pop_stack:
		    
			pop edx    			   ; <- pop our data back from the stack
			    
			add edx, '0'           ; <- convert to ascii    
			mov byte [edi], dl     
			
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

global _start

_start:

	call print_float

	exit_program

