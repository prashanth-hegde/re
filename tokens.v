
/******************************************************************************
*
* Parser constructs
*
******************************************************************************/

struct Parser {
	pattern 							string 				[required]
	runes								 	[]rune
	mut:
	position 							int
	tokens 								[]Token
	raw_tokens						[]Token
	curr_group						int					 = 1
}

fn (parser Parser) string() string {
	return "position=$parser.position | lookahead=$parser.lookahead().symbol"
}

fn (mut parser Parser) get_token(escaped bool) Token {
	if parser.position >= parser.runes.len {
		return end_token
	}

	chr := parser.runes[parser.position]
	return if escaped && chr == `.` {
		parser.position++
		Token{'.', .char}
	} else if !escaped && chr == `.` {
		parser.position++
		Token{dot, .dot}
	} else if escaped	&& chr in switches {
		parser.position++
		sw := switches[chr] or { Symbol.char }
		Token{chr.str(), sw}
	} else if !escaped && chr == `\\` {
		parser.position++
		parser.get_token(true)
	} else if !escaped && chr in symbol_map {
		parser.position++
		sym := symbol_map[chr] or { Symbol.char }
		Token{chr.str(), sym}
	} else {
		parser.position++
		Token{chr.str(), .char}
	}
}

fn (parser Parser) lookahead() Token {
	pos := parser.position
	return if pos >= parser.raw_tokens.len {
		end_token
	} else {
		parser.raw_tokens[pos]
	}
}

fn (mut parser Parser) next_token() Token {
	return if parser.position >= parser.raw_tokens.len {
		end_token
	} else {
		tok := parser.raw_tokens[parser.position]
		parser.position++
		tok
	}
}

/**
	Now since the foundationals have been established it is time to
	look at the precedence of operation:
		concat > opt > factor (*,+,?) > group ('(', ')')
	So we define all these operations, with recursive dependencies
*/

fn (mut parser Parser) parse() []Token {
	// init the lookahead to begin with
	parser.opt()
	return parser.tokens
}

fn (mut p Parser) opt() {
	log.trace("evaluating opt")
	p.concat()
	if p.lookahead().symbol == .opt {
		tok := p.lookahead()
		p.next_token()
		p.opt()
		p.tokens << tok
	} else if p.lookahead().symbol == .group_end {
		p.tokens << p.lookahead()
	}
}

fn (mut p Parser) concat() {
	log.trace("evaluating concat")
	p.factor()
	if p.lookahead().symbol !in [.group_end, .opt, .end] {
		p.concat()
		p.tokens << Token{concat.str(), .concat}
	}
}

fn (mut p Parser) factor() {
	log.trace("evaluating factor")
	p.primary()
	if p.lookahead().symbol in [.star, .plus, .qmark] {
		p.tokens << p.lookahead()
		p.next_token()
	}
}

fn (mut p Parser) primary() {
	log.trace("evaluating primary")
	if p.lookahead().symbol == .group_start {
		p.tokens << Token{'${p.curr_group++}', .group_start}
		p.next_token()
		p.opt()
		p.next_token()
	} else {
		p.tokens << p.lookahead()
		p.next_token()
	}
}

fn (mut p Parser) gp_end() {
	if p.lookahead().symbol == .group_end {
		p.tokens << Token{'0', .group_end}
	}
}

fn parse(expr string) []Token {
	mut parser := Parser{pattern:expr, runes:expr.runes()}
	mut tok := parser.get_token(false)
	for tok.symbol != .end {
		parser.raw_tokens << tok
		tok = parser.get_token(false)
	}
	parser.position = 0
	return parser.parse()
}

fn main() {
	//expr := r'ab((ppp)cd+)+(e*)'
	expr1 := r'(ab+)+c'
	//text := r'abcddddcddcdee'
	//toks := parse(expr1)
	//log.trace("toks = $toks")
	matc := match_all('(ab+)+.d', 'abbabbbd') ?
	println(matc)
}
