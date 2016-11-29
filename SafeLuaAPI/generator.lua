---
-- ## SafeLuaAPI compiler, generate the C code needed for the library
--
-- @author Demi Marie Obenour
-- @copyright 2016
-- @license MIT/X11 OR Apache 2.0 OR Boost OR ISC (your choice)
-- @module generator
local generator = {}

-- Local versions of global variables
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

-- Require pl/strict.  But don't bail out if it is absent, since it
-- is not really required.
local strict, err = pcall(require, 'pl/strict')

local finally = require 'SafeLuaAPI/finally'

local parse_prototype = require 'SafeLuaAPI/parse_prototype'
local parse_prototypes = parse_prototype.extract_args

-- Metatable for objects used by this library
local metatable = { __index = generator, __metatable = nil }

-- Consistency check for argument validation
local function check_metatable(table_)
   return getmetatable(table_) == metatable or
      error('Incorrect type passed to binder API', 2)
end

---
-- Emit all of its arguments to the current handle.
function generator:emit(...)
   local handle = self.handle
   for _, j in ipairs {...} do
      assert(handle:write(j))
   end
   return true, nil, nil
end


---
-- Emits the declaration for the temporary struct.
-- @tparam string name The name of the Lua API function being wrapped.
-- @tparam {string,...} arguments The arguments of the function being wrapped.
-- @tparam {string,...} argument_names The names of the arguments of the
--   function being wrapped.
-- @tparam {string=number,...} indexes The names of arguments that are stack
--   indexes.
-- @treturn {string,...} A table containing the parameters to use as the
--   initializers in the proper order.
function generator:emit_struct(name, arguments, argument_names, indexes)
   self:emit('STRUCT_STATIC struct Struct_', name, ' {\n')
   local initializers = {}
   local initializer_length = 0
   for i = 2, #arguments do
      local name = argument_names[i]
      if not indexes[name] then
         self:emit('   ', arguments[i], ';\n')
         initializer_length = initializer_length + 1
         initializers[initializer_length] = name
      end
   end
   self:emit '};\n'
   assert(#initializers > 0)
   return initializers
end

local function emit_arglist(argument_names, indexes)
   local z = {''}
   for i, j in ipairs(argument_names) do
      if i ~= 1 then
         z[i] = indexes[j] or 'args->'..j
      end
   end
   return z
end

---
-- Check if `ident` is a C identifier
-- @tparam string ident The string to check for being a C identifier
function generator.check_ident(ident)
   return find(ident, '^[_%a][_%w]*$') or
      error(('String %q is not an identifier'):format(ident))
end

function generator.check_type(ty)
   if not (find(ty, '^[%s_%w%b()%*]*$') and find(ty, '^[%s_%w%(%)%*]*$')) then
      error(('String %q is not a valid C type'):format(ty))
   end
end

function generator:emit_binding_function_prototype(prototype)
   check_metatable(self)
   self.header_handle:write(prototype)
   self.header_handle:write ';\n'
end

function generator:emit_lua_function_prototype(name, prototype)
   local c_source_text = '\n#ifndef '..name..'\n'..prototype..';\n#endif'
   self.handle:write(c_source_text)
end

local function emit_trampoline(self, name, needs_struct)
   -- Emit trampoline code.
   self:emit('static int trampoline_', name, '(lua_State *L) {\n')
   if needs_struct then
      self:emit('   struct Struct_', name, ' *args = CAST(struct Struct_', name,
                ' *, TLS);\n')
   end
end

local function handle_stack(self, stack_in, popped)
   for i = #stack_in, 1, -1 do
      self:emit('   lua_pushvalue(L, ', stack_in[i], ');\n')
      if popped ~= 0 then
         self:emit('   lua_insert(L, ', -i - popped, ');\n')
      end
   end
end

--- Generates a wrapper for API function `name`.
-- @tparam string popped The number of arguments popped from the Lua stack.
-- @tparam string pushed The number of arguments pushed onto the Lua stack.
-- @tparam {string,...} stack_in A list of arguments that name stack slots
--  used by the function.
-- @tparam string prototype The function prototype for the function.
-- @treturn ()
function generator:emit_wrapper(popped, pushed, stack_in, prototype, name_to_emit)
   check_metatable(self)

   local return_type, name, arguments, argument_names, argument_types =
      parse_prototype.extract_args(prototype)
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
   self:emit_lua_function_prototype(name, prototype)

   local call_string = emit_arglist(argument_names, indexes)

   -- C needs different handling of `void` than of other types.  Boo.
   local trampoline_type = return_type == 'void'
      and '   VOID_TRAMPOLINE('
      or '   TRAMPOLINE('

   -- Initial newline
   self:emit '\n'
   do
      -- C does not allow empty structs or initializers.  Boo.
      local needs_struct = #arguments > #stack_in + 1
      local initializers = {}
      if needs_struct then
         -- At least one argument that is not a stack index.
         -- Actually emit the struct and get the initializers.
         initializers = self:emit_struct(name, arguments, argument_names,
                                         indexes)
         --needs_struct = #initializers ~= 0
      end
      -- local args = concat({name, argcount}, ', ')
      emit_trampoline(self, name, needs_struct)
      self:emit(trampoline_type, return_type, ', ', name, ', ', pushed, ', L',
                concat(call_string, ', ') ,');\n}\n')
      do
         name_to_emit = name_to_emit or 'safe_'..name
      end
      -- Emit main function
      local prototype = concat {
         return_type, ' ', name_to_emit, '(int *success, ',
         concat(arguments, ',') ,')' }
      self:emit_binding_function_prototype(prototype)
      self:emit(prototype, ' {\n')
      if needs_struct then
         self:emit([[
   struct Struct_]], name, ' local = {', concat(initializers, ','), [[};
   TLS = CAST(void *, &local);
]])
      end
   end
   handle_stack(self, stack_in, popped)
   self:emit '   '
   if return_type ~= 'void' then
      self:emit 'uintptr_t succeeded = '
   end
   self:emit('protected_call(L, &trampoline_', name,' , success, ',
      popped, ');\n')
   if return_type ~= 'void' then
      self:emit('   return CAST(', return_type,
                ', succeeded ? TLS : CAST(uintptr_t, 0));\n')
   else
      self:emit('   return;\n')
   end
   self:emit '}\n'
end

function generator:generate(table_)
   assert(self.handle and self.header_handle)
   check_metatable(self)
   for _, j in ipairs(table_) do
      self:emit_wrapper(j.popped, j.pushed, j.stack_in, j.prototype, j.name)
   end
end

function generator.new(handle, header_handle)
   assert(handle and header_handle)
   return setmetatable({ handle = handle,
                         header_handle = header_handle }, metatable)
end

local generate = generator.generate

--- Generate C code to a given filename
-- @tparam string filename The name of the file to write the C code to.
-- @tparam {} table_ The table containing function descriptions
function generator.generate_to_file(filename, table_)
   return finally.with_file(filename, 'w', generate)
end

function generator:emit_function(prototype)
   assert(type(prototype) == 'string')
   return function(metadata)
      self:emit_wrapper(metadata.popped,
                        metadata.pushed,
                        metadata.stack_in,
                        prototype,
                        metadata.name)
   end
end

return setmetatable({}, metatable)
