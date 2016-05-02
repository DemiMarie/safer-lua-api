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

function generator:emit(...)
   local handle = self.handle
   for _, j in ipairs({...}) do
      handle:write(j)
   end
end

function generator:emit_struct(name, arguments, indexes)
   local handle = self.handle
   self:emit 'STRUCT_STATIC struct Struct_'
   self:emit(name)
   self:emit ' {\n'
   for i = 2, #arguments do
      local arg = arguments[i]
      if not indexes[arg] then
         self:emit(arguments[i])
         self:emit';\n'
      end
   end
   handle:write '};\n'
end

local function emit_arglist(arguments, indexes)
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
         z[i] = indexes[argname] or 'args->'..argname
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

function generator:emit_function_prototype(name, prototype)
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
   self.check_type(return_type)
   self.check_ident(name)
   tonumber(popped)
   tonumber(pushed)

   -- Generate indexes table.  Map from argument names to stack indexes.
   local indexes = {}
   for i, j in ipairs(stack_in) do
      indexes[j] = i + popped
   end
   self:emit_function_prototype(name, prototype)

   -- Get the various lists
   local prototype_args, initializers, call_string = emit_arglist(arguments, indexes)

   -- C needs different handling of `void` than of other types.  Boo.
   local trampoline_type, retcast_type = 'TRAMPOLINE(', ', RETCAST_VALUE, '
   if return_type == 'void' then
      trampoline_type, retcast_type = 'VOID_TRAMPOLINE(', ', RETCAST_VOID, '
   end

   -- Initial newline
   self:emit '\n'

   -- C does not allow empty structs or initializers.  Boo.
   local local_struct = ', DUMMY_LOCAL_STRUCT'
   if #arguments ~= 1 then
      -- Actually emit the struct
      self:emit_struct(name, arguments, indexes)

      -- Use a different macro for the local struct (one that actually
      -- assigns to thread-local storage)
      local_struct = ', LOCAL_STRUCT'
   end

   -- local args = concat({name, argcount}, ', ')
   --
   -- Emit trampoline code.
   self:emit(trampoline_type, return_type, ', ', name, ', ', pushed, ', ', call_string,')\n')

   -- Emit main function
   self:emit(return_type, ' safe_', name, '(int *success, ', prototype_args,') {\n')
   do
      local num_stack_inputs = #stack_in
      if num_stack_inputs ~= 0 then
         for i = num_stack_inputs, 1, -1 do
            self:emit('  lua_pushvalue(L, ', stack_in[i], ');\n')
            if popped ~= 0 then
               self:emit('  lua_insert(L, ', -i - popped, ');\n')
            end
         end
      end
   end
   self:emit('  EMIT_WRAPPER(', return_type, ', ', name, ',\
               ', popped, local_struct, retcast_type, initializers, ');\n}\n')
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
