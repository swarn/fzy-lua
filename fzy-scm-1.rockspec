package = "fzy"
version = "scm-1"
source = {
  url = "git://github.com/swarn/fzy-lua",
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
  "lua >= 5.1"
}
build = {
  type = "builtin",
  modules = {
    fzy = "src/fzy.lua",
    fzy_lua = "src/fzy_lua.lua",
    fzy_native = {
      sources = { "src/fzy_native.c", "src/match.c" },
      defines = { "LUA_COMPAT_5_1" }
    }
  },

  copy_directories = { "test" }
}

