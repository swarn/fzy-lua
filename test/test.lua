-- luacheck: std max+busted

-- test.lua
-- A test framework for fzy-lua
--
-- Seth Warn, https://github.com/swarn
-- Partially based on John Hawthorn's fzy testing.


local say = require('say')

-- tolerance for floating-point equivalence
local e = 0.000001

local fzy = require('fzy')
local score = fzy.score
local has_match = fzy.has_match
local positions = fzy.positions
local filter = fzy.filter

-- Be a little tricky here: if both the native and lua implementations are
-- availble, always run both and check against each other.
if fzy.get_implementation_name() == "native" then
  local fzy_lua = require('fzy_lua')

  local imp_err = "Native and lua versions of fzy do not match!"

  has_match = function(needle, haystack, case_sensitive)
    local native_result = fzy.has_match(needle, haystack, case_sensitive)
    local lua_result = fzy_lua.has_match(needle, haystack, case_sensitive)
    assert.equal(native_result, lua_result, imp_err)
    return native_result
  end

  score = function(needle, haystack, case_sensitive)
    local native_result = fzy.score(needle, haystack, case_sensitive)
    local lua_result = fzy_lua.score(needle, haystack, case_sensitive)
    assert.near(native_result, lua_result, e, imp_err)
    return native_result
  end

  positions = function(needle, haystack, case_sensitive)
    local np, ns = fzy.positions(needle, haystack, case_sensitive)
    local lp, ls = fzy_lua.positions(needle, haystack, case_sensitive)
    assert.near(ns, ls, e, imp_err)
    assert.same(np, lp, imp_err)
    return np, ns
  end

  filter = function(needle, haystack, case_sensitive)
    local nr = fzy.filter(needle, haystack, case_sensitive)
    local lr = fzy_lua.filter(needle, haystack, case_sensitive)
    assert.same(nr, lr, imp_err)
    return nr
  end
else
  print("\nNative version not loaded or tested!\n")
end

local SCORE_MIN = fzy.get_score_min()
local SCORE_MAX = fzy.get_score_max()
local MATCH_MAX_LENGTH = fzy.get_max_length()

-- A fun little fluent interface for assertions
local function query(state, args, _)
  assert(args.n > 0, "No query provided to the query-modifier")
  assert(rawget(state, "query") == nil, "Query already set")
  rawset(state, "query", args[1])
end

local function closerTo(state, args, _)
  assert(args.n > 0, "No sample provided to the closerTo-modifier")
  assert(rawget(state, "closer") == nil, "Closer value already set")
  rawset(state, "closer", args[1])
end

local function thanTo(state, args, _)
  assert(args.n > 0, "No sample provided to the thanTo-modifier")
  local queryStr = rawget(state, "query")
  local betterStr = rawget(state, "closer")
  local worseStr = args[1]

  args[1] = queryStr
  args[2] = betterStr
  args[3] = worseStr
  return score(queryStr, betterStr) > score(queryStr, worseStr)
end

say:set("assertion.thanTo.positive",
  [[Expected %s to be closer to "%s" than to "%s", but it wasn't.]])
say:set("assertion.thanTo.negative",
  [[Expected %s to be farther from "%s" than from "%s", but it wasn't.]])

assert:register("assertion", "thanTo", thanTo, "assertion.thanTo.positive",
                "assertion.thanTo.negative")
assert:register("modifier", "query", query)
assert:register("modifier", "closerTo", closerTo)

describe("matching", function()
  it("exact matches", function()
    assert.True(has_match("a", "a"))
    assert.True(has_match("a", "a", true))
    assert.True(has_match("A", "A", true))
    assert.True(has_match("a.bb", "a.bb"))
  end)
  it("handles special characters", function()
    assert.True(has_match("\\", "\\"))
    assert.True(has_match("/", "/"))
    assert.True(has_match("[", "["))
    assert.True(has_match("%", "%"))
  end)
  it("ignores case by default", function()
    assert.True(has_match("AbB", "abb"))
    assert.True(has_match("abb", "ABB"))
  end)
  it("is case-sensitive when requested", function()
    assert.False(has_match("AbB", "abb", true))
    assert.False(has_match("abb", "ABB", true))
  end)
  it("partial matches", function()
    assert.True(has_match("a", "ab"))
    assert.True(has_match("a", "ba"))
    assert.True(has_match("aba", "baabbaab"))
  end)
  it("with delimiters between", function()
    assert.True(has_match("abc", "a|b|c"))
  end)
  it("with empty query", function()
    assert.True(has_match("", ""))
    assert.True(has_match("", "a"))
  end)
  it("rejects non-matches", function()
    assert.False(has_match("a", ""))
    assert.False(has_match("a", "b"))
    assert.False(has_match("aa", "a"))
    assert.False(has_match("ba", "a"))
    assert.False(has_match("ab", "a"))
  end)
end)

describe("scoring", function()
  it("prefers beginnings of words", function()
    assert.query("amor").closerTo("app/models/order").thanTo("app/models/zrder")
    assert.query("amor").closerTo("app models order").thanTo("app models zrder")
    assert.query("amor").closerTo("appModelsOrder").thanTo("appModelsZrder")
    assert.query("amor").closerTo("app\\models\\order").thanTo("app\\models\\zrder")
    assert.query("a").closerTo(".a").thanTo("ba")
  end)
  it("prefers consecutive letters", function()
    assert.query("amo").closerTo("app/models/foo").thanTo("app/m/foo")
    assert.query("amo").closerTo("app/models/foo").thanTo("app/m/o")
    assert.query("erf").closerTo("perfect").thanTo("terrific")
    assert.query("abc").closerTo("*ab**c*").thanTo("*a*b*c*")
  end)
  it("prefers contiguous over letter following period", function()
    assert.query("gemfil").closerTo("Gemfile").thanTo("Gemfile.lock")
  end)
  it("prefers shorter matches", function()
    assert.query("abce").closerTo("abcdef").thanTo("abc de")
    assert.query("abc").closerTo("    a b c ").thanTo(" a  b  c ")
    assert.query("abc").closerTo(" a b c    ").thanTo(" a  b  c ")
    assert.query("aa").closerTo("*a*a*").thanTo("*a**a")
  end)
  it("prefers shorter candidates", function()
    assert.query("test").closerTo("tests").thanTo("testing")
  end)
  it("prefers matches at the beginning", function()
    assert.query("ab").closerTo("abbb").thanTo("babb")
    assert.query("test").closerTo("testing").thanTo("/testing")
  end)
  it("returns the max score for exact matches", function()
    assert.are.same(score("abc", "abc"), SCORE_MAX)
    assert.are.same(score("aBc", "abC"), SCORE_MAX)
  end)
  it("returns the min score for empty queries", function()
    assert.are.same(score("", ""), SCORE_MIN)
    assert.are.same(score("", "a"), SCORE_MIN)
    assert.are.same(score("", "bb"), SCORE_MIN)
  end)
  it("rewards matching slashes correctly", function()
    assert.query("a").closerTo("*/a").thanTo("**a")
    assert.query("a").closerTo("*\\a").thanTo("**a")
    assert.query("a").closerTo("**/a").thanTo("*a")
    assert.query("a").closerTo("**\\a").thanTo("*a")
    assert.query("aa").closerTo("a/aa").thanTo("a/a")
  end)
  it("rewards matching camelCase correctly", function()
    assert.query("a").closerTo("bA").thanTo("ba")
    assert.query("a").closerTo("baA").thanTo("ba")
  end)
  it("scores in the prescribed bounds", function()
    local aaa = string.rep("a", MATCH_MAX_LENGTH)
    local aa = string.rep("a", MATCH_MAX_LENGTH - 1)
    assert.True(fzy.get_score_ceiling() > score(aa, aaa))
    local aba = "a" .. string.rep("b", MATCH_MAX_LENGTH - 2) .. "a"
    assert.True(fzy.get_score_floor() < score("aa", aba))
  end)
  it("ignores really long strings", function()
    local longstring = string.rep("a", MATCH_MAX_LENGTH + 1)
    assert.equal(SCORE_MIN, score("aa", longstring))
    assert.equal(SCORE_MIN, score(longstring, "aa"))
    assert.equal(SCORE_MIN, score(longstring, longstring))
  end)
  it("respects the case-sensitive argument", function()
    assert.near(score("aa", "bbbabab"), score("AA", "aaBABAB", true), e)
    assert.near(score("bab", "bAacb"), score("bAb", "bAaBb", true), e)
  end)
end)

describe("positioning", function()
  it("favors consecutive positions", function()
    assert.same({1, 5, 6}, positions("amo", "app/models/foo"))
  end)
  it("favors word beginnings", function()
    assert.same({1, 5, 12, 13}, positions("amor", "app/models/order"))
    assert.same({3, 4}, positions("aa", "baAa"))
    assert.same({4}, positions("a", "ba.a"))
  end)
  it("works when there are no bonuses", function()
    assert.same({2, 4}, positions("as", "tags"))
    assert.same({3, 8}, positions("as", "examples.txt"))
  end)
  it("favors smaller groupings of positions", function()
    assert.same({3, 5, 7}, positions("abc", "a/a/b/c/c"))
    assert.same({3, 5, 7}, positions("abc", "a\\a\\b\\c\\c"))
    assert.same({4, 6, 8}, positions("abc", "*a*a*b*c*c"))
    assert.same({3, 5}, positions("ab", "caacbbc"))
  end)
  it("handles exact matches", function()
    assert.same({1, 2, 3}, positions("foo", "foo"))
  end)
  it("ignores empty requests", function()
    assert.same({}, positions("", ""))
    assert.same({}, positions("", "foo"))
  end)
  it("ignores really long strings", function()
    local longstring = string.rep("a", MATCH_MAX_LENGTH + 1)
    assert.same(SCORE_MIN, score("aa", longstring))
    assert.same(SCORE_MIN, score(longstring, "aa"))
    assert.same(SCORE_MIN, score(longstring, longstring))
  end)
  it("is case-sensitive when requested", function()
    assert.same({2, 5}, positions("AB", "aAabBb", true))
  end)
  it("returns the same score as `score()`", function()
    local _, s = positions("ab", "aaabbb")
    assert.same(score("ab", "aaabbb"), s)
    _, s = positions("aaa", "aaa")
    assert.same(score("aaa", "aaa"), s)
    _, s = positions("", "aaa")
    assert.same(score("", "aaa"), s)
  end)
end)

describe("filtering", function()
  it("repeats application of has_match and positions", function()

    -- compare the result of `filter` with repeated calls to `positions`
    local function check_filter(needle, haystacks, case)
      local result = filter(needle, haystacks, case)
      local r = 0
      for i, line in ipairs(haystacks) do
        local match = has_match(needle, line, case)
        if match then
          r = r + 1
          assert.equals(i, result[r][1])
          local p, s = positions(needle, line, case)
          assert.same(p, result[r][2])
          assert.near(s, result[r][3], e)
        end
      end
      assert.equals(#result, r)
    end

    check_filter("a", {"a", "A", "aa", "b", ""})
    check_filter("a", {"a", "A", "aa", "b", ""}, true)
    check_filter("", {"a", "A", "aa", "b", ""})
    check_filter("a", {"b"})
    check_filter("a", {})
  end)
end)
