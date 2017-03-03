--- SafeLuaAPI.functions, contains the API function descriptions.
--
-- @author Demi Marie Obenour
-- @copyright 2016
-- @license MIT/X11
-- @module functions
local functions = {}

local assert, pairs, type, setmetatable, error = assert, pairs, type, setmetatable, error
local format = string.format
local pretty = pcall(require, 'pl/pretty')
if module then
   module 'functions'
end
local _ENV = nil
local function single_push(x)
   return { prototype = x, pushed = 1 }
end
local function proto(x)
   return { prototype = x }
end

--- The functions needing wrappers in the main library
functions.api_functions_needing_wrappers = {
   -- lua_call is omitted (use lua_pcall instead)
   -- lua_call = { args = {'lua_State *L', 'int', 'int'}, retval = 'int'},
   {
      prototype = 'int safe_lua_checkstack_impl(lua_State *L, int n)',
      name = 'safe_lua_checkstack',
   },

   {
      prototype = 'void lua_concat(lua_State *L, int n)',
      popped = 'n',
      pushed = 1
   },

   single_push 'void lua_createtable(lua_State *L, int array_size, int hash_size)',

   {
      prototype = 'int lua_dump(lua_State *L, lua_Writer writer, void* data)',
      stack_in = 1,
   },

   {
      prototype = 'int lua_equal(lua_State *L, int index1, int index2)',
      stack_in = {'index1', 'index2'},
   },

   -- lua_error = {
   --    args = {'lua_State *L', },
   --    stack_in = {},
   --    popped = 1,
   -- },

   proto 'int lua_gc(lua_State *L, int what, int data)',

   {
      prototype = 'void lua_getfield(lua_State *L, int index, const char* key)',
      stack_in = 'index',
      pushed = 1,
   },

   {
      prototype = 'void lua_getglobal(lua_State *L, const char *name)',
      pushed = 1,
   },

   {
      prototype = 'void lua_gettable(lua_State *L, int depth)',
      stack_in = 'depth',
      popped = 1,
      pushed = 1,
   },

   {
      prototype = 'int lua_lessthan(lua_State *L, int index1, int index2)',
      stack_in = {'index1', 'index2'},
   },

   {
      prototype = 'void lua_newtable(lua_State *L)',
      pushed = 1,
   },

   {
      prototype = 'lua_State *lua_newthread(lua_State *L)',
      pushed = 1,
   },

   {
      prototype = 'void *lua_newuserdata(lua_State *L, size_t size)',
      pushed = 1,
   },

   {
      prototype = 'int lua_next(lua_State *L, int table_index)',
      stack_in = 'table_index',
      popped = 1,
      pushed = '(2 * (0 != retval))',
   },

   {
      prototype = 'void lua_pushcclosure(lua_State *L,\
      lua_CFunction function, int num_upvalues)',
      popped = 'num_upvalues',
      pushed = 1,
   },

   {
      prototype = 'void lua_pushcfunction(lua_State *L, lua_CFunction function)',
      pushed = 1,
   },

   {
      prototype = [[
void lua_pushlstring(lua_State *L, const char *string, size_t len)]],
      pushed = 1,
   },

   {
      prototype = 'void lua_pushstring(lua_State *L, const char *string)',
      pushed = 1,
   },

   -- TODO: handle va_list correctly
   --
   -- lua_pushvfstring = {
   --    args = {'lua_State *L', 'const char *fmt', 'va_list argp'},
   --    retval = 'const char *',
   --    stack_in = {},
   --    pushed = 1,
   -- },

   {
      prototype = 'void lua_rawset(lua_State *L, int index)',
      stack_in = 'index',
      popped = 2,
   },

   {
      prototype = 'void lua_rawseti(lua_State *L, int index, int n)',
      stack_in = 'index',
      popped = 1,
   },

   {
      prototype = 'void lua_register(lua_State *L, const char *name, lua_CFunction function)',
   },

   {
      prototype = 'void lua_setfield(lua_State *L, int index, const char *key)',
      stack_in = 'index',
      popped = 1,
   },

   {
      prototype = 'void lua_setglobal(lua_State *L, char *key)',
      popped = 1,
   },

   {
      prototype = 'void lua_settable(lua_State *L, int index)',
      stack_in = 'index',
   },

   {
      prototype = 'const char *lua_tolstring(lua_State *L, int index, size_t *length)',
      stack_in = 'index',
   },

   {
      prototype = 'const char *lua_tostring(lua_State *L, int index)',
      stack_in = 'index',
   },

   --- The debug interface
   {
      prototype = 'int lua_getinfo(lua_State *L, const char *what, lua_Debug *activation_record)',
      pushed = "(args->what[0] == '<' ? 1 : 0)",
      popped = '(get_popped(what))',
   },
}

--- The functions needing wrappers in the auxillary library.
functions.auxlib_functions_needing_wrappers = {
   -- The auxillary library
   -- The buffer related functions are omitted.  It is assumed that any
   -- higher level language will have its own buffer facilities, and their use
   -- of the Lua stack is completely incompatible with this wrapper's.

   -- Most of the argument checking functions are also omitted.  It is assumed
   -- that clients will use the provided trampoline to throw errors.
   {
      prototype = 'void luaL_argcheck(lua_State *L, int cond, int narg, const char *extramsg)',
   },

   {
      prototype = 'int luaL_argerror (lua_State *L, int narg, const char *extramsg)',
   },

   {
      prototype = 'int luaL_callmeta (lua_State *L, int obj, const char *e)',
      stack_in = {'obj'},
      pushed = '(retval != 0)',
   },

   {
      prototype = 'int luaL_getmetafield (lua_State *L, int obj, const char *e)',
      stack_in = {'obj'},
      pushed = '(retval != 0)',
   },

   -- luaL_gsub is omitted because it assumes NUL-terminated strings
   -- luaL_openlibs = { args = {'lua_State *L', }},
   -- luaL_newmetatable = { args = {'lua_State *L', 'char*'}, retval = 'int'},
   -- luaL_ref = { args = {'lua_State *L', 'int'}, retval = 'int'},
   -- luaL_loadfile = { args = {'lua_State *L', 'int', 'char*'}, retval = 'int'},
   -- luaL_loadstring = { args = {'lua_State *L', 'int', 'char*'}, retval = 'int'},
   -- luaL_where = { args = {'lua_State *L',  'int' }}, ]]
}

local function fixup_fields(functions)

   local mymetatable = {}
   function mymetatable:__index(index)
      error(format('Attempt to access non-existent field %q', index), 2)
   end
   function mymetatable:__newindex(index)
      error(format('Attempt to create non-existent field %q', index), 2)
   end
   for _, i in pairs(functions) do
      for _, j in pairs(i) do
         local stack_in = j.stack_in
         if stack_in == nil then
            j.stack_in = {}
         elseif type(stack_in) ~= 'table' then
            j.stack_in = {stack_in}
         end
         if j.pushed == nil then
            j.pushed = 0
         end
         if j.name == nil then
            j.name = false
         end
         if j.popped == nil then
            j.popped = 0
         end
         setmetatable(j, mymetatable)
      end
   end
   return functions
end
fixup_fields(functions)

return functions
   --
   -- {
   --    prototype = 'void luaL_addchar (luaL_Buffer *B, char c)'
   --    retval = 'void',
   --    stack_in = {},
   --    pushed = 0,
   --    popped = 0,
   -- },

   -- { 
   --    prototype = 'void luaL_addlstring (luaL_Buffer *B, const char *s, size_t l)', 
   --    stack_in = {},
   --    pushed = 0,
   --    popped = 0,
   -- },

   -- {
   --    prototype = 'void luaL_addsize (luaL_Buffer *B, size_t n)',
   --    stack_in = {},
   --    pushed = 0,
   --    popped = 0,
   -- },

   -- {
   --    prototype = 'void luaL_addstring (luaL_Buffer *B, const char *s)';
   --    stack_in = {},
   --    pushed = 0,
   --    popped = 0,
   -- },
   --
   -- {
   --    prototype = 'void luaL_addvalue (luaL_Buffer *B)'
   --    stack_in = {},
   --    pushed = 0,
   --    popped = 1,
   -- },
   --
   -- {
   --    prototype = 'void luaL_buffinit (lua_State *L, luaL_Buffer *B)'
   --    stack_in = {},

 
