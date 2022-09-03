module main

import re

fn main() {
	//expr := r'ab((ppp)cd+)+(e*)'
	//expr1 := r'(ab+)+c'
	//text := r'abcddddcddcdee'
	//toks := parse(expr1)
	//log.trace("toks = $toks")
	//matc := re.match_all('a.b', 'axbaxbaxb') ?
	txt := 'ggaxbkkaxbkkaxb'
	expr := re.compile(r'a.b') ?
	m_all := expr.match_all(txt)
	find_first := expr.find_first(txt) ?
	find_all := expr.find_all(txt)
	no_match := expr.find_all('hhhhhh')
	no_match1 := expr.match_all('hhhhhh')
	println('match_all         -> $m_all')
	println('find_first        -> $find_first')
	println('find_all          -> $find_all')
	println('no_match          -> $no_match')
	println('no_match1         -> $no_match1')
}
