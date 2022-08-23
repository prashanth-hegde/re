module main

struct TestData {
  name          string
  expr          string
  exp_tokens    []Symbol
}
fn test_parser() {
  test_data := [
    TestData{'simple string match',     r'abcd',             [Symbol.char, .char, .char, .char, .concat, .concat, .concat]}
    TestData{'opt',                     r'a|bc|d',           [Symbol.char, .char, .char, .concat, .char, .opt, .opt]}
    TestData{'star',                    r'abc*d',            [Symbol.char, .char, .char, .star, .char, .concat, .concat, .concat]}
    TestData{'backslash',               r'ab\*c',            [Symbol.char, .char, .char, .char, .concat, .concat, .concat]}
    TestData{'group',                   r'(ab+)c',           [Symbol.char, .char, .plus, .concat, .char, .concat]}
    TestData{'group+',                  r'(ab+)+c',          [Symbol.char, .char, .plus, .concat, .plus, .char, .concat]}
    TestData{'pathological',            r'a?a?aa',           [Symbol.char, .qmark, .char, .qmark, .char, .char, .concat, .concat, .concat]}
  ]

  for test in test_data {
    mut parser := Parser{pattern:test.expr}
    tokens := parser.parse()
    assert tokens.len == test.exp_tokens.len, '$test.name'
    for i, tok in tokens {
      assert tok.symbol == test.exp_tokens[i]
    }
  }
}

struct ReTestData {
  name        string
  expr        string
  text        string
  exp_match   bool
}
fn test_match_all() ? {
  test_data := [
    ReTestData{'simple',                r'abcd',             r'abcd',                               true}
    ReTestData{'simple',                r'abcde',            r'abcde',                              true}
    ReTestData{'simple',                r'ab+d',             r'abbd',                               true}
    ReTestData{'simple',                r'(ab)+d',           r'abbbbd',                             false}
    ReTestData{'simple',                r'(ab)+d',           r'abababd',                            true}
  ]
  for test in test_data {
    re := compile(test.expr) ?
    assert re.match_all(test.text) == test.exp_match
  }
}

