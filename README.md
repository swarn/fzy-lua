# fzy-lua

A lua port of [fzy](https://github.com/jhawthorn/fzy)'s fuzzy matching
algorithm.

## Why

From the original `fzy`:

> fzy is faster and shows better results than other fuzzy finders.

> Most other fuzzy matchers sort based on the length of a match. fzy tries to
> find the result the user intended. It does this by favouring matches on
> consecutive letters and starts of words. This allows matching using acronyms
> or different parts of the path.

## Usage

`score(needle, haystack)`

``` lua
local fzy = require('fzy')

fzy.score("amuser", "app/models/user.rb")     -- 5.595
fzy.score("amuser", "app/models/customer.rb") -- 3.655
```

`positions(needle, haystack)`

``` lua
fzy.positions("amuser", "app/models/user.rb")     -- { 1, 5, 12, 13, 14, 15 }
--                       ^   ^      ^^^^
fzy.positions("amuser", "app/models/customer.rb") -- { 1, 5, 13, 14, 18, 19 }
--                       ^   ^       ^^   ^^
```

`fzy` is case-insensitive by default, which can be disabled:

``` lua
fzy.match("acE", "abcde")              -- true
fzy.match("acE", "abcde", true)        -- false
fzy.positions("ABC", "abcA*B*C")       -- {1, 2, 3}
--                    ^^^
fzy.positions("ABC", "abcA*B*C", true) -- {4, 6, 8}
--                       ^ ^ ^
```

NB: `score` and `positions` must be called with matching needle and haystack,
doing otherwise is undefined. The caller needs to check that there is a match
using the `has_match` function.

If you want the results of both `score` and `positions`, call the
creatively-named `score_and_positions` function to avoid redundant computation.

## Testing

```
busted test/test.lua
```

## Thanks

John Hawthorn wrote the original `fzy`, and this code is *very* similar to
his `fzy.js` implementation.

[Rom Grk](https://github.com/romgrk) made several useful suggestions, and has a
Lua [wrapper](https://github.com/romgrk/fzy-lua-native) of a C implementation
of `fzy` that is _much_ faster than this pure-Lua version.
