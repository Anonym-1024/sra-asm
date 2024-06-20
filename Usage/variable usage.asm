exec {
	main {
		
		// Usage in mov, mvn

		
		mov r0, number // Compiles to: mov r0, #address_of_number_immed
		// mov r0, #number // Compiles to: ldr r0, number

		mvn r0, number // Compiles to: mvn r0, #address_of_number_immed
		// mvn r0, #number // Compiles to: ldr r0, number; xor r0, r0, #Ob11111111[3]

		ret_point:
		// Usage in ldr, str

		ldr r0, number // Compiles to: mov r0, number; ldr r0, r0, #0
		str number[r1], r0 // Compiles to: mov r1, number; str r1, r0, #0



		// Using a variable in normal instructions

		add r0, number.jj[r1], x[r2] // Adds addresses of vars. Compiles to: mov r1, number; mov r2, x; add r0, r1, r2
		add r0, number[r1], x // Adds addresses of vars. Tries to compile to: mov r1, number; add r0, r1, #address_of_x_immed. Fails when cannot generate

		add r0, #number[r1], #x[r2] // Adds contents of vars. Compiles to: ldr r1, number; ldr r2, x; add r0, r1, r2

		sub r0, r1, #"c"


		// Using labels

		label: 

		ban label[r0] // Compiles to: mov r0, label; brn r0
		brn label[r0] // Computes offset at compile time. Compiles to: mov r0, #offset_immed; brn r0

	}

	
}

data {
	const number = 0b0

	x = 0xFF

	var3 = 9

	section1 {
		konstanta = 8
	}


	section2 {
	 	const konstanta = 8
	}
}




