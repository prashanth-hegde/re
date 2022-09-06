module re

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
    TestData{'group',                   r'(ab+)c',           [Symbol.group_start, .char, .char, .plus, .concat, .group_end, .char, .concat]}
    TestData{'group+',                  r'(ab+)+c',          [Symbol.group_start, .char, .char, .plus, .concat, .group_end, .plus, .char, .concat]}
    TestData{'pathological',            r'a?a?aa',           [Symbol.char, .qmark, .char, .qmark, .char, .char, .concat, .concat, .concat]}
    TestData{'dot',                     r'a\.b',             [Symbol.char, .char, .char, .concat, .concat]}
    TestData{'dot',                     r'a.b',              [Symbol.char, .dot, .char, .concat, .concat]}
  ]

  for test in test_data {
    tokens := parse(test.expr)
    assert tokens.len == test.exp_tokens.len, '$test.name'
    for i, tok in tokens {
      assert tok.symbol == test.exp_tokens[i], '$test.name'
    }
  }
}

struct ReTestData {
  name        string
  expr        string
  text        string
  exp_match   bool
}
fn test_contains_in() ? {
  test_data := [
    ReTestData{'simple',                r'abcd',             r'abcd',                               true}
    ReTestData{'alt',                   r'ab+d',             r'abbd',                               true}
    ReTestData{'group alt',             r'(ab)+d',           r'abbbbd',                             false}
    ReTestData{'group alt 2',           r'(ab)+d',           r'abababd',                            true}
    ReTestData{'group star',            r'a(a+b)*b',         r'aaababb',                            true}
    ReTestData{'group star 2',          r'a(a+b)*b',         r'ab',                                 true}
    ReTestData{'dot',                   r'....',             r'abcd',                               true}
    ReTestData{'backslash',             r'a\.b',             r'a.b',                                true}
    ReTestData{'multiple matches',      r'a.b',              r'axbaxbaxb',                          true}
  ]
  for test in test_data {
    regex := compile(test.expr) ?
		println("testing $test.name | ${regex.contains_in(test.text)}")
    assert regex.contains_in(test.text) == test.exp_match, test.name
  }
}

// ========================= find all ============================
struct Test_find_all {
	src     string
	q       string
	res     []int    // [0,4,5,6...]
	res_str []string // ['find0','find1'...]
}
const (
find_all_test_suite = [
	Test_find_all{
		"abcd 1234 efgh 1234 ghkl1234 ab34546df",
		r"\d+",
		[5, 9, 15, 19, 24, 28, 31, 36],
		['1234', '1234', '1234', '34546']
	},
//	Test_find_all{
//		"abcd 1234 efgh 1234 ghkl1234 ab34546df",
//		r"\w+",
//		[0, 4, 10, 14, 20, 24, 29, 31, 36, 38],
//		['abcd', 'efgh', 'ghkl', 'ab', 'df']
//	},
//	Test_find_all{
//		"oggi pippo è andato a casa di pluto ed ha trovato pippo",
//		r"p[iplut]+o",
//		[5, 10, 31, 36, 51, 56],
//		['pippo', 'pluto', 'pippo']
//	},
//	Test_find_all{
//		"oggi pibao è andato a casa di pbababao ed ha trovato pibabababao",
//		r"(pi?(ba)+o)",
//		[5, 10, 31, 39, 54, 65],
//		['pibao', 'pbababao', 'pibabababao']
//	},
//	Test_find_all{
//		"Today is a good day and tomorrow will be for sure.",
//		r"[Tt]o\w+",
//		[0, 5, 24, 32],
//		['Today', 'tomorrow']
//	},
//	Test_find_all{
//		"pera\nurl = https://github.com/dario/pig.html\npippo",
//		r"url *= *https?://[\w./]+",
//		[5, 44],
//		['url = https://github.com/dario/pig.html']
//	},
//	Test_find_all{
//		"pera\nurl = https://github.com/dario/pig.html\npippo",
//		r"url *= *https?://.*"+'\n',
//		[5, 45],
//		['url = https://github.com/dario/pig.html\n']
//	},
//	Test_find_all{
//		"#.#......##.#..#..##........##....###...##...######.......#.....#..#......#...#........###.#..#.",
//		r"#[.#]{4}##[.#]{4}##[.#]{4}###",
//		[29, 49],
//		['#....###...##...####']
//	},
//	Test_find_all{
//		"#.#......##.#..#..##........##....###...##...######.......#.....#..#......#...#........###.#..#.",
//		r".*#[.#]{4}##[.#]{4}##[.#]{4}###",
//		[0, 49],
//		['#.#......##.#..#..##........##....###...##...####']
//	},
//	Test_find_all{
//		"1234 Aa dddd Aaf 12334 Aa opopo Aaf",
//		r"Aa.+Aaf",
//		[5, 16, 23, 35],
//		['Aa dddd Aaf', 'Aa opopo Aaf']
//	},
//	Test_find_all{
//		"@for something @endfor @for something else @endfor altro testo @for body @endfor uno due @for senza dire più @endfor pippo",
//		r"@for.+@endfor",
//		[0, 22, 23, 50, 63, 80, 89, 117],
//		['@for something @endfor', '@for something else @endfor', '@for body @endfor', '@for senza dire più @endfor']
//	},
//	Test_find_all{
//		"+++pippo+++\n elvo +++ pippo2 +++ +++ oggi+++",
//		r"\+{3}.*\+{3}",
//		[0, 11, 18, 32, 33, 44],
//		['+++pippo+++', '+++ pippo2 +++', '+++ oggi+++']
//	}
]
)

fn test_find_all() {
	for test in find_all_test_suite {
		expr := compile(test.q) or {
			eprintln('err: $err')
			assert false
			continue
		}
		res := expr.match_all(test.src)
		assert res.matches.len * 2 == test.res.len, '$test.q'
	}
}

