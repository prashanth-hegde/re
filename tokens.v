module main
import log {Log}
//import regex
//import time

enum Symbol {
	end 									// terminal symbol
	group_start						// (
	group_end							// )
	star 									// *
	opt 									// |
	concat								// \x08
	plus									// +
	qmark 								// ?
	char									// normal character
}
const log = Log{level: .debug}
const concat = `\x08`
const end_token = Token{concat.str(), .end}
const symbol_map = {
	`(`										: Symbol.group_start
	`)` 									: .group_end
	`*`										: .star
	`|`										: .opt
	concat								: .concat
	`+`										: .plus
	`?`										: .qmark
}

/*
	Token maintains a simple mapping of character with any special meaning
  For instance, a * is interpreted literally if it is preceeded with a backslash
  But * has a special meaning if it is not preceeded by a backslash
*/
struct Token {
	char 									string 			  [required]
	symbol 								Symbol 				[required]
}

fn (token Token) str() string {
	return '$token.char:$token.symbol'
}

/******************************************************************************
*
* Parser constructs
*
******************************************************************************/

struct Parser {
	pattern 							string 				[required]
	mut:
	position 							int
	tokens 								[]Token
  curr_token            Token
  lookahead             Token
}

fn (parser Parser) string() string {
  return "position=$parser.position | curr=$parser.curr_token.symbol | lookahead=$parser.lookahead.symbol"
}

fn (mut parser Parser) get_token(escaped bool) Token {
	pattern := parser.pattern.runes()
	return if parser.position >= pattern.len {
    end_token
	} else if escaped {
    ch := pattern[parser.position]
		tok := Token{ch.str(), .char}
		parser.position++
		tok
	} else if pattern[parser.position] == `\\` {
		parser.position++
		parser.get_token(true)
	} else {
		ch := pattern[parser.position]
		sym := symbol_map[ch] or { Symbol.char }
		parser.position++
    Token{ch.str(), sym}
	}
}

fn (parser Parser) lookahead() Token {
  pat := parser.pattern.runes()
  if parser.position >= pat.len { return end_token }
  ch := pat[parser.position]
  sym := symbol_map[ch] or {Symbol.char}

  return Token {
    char    : ch.str()
    symbol  : sym
  }
}

fn (mut parser Parser) next_token() Token {
  parser.curr_token = parser.get_token(false)
  parser.lookahead = parser.lookahead()
  return parser.curr_token
}

/**
  Now since the foundationals have been established it is time to
  look at the precedence of operation:
    concat > opt > factor (*,+,?) > group ('(', ')')
  So we define all these operations, with recursive dependencies
*/

fn (mut parser Parser) parse() []Token {
  // init the lookahead to begin with
  parser.lookahead = parser.lookahead()
  parser.opt()
  return parser.tokens
}

fn (mut p Parser) opt() {
  p.concat()
  if p.lookahead().symbol == .opt {
    tok := p.lookahead()
    p.next_token()
    p.opt()
    p.tokens << tok
  }
}

fn (mut p Parser) concat() {
  p.factor()
  if p.lookahead().symbol !in [.group_end, .opt, .end] {
    p.concat()
    p.tokens << Token{concat.str(), .concat}
  }
}

fn (mut p Parser) factor() {
  p.primary()
  if p.lookahead().symbol in [.star, .plus, .qmark] {
    p.tokens << p.lookahead()
    p.next_token()
  }
}

fn (mut p Parser) primary() {
  if p.lookahead().symbol == .group_start {
    p.next_token()
    p.opt()
    p.next_token()
  } else if p.lookahead().symbol == .char {
    p.tokens << p.lookahead()
    p.next_token()
  }
}

fn parse(expr string) []Token {
  mut parser := Parser{pattern:expr}
  return parser.parse()
}
