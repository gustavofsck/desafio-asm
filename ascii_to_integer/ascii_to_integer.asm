

	conv_str_to_int:

		xor ebx, ebx
		xor ecx, ecx
		xor eax, eax
		xor edi, edi

		mov edi, TRUE 
		mov [is_positive], edi

		.nextchar: ; loop for going char by char until we find the end of the string

			; the whole string is in esi, a single char is in the lower byte
			; by loading a byte of esi into a 1 byte register we load a single char
			mov bl, byte [esi]  ; load current char


			; if that char is a number and it zero, its the null terminator
			cmp bl, 0 ; zero signifies the end of the string
			je .end_nextchar

			cmp bl, '-'
			je .negative

			; convert from ascii to number and compare it to 9 if its above the char was not a digit
			sub bl, '0'			
			jmp .positve
						
			.negative:
				
				mov edi, FALSE 
				mov [is_positive], edi

				inc esi
				jmp .nextchar	 


			.positve:
				cmp bl, 9
				ja .error
				
				;imul eax, eax, 10 multiplies the current value in EAX by 10 and stores the result back in EAX
				imul eax, eax, 10

				; since the converted digit is now in bl (lower portion of ebx)
				; we can add ebx (which only contains the digit to eax) slowly building the stringh
				add eax, ebx

				; increment esi so we use the next char (esi is pointer to string)
				inc esi
				jmp .nextchar
			
			.error:
	
				mov edi, -1
				ret 

		.end_nextchar:

			ret
