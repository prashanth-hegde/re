module main
import log {Log}

enum Symbol {
	end 									// terminal symbol
	group_start						// (
	group_end							// )
	star 									// *
	opt 									// |
	concat								// \x08
	plus									// +
	qmark 								// ?
	dot									  // .
	char									// normal character
  word                  // \w
  nonword               // \W
  digit                 // \d
  nondigit              // \D
  space                 // \s
  nonspace              // \S
}
const log = Log{level: .debug}
const concat = `\x08`
const dot = 'dot'
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

const switches = {
  `.`                   : Symbol.dot
  `w`                   : .word
  `W`                   : .nonword
  `d`                   : .digit
  `D`                   : .nondigit
  `s`                   : .space
  `S`                   : .nonspace
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
  runes                 []rune
	mut:
	position 							int
	tokens 								[]Token
  raw_tokens            []Token
  curr_token            Token
  curr_group            int           = 1
}

fn (parser Parser) string() string {
  return "position=$parser.position | curr=$parser.curr_token.symbol | lookahead=$parser.lookahead().symbol"
}

fn (mut parser Parser) get_token(escaped bool) Token {
  if parser.position >= parser.runes.len {
    return end_token
  }

  chr := parser.runes[parser.position]
  token := if escaped && chr == `.` {
    parser.position++
    Token{'.', .char}
  } else if !escaped && chr == `.` {
    parser.position++
    Token{dot, .dot}
  } else if escaped  && chr in switches {
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
  return token
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
  } else if p.lookahead().symbol == .group_end {
    p.tokens << Token{'0', .group_end}
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
    p.tokens << Token{'${p.curr_group++}', .group_start}
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
  //expr1 := r'abcd'
  //text := r'abcddddcddcdee'
  //toks := parse(expr1)
  //println("toks = $toks")
  matc := match_all('ab.d', 'abcd') ?
  println(matc)
}
