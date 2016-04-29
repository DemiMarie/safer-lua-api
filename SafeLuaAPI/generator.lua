---
-- ## SafeLuaAPI compiler, generate the C code needed for the library
--
-- @author Demi Marie Obenour
-- @copyright 2016
-- @license MIT/X11
-- @module generator
local generator = {}

local require = require
local concat = table.concat
local assert = assert
local sub, find, match = string.sub, string.find, string.match
local format = string.format
local stdout, stderr = io.stdout, io.stderr
local pairs, ipairs, next = pairs, ipairs, next
local tostring = tostring
local io = io
local type = type
local string = string
local os = os
local pcall = pcall
local print, error = print, error

local strict = require 'pl/strict'
local pretty = require 'pl/pretty'

local finally = require 'SafeLuaAPI/finally'

local function emit_struct(handle, name, arguments)
   if #arguments == 0 then
      return
   end
   local x = {}
   handle:write 'STRUCT_STATIC struct Struct_'
   handle:write(name)
   handle:write ' {\n'
   local n = 1
   for i, j in pairs(arguments) do
      n = n + 1
      --print(j)
      handle:write '  '
      handle:write(j)
      handle:write ';\n'
   end
   handle:write '};\n'
end

local function emit_arglist(arguments)
   local len = #arguments
   if len == 0 then
      return '', '', 'L'
   end
   local x, y, z = {''}, {}, {'L'}
   for i, j in ipairs(arguments) do
      -- print('[ARGUMENT] '..j)
      local argindex, end_ = find(j, '[_%w]+%s*$')
      local argname = sub(j, argindex, end_)
      -- print('[ARGNAME] '..argname)
      x[i+1] = j
      y[i] = argname
      z[i+1] = 'args->'..argname
   end
   return concat(x, ', '), concat(y, ', '), concat(z, ', ')
end

local function check_ident(ident)
   return find(ident, '^[_%a][_%w]*$') or
      error(('String %q is not an identifier'):format(ident))
end

local function check_type(ty)
   if not (find(ty, '^[%s_%w%b()%*]*$') and find(ty, '^[%s_%w%(%)%*]*$')) then
      error(('String %q is not a valid C type'):format(ty))
   end
end

--- Generates a wrapper for API function `name`
-- @tparam string name The function name.
-- @tparam {string = string, ...} arguments The function arguments
-- @tparam string retval the return type of the function
-- @treturn string The wrapper C code for the function
local function emit_wrapper(handle, rettype, name, retcount, argcount, arguments)
   rettype = rettype or 'void'
   -- Consistency checks on the arguments
   check_type(rettype)
   check_ident(name)

   -- Get the various lists
   local prototype_args, initializers, call_string = emit_arglist(arguments)

   -- C needs different handling of `void` than of other types.  Boo.
   local trampoline_type, retcast_type = 'TRAMPOLINE(', ', RETCAST_VALUE, '
   if rettype == 'void' then
      trampoline_type, retcast_type = 'VOID_TRAMPOLINE(', ', RETCAST_VOID, '
   end

   -- C does not allow empty structs or initializers.  Boo.
   local local_struct = ', DUMMY_LOCAL_STRUCT'
   if #arguments ~= 0 then
      -- Actually emit the struct
      emit_struct(handle, name, arguments)
      -- Use a different macro for the local struct (one that actually
      -- assigns to thread-local storage)
      local_struct = ', LOCAL_STRUCT'
   end

   local args = concat({name, argcount}, ', ')
   return concat {
      trampoline_type, rettype, ', ', name, ', ', retcount, ', ', call_string,')\
#define ARGLIST ', prototype_args, '\
EMIT_WRAPPER(', rettype, ', ', name, ', ', argcount,
      local_struct, retcast_type, initializers, ')\
#undef ARGLIST\n\n' }
end

local function generate_wrapper(handle, name, arguments, pushed, popped, retval)
   assert(type(name) == 'string', '`name` must be a string')
   -- assert(type(arguments) == 'table' and #arguments == 0,
   --        '`arguments` must be a table with an empty array part')
   return (emit_wrapper(handle, retval, name, tostring(pushed), popped, arguments))
end

local function generate(handle, table_)
   --pretty.dump(table_)
   for i, j in pairs(table_) do
      assert(type(i) == 'string')
      --print(j)
      handle:write(generate_wrapper(handle, i, j.args, j.pushed, j.popped, j.retval))
   end
end

generator.generate = generate

--- Generate C code to a given filename
-- @tparam string filename The name of the file to write the C code to.
function generator.generate_to_file(filename, table_)
   return finally.with_file(filename, 'w', generate_to_handle)
end

return generator
