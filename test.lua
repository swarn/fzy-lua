local fzy = require('fzy')
local say = require('say')

local score = fzy.score
local has_match = fzy.has_match
local positions = fzy.positions

local SCORE_MIN = fzy.SCORE_MIN
local SCORE_MAX = fzy.SCORE_MAX
local MATCH_MAX_LENGTH = fzy.MATCH_MAX_LENGTH

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
        assert.True(has_match("a.bb", "a.bb"))
    end)
    it("handles special characters", function()
        assert.True(has_match("\\", "\\"))
        assert.True(has_match("[", "["))
        assert.True(has_match("%", "%"))
    end)
    it("ignores case", function()
        assert.True(has_match("AbB", "abb"))
        assert.True(has_match("abb", "ABB"))
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
    it("rewards matching '/' correctly", function()
        assert.query("a").closerTo("*/a").thanTo("**a")
        assert.query("a").closerTo("**/a").thanTo("*a")
        assert.query("aa").closerTo("a/aa").thanTo("a/a")
    end)
    it("rewards matching camelCase correctly", function()
        assert.query("a").closerTo("bA").thanTo("ba")
        assert.query("a").closerTo("baA").thanTo("ba")
    end)
    it("ignores really long strings", function()
        local longstring = string.rep("a", MATCH_MAX_LENGTH + 1)
        assert.equal(SCORE_MIN, score("aa", longstring))
        assert.equal(SCORE_MIN, score(longstring, "aa"))
        assert.equal(SCORE_MIN, score(longstring, longstring))
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
        assert.same({3, 5}, positions("ab", "caacbbc"))
    end)
    it("handles exact matches", function()
        assert.same({1, 2, 3}, positions("foo", "foo"))
    end)
    it("ignores empty requests", function()
        assert.same({}, positions("", ""))
        assert.same({}, positions("", "foo"))
        assert.same({}, positions("foo", ""))
    end)
    it("ignores really long strings", function()
        local longstring = string.rep("a", MATCH_MAX_LENGTH + 1)
        assert.same(SCORE_MIN, score("aa", longstring))
        assert.same(SCORE_MIN, score(longstring, "aa"))
        assert.same(SCORE_MIN, score(longstring, longstring))
    end)
end)

