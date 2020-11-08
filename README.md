# fzy-lua

[![Actions Status](https://github.com/swarn/fzy-lua/workflows/build/badge.svg)](https://github.com/swarn/fzy-lua/actions)

A Lua port of [fzy](https://github.com/jhawthorn/fzy)'s fuzzy string matching
algorithm. This includes both a pure Lua implementation and a compiled C
implementation with a Lua wrapper.

## Why

From the original `fzy`:

> fzy is faster and shows better results than other fuzzy finders.
>
> Most other fuzzy matchers sort based on the length of a match. fzy tries to
> find the result the user intended. It does this by favouring matches on
> consecutive letters and starts of words. This allows matching using acronyms
> or different parts of the path.

## Install

``` sh
luarocks install fzy
```

Or, just download a copy of `fzy_lua.lua` and drop it in your project.

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

NB: `score` and `positions` must be called with a `needle` that is a
subsequence of the `haystack`, which you can check with the `has_match`
function.

The `positions` function returns two values, the array shown above and the same
score that `score` returns. If you need both values, it's more efficient to use
`positions`.

There are two libraries, `fzy_lua` with the Lua implementation and `fzy_native`
with the C implementation. When you use `require'fzy'`, it attempts to load the
native module; if that fails, it automatically substitutes the Lua
implementation.

## Testing

```sh
busted test/test.lua
```

## Thanks

John Hawthorn wrote the original `fzy`, and this code is *very* similar to
his `fzy.js` implementation.

[Rom Grk](https://github.com/romgrk) made several useful suggestions, and has a
a [lua C implemenation](https://github.com/romgrk/fzy-lua-native) using
the luajit `ffi` library.
