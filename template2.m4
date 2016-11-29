typedef char *Pchar;
typedef void *Pvoid;

#ifdef __cplusplus
extern "C" {
#if 0
}
#endif

#define STRUCT_STATIC static

#define CAST(a, b) (static_cast<(a)>(b))

#if __cplusplus >= 201103L
static thread_local void *TLS;
#define HAS_STD_TLS 1
#endif

#else

#define STRUCT_STATIC
#define CAST(a, b) ((a)(b))

#if __STDC_VERSION__ >= 201112L
static _Thread_local void *TLS;
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

#define TRAMPOLINE(rettype, name, argcount, ...)
   static int trampoline_##name(lua_State *L) {
      struct Struct_##name *args = CAST(struct Struct_##name *, TLS);
      rettype retval = name(__VA_ARGS__);
      int number_return_values = (COMPUTE_NUMBER_RETURN_VALUES);
      TLS = CAST(void *, retval);
      return number_return_values;
   }

#define VOID_TRAMPOLINE(name, argcount, ...)
   static int trampoline_##name(lua_State *L) {
      struct Struct_##name *args = CAST(struct Struct_##name *, TLS);
      name(__VA_ARGS__);
      return (COMPUTE_NUMBER_RETURN_VALUES);
   }

#define EMIT_STRUCT(name) STRUCT_STATIC struct Struct_##name { MEMBERLIST };

m4_define(`VOID_WRAPPER',
   `EMIT_STRUCT(`$1')dnl
   VOID_TRAMPOLINE($@)dnl
   EMIT_WRAPPER(`int', `$1', `argcount')')dnl
dnl
m4_define(`WRAPPER',
   `EMIT_STRUCT(`$2')dnl
   TRAMPOLINE($@)dnl
   EMIT_WRAPPER(`$1', `$2', `$3')')dnl
dnl
m4_define(`EMIT_WRAPPER',
      `ifelse(`$#',`0',`$0',`$#',`2',
         ``$2 safe_$1(int *success, lua_State *L ARGLIST) {
      struct Struct_$1 local = {ARGUMENTS};
      TLS = CAST(void *, &local);
      lua_pushlightuserdata(L, &trampoline_##name);
      lua_rawget(L, (LUA_REGISTRYINDEX));
      if (lua_isnil(L, -1)) {
         int x =
             lua_cpcall(L, &add_c_function, CAST(void *, &trampoline_$1));
         if (x) {
            *success = x;
            return ((rettype)0);
         }
         lua_pushlightuserdata(L, &trampoline_$1);
         lua_rawget(L, (LUA_REGISTRYINDEX));
      }
      if (0 != (*success = lua_pcall(L, ($3), (LUA_MULTRET), 0))) {
         return ($2)0;
      }
      return ($2)TLS;
   }
'')')`
#if 0
{
#elif defined __cplusplus
}
#endif'
