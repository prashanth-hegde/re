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
		log.trace("evaluating state transition $tr.token against $ch")
		res = match tr.token.symbol {
			.char					 		{ tr.token.ch() == ch }
			.dot							{ true }
			.word 						{
				log.info("word match - $ch - ${is_alnum(ch)}")
				is_alnum(ch)
			}
			.nonword 					{ !is_alnum(ch) }
			.digit 						{ is_digit(ch) }
			.nondigit 				{ !is_digit(ch) }
			else							{ false }
		}
		if res {
			return tr.state
		}
	}
	return error("no matching state found for $state.name")
}

[direct_array_access; inline]
fn eval_match3(start &State, end &State, mut curr_match Group, mut matches []Group, i int) bool {
	// adding current match
	if curr_match.start == -1 {
		log.info("setting match start = $i")
		curr_match.start = i
	}
	if end.is_end {
		log.info("evaluating match end = $i")
		curr_match.end = i + 1
		matches << curr_match
		curr_match = Group{}
	}

	return false
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
		//mut match_found := false
		for state in curr_states {
			next_state := can_transition(state, ch) or { continue }
			//log.debug("group info for state $next_state.name : start=$next_state.group_start, end=$next_state.group_end")
			eval_group(state, next_state, mut groups, i)
			//eval_match3(state, next_state, mut curr_match, mut matches, i)

			// =========== matcher ===============
			if curr_match.start == -1 {
				curr_match.start = i
			}
			// =========== matcher ===============


			add_state(next_state, mut next_states)
		}
		curr_states = next_states.clone()
		log.info("next_states: $curr_states")
		// needed for \d+ match
		if curr_states.len == 0 {
			log.info("no more states... resetting state machine")
			curr_match.start = -1
			add_state(re.transit.start, mut curr_states)
		} else if true in curr_states.map(it.is_end) {
			log.info("epsilon map = ${curr_states.map(it.name)} ${curr_states.map(it.is_end)}")
			//mut eps := false
			//for c in curr_states {
			//	if c.epsilon.len > 0 {
			//		eps = true
			//		break
			//	}
			//}
			//if eps && matches.len > 0 {
			//	matches[matches.len - 1].end = i + 1
			//} else {
				curr_match.end = i + 1
				matches << curr_match
				curr_match = Group{}
			//}
				add_state(re.transit.start, mut curr_states)
		}
		if matches.len > 0 && first_match {
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
fn eval_match(start &State, end &State, mut curr_match Group, mut matches []Group, i int) {
	// adding current match
	if curr_match.start == -1 {
		curr_match.start = i
	}
	if end.is_end {
		// || (i == text.len - 1 && true in next_state.epsilon.map(it.is_end)) {
		curr_match.end = i + 1
		matches << curr_match
		curr_match = Group{}
	} else if true in end.epsilon.map(it.is_end) {
		curr_match.end = i + 1
	}

	if curr_match.end > curr_match.start && true in end.epsilon.map(it.is_end) {
		curr_match.end = i + 1
		//matches << curr_match
		//curr_match = Group{}
	}
}

[direct_array_access; inline]
fn eval_match2(start &State, end &State, mut curr_match Group, mut matches []Group, i int) {
	// adding current match
	if curr_match.start == -1 {
		log.info("setting match start = $i")
		curr_match.start = i
	}
	if end.is_end {
		log.info("evaluating match end = $i")
		curr_match.end = i + 1
		matches << curr_match
		curr_match = Group{}
	} else if true in end.epsilon.map(it.is_end) {
		log.info("evaluating epsilon $end.epsilon")
		curr_match.end = i + 1
		if matches.len == 0 {
			matches << curr_match
		} else {
			matches[matches.len-1].start = curr_match.start
			matches[matches.len-1].end = curr_match.end
		}
	}
}

