# fzy-lua

A Lua module for the [fzy][] fuzzy string matching algorithm.

[fzy]: https://github.com/jhawthorn/fzy


## Summary

| function                      | description                                       |
|-------------------------------|---------------------------------------------------|
| `has_match(needle, haystack)` | Check if `needle` is a subsequence of `haystack`. |
| `score(needle, haystack)`     | Compute a matching score.                         |
| `positions(needle, haystack)` | Compute the locations where fzy matches a string. |
| `filter(needle, haystacks)`   | Match many strings at once.                       |


## Functions

### `fzy.has_match(needle, haystack[, case_sensitive])`

Check if `needle` is a subsequence of `haystack.`

``` lua
> fzy.has_match("ab", "acB")
true
> fzy.has_match("ab", "ac")
false
> fzy.has_match("ab", "acB", true)
false
```

**Parameters**
* **needle** (*string*)
* **haystack** (*string*)
* **case_sensitive** (*bool, optional*) – defaults to false

**Returns**
* *bool*


### `fzy.score(needle, haystack[, case_sensitive])`

**Parameters**
* **needle** (*string*): must be a subequence of `haystack`, or the result is
  undefined.
* **haystack** (*string*)
* **case_sensitive** (*bool, optional*) – defaults to false

**Returns**
* *number*, where higher numbers indicate better matches.


### `fzy.positions(needle, haystack[, case_sensitive])`

Determine where each character of the `needle` is matched to the `haystack` in
the optimal match.

``` lua
> p, s = fzy.positions("ab", "*a*b*b")
> require'pl.pretty'.write(p, '')
{2,4}
```

**Parameters**
* **needle** (*string*): must be a subequence of `haystack`, or the result is
  undefined.
* **haystack** (*string*)
* **case_sensitive** (*bool, optional*) – defaults to false

**Returns**
* **indices** (*{int, ...}*), where `indices[n]` is the location of the `n`th
  character of `needle` in `haystack`.
* **score**  (*number*): the same matching score returned by `score`


### `fzy.filter(needle, haystacks[, case_sensitive])`

Apply the `has_match` and `positions` functions to an array of `haystacks`.
For large numbers of haystacks, this will have better performance than
iterating over the `haystacks` and calling those functions for each string.

``` lua
> a = fzy.filter('ab', {'*ab', 'b', 'a*b'})
> require'pl.pretty'.write(a, '')
{{1,{2,3},0.995},{3,{1,3},0.89}}
```

**Parameters**
* **needle** (*string*): unlike the other functions, the `needle` need not be
  a subsequence of any of the strings in the `haystack`.
* **haystack** (*{string, ...}*)
* **case_sensitive** (*bool, optional*) – defaults to false

**Returns**
* *{{idx, positions, score}, ...}*, an array with one entry per matching line
  in `haystacks`, each entry giving the index of the line in `haystacks` as
  well as the equivalent to the return value of `positions` for that line.


## Special Values

`fzy.get_score_min()`: The lowest value returned by `score`, which is only returned
for an empty `needle`, or `haystack` larger than than `get_max_length`.

`fzy.get_score_max()`: The score returned for exact matches. This is the
highest possible score.

`fzy.get_max_length()`: The maximum size for which `fzy` will evaluate scores.

`fzy.get_score_floor()`: For matches that don't return `get_score_min`, their
score will be greater than than this value.

`fzy.get_score_ceiling()`: For matches that don't return `get_score_max`, their
score will be less than this value.

`fzy.get_implementation_name()`: The name of the currently-running
implementation, "lua" or "native".


### Implementations

The lua implementation of fzy is in `fzy_lua`, and the C implementation is in
`fzy_native`. When you `require('fzy')`, it automatically loads the native
version. If that fails, it will fall back on the lua version. This is transparent;
in either case, all functions will be available as `fzy.*`.

