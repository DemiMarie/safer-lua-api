#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#if 0
}
#endif

#define STRUCT_STATIC static

#define CAST(a, b) (static_cast<(a)>(b))

#if __cplusplus >= 201103L
thread_local static void *TLS;
#define HAS_STD_TLS 1
#endif

#else
#include <stdbool.h>
#define STRUCT_STATIC
#define CAST(a, b) ((a)(b))

#if __STDC_VERSION__ >= 201112L
_Thread_local static void *TLS;
#define HAS_STD_TLS 1
#endif

#endif

#if !defined HAS_STD_TLS
#if __GNUC__ >= 4
static __thread void *TLS;
#else
#error "Don't know how to declare thread-local data with this compiler"
#endif
#else
#undef HAS_STD_TLS
#endif

static int add_c_function(lua_State *L) {
   lua_CFunction f = CAST(lua_CFunction, lua_touserdata(L, -1));
   lua_pushcfunction(L, f);
   lua_settable(L, LUA_REGISTRYINDEX);
   return 0;
}

#define TRAMPOLINE(rettype, name, retcount, ...)                       \
   rettype retval = name(__VA_ARGS__);                                 \
   int number_return_values = (retcount);                              \
   TLS = CAST(void *, CAST(uintptr_t, (retval)));                      \
   return number_return_values;

#define VOID_TRAMPOLINE(_, name, retcount, ...)                        \
   name(__VA_ARGS__);                                                  \
   return (retcount);

static int get_popped(const char *str) {
   bool seen_f = false, seen_L = false;
   while (true) {
      switch (*str) {
      case 'L':
         seen_L = true;
         break;
      case 'f':
         seen_f = true;
         break;
      case '\0':
         return seen_L + seen_f;
      }
      str++;
   }
}

static bool protected_call(lua_State *L, lua_CFunction func, int *success, int argcount) {
   *success = 0;
   void *const lightuserdatum = CAST(void *, func);
   lua_pushlightuserdata(L, lightuserdatum);
   lua_rawget(L, (LUA_REGISTRYINDEX));
   if (lua_isnil(L, -1)) {
      int x = lua_cpcall(L, &add_c_function, lightuserdatum);
      if (x) {
         *success = x;
         return false;
      }
      lua_pushlightuserdata(L, lightuserdatum);
      lua_rawget(L, (LUA_REGISTRYINDEX));
   }
   return (*success = lua_pcall(L, (argcount), (LUA_MULTRET), 0)) == 0;
}

#define EMIT_WRAPPER(rettype, name, argcount) \
   (protected_call(L, &(trampoline_##name), success, argcount))
#if 0
{
#elif defined __cplusplus
}
#endif
