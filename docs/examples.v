module main

import re

fn main() {
	//failed_exprs()
	happy_path() or { return }
}

fn happy_path() ? {
	txt := "abcd 1234 efgh 1234 ghkl1234 ab34546df"
	println("test string = $txt")
	//expr := re.compile(r'abcd') ?
	//word := re.compile(r'ab\w\w') ?
	//unicode_expr :=
	//ff := expr.find_first("hhhh") or {"not found"}
	//println('match_all         -> ${expr.match_all("abcd")}')
	//println('no_match_s        -> $ff')
	//println('find_all          -> ${expr.find_all(txt)}')
	//println('no_match          -> ${expr.find_all("hhhhhh")}')
	//println('all_matches       -> ${expr.match_all(txt).get_matches()}')
	//println('word              -> ${word.match_all("abcd").get_matches()}')
	//println('word              -> ${word.match_all(txt).get_matches()}')
	//println('unicode           -> ${expr.match_all(txt).get_matches()}')
	//println('digit             -> ${digit.match_all(txt).get_matches()}')

	//println('contains -> ${group_alt.contains_in("abbbbd")}')

	//mul_matches := re.compile('Aa.+?Aaf') ?
	//mul_matches := re.compile(r'A.+f') ?
	//println('mult matches      -> ${mul_matches.match_all("1234 AaA dddd Aaf 12334 Aa opopo Aaf").get_matches()}')

	//digit := re.compile(r'\d+') ?
	//println('digit             -> ${digit.match_all(txt).get_matches()}')

	//group_alt := re.compile(r'(ab)+d') ?
	//println('group_alt 					-> ${group_alt.match_all("abbbbd").get_matches()}')

	char_set_any := re.compile(r'ab[c3-9A-Fa-f]') ?
	println('char_set_any      -> ${char_set_any.match_all(txt).get_matches()}')
}

//fn failed_exprs() {
//	expr := re.compile(r'a(b') or {
//		println("failed to parse, $err")
//		return
//	}
//}
