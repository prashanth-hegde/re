module main
import datatypes {Stack}

struct State {
  name              string
  mut:
  epsilon           []State
  transitions       map[string]State
  is_end            bool = true
}
fn (s State) str() string {
  e := if s.is_end { ", end" } else { "" }
  return 's${s.name}[ep=$s.epsilon.len, tr=$s.transitions.len$e]'
}

struct Transition {
  mut:
  start            State
  end              State
}

fn (tr Transition) str() string {
  t := '$tr.start -> $tr.end'
  e := '${tr.start.epsilon.map(it.name)}'
  r := '${tr.start.transitions.keys()}'
  return 'transition=$t | epsilon=$e | trans=$r'
}

struct NFA {
  mut:
  nfa_stack         Stack<Transition>          = Stack<Transition>{}
  state_count       int
}

fn (mut n NFA) create_state() State {
  return State{name: '${n.state_count++}'}
}

fn (mut n NFA) add_transition(start State, end State) {
  edge := Transition{start, end}
  n.nfa_stack.push(edge)
}

fn (mut n NFA) handle(tok Token) {
  match tok.symbol {
    .char   { n.handle_char(tok) }
    .concat { n.handle_concat(tok) }
    else    {  }
  }
}

fn (mut n NFA) handle_char(tok Token) {
  mut s0 := n.create_state()
  mut s1 := n.create_state()
  s0.transitions[tok.char.str()] = s1
  n.add_transition(s0, s1)
  log.debug('char handler     -> $tok, start=$s0, end=$s1')
}

fn (mut n NFA) handle_concat(tok Token) {
  mut n2 := n.nfa_stack.pop() or { return }
  mut n1 := n.nfa_stack.pop() or { return }
  n1.end.is_end = false
  n1.end.epsilon << n2.start
  n.add_transition(n1.start, n2.end)
  log.debug('concat handler   -> $tok, start=$n1.start, end=$n2.end')
  print_tr(n1.start, '')
}

fn (mut n NFA) handle_alt(tok Token) {
  mut n2 := n.nfa_stack.pop() or {return}
  mut n1 := n.nfa_stack.pop() or {return}
  mut s0 := n.create_state()
  s0.epsilon << n1.start
  s0.epsilon << n2.start
  mut s3 := n.create_state()
  n1.end.epsilon << s3
  n2.end.epsilon << s3
  n1.end.is_end = false
  n2.end.is_end = false
  n.add_transition(s0, s3)
}

fn (mut n NFA) handle_rep(tok Token) {
  mut n1 := n.nfa_stack.pop() or {return}
  mut s0 := n.create_state()
  mut s1 := n.create_state()
  s0.epsilon << n1.start
  if tok.symbol == .star {
    s0.epsilon << s1
  }
  n1.end.epsilon << s1
  n1.end.epsilon << n1.start
  n1.end.is_end = false
  n.add_transition(s0, s1)
}

fn (mut n NFA) handle_qmark(tok Token) {
  mut n1 := n.nfa_stack.pop() or {return}
  n1.start.epsilon << n1.end
  n.nfa_stack.push(n1)
}

/******************************************************************************
*
* abstracted constructs
*
******************************************************************************/
fn build_nfa(expr string) ?Transition {
  tokens := parse(expr)
  println("tokens = $tokens")
  mut nfa := NFA{}
  for tok in tokens {
    nfa.handle(tok)
  }
  log.debug("building nfa completed, stack = $nfa.nfa_stack")
  assert nfa.nfa_stack.len() == 1

  return nfa.nfa_stack.pop()
}

//fn main() {
//  exp0 := r'abcd'
//  exp1 := r'aab+?b?'
//  exp2 := r'abc|d'
//  tr := build_nfa(exp0) or {
//    println("building nfa failed, $err")
//    return
//  }
//  print_tr(tr.start, '')
//}

fn print_tr(s State, spaces string) {
  log.debug('$spaces for $s.name:')
  log.debug('$spaces epsilons:')
  for e in s.epsilon {
    print_tr(e, spaces + '  ')
  }
  log.debug('$spaces transitions:')
  for _, tr in s.transitions {
    print_tr(tr, spaces + '  ')
  }
}
