### Motivation for this regex library

#### Immutability
One of the primary advantages of V is it makes variables immutable by default.
Immutablity is a great principle to follow in general. See [this](https://justamonad.com/advantages-of-immutable-objects/)
A compiled regex expression has a 1-1 mapping with its raw representation, and hence can be made immutable.
This enables us to re-use a compiled regex object to match various strings and patterns without having to
declare and pass mutable variables everywhere, thereby buying us all the advantages of immutability along with
simplified usages

#### Simplified APIs
V is inspired by golang. And golang has an elegant (albeit slightly inefficient) api for its regex. This implementation
borrows heavily from that design and makes usage of regex really simple to use for the end user. See the below snippet
for comparison.

**built in implementation**
```v
 // find matching strings
 import regex

 text := r'cpaz cpapaz cpapapaz'
 query := r'(c(pa)+z ?)+'
 mut re := regex.regex_opt(query) ?
 start, end := re.match_string(text)

 matching_text := text[start..end]
 println(matching_text)
```

**re implementation**
```v
 // find matching strings
 import re

 text := r'cpaz cpapaz cpapapaz'
 query := r'(c(pa)+z ?)+'
 r := re.compile(query) ? //notice no mut variable
 println(r.find_all(text))
```


