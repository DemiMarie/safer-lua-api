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
#define CHECK(x)                                                               \
   if (NULL == (x)) {                                                          \
      return NULL;                                                             \
   } else                                                                      \
   ((void)0)
#if !defined __cplusplus || __cplusplus < 201103L
#define nullptr((void *) 0)
#endif
#ifdef __cplusplus
extern "C" {
#endif
#if 0
}
#endif
/**
 * @brief Serves as a call gate.
 *
 * luaS_call_gate serves as a call gate.  Behavior is
 * undefined unless called by Lua, either as a C function or via
 * lua_pcall/lua_call, etc.  It calls its first upvalue as a
 * @p lua_CFunction with the current Lua stack, and inspects the
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
 * @param L The @p lua_State
 * @return @p result if result is non-negative, otherwise never
 * returns.
 */
static int luaS_call_gate(lua_State *L) {
   luaS_SafeCFunction *func = lua_touserdata(L, lua_upvalueindex(1));
   luaL_checkstack(L, func->max_stack_slots, "Cannot grow stack to");

   // Check types of incoming arguments
   for (size_t i = 1; i < func->num_types; ++i) {
      if (LUA_TNONE == func->types[i]) {
         continue;
      }
      luaL_checktype(L, i, func->types[i]);
   }
   int result = func->func(L);
   if (result >= 0) {
      return result;
   } else if (-1 == result) { /* Error occurred */
      return lua_error(L);
   } else { /* Yield to Lua */
      return lua_yield(L, -2 - result);
   }
}

/**
 * @brief luaS__registerclosure registers the luaS_call_gate function.
 * @param L the Lua state.
 * @return 1
 * This function converts the first element of the stack to a lightuserdata,
 * which it treats as a lua_CFunction.  It then pops this lightuserdata and
 * calls `lua_pushcclosure(L, &luaS_call_gate, count);`, where
 * @p count is the size of the stack this function was passed.
 */
static int luaS__registerclosure(lua_State *L) {
   int count = lua_gettop(L) - 1;
   lua_pop(L, 1);
   lua_pushcclosure(L, &luaS_call_gate, count);
   return 1;
}

/// Registers the @code{luaS__registerclosure} function
static int luaS__registerclosure_(lua_State *L) {
   lua_checkstack(L, LUA_MINSTACK + 3);
   lua_CFunction func = lua_touserdata(L, -1);
   lua_pop(L, 1);
   lua_pushcfunction(L, func);
   lua_pushlightuserdata(L, &luaS__registerclosure);
   lua_rawset(L, LUA_REGISTRYINDEX);
}

int luaS_pushcclosure(lua_State *L, lua_CFunction func, lua_CFunction finalizer,
                      uint8_t n) {
   assert(n > 0);
   assert(lua_gettop(L) >= n);
   assert(lua_checkstack(L, 3));
   lua_pushlightuserdata(L, &luaS__registerclosure);
   lua_rawget(L, LUA_REGISTRYINDEX);
   lua_insert(L, -n); // Ensure that there are n values above this lua_CFunction
   lua_pushlightuserdata(L, func);
   return lua_pcall(L, n, 1, 0);
}

typedef struct {
   lua_CFunction func;
   void *ud;
   ssize_t num_types;
   int max_stack_slots;
   char const *name;
   unsigned char *types;
   bool success;
} luaS_SafeCFunction_;

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
   bool enough_stack = lua_checkstack(L, 1);
   assert(enough_stack);
   lua_cpcall(L, &luaS_pushSafeCFunction_, &val);
   return val.success;
}

lua_State *luaS_newstate(void) {
   lua_State *L = luaL_newstate();
   if (nullptr == L) {
      return nullptr;
   }
#ifdef LUAJIT_VERSION
   assert((uint64_t)&luaS__registerclosure <= 1ULL << 47);
#endif
#if LUA_VERSION_NUM <= 501 || defined LUAJIT_VERSION
   int errorcode =
       lua_cpcall(L, &luaS__registerclosure_, &luaS__registerclosure);
#else
   lua_pushcfunction(L, &luaS__registerclosure_);
   lua_pushlightuserdata(L, &luaS__registerclosure);
   int errorcode = lua_pcall(L, 1, 0, 0);
#endif
   switch (errorcode) {
   case 0:
      return L;
   case LUA_ERRMEM: /* Out of memory */
      lua_close(L);
      return NULL;
   default:
      assert(0 && "Lua returned invalid error code");
   }
}
#if 0
{
#endif
#ifdef __cplusplus
}
#endif
