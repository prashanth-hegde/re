module re

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
fn (re Re) match_internal(text string, first_match bool) Result {
	log.debug('$re.transit')

	// variables
	mut curr_states := []State{}
	mut groups := [Group{}] 			// regex groups enclosed in parenthesis
	mut matches := []Group{}			// text matches, there could be multiple matches
	mut curr_match := Group{}

	// initialization
	add_state(re.transit.start, mut curr_states)
	for i, ch in text.runes() {
		mut next_states := []State{}
		//mut match_found := false
		for state in curr_states {
			next_state := can_transition(state, ch) or { continue }
			log.trace("group info for state $next_state.name : start=$next_state.group_start, end=$next_state.group_end")
			// evaluate group-0 for the evaluated state
			if groups[0].start == -1 {
				groups[0].start = i
			} else if next_state.is_end && groups[0].end < i {
				groups[0].end = i + 1
			}
			// adding current match
			if curr_match.start == -1 {
				curr_match.start = i
			} else if next_state.is_end {
				curr_match.end = i + 1
				matches << curr_match
				curr_match = Group{}

				if first_match {
					return Result{text, groups, matches}
				}
			}
			eval_group(state, next_state, mut groups, i)
			add_state(next_state, mut next_states)
		}
		curr_states = next_states.clone()
		log.debug("next_states: $curr_states")
		if curr_states.len == 0 || true in curr_states.map(it.is_end) {
			// if there are no more states to evaluate, break and move on to next
			//break // this may need to be continue, more tests needed
			add_state(re.transit.start, mut curr_states)
		}
	}

	return Result{text, groups, matches}
	// todo: the below logic mat not be needed, check with tests
	//return if true in curr_states.map(it.is_end) {
	//	Result{text, groups, matches}
	//} else {
	//	Result{text, []Group{}, []Group{}}
	//}
}

[inline]
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
			groups[gp].end = position + 1
		} else {
			log.warn("group $gp specified, but not found in groups list")
		}
	}
}

