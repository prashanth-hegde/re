module main

pub struct RegexOpts {
  ignore_case       bool
}

struct ReProcessor {
  //text              string
  opts              RegexOpts
  mut:
  transitions       Transition
  states            []State
}

//fn (mut re ReProcessor) add_state(state State) {
//  if state !in re.states {
//    re.states << state
//    for eps in state.epsilon {
//      re.states << eps
//    }
//  }
//}

fn add_state(s State, mut state_set []State) {
  log.debug("adding state s$s.name")
  state_names := state_set.map(it.name)
  if s.name !in state_names {
    state_set << s
    for eps in s.epsilon {
      add_state(eps, mut state_set)
    }
  }
}

fn (mut rp ReProcessor) match_all(text string) bool {
  // todo: externalize this processing logic
  // todo: modify the logic to process indexes rather than text itself

  log.debug('$rp.transitions')
  mut curr_states := []State{}
  curr_states << rp.transitions.start
  for ch in text.runes() {
    mut next_states := []State{}
    for state in curr_states {
      c := ch.str()
      log.debug("processing $c")
      log.debug("state transitions = ${state.transitions}")
      if c in state.transitions {
        trans_state := state.transitions[c]
        add_state(trans_state, mut next_states)
      }
    }
    log.debug("before clone: curr_states=$curr_states")
    curr_states = next_states.clone()
    log.debug("after clone: curr_states=$curr_states")
  }

  log.debug("new curr_states = $curr_states")
  for s in curr_states {
    if s.is_end {
      return true
    }
  }
  return false
}

/******************************************************************************
*
* public interfaces
*
******************************************************************************/
pub struct Re {
  transit           Transition
  pub mut:
  opts              RegexOpts
}

pub fn compile_opt(pattern string, opts RegexOpts) ?Re {
  return Re{transit: build_nfa(pattern)?, opts: opts}
}

pub fn compile(pattern string) ?Re {
  return Re{transit: build_nfa(pattern)?, opts:RegexOpts{}}
}

pub fn (re Re) match_all(text string) bool {
  rp := ReProcessor{
    opts: re.opts
    transitions: re.transit
  }
  curr_states := []State
  return true
}

//fn main() {
//  expr := 'abcd'
//  nfa := build_nfa(expr) ?
//  mut rp := ReProcessor{
//    transitions: nfa
//  }
//  res := rp.match_all('abcd')
//  println("hello $res")
//}
