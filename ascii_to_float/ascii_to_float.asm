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


	str_input_not_number db 'Invalid input, try again!',0Ah,0
	str_input_not_number_len equ $ - str_input_not_number

	is_positive db 1
	is_number db 0

	;num_of_conv_vals dd 0
	limit_to_convert db 2

	end_of_str_flag dd 0

	TRUE equ 1
	FALSE equ 0

	buffer:    times 201 db 0
	inputed_nums: times 201 dd 0

	float_number dd 0.0
	decimal_scale dd 10
	temp_numb dd 0
	
	current_iteration db 0

	;welcome_msg_buffer_len equ (str_welcome_len1 + str_temperature_len + str_energia_len + str_com_qual_len + str_module_status_len) - 6

section .bss

	; 32 bits word to hold eax (converted u_str)
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
				jmp .nextchar

			; works
			.decimal:

				inc esi
				
				xor ebx, ebx
				mov bl, byte [esi]
				
				cmp bl, 0 ; zero signifies the end of the string
				je .end_decimal
				cmp bl, ' '
				je .end_decimal

				sub bl, '0'
				mov [temp_numb], ebx
				
				fild dword [temp_numb]
				fild dword [decimal_scale]
				fdivp ; divides the two above
				fld dword [float_number] 
				faddp 
				fstp dword [float_number]
				

				xor edi, edi
				mov edi, [decimal_scale]
				imul edi, 10
				mov [decimal_scale], edi

				jmp .decimal

			.end_decimal:

				mov [temp_numb], eax
				fild dword [temp_numb]
				fld dword [float_number]
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

				fstp dword [float_number] ; load the top of the stack into float number
				
				cmp bl, 0 ; zero signifies the end of the string
				je .end_nextchar
				jmp .nextchar
			
			.error:
			
				mov edi, -1
				ret 

		.end_nextchar:
		
			ret

	check_u_expression:

		; clear all registers for use
		xor ecx, ecx
		xor eax, eax
		xor ebx, ebx
		xor esi, esi
		xor edi, edi 
		xor edx, edx
					
			.check_number:
						
				; call read and pass our string and lenght	
				read_stdin ustr, 200
				
				; ecx = ptr to buffer (beggining of the string) eax = number of bytes read (doing this equation gives us str lenght)
				mov byte [ecx + eax - 1], 0 ; <- null terminate the ustr by replacing \n with 0

				; mov the user input to esi and call conv_str_to_int
				; to convert it into a number not a string
				mov esi, ustr
				call conv_str_to_int

				; compare conv_str_to_int return value
				mov ebx, -1
				; if edi is not -1, but instead of a converted positive nubmer, goto valid 
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
	exit_program
