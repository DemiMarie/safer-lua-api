`#include <lua.h>

typedef char *Pchar;
typedef void *Pvoid;

#ifdef __cplusplus
# define CAST(a, b) (static_cast<(a)>(b))
# if __cplusplus >= 201103L
static thread_local void *TLS;
# define HAS_STD_TLS 1
extern "C" {
# elif 0
}
# endif
#else
# define CAST(a, b) ((a)(b))
# if __STDC_VERSION__ >= 201112L
static _Thread_local void *TLS;
# define HAS_STD_TLS 1
# endif
#endif
#if !defined HAS_STD_TLS
# if __GNUC__ >= 4
static __thread void *TLS;
# else
#  error "Don't know how to declare thread-local data with this compiler"
# endif
#endif

#define CONCAT_IDENTS_(a, b) a##b
#define CONCAT_IDENTS(a, b) CONCAT_IDENTS_(a, b)

#define EMIT_WRAPPER(rettype, name, argcount)                           \
   /* Yes this is ugly, but it also makes the generating Lua script     \
    * MUCH simpler.  So this ugly long macro stays.                     \
    *                                                                   \
    * Ideally the C preprocessor would have loops like M4, but          \
    * it doesn't,                                                       \
    */                                                                  \
static struct Struct_##name {                                        \
   MEMBERLIST                                                        \
};                                                                   \
\
rettype safe_##name(int *success, lua_State L, ARGLIST) {            \
   struct Struct_##name local { &CONCAT_IDENTS(inner_,name), \
      ARGUMENTS };          \
   TLS = CAST_VOID(&local);                                          \
   lua_pushlightuserdata(L, &inner##name);                           \
   lua_rawget(L, LUA_REGISTRYINDEX);                                 \
   if (lua_isnil(L, -1)) {                                           \
      int x = lua_cpcall(L, &add_c_function, (void*)&inner_##name);  \
      if (x) {                                                       \
         *success = x;                                               \
         return ((rettype)0);                                        \
      }                                                              \
      lua_pushlightuserdata(L, &inner_##name);                       \
      lua_rawget(L, LUA_REGISTRYINDEX);                              \
   }                                                                 \
   if (0 != (*success = lua_pcall(L, argcount, LUA_MULTRET, 0))) {   \
      return (rettype)0;                                             \
   }                                                                 \
   return (rettype)TLS;                                              \
}                                                                    \
\
static int trampoline_##name(lua_State L) {                          \
   struct Struct_##name *args = (struct Struct_##name *)TLS;         \
   rettype retval = name(args->CALLLIST);                            \
   int number_return_values = COMPUTE_NUMBER_RETURN_VALUES;          \
   TLS = retval;                                                     \
}
