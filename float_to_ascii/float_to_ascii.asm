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


	end_of_str_flag dd 0

	float_number dq -436.1464
	int_part dd 0
	mul_value dd 10
	temp_number dd 0
	decimal_threshold dd 0.0000001

	buffer:    times 201 db 0

section .bss


section .text

global _start


	print_float:

		; esi =  counter of how many chars the string will have
		; edi = pointer to the buffer where the string will lice

		xor ecx, ecx                
		xor edx, edx
		xor edi, edi
		xor esi, esi

		mov edi, buffer	
    
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


_start:

	call print_float

	exit_program
