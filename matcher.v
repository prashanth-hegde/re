module main

pub struct RegexOpts {
	ignore_case			 bool
	standard_expr		 bool
}

// recursively add states for epsilons
[inline]
fn add_state(s State, mut state_set []State) {
	log.debug('adding state $s')
	state_names := state_set.map(it.name)
	if s.name !in state_names {
		state_set << s
		for eps in s.epsilon {
			add_state(eps, mut state_set)
		}
	}
}

[inline]
fn can_transition(state &State, ch rune) ?&State {
	mut res := false
	for tr in state.transitions {
		log.debug("evaluating state transition $tr.token against $ch")
		res = match tr.token.symbol {
			.char					 {
				log.debug("char $ch being matched ${tr.token.char == ch.str()}")
				tr.token.char == ch.str() }
			.dot						{ true }
			else						{ false }
		}
		if res {
			return tr.state
		}
	}
	return error("no matching state found for $state.name")
}

[direct_array_access]
fn (re Re) match_all(text string) bool {
	// todo: externalize this processing logic
	// todo: modify the logic to process indexes rather than text itself
	log.debug('$re.transit')
	mut curr_states := []State{}
	add_state(re.transit.start, mut curr_states)
	for ch in text.runes() {
		mut next_states := []State{}
		for state in curr_states {
			next_state := can_transition(state, ch) or { continue }
			add_state(next_state, mut next_states)
		}
		curr_states = next_states.clone()
		log.debug("next_states: $curr_states")
		if curr_states.len == 0 {
			break
		}
	}

	for s in curr_states {
		if s.is_end {
			log.debug("evaluating end for $s.name")
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
	transit					 Transition
	opts							RegexOpts
}

pub fn compile_opt(pattern string, opts RegexOpts) ?Re {
	return Re{transit: build_nfa(pattern)?, opts: opts}
}

pub fn compile(pattern string) ?Re {
	return Re{transit: build_nfa(pattern)?, opts:RegexOpts{}}
}

pub fn match_all(pattern string, txt string) ?bool {
	mut compiled := false
	re := fn [pattern, mut compiled] () ?Re {
		mut re_ := Re{}
		if !compiled {
			re_ = compile(pattern)?
			compiled = true
		}
		return re_
	}
	return re()?.match_all(txt)
}

