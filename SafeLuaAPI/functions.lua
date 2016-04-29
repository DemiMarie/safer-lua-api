--- ## SafeLuaAPI.functions, contains the API function descriptions
--
-- @author Demi Marie Obenour
-- @copyright 2016
-- @license MIT/X11
-- @module functions
local functions = {}
local pairs = pairs
local type = type
local pretty = require 'pl/pretty'
if module then
   module 'functions'
end
local _ENV = nil


--- The functions needing wrappers in the main library
functions.api_functions_needing_wrappers = {
   -- lua_call is omitted (use lua_pcall instead)
   -- lua_call = { args = {'int', 'int'}, retval = 'int'},
   lua_checkstack = {
      args = {'int n'},
      retval = 'int',
      stack_in = {},
      popped = 0,
      pushed = 0
   },

   lua_concat = {
      args = {'int n'},
      retval = 'void',
      stack_in = {},
      popped = 'n',
      pushed = 1
   },

   lua_createtable = {
      args = { 'int array_size', 'int hash_size'},
      retval = 'void',
      stack_in = {},
      popped = 0,
      pushed = 1
   },

   lua_dump = {
      args = {'lua_Writer writer', 'void* data'},
      retval = 'void',
      stack_in = {},
      popped = 0,
      pushed = 0,
   },

   lua_equal = {
      args = {'int index1', 'int index2'},
      retval = 'int',
      stack_in = {'index1', 'index2'},
      popped = 0,
      pushed = 0,
   },

   -- lua_error = {
   --    args = {},
   --    retval = 'void',
   --    stack_in = {},
   --    popped = 1,
   --    pushed = 0,
   -- },

   lua_gc = {
      args = {'int what', 'int data'},
      retval = 'int',
      stack_in = {},
      popped = 0,
      pushed = 0,
   },

   lua_getfield = {
      args = {'int index', 'const char* key'},
      retval = 'void',
      stack_in = {'index'},
      popped = 0,
      pushed = 1,
   },

   lua_getglobal = {
      args = {'const char *name'},
      retval = 'void',
      stack_in = {},
      popped = 0,
      pushed = 1,
   },

   lua_gettable = {
      args = {'int depth'},
      retval = 'void',
      stack_in = 'depth',
      popped = 1,
      pushed = 1,
   },

   lua_lessthan = {
      args = {'int index1', 'int index2'},
      retval = 'int',
      stack_in = {'index1', 'index2'},
      popped = 0,
      pushed = 0,
   },

   lua_newtable = {
      args = {},
      retval = 'void',
      stack_in = {},
      popped = 0,
      pushed = 1,
   },

   lua_newthread = {
      args = {},
      retval = 'void',
      stack_in = {},
      popped = 0,
      pushed = 1,
   },

   lua_newuserdata = {
      args = {'size_t size'},
      retval = 'void*',
      stack_in = {},
      popped = 0,
      pushed = 1,
   },

   lua_next = {
      args = {'int table_index'},
      retval = 'int',
      stack_in = 'table_index',
      popped = 1,
      pushed = '(2 * (0 != retval))',
   },

   lua_pushcclosure = {
      args = {'lua_CFunction function', 'int number_upvalues'},
      retval = 'void',
      stack_in = {},
      popped = 'number_upvalues',
      pushed = 1,
   },

   lua_pushcfunction = {
      args = {'lua_CFunction function'},
      retval = 'void',
      stack_in = {},
      popped = 0,
      pushed = 1,
   },

   lua_pushlstring = {
      args = {'const char *string', 'size_t len'},
      retval = 'void',
      stack_in = {},
      popped = 0,
      pushed = 1,
   },

   lua_pushstring = {
      args = {'const char *string'},
      retval = 'void',
      stack_in = {},
      popped = 0,
      pushed = 1,
   },

   -- TODO: handle va_list correctly
   --
   -- lua_pushvfstring = {
   --    args = {'const char *fmt', 'va_list argp'},
   --    retval = 'const char *',
   --    stack_in = {},
   --    popped = 0,
   --    pushed = 1,
   -- },

   lua_rawset = {
      args = {'int index'},
      retval = 'void',
      stack_in = 'index',
      popped = 2,
      pushed = 0,
   },

   lua_rawseti = {
      args = {'int index', 'int n'},
      retval = 'void',
      stack_in = 'index',
      popped = 1,
      pushed = 0,
   },

   lua_register = {
      args = {'const char *name', 'lua_CFunction function'},
      retval = 'void',
      stack_in = {},
      popped = 0,
      pushed = 0,
   },

   lua_setfield = {
      args = {'int index', 'const char *key'},
      retval = 'void',
      stack_in = 'key',
      popped = 1,
      pushed = 0,
   },

   lua_setglobal = {
      args = {'char *key'},
      retval = 'void',
      stack_in = {},
      popped = 1,
      pushed = 0,
   },

   lua_settable = {
      args = {'int index'},
      retval = 'void',
      stack_in = 'index',
      pushed = 0,
      popped = 2,
   },

   lua_tolstring = {
      args = {'int index', 'size_t *length'},
      retval = 'const char *',
      stack_in = 'index',
      popped = 0,
      pushed = 0,
   },

   lua_tostring = {
      args = {'int index'},
      retval = 'const char *',
      stack_in = 'index',
      popped = 0,
      pushed = 0,
   },

   -- The debug interface
   lua_getinfo = {
      args = {'const char *what', 'lua_Debug *activation_record'},
      retval = 'int',
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
      args = {'int', 'CPchar'},
      retval = 'int',
   },
   luaL_getmetafield = {
      args = {'int', 'CPchar'},
      retval = 'int',
   },
   luaL_loadbuffer = {
      args = {'CPchar', 'size_t', 'CPchar'},
      retval = 'int',
   },
   lua_newthread = {
      args = {},
      retval = 'lua_State',
      stack_in = {},
      pushed = 1,
      popped = 0,
   },
   luaL_openlibs = { args = {}},
   luaL_newmetatable = { args = {'char*'}, retval = 'int'},
   luaL_ref = { args = {'int'}, retval = 'int'},
   luaL_loadfile = { args = {'int', 'char*'}, retval = 'int'},
   luaL_loadstring = { args = {'int', 'char*'}, retval = 'int'},
   luaL_where = { args = { 'int' }},
}

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
   end
end
-- pretty.dump(functions)
return functions
