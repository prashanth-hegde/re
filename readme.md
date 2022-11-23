## re - the regex library for v

---
**NOTE**

This regex library has been deprecated in favor of v's built-in regex parser.
v's built-in regex offers excellent performance compared to this library. Although in theory, the NFA method
is supposed to be linear time-efficient (and it is), the v's standard regex comes with a lot more optimizations
built-in which reduces array copies etc that make it a lot more efficient.

Having said that, I still wish the ease-of-use would be addressed in V, for which, I am planning to write a wrapper
on top of existing v's regex parser

---

### Description
`re` is an intuitive, easy-to-use, light and fast regex library in and for v

### Features (a.k.a, why should I use `re`)
* Intuitive - the functions and usage is very straightforward and easy to use
* Type safety - `re` is written in a way where multiple threads can be run on the same expression, ensuring type safety
* Fast - expressions are compiled before-hand, and offers linear-time matches for any complex regular expressions

### Motivation
The main motivation to write a new regular expression library is ease-of-use and type-safety.
See [Motivation](./docs/motivation.md) for more details

### Concepts
This regex implementation follows very closely in principle to V stdlib's documentation laid out
(here)[https://modules.vlang.io/regex.html]
with very few exceptions

1. No support for negative groups. The concept of negative groups is counter-intuitive.
By laying out groups according to their occurrence, the user is able to associate each group
with its index number. Negative groups sort of upsets this dynamic by ignoring certain groups.
With `re`, extraction of a group has been made super-simple by providing helper functions as shown in examples
1. All interfaces are immutable. A compiled regex expression should be immutable. This enables us to
use the same compiled regex expressions across multiple threads (or coroutines). For instance, if we need a regex
validation for a web server, we should be able to use the same compiled expression across multiple requests
1. Higher order interfaces. The functions and data structures are defined such that the user will be able to just use
the library without having to write any wrapper code around it. See examples for more details
1. Special operations like matching beginning of string, end of string, and entire string is offered using functions.
This enables the regex parser to be more efficient and less error prone

### Usage and examples

