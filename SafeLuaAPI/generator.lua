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
local type, tonumber, tostring = type, tonumber, tostring
local string = string
local os = os
local pcall, xpcall = pcall, xpcall
local print, error = print, error
local getmetatable, setmetatable = getmetatable, setmetatable

require 'pl/strict'
local strict, err = pcall(require, 'pl/strict')
local err, pretty = pcall(require, 'pl/pretty')
pretty = err and pretty

local finally = require 'SafeLuaAPI/finally'

local parse_prototype = require 'SafeLuaAPI/parse_prototype'
local parse_prototypes = parse_prototype.extract_args

if pretty then
   pretty.dump { parse_prototypes('int main(int argc, char **argv)') }
end

local metatable = { __index = generator, __metatable = nil }

local function check_metatable(table_)
   return getmetatable(table_) == metatable or
      error('Incorrect type passed to binder API', 2)
end

function generator:emit_struct(name, arguments)
   check_metatable(self)
   local handle = self.handle
   handle:write 'STRUCT_STATIC struct Struct_'
   handle:write(name)
   handle:write ' {\n'
   for i = 2, #arguments do
      handle:write(arguments[i])
      handle:write ';\n'
   end
   handle:write '};\n'
end

local function emit_arglist(arguments)
   local len = #arguments
   if len == 0 then
      return '', '', 'L'
   end
   local y, z = {}, {'L'}
   for i, j in ipairs(arguments) do
      if i ~= 1 then
         -- print('[ARGUMENT] '..j)
         local argname = match(j, '[_%w]+%s*$')
         -- print('[ARGNAME] '..argname)
         y[i-1] = argname
         z[i] = 'args->'..argname
      end
   end
   return concat(arguments, ', '), concat(y, ', '), concat(z, ', ')
end

function generator.check_ident(ident)
   return find(ident, '^[_%a][_%w]*$') or
      error(('String %q is not an identifier'):format(ident))
end

function generator.check_type(ty)
   if not (find(ty, '^[%s_%w%b()%*]*$') and find(ty, '^[%s_%w%(%)%*]*$')) then
      error(('String %q is not a valid C type'):format(ty))
   end
end

local check_ident, check_type = generator.check_ident, generator.check_type

function generator:emit_function_prototype(name, prototype)
   check_metatable(self)
   local c_source_text = '#ifndef '..name..'\n'..prototype..';\n#endif\n'
   self.handle:write(c_source_text)
end

--- Generates a wrapper for API function `name`.
-- @tparam string name The function name.
-- @tparam string popped The number of arguments popped from the Lua stack.
-- @tparam string pushed The number of arguments pushed onto the Lua stack.
-- @tparam {string,...} stack_in A list of arguments that name stack slots
--  used by the function.
-- @tparam string prototype The function prototype for the function.
-- @treturn string The wrapper C code for the function
function generator:emit_wrapper(popped, pushed, stack_in, prototype)
   check_metatable(self)

   local return_type, name, arguments = parse_prototype.extract_args(prototype)
   assert(#arguments > 0, 'No Lua API function takes no arguments')

   -- Consistency checks on the arguments
   check_type(return_type)
   check_ident(name)
   tonumber(popped)
   tonumber(pushed)

   self:emit_function_prototype(name, prototype)

   -- Get the various lists
   local prototype_args, initializers, call_string = emit_arglist(arguments)

   -- C needs different handling of `void` than of other types.  Boo.
   local trampoline_type, retcast_type = 'TRAMPOLINE(', ', RETCAST_VALUE, '
   if return_type == 'void' then
      trampoline_type, retcast_type = 'VOID_TRAMPOLINE(', ', RETCAST_VOID, '
   end

   -- C does not allow empty structs or initializers.  Boo.
   local local_struct = ', DUMMY_LOCAL_STRUCT'
   if #arguments ~= 1 then
      -- Actually emit the struct
      self:emit_struct(name, arguments)

      -- Use a different macro for the local struct (one that actually
      -- assigns to thread-local storage)
      local_struct = ', LOCAL_STRUCT'
   end

   -- local args = concat({name, argcount}, ', ')
   self.handle:write(concat {
      trampoline_type, return_type, ', ', name, ', ', pushed, ', ',
      call_string,')\
#define ARGLIST ', prototype_args:gsub('\n', ' '), '\
EMIT_WRAPPER(', return_type, ', ', name, ', ', popped, local_struct, retcast_type, initializers, ')\n#undef ARGLIST\n\n'
   })
end

function generator:generate(table_)
   --pretty.dump(table_)
   check_metatable(self)
   for i, j in pairs(table_) do
      assert(type(i) == 'string')
      -- print(argument_list)
      self:emit_wrapper(j.popped, j.pushed, j.stack_in, i)
   end
end

function generator.new(handle)
   return setmetatable({ handle = handle }, metatable)
end

local generate = generator.generate

--- Generate C code to a given filename
-- @tparam string filename The name of the file to write the C code to.
-- @tparam {} table_ The table containing function descriptions
function generator.generate_to_file(filename, table_)
   return finally.with_file(filename, 'w', generate)
end

return generator
