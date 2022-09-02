
struct Group {
	mut:
	start 								int 				= -1
	end 									int 				= -1
}

struct Result {
	txt 									&string
	groups 								[]Group
	matches 							[]Group
}
