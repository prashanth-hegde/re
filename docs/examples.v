import re

fn main() {
	txt := 'ggaxbkkaxbkkaxb'
	expr := re.compile(r'a.\w?') ?
	ff := expr.find_first("hhhh") or {"not found"}
	println('match_all         -> ${expr.match_all(txt)}')
	println('no_match_s        -> $ff')
	println('find_all          -> ${expr.find_all(txt)}')
	println('no_match          -> ${expr.find_all("hhhhhh")}')
	println('all_matches       -> ${expr.match_all(txt).get_matches()}')
	println('word              -> ${expr.match_all(txt).get_matches()}')
}
