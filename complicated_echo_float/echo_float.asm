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

	is_positive db 1
	is_number db 0
	end_of_str_flag dd 0
	TRUE equ 1
	FALSE equ 0
	str_input_not_number db 'Invalid input, try again!',0Ah,0
	str_input_not_number_len equ $ - str_input_not_number

	control_word dw 0
	new_control_word dw 0x037f


	scale dq 1000.0
	float_number dq 0.0
	abs_float_number dq 0.0
	temp_fi dq 0
	
	int_part dd 0
	mul_value dd 10
	temp_number dd 0
	decimal_lenght dd 3
	decimal_threshold dd 0.0001
	decimal_scale dd 10

	buffer:    times 201 db 0
	inputed_nums: times 201 dd 0

section .bss

	u_n1 resd 1
	u_n2 resd 1

	counter resb 1
	unit resb 1

	ustr resb 200


section .text

	conv_str_to_int:

		xor edi, edi
		mov edi, 1
		mov [is_positive], edi

		xor ebx, ebx
		xor ecx, ecx
		xor eax, eax
		xor edi, edi

		.nextchar: ; loop for going char by char until we find the end of the string

			xor ebx, ebx			
			mov bl, byte [esi]  ; load current char

			cmp bl, 0 ; zero signifies the end of the string
			je .end_nextchar

			cmp bl, '.'
			je .decimal

			cmp bl, '-'
			je .negative
			
			; convert from ascii to number and compare it to 9 if its above the char was not a digit
			sub bl, '0'			
			jmp .positve

			.negative:

				inc esi
				mov bl, byte [esi]

				cmp bl, ' '
				je .nextchar

				xor edi, edi
				mov [is_positive], edi
				jmp .nextchar
					
			.positve:
			
				cmp bl, 9
				ja .error
				
				;imul eax, eax, 10 multiplies the current value in EAX by 10 and stores the result back in EAX
				imul eax, eax, 10
				add eax, ebx

				; increment esi so we use the next char (esi is pointer to string)
				inc esi
				mov [int_part], eax
				jmp .nextchar

			.decimal:

				inc esi
				
				xor ebx, ebx
				mov bl, byte [esi]
				
				cmp bl, 0 ; zero signifies the end of the string
				je .end_decimal
				cmp bl, ' '
				je .end_decimal

				sub bl, '0'
				mov [temp_number], ebx
				
				fild dword [temp_number]
				fild dword [decimal_scale]
				fdivp ; divides the two above
				fld qword [float_number] 
				faddp 
				fstp qword [float_number]
				

				xor edi, edi
				mov edi, [decimal_scale]
				imul edi, 10
				mov [decimal_scale], edi

				jmp .decimal

			.end_decimal:

				fild dword [int_part]
				fld qword [float_number]
				faddp

				; if its positive skip to .end_negate
				xor edi, edi
				mov edi, [is_positive]
				cmp edi, TRUE
				je .end_negate
				
				fchs ; negate top of the stack

				; make flag true again
				xor edi, edi
				mov edi, 1
				mov [is_positive], edi
				
				.end_negate:

				fstp qword [float_number] ; load the top of the stack into float number
				
				cmp bl, 0 ; zero signifies the end of the string
				je .end
				jmp .nextchar
			
			.error:
			
				mov edi, -1
				ret 

		.end_nextchar:

			fild dword [int_part]
			fstp qword [float_number]
			
			xor edx, edx
			mov dword [int_part], edx

		.end:
		
			ret


	round_float:

		fstcw word [control_word]
		fldcw word [new_control_word]
		
		fld qword [float_number]
		fld qword [scale]
		fmulp
		frndint
		fld qword [scale]
		fdivp st1, st0
		fstp qword [float_number]

		fldcw word [control_word]
		ret

	print_float:

		; esi =  counter of how many chars the string will have
		; edi = pointer to the buffer where the string will lice

		xor ecx, ecx                
		xor edx, edx
		xor edi, edi
		xor esi, esi

		mov edi, buffer	
		mov dword [temp_number], edx
    
		fld qword [float_number]
    	                 
		xor edx, edx
		mov [temp_number], edx
		

		.load_int_part:

			fld st0
			fisttp dword [int_part] ; store the trucated integer part (st0)
			fild dword [int_part] ; load it back
			fsubp st1, st0
			
			xor eax, eax
			xor edx, edx

			mov eax, dword [int_part]

			mov ebx, 10
			xor ecx, ecx

			cmp eax, 0
			jnl .loop_convert_int

		.negate_value:

			fabs  ; makes the decimal part positive
			neg eax ; negates the interger part, so it becomes negative
			mov [edi], '-'
			inc edi
			inc esi
			
		.loop_convert_int:

		    xor edx, edx ; clear it after we store it or we blow up
			div ebx ; div ebx by eax
			
			add edx, '0'     	           
			push edx 
			inc ecx 
			
			cmp eax, 0    	         ; <- compare the result of the division to 0		
			jne .loop_convert_int    ; <- if its not zero, continue

		.loop_str_int_part:

			pop edx
			inc esi
			mov [edi], edx
			inc edi
					
			dec ecx

			cmp ecx, 0
			jne .loop_str_int_part
			
		.add_period:

			xor edx, edx
			mov edx, '.'

			inc edi
			mov [edi], edx
			inc esi

			xor ebx, ebx
				
		.loop_convert_fraction:

			fild dword [mul_value] ; mul value = 10 
			fmulp st1, st0; our mul_value gets popped
			fld st0 ; could use this + fisttp right after
			fisttp dword [temp_number]
			fild dword [temp_number]
			
			mov edx, dword [temp_number]
			add edx, '0'

			inc edi
			mov [edi], edx
			inc esi

		
			xor edx, edx
			mov [temp_number], edx

			inc ebx
			cmp ebx, 2
			ja .add_null_terminator
						
			fsubp st1, st0
			fabs
			
			fld dword [decimal_threshold]
			fcomip st0, st1
			jb .loop_convert_fraction

		.add_null_terminator:
		
			inc edi
			inc esi
			mov [edi], 0 ; 0 is the actual null terminator
			
		.print_buffer:
	 
	    	print_str buffer, esi

		ret

	check_u_expression:

		
					
		.check_number:
						
			; call read and pass our string and lenght	
			read_stdin ustr, 200
				
			; ecx = ptr to buffer (beggining of the string) eax = number of bytes read (doing this equation gives us str lenght)
			mov byte [ecx + eax - 1], 0 ; <- null terminate the ustr by replacing \n with 0

			mov esi, ustr
			call conv_str_to_int

			; compare conv_str_to_int return value
			mov ebx, -1
			cmp edi, ebx
			jne .valid 
							
			; if not digit, tell user input was not valid, and iterate again
			print_str str_input_not_number, str_input_not_number_len

			jmp .check_number
		
			.valid: 
			
			mov [u_n1], eax										
			
		.end_check_u_expression:
			
			ret
			
global _start

_start:

	call check_u_expression
	call round_float
	call print_float

	exit_program
