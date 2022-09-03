module re

struct Group {
	mut:
	start 								int 				= -1
	end 									int 				= -1
}

fn (g Group) str() string {
	return '$g.start:$g.end'
}

struct Result {
	txt 									&string
	match_found 					bool
	groups 								[]Group
	matches 							[]Group
}
