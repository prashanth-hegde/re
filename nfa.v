module main

[heap]
struct State {
  name              int
  mut:
  epsilon           []&State
  // todo: The ideal data structure for transitions is
  // map[Token]&State. However, struct keys are not supported
  // in map as of v0.3. Once this is supported, we need to revisit
  // this data structure to simplify fom
  transitions       []StateTransition
  is_end            bool = true
}

fn (s &State) str() string {
  e := if s.is_end { ", end" } else { "" }
  return 's${s.name}[ep=$s.epsilon.len, tr=$s.transitions.len$e]'
}

struct Transition {
  mut:
  start            &State
  end              &State
}

struct StateTransition {
  token           Token
  state           &State
}

fn (tr Transition) str() string {
  t := '$tr.start -> $tr.end'
  e := '${tr.start.epsilon.map(it.name)}'
  r := '${tr.start.transitions.map(it.token.char)}'
  return 'transition=$t | epsilon=$e | trans=$r'
}

struct NFA {
  mut:
  nfa_stack         []&Transition       = []&Transition{}
  state_count       int
}

fn (mut n NFA) create_state() &State {
  return &State{name: n.state_count++}
}

fn (mut n NFA) add_transition(start &State, end &State) {
  edge := &Transition{start, end}
  n.nfa_stack << edge
}

// Thompson's algorithm:
// https://medium.com/swlh/visualizing-thompsons-construction-algorithm-for-nfas-step-by-step-f92ef378581b
fn (mut n NFA) handle(tok Token) {
  match tok.symbol {
    .char   { n.handle_char(tok) }
    .dot    { n.handle_char(tok) }
    .concat { n.handle_concat(tok) }
    .opt    { n.handle_alt(tok) }
    .qmark  { n.handle_qmark(tok) }
    .plus   { n.handle_rep(tok) }
    .star   { n.handle_rep(tok) }
    else    {  }
  }
}

fn (mut n NFA) handle_char(tok Token) {
  mut s0 := n.create_state()
  mut s1 := n.create_state()
  transit_state := &StateTransition{tok, s1}
  s0.transitions << transit_state
  n.add_transition(s0, s1)
  log.debug('char handler     -> $tok, start=$s0, end=$s1')
}

fn (mut n NFA) handle_concat(tok Token) {
  mut n2 := n.nfa_stack.pop()
  mut n1 := n.nfa_stack.pop()
  n1.end.is_end = false
  n1.end.epsilon << n2.start
  n.add_transition(n1.start, n2.end)
  log.debug('concat handler   -> $tok, start=$n1.start, end=$n2.end')
}

fn (mut n NFA) handle_alt(tok Token) {
  mut n2 := n.nfa_stack.pop()
  mut n1 := n.nfa_stack.pop()
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
  mut n1 := n.nfa_stack.pop()
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
  log.debug('rep handler      -> $tok, start=$s0, end=$s1')
}

fn (mut n NFA) handle_qmark(tok Token) {
  mut n1 := n.nfa_stack.pop()
  n1.start.epsilon << n1.end
  n.nfa_stack << n1
}

// helper function to print state diagram
//fn print_tr(s State, spaces string) {
//  log.debug('$spaces for $s.name:')
//  log.debug('$spaces epsilons: $s.epsilon.len')
//  //for e in s.epsilon {
//  //  print_tr(e, spaces + '  ')
//  //}
//  log.debug('$spaces transitions:')
//  for _, tr in s.transitions {
//    print_tr(tr, spaces + '  ')
//  }
//}

/******************************************************************************
*
* abstracted constructs
*
******************************************************************************/
fn build_nfa(expr string) ?&Transition {
  tokens := parse(expr)
  log.debug("tokens = $tokens")
  mut nfa := NFA{}
  for tok in tokens {
    nfa.handle(tok)
  }
  assert nfa.nfa_stack.len == 1
  tr := nfa.nfa_stack.pop()
  return tr
}

