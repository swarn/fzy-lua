# fzy-lua

[![Actions Status](https://github.com/swarn/fzy-lua/workflows/build/badge.svg)](https://github.com/swarn/fzy-lua/actions)

A Lua port of [fzy](https://github.com/jhawthorn/fzy)'s fuzzy string matching
algorithm. This includes both a pure Lua implementation and a compiled C
implementation with a Lua wrapper.


## What does it do?

From the original `fzy`:

> fzy is faster and shows better results than other fuzzy finders.
>
> Most other fuzzy matchers sort based on the length of a match. fzy tries to
> find the result the user intended. It does this by favouring matches on
> consecutive letters and starts of words. This allows matching using acronyms
> or different parts of the path.

Let's give it a try:

``` lua
local fzy = require('fzy')
local haystacks = {'cab', 'ant/bat/cat', 'ant/bat/ace'}
local needle = 'abc'
local result = fzy.filter(needle, haystacks)
```

Here is what `result` looks like:
``` lua
{
  {2, {1, 5,  9}, 2.63},
  {3, {1, 5, 10}, 1.725}
}
```
Which tells us:

- We get a result from `filter` for each match. The string at index 1, `cab`,
  did not match the query, because `abc` is not a subsequence of `cab`.

- The string at index 2 matched with a score of 2.63. It matched characters at
  the following positions:

      ant/bat/cat
      ^   ^   ^
      1   5   9

- The string at index 3 matched with a score of 1.725. It matched characters at
  the following positions:

      ant/bat/ace
      ^   ^    ^
      1   5    10

  This match has a lower score than the previous string because `fzy` tries to
  find what you intended, and one way it does that is by favoring matches at
  the beginning of words.


## Install

``` sh
luarocks install fzy
```

Or, just download a copy of `fzy_lua.lua` and drop it in your project.


## Usage

See [the docs](docs/fzy.md).


## Testing

```sh
busted test/test.lua
```


## Thanks

John Hawthorn wrote the original `fzy`. The native implementation here is
basically his code with a few tweaks, and the lua implementation is derived
from his `fzy.js` implementation.

[Rom Grk](https://github.com/romgrk) made several useful suggestions, and has a
[lua C implemenation](https://github.com/romgrk/fzy-lua-native) using
the luajit `ffi` library.
