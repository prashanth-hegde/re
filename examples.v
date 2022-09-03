module main

import re

fn main() {
	//expr := r'ab((ppp)cd+)+(e*)'
	//expr1 := r'(ab+)+c'
	//text := r'abcddddcddcdee'
	//toks := parse(expr1)
	//log.trace("toks = $toks")
	//matc := re.match_all('a.b', 'axbaxbaxb') ?
	multiple_matches := re.match_all('a.b', 'axbaxbaxb') ?
	println(multiple_matches)
}
