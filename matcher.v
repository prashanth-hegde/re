pub struct RegexOpts {
	ignore_case			 			bool
	standard_expr		 			bool
}

// recursively add states for epsilons
[inline]
fn add_state(s State, mut state_set []State) {
	log.trace('adding state $s')
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
		log.trace("evaluating state transition $tr.token against $ch")
		res = match tr.token.symbol {
			.char					 		{ tr.token.char == ch.str() }
			.dot							{ true }
			else							{ false }
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

	// variables
	mut curr_states := []State{}
	mut groups := [Group{}]
	//mut matches := []Group{}

	// initialization
	add_state(re.transit.start, mut curr_states)
	for i, ch in text.runes() {
		mut next_states := []State{}
		for state in curr_states {
			next_state := can_transition(state, ch) or { continue }
			log.trace("group info for state $next_state.name : start=$next_state.group_start, end=$next_state.group_end")
			// evaluate group-0 for the evaluated state
			if groups[0].start == -1 {
				groups[0].start = i
			} else if next_state.is_end && groups[0].end < i {
				groups[0].end = i
			}
			eval_group(state, next_state, mut groups, i)
			add_state(next_state, mut next_states)
		}
		curr_states = next_states.clone()
		log.debug("next_states: $curr_states")
		if curr_states.len == 0 {
			// if there are no more states to evaluate, break and move on to next
			break // this may need to be continue, more tests needed
		} else if curr_states.len > 0 && true in curr_states.map(it.is_end) {
			// if we haven't matched anything yet or
			// exhausted all states, reset the states and start over
			// for the next match
			add_state(re.transit.start, mut curr_states)
		}
	}

	for s in curr_states {
		if s.is_end {
			log.debug("evaluating end for $s.name, groups=$groups")
			return true
		}
	}
	return false
}

fn eval_group(start &State, end &State, mut groups []Group, position int) {
	// group start
	for gp in start.group_starts() {
		if groups.len <= gp {
			log.debug("group $gp does not exist, adding | len=$groups.len gp=$gp")
			groups << Group { position, position }
		} else {
			log.warn("group $gp already filled, ignoring")
		}
	}

	// group end
	for gp in end.group_ends() {
		if gp < groups.len {
			groups[gp].end = position
		} else {
			log.warn("group $gp specified, but not found in groups list")
		}

		if groups[0].end < position {
			groups[0].end = position
		}
	}
}

/******************************************************************************
*
* public interfaces
*
******************************************************************************/
pub struct Re {
	transit					 			Transition
	opts									RegexOpts
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

