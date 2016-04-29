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
   lua_checkstack = {
      args = {'lua_State *L', 'int n'},
      retval = 'int',
      stack_in = {},
      popped = 0,
      pushed = 0
   },

   lua_concat = {
      args = {'lua_State *L', 'int n'},
      retval = 'void',
      stack_in = {},
      popped = 'n',
      pushed = 1
   },

   lua_createtable = {
      args = {'lua_State *L',  'int array_size', 'int hash_size'},
      retval = 'void',
      stack_in = {},
      popped = 0,
      pushed = 1
   },

   lua_dump = {
      args = {'lua_State *L', 'lua_Writer writer', 'void* data'},
      retval = 'int',
      stack_in = {},
      popped = 0,
      pushed = 0,
   },

   lua_equal = {
      args = {'lua_State *L', 'int index1', 'int index2'},
      retval = 'int',
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

   lua_gc = {
      args = {'lua_State *L', 'int what', 'int data'},
      retval = 'int',
      stack_in = {},
      popped = 0,
      pushed = 0,
   },

   lua_getfield = {
      args = {'lua_State *L', 'int index', 'const char* key'},
      retval = 'void',
      stack_in = {'index'},
      popped = 0,
      pushed = 1,
   },

   lua_getglobal = {
      args = {'lua_State *L', 'const char *name'},
      retval = 'void',
      stack_in = {},
      popped = 0,
      pushed = 1,
   },

   lua_gettable = {
      args = {'lua_State *L', 'int depth'},
      retval = 'void',
      stack_in = 'depth',
      popped = 1,
      pushed = 1,
   },

   lua_lessthan = {
      args = {'lua_State *L', 'int index1', 'int index2'},
      retval = 'int',
      stack_in = {'index1', 'index2'},
      popped = 0,
      pushed = 0,
   },

   lua_newtable = {
      args = {'lua_State *L', },
      retval = 'void',
      stack_in = {},
      popped = 0,
      pushed = 1,
   },

   lua_newthread = {
      args = {'lua_State *L', },
      retval = 'lua_State *',
      stack_in = {},
      popped = 0,
      pushed = 1,
   },

   lua_newuserdata = {
      args = {'lua_State *L', 'size_t size'},
      retval = 'void*',
      stack_in = {},
      popped = 0,
      pushed = 1,
   },

   lua_next = {
      args = {'lua_State *L', 'int table_index'},
      retval = 'int',
      stack_in = 'table_index',
      popped = 1,
      pushed = '(2 * (0 != retval))',
   },

   lua_pushcclosure = {
      args = {'lua_State *L', 'lua_CFunction function', 'int number_upvalues'},
      retval = 'void',
      stack_in = {},
      popped = 'number_upvalues',
      pushed = 1,
   },

   lua_pushcfunction = {
      args = {'lua_State *L', 'lua_CFunction function'},
      retval = 'void',
      stack_in = {},
      popped = 0,
      pushed = 1,
   },

   lua_pushlstring = {
      args = {'lua_State *L', 'const char *string', 'size_t len'},
      retval = 'void',
      stack_in = {},
      popped = 0,
      pushed = 1,
   },

   lua_pushstring = {
      args = {'lua_State *L', 'const char *string'},
      retval = 'void',
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

   lua_rawset = {
      args = {'lua_State *L', 'int index'},
      retval = 'void',
      stack_in = 'index',
      popped = 2,
      pushed = 0,
   },

   lua_rawseti = {
      args = {'lua_State *L', 'int index', 'int n'},
      retval = 'void',
      stack_in = 'index',
      popped = 1,
      pushed = 0,
   },

   lua_register = {
      args = {'lua_State *L', 'const char *name', 'lua_CFunction function'},
      retval = 'void',
      stack_in = {},
      popped = 0,
      pushed = 0,
   },

   lua_setfield = {
      args = {'lua_State *L', 'int index', 'const char *key'},
      retval = 'void',
      stack_in = 'key',
      popped = 1,
      pushed = 0,
   },

   lua_setglobal = {
      args = {'lua_State *L', 'char *key'},
      retval = 'void',
      stack_in = {},
      popped = 1,
      pushed = 0,
   },

   lua_settable = {
      args = {'lua_State *L', 'int index'},
      retval = 'void',
      stack_in = 'index',
      pushed = 0,
      popped = 2,
   },

   lua_tolstring = {
      args = {'lua_State *L', 'int index', 'size_t *length'},
      retval = 'const char *',
      stack_in = 'index',
      popped = 0,
      pushed = 0,
   },

   lua_tostring = {
      args = {'lua_State *L', 'int index'},
      retval = 'const char *',
      stack_in = 'index',
      popped = 0,
      pushed = 0,
   },

   -- The debug interface
   lua_getinfo = {
      args = {'lua_State *L', 'const char *what', 'lua_Debug *activation_record'},
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
