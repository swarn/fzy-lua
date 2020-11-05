#include <stdbool.h>
#include <string.h>

#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>

#include "bonus.h"
#include "match.h"


static int native_has_match(lua_State * L)
{
    char const * needle = luaL_checkstring(L, 1);
    char const * haystack = luaL_checkstring(L, 2);
    bool case_sensitive = false;
    if (lua_gettop(L) > 2 && lua_isboolean(L, 3))
        case_sensitive = lua_toboolean(L, 3);

    lua_pushnumber(L, has_match(needle, haystack, case_sensitive));
    return 1;
}

static int score(lua_State * L)
{
    char const * needle = luaL_checkstring(L, 1);
    char const * haystack = luaL_checkstring(L, 2);
    bool case_sensitive = false;
    if (lua_gettop(L) > 2 && lua_isboolean(L, 3))
        case_sensitive = lua_toboolean(L, 3);

    lua_pushnumber(L, match(needle, haystack, case_sensitive));

    return 1;
}

static int positions(lua_State * L)
{
    char const * needle = luaL_checkstring(L, 1);
    char const * haystack = luaL_checkstring(L, 2);
    bool case_sensitive = false;
    if (lua_gettop(L) > 2 && lua_isboolean(L, 3))
        case_sensitive = lua_toboolean(L, 3);

    index_t result[MATCH_MAX_LEN];
    match_positions(needle, haystack, result, case_sensitive);

    int n = strlen(needle);
    lua_createtable(L, n, 0);
    for (int i = 0; i < n; i++)
    {
        // Convert from 0-indexing to 1-indexing.
        lua_pushinteger(L, result[i] + 1);
        lua_rawseti(L, -2, i + 1);
    }

    return 1;
}

static int score_and_positions(lua_State * L)
{
    char const * needle = luaL_checkstring(L, 1);
    char const * haystack = luaL_checkstring(L, 2);
    bool case_sensitive = false;
    if (lua_gettop(L) > 2 && lua_isboolean(L, 3))
        case_sensitive = lua_toboolean(L, 3);

    index_t result[MATCH_MAX_LEN];
    score_t score = match_positions(needle, haystack, result, case_sensitive);
    lua_pushnumber(L, score);

    int n = strlen(needle);
    lua_createtable(L, n, 0);
    for (int i = 0; i < n; i++)
    {
        // Convert from 0-indexing to 1-indexing.
        lua_pushnumber(L, result[i] + 1);
        lua_rawseti(L, -2, i + 1);
    }

    return 2;
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
    lua_pushcfunction(L, score_and_positions);
    lua_setfield(L, -2, "score_and_positions");
    lua_pushcfunction(L, get_score_min);
    lua_setfield(L, -2, "get_score_min");
    lua_pushcfunction(L, get_score_max);
    lua_setfield(L, -2, "get_score_max");
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
