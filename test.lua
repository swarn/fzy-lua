local fzy = require('fzy')

local score = fzy.score
local has_match = fzy.has_match
local positions = fzy.positions

local SCORE_MIN = fzy.SCORE_MIN
local SCORE_MAX = fzy.SCORE_MAX
local SCORE_GAP_LEADING = fzy.SCORE_GAP_LEADING
local SCORE_GAP_TRAILING = fzy.SCORE_GAP_TRAILING
local SCORE_GAP_INNER = fzy.SCORE_GAP_INNER
local SCORE_MATCH_CONSECUTIVE = fzy.SCORE_MATCH_CONSECUTIVE
local SCORE_MATCH_SLASH = fzy.SCORE_MATCH_SLASH
local SCORE_MATCH_WORD = fzy.SCORE_MATCH_WORD
local SCORE_MATCH_CAPITAL = fzy.SCORE_MATCH_CAPITAL
local SCORE_MATCH_DOT = fzy.SCORE_MATCH_DOT
local MATCH_MAX_LENGTH = fzy.MATCH_MAX_LENGTH

-- tolerance for floating-point equivalence
local e = 0.000001


local has_match = fzy.has_match
describe("matching", function()
    it("exact matches", function()
        assert.True(has_match("a", "a"))
        assert.True(has_match("a.bb", "a.bb"))
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
        assert.True(score("amor", "app/models/order") > score("amor", "app/models/zrder"))
    end)
    it("prefers consecutive letters", function()
        assert.True(score("amo", "app/m/foo") < score("amo", "app/models/foo"))
        assert.True(score("erf", "terrific") < score("erf", "perfect"))
    end)
    it("prefers contiguous over letter following period", function()
        assert.True(score("gemfil", "Gemfile.lock") < score("gemfil", "Gemfile"))
    end)
    it("prefers shorter matches", function()
        assert.True(score("abce", "abcdef") > score("abce", "abc de"));
        assert.True(score("abc", "    a b c ") > score("abc", " a  b  c "));
        assert.True(score("abc", " a b c    ") > score("abc", " a  b  c "));
    end)
    it("prefers shorter candidates", function()
        assert.True(score("test", "tests") > score("test", "testing"))
    end)
    it("prefers matches at the beginning", function()
        assert.True(score("ab", "abbb") > score("ab", "babb"))
        assert.True(score("test", "testing") > score("test", "/testing"))
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
    it("penalizes gaps correctly", function()
        assert.near(SCORE_GAP_LEADING, score("a", "*a"), e)
        assert.near(SCORE_GAP_LEADING * 2, score("a", "*ba"), e)
        assert.near(SCORE_GAP_LEADING * 2 + SCORE_GAP_TRAILING, score("a", "**a*"), e)
        assert.near(SCORE_GAP_LEADING * 2 + SCORE_GAP_TRAILING * 2,
            score("a", "**a**"), e)
        assert.near(SCORE_GAP_LEADING * 2 + SCORE_MATCH_CONSECUTIVE +
            SCORE_GAP_TRAILING * 2, score("aa", "**aa**"), e)
        assert.near(SCORE_GAP_LEADING * 2 + SCORE_GAP_INNER +
            SCORE_GAP_TRAILING * 2, score("aa", "**a*a**"), e)
    end)
    it("rewards consecutive matches correctly", function()
        assert.near(score("aa", "*aa"), SCORE_GAP_LEADING + SCORE_MATCH_CONSECUTIVE, e)
        assert.near(score("aaa", "*aaa"), SCORE_GAP_LEADING +
            SCORE_MATCH_CONSECUTIVE * 2, e)
        assert.near(score("aaa", "*a*aa"), SCORE_GAP_LEADING + SCORE_GAP_INNER +
            SCORE_MATCH_CONSECUTIVE, e);
    end)
    it("rewards matching '/' correctly", function()
        assert.near(score("a", "/a"), SCORE_GAP_LEADING + SCORE_MATCH_SLASH, e)
        assert.near(score("a", "*/a"), SCORE_GAP_LEADING * 2 + SCORE_MATCH_SLASH, e)
        assert.near(score("aa", "a/aa"), SCORE_GAP_LEADING * 2 + SCORE_MATCH_SLASH +
            SCORE_MATCH_CONSECUTIVE, e)
    end)
    it("rewards matching camelCase correctly", function()
        assert.near(score("a", "bA"), SCORE_GAP_LEADING + SCORE_MATCH_CAPITAL, e)
        assert.near(score("a", "baA"), SCORE_GAP_LEADING * 2 + SCORE_MATCH_CAPITAL, e)
        assert.near(score("aa", "baAa"), SCORE_GAP_LEADING * 2 + SCORE_MATCH_CAPITAL +
            SCORE_MATCH_CONSECUTIVE, e)
    end)
    it("rewards matching '.' correctly", function()
        assert.near(score("a", ".a"), SCORE_GAP_LEADING + SCORE_MATCH_DOT, e)
        assert.near(score("a", "*a.a"), SCORE_GAP_LEADING * 3 + SCORE_MATCH_DOT, e)
        assert.near(score("a", "*a.a"), SCORE_GAP_LEADING + SCORE_GAP_INNER +
            SCORE_MATCH_DOT, e)
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
end)

