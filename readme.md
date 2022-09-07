## re - the regex library for v

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

### Usage and examples

