/* bonus.h
 * precomputed scoring for the fzy algorithm
 *
 * original code by John Hawthorn, https://github.com/jhawthorn/fzy
 * modifications by
 *   Rom Grk, https://github.com/romgrk
 *   Seth Warn, https://github.com/swarn
 */

#ifndef BONUS_H
#define BONUS_H

#include "match.h"


#define SCORE_GAP_LEADING (-0.005)
#define SCORE_GAP_TRAILING (-0.005)
#define SCORE_GAP_INNER (-0.01)
#define SCORE_MATCH_CONSECUTIVE (1.0)
#define SCORE_MATCH_SLASH (0.9)
#define SCORE_MATCH_WORD (0.8)
#define SCORE_MATCH_CAPITAL (0.7)
#define SCORE_MATCH_DOT (0.6)

// clang-format off
#define ASSIGN_LOWER(v) \
    ['a'] = (v), \
    ['b'] = (v), \
    ['c'] = (v), \
    ['d'] = (v), \
    ['e'] = (v), \
    ['f'] = (v), \
    ['g'] = (v), \
    ['h'] = (v), \
    ['i'] = (v), \
    ['j'] = (v), \
    ['k'] = (v), \
    ['l'] = (v), \
    ['m'] = (v), \
    ['n'] = (v), \
    ['o'] = (v), \
    ['p'] = (v), \
    ['q'] = (v), \
    ['r'] = (v), \
    ['s'] = (v), \
    ['t'] = (v), \
    ['u'] = (v), \
    ['v'] = (v), \
    ['w'] = (v), \
    ['x'] = (v), \
    ['y'] = (v), \
    ['z'] = (v)

#define ASSIGN_UPPER(v) \
    ['A'] = (v), \
    ['B'] = (v), \
    ['C'] = (v), \
    ['D'] = (v), \
    ['E'] = (v), \
    ['F'] = (v), \
    ['G'] = (v), \
    ['H'] = (v), \
    ['I'] = (v), \
    ['J'] = (v), \
    ['K'] = (v), \
    ['L'] = (v), \
    ['M'] = (v), \
    ['N'] = (v), \
    ['O'] = (v), \
    ['P'] = (v), \
    ['Q'] = (v), \
    ['R'] = (v), \
    ['S'] = (v), \
    ['T'] = (v), \
    ['U'] = (v), \
    ['V'] = (v), \
    ['W'] = (v), \
    ['X'] = (v), \
    ['Y'] = (v), \
    ['Z'] = (v)

#define ASSIGN_DIGIT(v) \
    ['0'] = (v), \
    ['1'] = (v), \
    ['2'] = (v), \
    ['3'] = (v), \
    ['4'] = (v), \
    ['5'] = (v), \
    ['6'] = (v), \
    ['7'] = (v), \
    ['8'] = (v), \
    ['9'] = (v)

static const score_t bonus_states[3][256] = {
    { 0 },
    {
        ['/'] = SCORE_MATCH_SLASH,
        ['\\'] = SCORE_MATCH_SLASH,
        ['-'] = SCORE_MATCH_WORD,
        ['_'] = SCORE_MATCH_WORD,
        [' '] = SCORE_MATCH_WORD,
        ['.'] = SCORE_MATCH_DOT,
    },
    {
        ['/'] = SCORE_MATCH_SLASH,
        ['\\'] = SCORE_MATCH_SLASH,
        ['-'] = SCORE_MATCH_WORD,
        ['_'] = SCORE_MATCH_WORD,
        [' '] = SCORE_MATCH_WORD,
        ['.'] = SCORE_MATCH_DOT,

        /* ['a' ... 'z'] = SCORE_MATCH_CAPITAL, */
        ASSIGN_LOWER(SCORE_MATCH_CAPITAL)
    }
};

static const index_t bonus_index[256] = {
    /* ['A' ... 'Z'] = 2 */
    ASSIGN_UPPER(2),

    /* ['a' ... 'z'] = 1 */
    ASSIGN_LOWER(1),

    /* ['0' ... '9'] = 1 */
    ASSIGN_DIGIT(1)
};

// clang-format on

#define COMPUTE_BONUS(last_ch, ch)                                                     \
    (bonus_states[bonus_index[(unsigned char)(ch)]][(unsigned char)(last_ch)])

#endif
