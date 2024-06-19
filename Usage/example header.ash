header {

	// Product name
	name: 

	// Product type
	product: exec

}

// Source code files
compile {

	"file.asm"

}

// Static libraries
include {

	"library.asl"

}

// Dynamic libraries
link {

	[#math; "dlib.asl"]

}

header {
	name: ahoj
	product: 
}