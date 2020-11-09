// The lua wrapper to the native C implementation of fzy
//

#include <stdbool.h>
#include <string.h>

#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>

#include "bonus.h"
#include "match.h"

// 5.1 had lua_objlen(). Luajit is based on 5.1, and is used by neovim.
// 5.2 replaced lua_objlen() with lua_rawlen(). 5.4 is the current version.
//
// The two functions are so close that the Lua headers for later versions
// aliased lua_objlen to lua_rawlen if you defined LUA_COMPAT_5_1, so that old
// code would still work. But my CI tests showed this wasn't always true, and
// lua_objlen was still undefined on some platforms.
//
// So, this is my workaround: for Lua 5.1 and luajit, alias the new function
// to the old one.
#if LUA_VERSION_NUM == 501
    #define lua_rawlen(L, i) lua_objlen(L, i)
#endif

static int native_has_match(lua_State * L)
{
    char const * needle = luaL_checkstring(L, 1);
    char const * haystack = luaL_checkstring(L, 2);
    bool case_sensitive = false;
    if (lua_gettop(L) > 2)
        case_sensitive = lua_toboolean(L, 3);

    lua_pushboolean(L, has_match(needle, haystack, case_sensitive));
    return 1;
}

static int score(lua_State * L)
{
    char const * needle = luaL_checkstring(L, 1);
    char const * haystack = luaL_checkstring(L, 2);
    bool case_sensitive = false;
    if (lua_gettop(L) > 2)
        case_sensitive = lua_toboolean(L, 3);

    lua_pushnumber(L, match(needle, haystack, case_sensitive));
    return 1;
}

// Given an array of `count` 0-based indices, push a table on to `L` with
// equivalent 1-based indices.
void push_indices(lua_State * L, index_t const * const indices, size_t count)
{
    lua_createtable(L, count, 0);
    for (int i = 0; i < count; i++)
    {
        // Convert from 0-indexing to 1-indexing.
        lua_pushinteger(L, indices[i] + 1);
        lua_rawseti(L, -2, i + 1);
    }
}

static int positions(lua_State * L)
{
    char const * needle = luaL_checkstring(L, 1);
    char const * haystack = luaL_checkstring(L, 2);
    bool case_sensitive = false;
    if (lua_gettop(L) > 2)
        case_sensitive = lua_toboolean(L, 3);

    index_t result[MATCH_MAX_LEN];
    score_t score = match_positions(needle, haystack, result, case_sensitive);

    push_indices(L, result, strlen(needle));
    lua_pushnumber(L, score);
    return 2;
}

static int filter(lua_State * L)
{
    const char * const needle = luaL_checkstring(L, 1);
    size_t const needle_len = strlen(needle);

    int const haystacks_idx = 2;
    luaL_checktype(L, haystacks_idx, LUA_TTABLE);
    int const haystacks_len = lua_rawlen(L, haystacks_idx);

    bool case_sensitive = false;
    if (lua_gettop(L) > 2)
        case_sensitive = lua_toboolean(L, 3);

    // Push the result array onto the lua stack.
    lua_newtable(L);
    int const result_idx = lua_gettop(L);
    int result_len = 0;

    // Call `positions` on each haystack string.
    for (int i = 1; i <= haystacks_len; i++)
    {
        lua_rawgeti(L, haystacks_idx, i);
        char const * haystack = luaL_checkstring(L, -1);

        if (has_match(needle, haystack, case_sensitive))
        {
            result_len++;

            // Make the {idx, positions, score} table.
            lua_createtable(L, 3, 0);

            // Set the idx
            lua_pushinteger(L, i);
            lua_rawseti(L, -2, 1);

            // Generate the positions and the score
            index_t result[MATCH_MAX_LEN];
            score_t score = match_positions(needle, haystack, result, case_sensitive);

            // Set the positions
            push_indices(L, result, needle_len);
            lua_rawseti(L, -2, 2);

            // Set the score
            lua_pushnumber(L, score);
            lua_rawseti(L, -2, 3);

            // Add this table to the result
            lua_rawseti(L, result_idx, result_len);
        }

        // Pop the current haystack string off the lua stack.
        lua_pop(L, 1);
    }

    return 1;
}

static int get_score_min(lua_State * L)
{
    lua_pushnumber(L, SCORE_MIN);
    return 1;
}

static int get_score_max(lua_State * L)
{
    lua_pushnumber(L, SCORE_MAX);
    return 1;
}

static int get_max_length(lua_State * L)
{
    lua_pushnumber(L, MATCH_MAX_LEN);
    return 1;
}

static int get_score_floor(lua_State * L)
{
    lua_pushnumber(L, MATCH_MAX_LEN * SCORE_GAP_INNER);
    return 1;
}

static int get_score_ceiling(lua_State * L)
{
    lua_pushnumber(L, MATCH_MAX_LEN * SCORE_MATCH_CONSECUTIVE);
    return 1;
}

static int get_implementation_name(lua_State * L)
{
    lua_pushstring(L, "native");
    return 1;
}

int luaopen_fzy_native(lua_State * L)
{
    lua_newtable(L);

    lua_pushcfunction(L, native_has_match);
    lua_setfield(L, -2, "has_match");
    lua_pushcfunction(L, score);
    lua_setfield(L, -2, "score");
    lua_pushcfunction(L, positions);
    lua_setfield(L, -2, "positions");
    lua_pushcfunction(L, filter);
    lua_setfield(L, -2, "filter");
    lua_pushcfunction(L, get_score_min);
    lua_setfield(L, -2, "get_score_min");
    lua_pushcfunction(L, get_score_max);
    lua_setfield(L, -2, "get_score_max");
    lua_pushcfunction(L, get_max_length);
    lua_setfield(L, -2, "get_max_length");
    lua_pushcfunction(L, get_score_floor);
    lua_setfield(L, -2, "get_score_floor");
    lua_pushcfunction(L, get_score_ceiling);
    lua_setfield(L, -2, "get_score_ceiling");
    lua_pushcfunction(L, get_score_max);
    lua_setfield(L, -2, "get_score_max");
    lua_pushcfunction(L, get_implementation_name);
    lua_setfield(L, -2, "get_implementation_name");

    return 1;
}
