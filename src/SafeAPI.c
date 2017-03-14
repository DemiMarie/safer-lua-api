// -*- C -*-
#ifdef NDEBUG
#undef NDEBUG
#endif
#define SAFEAPI_CORE 1
#include "SafeAPI.h"
#include <assert.h>
#include <lua.h>
#include <stdint.h>
#include <string.h>
#ifdef USE_LUAJIT
#include <luajit.h>
#endif
#include <stdbool.h>
#define CHECK(x)         \
   if (NULL == (x)) {    \
      return NULL;       \
   } else                \
   ((void)0)
#if !defined __cplusplus || __cplusplus < 201103L
#define nullptr((void *) 0)
#endif
#ifdef __cplusplus
extern "C" {
using std::intptr_t;
using std::ssize_t;
using std::size_t;
using std::uintptr_t;
#endif
#if 0
}
#endif

THREAD_LOCAL luaS_SafeCFunction *func;

typedef struct {
   lua_CFunction func;
   void *ud;
   ssize_t num_types;
   int max_stack_slots;
   char const *name;
   unsigned char *types;
   bool success;
} luaS_SafeCFunction_;

void *luaS_alloc(lua_State *L, size_t size) {
   void *ud;
   lua_Alloc f = lua_getallocf(L, &ud);
   return f(ud, NULL, 0, size);
}
void luaS_free(lua_State *L, void *ptr, size_t size) {
   void *ud;
   lua_Alloc f = lua_getallocf(L, &ud);
   f(ud, ptr, size, 0);
}


/**
 * @brief luaS_call_gate serves as a call gate.
 * Behavior is undefined unless called by Lua, either as a C function or via
 * lua_pcall/lua_call, etc.  It calls its first upvalue as a
 * `lua_CFunction` with the current Lua stack, and inspects the
 * return value:
 *
 * - If the return value is zero or positive, this
 *   indicates success.  The return value is passed unchanged.
 * - If the return value is -1, the top of the stack is thrown as a
 *   Lua error.
 * - If the return value is a negative number \p x other than -1,
 *   then `(-2) - x` values are popped, and the function yields
 *   this many values to Lua.
 *
 * @param L The \p lua_State.
 * @return A value only useful to Lua.
 */
static int luaS_call_gate(lua_State *L) {
   luaS_SafeCFunction *func =
       (luaS_SafeCFunction *)lua_touserdata(L, lua_upvalueindex(1));
   luaL_checkstack(L, func->max_stack_slots, "Cannot grow stack to");


   /* Check types of incoming arguments */
   for (size_t i = 1; i < func->num_types; ++i) {
      if (LUA_TNONE != func->types[i]) {
         luaL_checktype(L, i, func->types[i]);
      }
   }
   /* Register the needed closure */
   lua_pushlightuserdata(L, &luaS__registerclosure);
   lua_pushcfunction(L, &luaS__registerclosure);
   lua_rawset(L, LUA_REGISTRYINDEX);

   int result = (func->func)(L);
   if (result >= 0) {
      return result;
   } else if (result == INT_MIN) { /* Error occurred */
      return lua_error(L); /* Does not return */
   } else { /* Yield to Lua */
      return lua_yield(L, ~result); /* Note that overflow is not possible */
   }
}

static int luaS_finalize(lua_State *L) {
   luaS_SafeCFunction *p = (luaS_SafeCFunction*)lua_touserdata(L, -1);
   if (NULL == p)
      luaL_error(L, "internal error – luaS_finalize called on non-userdata");
   p->finalizer(p->func, p->ud);
}

/**
 * \brief luaS__registerclosure
 * This function converts the first element of the stack to a lightuserdata,
 * which it treats as a lua_CFunction.  It then pops this lightuserdata and
 * calls `lua_pushcclosure(L, &luaS_call_gate, count)`, where
 * `count` is the size of the stack this function was passed.
 * \param L the Lua state
 * \return 1, unless Lua throws a memory error (in which case this
 * function never returns).
 */
static int luaS__registerclosure(lua_State *L) {
   int count = lua_gettop(L);
   luaS_SafeCFunction *S = (luaS_SafeCFunction *)lua_touserdata(-1);
   lua_pop(1);
   luaS_SafeCFunction_* f = lua_newuserdata(L, sizeof(*S) + f->num_types);
   memset(f, 0xFF, sizeof *f);
   S->func = f->func;
   S->num_types = f->num_types;
   S->ud = f->ud;
   S->finalizer = f->finalizer;
   S->max_stack_slots = f->max_stack_slots;
   S->name = f->name;
   memcpy(S + sizeof(*S), f->types, f->num_types);
   if (f->finalizer) {
      if (luaL_newmetatable(L, "SafeLuaAPI safe C function")) {
         lua_pushcfunction(&luaS_finalize);
         lua_setfield(L, -2, "__gc");
         lua_pushboolean(L, 0);
         lua_setfield(L, -2, "__metatable");
      }
      lua_setmetatable(L, -2);
   }
   lua_insert(L, count);
   lua_pushcclosure(L, &luaS_call_gate, count)
   return 1;
}

/**
 * Registers the `luaS__registerclosure` function */
static int luaS__registerclosure_(lua_State *L) {
   if (defined LUAJIT_VERSION && ((uintptr_t)(&luaS__registerclosure)) >=
        (1ULL << 48)) {
      return luaL_error("Cannot register luaS__registerclosure: "
                        "address too high!");
   }
   lua_pushlightuserdata(L, &luaS__registerclosure);
   lua_pushcfunction(L, &luaS__registerclosure);
   lua_rawset(L, LUA_REGISTRYINDEX);
   return 0;
}

int luaS_pushcclosure(lua_State *L, luaS_SafeCFunction func, uint8_t n) {
   lua_pushlightuserdata(L, &luaS__registerclosure);
   lua_rawget(L, LUA_REGISTRYINDEX);
   return lua_pcall(L, n, LUA_MULTRET, 0);
}

bool luaS_pushSafeCFunction(lua_State *L, lua_CFunction func, void *ud,
                            ssize_t num_types, int max_stack_slots,
                            const char *name, unsigned char *types) {
   luaS_SafeCFunction_ val = {
     .func = func,
     .ud = ud,
     .num_types = num_types,
     .max_stack_slots = max_stack_slots,
     .name = name,
     .types = types,
     false,
   };
   lua_cpcall(L, &luaS_pushSafeCFunction_, &val);
   return val.success;
}


#if 0
{
#endif
#ifdef __cplusplus
}
#endif
