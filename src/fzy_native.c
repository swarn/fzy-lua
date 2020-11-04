#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include "match.h"

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

/* static const struct luaL_Reg fzy_native[] = { */
/*     {"get_score_min", get_score_min}, {"get_score_max", get_score_max}, {NULL, NULL}}; */

int luaopen_fzy_native(lua_State * L)
{
    lua_newtable(L);
    lua_pushcfunction(L, get_score_min);
    lua_setfield(L, -2, "get_score_min");
    /* lua_pushcfunction(L, get_score_max); */
    /* lua_setglobal(L, "get_score_max"); */

    return 1;
}
