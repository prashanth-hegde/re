import time

/******************************************************************************
*
* Poor man's logger. Having problems with built in logger sometimes not working
*
******************************************************************************/

enum LogLevel {
	trace
	debug
	info
	warn
	error
}

struct Log {
	mut:
	level LogLevel = .info
}

fn (l Log) debug(msg string) {
	symbol := '[\033[94mDEBUG\33[0m]'
	if int(l.level) <= int(LogLevel.debug) {
		println('$time.now() $symbol $msg')
	}
}

fn (l Log) error(msg string) {
	symbol := '[\033[31mERROR\33[0m]'
	if int(l.level) <= int(LogLevel.error) {
		println('$time.now() $symbol $msg')
	}
}

fn (l Log) info(msg string) {
	symbol := '[\033[32mINFO\33[0m]'
	if int(l.level) <= int(LogLevel.info) {
		println('$time.now() $symbol  $msg')
	}
}

fn (l Log) trace(msg string) {
	symbol := '[\033[94mTRACE\33[0m]'
	if int(l.level) <= int(LogLevel.trace) {
		println('$time.now() $symbol $msg')
	}
}

fn (l Log) warn(msg string) {
	symbol := '[\033[33mWARN\33[0m]'
	if int(l.level) <= int(LogLevel.warn) {
		println('$time.now() $symbol  $msg')
	}
}

const log = Log{}

/******************************************************************************
*
* Core data structures for the module, used everywhere
*
******************************************************************************/

enum Symbol {
	end 									// terminal symbol
	group_start						// (
	group_end							// )
	star 									// *
	opt 									// |
	concat								// \x08
	plus									// +
	qmark 								// ?
	dot										// .
	char									// normal character
	word									// \w
	nonword								// \W
	digit									// \d
	nondigit							// \D
	space									// \s
	nonspace							// \S
}
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
	`.`									 : Symbol.dot
	`w`									 : .word
	`W`									 : .nonword
	`d`									 : .digit
	`D`									 : .nondigit
	`s`									 : .space
	`S`									 : .nonspace
}

/*
	Token maintains a simple mapping of character with any special meaning
	For instance, a * is interpreted literally if it is preceeded with a backslash
	But * has a special meaning if it is not preceeded by a backslash
*/
struct Token {
	char 									string 				[required]
	symbol 								Symbol 				[required]
}

fn (token Token) str() string {
	return '$token.char:$token.symbol'
}

/******************************************************************************
*
* Poor man's logger. Having problems with built in logger sometimes not working
*
******************************************************************************/


