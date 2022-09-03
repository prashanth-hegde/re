module re

/******************************************************************************
*
* public interfaces for Result
*
******************************************************************************/
pub struct Group {
	mut:
	start 								int 				= -1
	end 									int 				= -1
}

pub fn (g Group) str() string {
	return '$g.start:$g.end'
}

pub struct Result {
	txt 									string
	groups 								[]Group
	matches 							[]Group
}

pub fn (rs Result) get_group(group_num int) ?string {
	if group_num < 0 || group_num > rs.groups.len {
		return error("only groups 0 through $rs.groups.len available")
	}

	start, end := rs.groups[group_num].start, rs.groups[group_num].end
	return rs.txt[start..end]
}

/******************************************************************************
*
* public interfaces for Re
*
******************************************************************************/
pub struct Re {
	transit					 			Transition
	opts									RegexOpts
}

pub fn compile_opt(pattern string, opts RegexOpts) ?Re {
	return Re{transit: build_nfa(pattern)?, opts: opts}
}

pub fn compile(pattern string) ?Re {
	return Re{transit: build_nfa(pattern)?, opts:RegexOpts{}}
}

pub fn (re Re) match_all(txt string) Result {
	return re.match_internal(txt, false)
}

pub fn (re Re) find_first(txt string) ?string {
	result := re.match_internal(txt, true)
	if result.matches.len == 0 {
		return error("pattern not found")
	}

	m0 := result.matches[0]
	return txt[m0.start..m0.end]

}

pub fn (re Re) find_all(txt string) []string {
	result := re.match_internal(txt, false)
	return result.matches.map(txt[it.start..it.end])
}

pub fn (re Re) get_group(txt string) []string {
	result := re.match_internal(txt, false)
	return result.matches.map(txt[it.start..it.end])
}

pub fn (re Re) contains_in(txt string) bool {
	result := re.match_internal(txt, true)
	return result.matches.len > 0
}
