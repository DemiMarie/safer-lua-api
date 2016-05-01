--- SafeLuaAPI.functions, contains the API function descriptions.
--
-- @author Demi Marie Obenour
-- @copyright 2016
-- @license MIT/X11
-- @module functions
local functions = {}

local pairs, type, setmetatable, error = pairs, type, setmetatable, error
local format = string.format
local pretty = pcall(require, 'pl/pretty')
if module then
   module 'functions'
end
local _ENV = nil


--- The functions needing wrappers in the main library
functions.api_functions_needing_wrappers = {
   -- lua_call is omitted (use lua_pcall instead)
   -- lua_call = { args = {'lua_State *L', 'int', 'int'}, retval = 'int'},
   ['int lua_checkstack(lua_State *L, int n)'] = {
      stack_in = {},
      popped = 0,
      pushed = 0,
   },

   ['void lua_concat(lua_State *L, int n)'] = {
      stack_in = {},
      popped = 'n',
      pushed = 1
   },

   ['void lua_createtable(lua_State *L, int array_size, int hash_size)'] = {
      stack_in = {},
      popped = 0,
      pushed = 1
   },

   ['int lua_dump(lua_State *L, lua_Writer writer, void* data)'] = {
      stack_in = {},
      popped = 0,
      pushed = 0,
   },

   ['int lua_equal(lua_State *L, int index1, int index2)'] = {
      stack_in = {'index1', 'index2'},
      popped = 0,
      pushed = 0,
   },

   -- lua_error = {
   --    args = {'lua_State *L', },
   --    retval = 'void',
   --    stack_in = {},
   --    popped = 1,
   --    pushed = 0,
   -- },

   ['int lua_gc(lua_State *L, int what, int data)'] = {
      stack_in = {},
      popped = 0,
      pushed = 0,
   },

   ['void lua_getfield(lua_State *L, int index, const char* key)'] = {
      stack_in = {'index'},
      popped = 0,
      pushed = 1,
   },

   ['void lua_getglobal(lua_State *L, const char *name)'] = {
      stack_in = {},
      popped = 0,
      pushed = 1,
   },

   ['void lua_gettable(lua_State *L, int depth)'] = {
      stack_in = 'depth',
      popped = 1,
      pushed = 1,
   },

   ['int lua_lessthan(lua_State *L, int index1, int index2)'] = {
      stack_in = {'index1', 'index2'},
      popped = 0,
      pushed = 0,
   },

   ['void lua_newtable(lua_State *L)'] = {
      stack_in = {},
      popped = 0,
      pushed = 1,
   },

   ['lua_State *lua_newthread(lua_State *L)'] = {
      stack_in = {},
      popped = 0,
      pushed = 1,
   },

   ['void *lua_newuserdata(lua_State *L, size_t size)'] = {
      stack_in = {},
      popped = 0,
      pushed = 1,
   },

   ['int lua_next(lua_State *L, int table_index)'] = {
      stack_in = 'table_index',
      popped = 1,
      pushed = '(2 * (0 != retval))',
   },

   ['void lua_pushcclosure(lua_State *L, lua_CFunction function,\
                       int number_upvalues)'] = {
      stack_in = {},
      popped = 'number_upvalues',
      pushed = 1,
   },

   ['void lua_pushcfunction(lua_State *L, lua_CFunction function)'] = {
      stack_in = {},
      popped = 0,
      pushed = 1,
   },

   ['void lua_pushlstring(lua_State *L, const char *string, size_t len)'] = {
      stack_in = {},
      popped = 0,
      pushed = 1,
   },

   ['void lua_pushstring(lua_State *L, const char *string)'] = {
      stack_in = {},
      popped = 0,
      pushed = 1,
   },

   -- TODO: handle va_list correctly
   --
   -- lua_pushvfstring = {
   --    args = {'lua_State *L', 'const char *fmt', 'va_list argp'},
   --    retval = 'const char *',
   --    stack_in = {},
   --    popped = 0,
   --    pushed = 1,
   -- },

   ['void lua_rawset(lua_State *L, int index)'] = {
      stack_in = 'index',
      popped = 2,
      pushed = 0,
   },

   ['void lua_rawseti(lua_State *L, int index, int n)'] = {
      stack_in = 'index',
      popped = 1,
      pushed = 0,
   },

   ['void lua_register(lua_State *L, const char *name, lua_CFunction function)']
      = {
      stack_in = {},
      popped = 0,
      pushed = 0,
   },

   ['void lua_setfield(lua_State *L, int index, const char *key)'] = {
      stack_in = 'key',
      popped = 1,
      pushed = 0,
   },

   ['void lua_setglobal(lua_State *L, char *key)'] = {
      stack_in = {},
      popped = 1,
      pushed = 0,
   },

   ['void lua_settable(lua_State *L, int index)'] = {
      stack_in = 'index',
      pushed = 0,
      popped = 2,
   },

   ['const char *lua_tolstring(lua_State *L, int index, size_t *length)'] = {
      stack_in = 'index',
      popped = 0,
      pushed = 0,
   },

   ['const char *lua_tostring(lua_State *L, int index)'] = {
      stack_in = 'index',
      popped = 0,
      pushed = 0,
   },

   -- The debug interface
   ['int lua_getinfo(lua_State *L, const char *what,\
                 lua_Debug *activation_record)'] = {
      stack_in = {},
      pushed = "(args->what[0] == '<' ? 1 : 0)",
      popped = '(get_popped(what))',
   },
}

--- The functions needing wrappers in the auxillary library.
functions.auxlib_functions_needing_wrappers = {
   -- The auxillary library
   -- The buffer related functions are omitted.  It is assumed that any
   -- higher level language will have its own buffer facilities.
   --
   -- luaL_addchar = {
   --    args = {'luaL_Buffer *B', 'char c'},
   --    retval = 'void',
   --    stack_in = {},
   --    pushed = 0,
   --    popped = 0,
   -- },

   -- luaL_addlstring = {
   --    args = {'luaL_Buffer *B', 'const char *string', 'size_t size'},
   --    retval = 'void',
   --    stack_in = {},
   --    pushed = 0,
   --    popped = 0,
   -- },

   -- luaL_addsize = {
   --    args = {'luaL_Buffer *B', 'size_t size'},
   --    retval = 'void',
   --    stack_in = {},
   --    pushed = 0,
   --    popped = 0,
   -- },

   -- Most of the argument checking functions are also omitted.  It is assumed
   -- that clients will use the provided trampoline to throw errors.
   luaL_callmeta = {
      args = {'lua_State *L', 'int', 'CPchar'},
      retval = 'int',
   },
   luaL_getmetafield = {
      args = {'lua_State *L', 'int', 'CPchar'},
      retval = 'int',
   },
   luaL_loadbuffer = {
      args = {'lua_State *L', 'CPchar', 'size_t', 'CPchar'},
      retval = 'int',
   },
   luaL_openlibs = { args = {'lua_State *L', }},
   luaL_newmetatable = { args = {'lua_State *L', 'char*'}, retval = 'int'},
   luaL_ref = { args = {'lua_State *L', 'int'}, retval = 'int'},
   luaL_loadfile = { args = {'lua_State *L', 'int', 'char*'}, retval = 'int'},
   luaL_loadstring = { args = {'lua_State *L', 'int', 'char*'}, retval = 'int'},
   luaL_where = { args = {'lua_State *L',  'int' }},
}

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
      if j.popped == nil then
         j.popped = 0
      end
      setmetatable(j, mymetatable)
   end
end
-- pretty.dump(functions)
return functions
