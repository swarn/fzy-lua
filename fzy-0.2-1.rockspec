package = "fzy"
version = "0.2-1"
source = {
  url = "git://github.com/swarn/fzy-lua",
  tag = "v0.2"
}
description = {
  summary = "A fuzzy string-matching algorithm",
  detailed = [[
    fzy tries to find the result the user wants by favoring consecutive
    matches, and matches at the beginnings of words.
  ]],
  homepage = "https://github.com/swarn/fzy-lua",
  license = "MIT"
}
dependencies = {
  "lua >= 5.1, < 5.4"
}
build = {
  type = "builtin",
  modules = {
    fzy = "src/fzy.lua",
    fzy_lua = "src/fzy_lua.lua",
    fzy_native = {"src/fzy_native.c", "src/match.c" }
  },

  copy_directories = { "test" }
}

