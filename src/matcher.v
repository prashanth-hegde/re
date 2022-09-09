module re

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
fn is_lower(ch u8) bool {
	tmp := ch - `a`
	return tmp < 26 && tmp >= 0
}

[inline]
fn is_upper(ch u8) bool {
	tmp := ch - `A`
	return tmp < 26 && tmp >= 0
}

[inline]
fn is_digit(ch u8) bool {
	tmp := ch - `0`
	return tmp < 10 && tmp >= 0
}

[inline]
fn is_alnum(ch u8) bool {
	return is_lower(ch) ||
				 is_upper(ch) ||
				 is_digit(ch) ||
				 ch in [`_`]
}

[inline]
fn can_transition(state &State, ch rune) ?&State {
	mut res := false
	for tr in state.transitions {
		log.debug("evaluating state transition $tr.token against $ch")
		res = match tr.token.symbol {
			.char					 		{ tr.token.ch() == ch }
			.dot							{ true }
			.word 						{ is_alnum(ch) }
			.nonword 					{ !is_alnum(ch) }
			.digit 						{ is_digit(ch) }
			.nondigit 				{ !is_digit(ch) }
			.any 							{ ch in tr.token.char.runes() }
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
	mut groups := []Group{}       // regex groups enclosed in parenthesis
	mut matches := []Group{}      // text matches, there could be multiple matches
	mut curr_match := Group{}

	// initialization
	add_state(re.transit.start, mut curr_states)
	for i, ch in text {
		mut next_states := []State{}
		mut terminal := false
		for state in curr_states {
			next_state := can_transition(state, ch) or { continue }
			log.debug("group info for state $next_state.name : start=$next_state.group_start, end=$next_state.group_end")
			eval_group(state, next_state, mut groups, i)

			if curr_match.start == -1 {
				curr_match.start = i
			}
			if next_state.is_end && next_state.epsilon.len == 0 && next_state.transitions.len == 0 {
				log.info("terminal match")
				terminal = true
				break
			}

			add_state(next_state, mut next_states)
		}
		prev_last_state, prev_eps := check_end(curr_states)
		curr_states = next_states.clone()
		last_state, eps := check_end(curr_states)
		log.info("next_states: $curr_states")

		if terminal {
			log.info("terminal state")
			append_match(mut curr_match, mut matches, i + 1)
			curr_states.clear()
			add_state(re.transit.start, mut curr_states)
		} else if prev_last_state && prev_eps && curr_match.start != -1 && curr_states.len == 0 {
			log.info("previous state was last that got reset, so adding them to match | last_state=$prev_last_state, eps=$prev_eps")
			append_match(mut curr_match, mut matches, i)
			add_state(re.transit.start, mut curr_states)
		} else if i == text.len - 1 && prev_eps && curr_match.start != -1 {
			log.info("end of text match is epsilon, new start i=$i, curr_match=$curr_match, matches=$matches.len")
			append_match(mut curr_match, mut matches, i+1)
			// not resetting state here
		} else if curr_states.len == 0 {
			log.info("no more states... resetting state machine")
			curr_match.start = -1
			add_state(re.transit.start, mut curr_states)
		} else if last_state && !eps {
			log.info("epsilon map = ${curr_states.map(it.name)} ${curr_states.map(it.is_end)}, curr=$curr_match")
			append_match(mut curr_match, mut matches, i + 1)
			add_state(re.transit.start, mut curr_states)
		//} else if !last_state && eps && curr_match.start != -1 {
		//	log.info("digit match")
		//	if matches.len == 0 {
		//		append_match(mut curr_match, mut matches, i + 1)
		//	} else {
		//		matches[matches.len - 1].end = i + 1
		//	}
		}

		if first_match && matches.len > 0 {
			return Result{text, groups, matches}
		}
	}

	return Result{text, groups, matches}
}

[inline]
fn eval_group(start &State, end &State, mut groups []Group, position int) {
	// evaluate group-0 for the evaluated state
	if groups.len == 0 && start.group_start.len > 0 {
		groups << Group{position, position}
	} else if end.is_end && groups.len > 0 && groups[0].end < position {
		groups[0].end = position + 1
	}

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

[inline]
fn check_end (states []State) (bool, bool) {
	last_state := true in states.map(it.is_end)
	mut eps := 0
	for s in states {
		eps += s.epsilon.len
	}
	return last_state, eps > 0
}

[inline]
fn append_match(mut curr_match Group, mut matches []Group, match_end int) {
	curr_match.end = match_end
	matches << curr_match
	curr_match = Group{}
}

