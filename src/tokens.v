module re

/******************************************************************************
*
* Parser constructs
*
******************************************************************************/

struct Parser {
	pattern               string         [required]
	runes                 []rune
	mut:
	position              int
	tokens                []Token
	raw_tokens            []Token
	curr_group            int            = 1
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
		Token{'.', .char, []}
	} else if !escaped && chr == `.` {
		parser.position++
		Token{'', .dot, []}
	} else if escaped	&& chr in switches {
		parser.position++
		sw := switches[chr] or { Symbol.char }
		Token{chr.str(), sw, []}
	} else if !escaped && chr == `\\` {
		parser.position++
		parser.get_token(true)
	} else if !escaped && chr in symbol_map {
		parser.position++
		sym := symbol_map[chr] or { Symbol.char }
		Token{chr.str(), sym, []}
	} else if !escaped && chr == `[` {
		parser.position++
		parser.parse_char_set()
	} else {
		parser.position++
		Token{chr.str(), .char, []}
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
	log.trace("evaluating concat: $p.lookahead().char")
	p.factor()
	if p.lookahead().symbol !in [.group_end, .opt, .end] {
		p.concat()
		p.tokens << Token{concat.str(), .concat, []}
	}
}

fn (mut p Parser) factor() {
	log.trace("evaluating factor: $p.lookahead().symbol")
	p.primary()
	for p.lookahead().symbol in [.star, .plus, .qmark] {
		p.tokens << p.lookahead()
		p.next_token()
	}
}

fn (mut p Parser) primary() {
	log.trace("evaluating primary: $p.lookahead().char")
	if p.lookahead().symbol == .group_start {
		p.tokens << Token{'${p.curr_group++}', .group_start, []}
		p.next_token()
		p.opt()
		p.next_token()
	} else {
		p.tokens << p.lookahead()
		p.next_token()
	}
}

fn parse(expr string) []Token {
	mut parser := Parser{pattern:expr, runes:expr.runes()}
	log.debug("token_runes = $parser.runes")
	mut tok := parser.get_token(false)
	for tok.symbol != .end {
		parser.raw_tokens << tok
		tok = parser.get_token(false)
	}
	parser.position = 0
	return parser.parse()
}

/******************************************************************************
*
* Character Set parser
*
******************************************************************************/
fn (mut p Parser) parse_char_set() Token {
	run := fn [p] () rune {
	  return p.runes[p.position]
	}

	char_seq := fn (st rune, en rune) string {
		mut curr := st + 1
		mut seq := ''
		for curr < en {
			seq += curr.str()
			curr++
		}
		return seq
	}


	sym := if p.runes[p.position] == `^` {
		p.position++
		Symbol.non
	} else {
		Symbol.any
	}
	mut ch := ''
	mut escaped := false
	mut types := []Symbol{}
	for escaped || (!escaped && run() != `]`) {
		if escaped {
			escaped = !escaped
			p.position++
			if run() in switches {
				types << switches[run()]
			}
			p.position++
			continue
		} else if run() == `\\` {
			escaped = true
			continue
		} else if run() == `-` &&
		  (is_lower(ch[ch.len - 1]) ||
		   is_upper(ch[ch.len - 1]) ||
		   is_digit(ch[ch.len - 1])) {
		  // [A-Za-z] kind of format
		  p.position++
			ch += char_seq(ch[ch.len - 1], run())
		}
		ch += run().str()
		p.position++
	}
	p.position++ // close out the ]

	return Token{ch, sym, types}
}

