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

   // Check types of incoming arguments
   for (size_t i = 1; i < func->num_types; ++i) {
      if (LUA_TNONE != func->types[i]) {
         luaL_checktype(L, i, func->types[i]);
      }
   }
   // Register the needed closure
   lua_pushlightuserdata(L, &luaS__registerclosure);
   lua_pushcfunction(L, &luaS__registerclosure);
   lua_settable(L, LUA_REGISTRYINDEX);

   int result = func->func(L);
   if (result >= 0) {
      return result;
   } else if (result == INT_MIN) { /* Error occurred */
      return lua_error(L); /* Does not return */
   } else { /* Yield to Lua */
      return lua_yield(L, ~result); /* Note that overflow is not possible */
   }
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
static int luaS__registerclosure(lua_State *L, luaS_SafeCFunction *S, int count) {
   int count = lua_gettop(L);
   luaL_checkstack(L, count + 1);
   memcpy(lua_newuserdata(L, sizeof(*S)), S, sizeof(*S));
   lua_insert(L, count + 1);
   lua_pushcclosure(L, &luaS_call_gate, count + 1)
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

// Throw a Lua error containing a userdata holding the safe C function
static int luaS_pushSafeCFunction_(lua_State *L) {
   luaS_SafeCFunction_ *const func =
       (luaS_SafeCFunction_ *)lua_touserdata(L, 1);
   size_t const offset = offsetof(luaS_SafeCFunction, types);
   size_t const size = offset + (func->num_types >= 0 ? func->num_types : 0);
   luaS_SafeCFunction *safefunc = lua_newuserdata(L, size);
   safefunc->func = func->func;
   safefunc->ud = func->ud;
   safefunc->max_stack_slots = func->max_stack_slots;
   safefunc->name = func->name;
   safefunc->num_types = func->num_types;
   memcpy(safefunc + offset, func->types, func->num_types);
   func->success = true;
   lua_error(L);
}

bool luaS_pushSafeCFunction(lua_State *L, lua_CFunction func, void *ud,
                            ssize_t num_types, int max_stack_slots,
                            const char *name, unsigned char *types) {
   luaS_SafeCFunction_ val = {func, ud,    num_types, max_stack_slots,
                              name, types, false};
#ifndef LUAJIT_VERSION
   lua_cpcall(L, &luaS_pushSafeCFunction_, &val);
#else
   lua_cpcall(L, &luaS_pushSafeCFunction_, &val);
#endif
   return val.success;
}


#if 0
{
#endif
#ifdef __cplusplus
}
#endif
