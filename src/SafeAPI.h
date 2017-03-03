/* -*- C -*- */
#include <lua.h>
#include <lauxlib.h>
#include <stdbool.h>

/* C vs C++ checks */
#ifdef __cplusplus
extern "C" {
#elif !defined __STDC_LIMIT_MACROS
# define __STDC_LIMIT_MACROS 1
#elif 0
}
#endif

#include <stdint.h>

/* LuaJIT version checks */
#ifdef USE_LUAJIT
# include <luajit.h>
# if LUA_VERSION_NUM != 501
#  error LuaJIT should have LUA_VERSION_NUM equal to 501
# endif
#endif

/* Windows DLL symbol visibility */
#if defined _WIN32 || defined __CYGWIN__
# ifdef SafeLuaAPI_EXPORTS
#  define LUAS_API extern __declspec(dllexport)
# else
#  define LUAS_API extern __declspec(dllimport)
# endif
#else
# if (defined __GNUC__ && __GNUC__ >= 4) || defined __clang__
#  define LUAS_API extern __attribute__((visibility("default")))
# else
#  define LUAS_API extern
# endif
#endif

#if LUA_VERSION_NUM < 501 || LUA_VERSION_NUM > 503
# error Only Lua 5.1 through 5.3 are supported
#endif

#if LUA_VERSION_NUM >= 502
# define LUAS_HAVE_YIELDK 1
#endif

typedef enum {
   LUAS_TNONE = LUA_TNONE,
   LUAS_TNIL = LUA_TNIL,
   LUAS_TBOOLEAN = LUA_TBOOLEAN,
   LUAS_TLIGHTUSERDATA = LUA_TLIGHTUSERDATA,
   LUAS_TNUMBER = LUA_TNUMBER,
   LUAS_TSTRING = LUA_TSTRING,
   LUAS_TTABLE = LUA_TTABLE,
   LUAS_TFUNCTION = LUA_TFUNCTION,
   LUAS_TUSERDATA = LUA_TUSERDATA,
} luaS_type;

/**
 * @class luaS_CFunction "SafeAPI.h"
 */
typedef struct {
   lua_CFunction func;          ///< The function
   void *ud;                    ///< Arbitrary callback
   ssize_t num_types;           ///< Number of types, or -1 for no count
   int max_stack_slots;         ///< Max. stack slots used by the function
   char const *name;            ///< Name of the function
   unsigned char types[];       ///< Types of the function
} luaS_SafeCFunction;

/**
 * @typedef luaS_CFuncFinalizer "SafeAPI.h"
 * @brief The type of callbacks for function finalizers
 */
typedef void *luaS_CFuncFinalizer(luaS_SafeCFunction *);

/**
 * @brief luaS_pushSafeCFunction
 * @param L the lua_State
 * @param ud arbitrary @code{void*} passed
 * @param num_types The number of types passed to this function
 * @param max_stack_slots The maximum number of slots on the Lua stack this
 * function will use.
 * @param name The name of the function.
 * @param types An array of chars representing Lua types.
 * @return @code{true} on success, @code{false} on out-of-memory.
 */
LUAS_API bool luaS_pushSafeCFunction(lua_State *L, lua_CFunction func,
      void *ud,
      ssize_t num_types,
      int max_stack_slots,
      char const *name,
      unsigned char *types);

/**
 * @brief create a Lua state with associated resources
 * @return the Lua state, or NULL on error
 */
LUAS_API lua_State *luaS_newstate(void);

/**
 * @brief luaS_pushcclosure creates a C closure.  Note that the first upvalue
 * is reserved for the C function that made the call.
 * @param L
 * @param n The number of arguments to put into the closure.  Must be > 0.
 * @return
 */
LUAS_API int luaS_pushcclosure(lua_State *L, lua_CFunction func,
      lua_CFunction finalizer, uint8_t n);
#if 0
{
#elif defined __cplusplus
}
#endif
