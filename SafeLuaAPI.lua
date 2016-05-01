local io = io
local require = require
local arg = arg
local print = print
local os = os
if module then
   module 'SafeLuaAPI'
end

local generator = require 'SafeLuaAPI/generator'
local functions = require 'SafeLuaAPI/functions'
local finally = require 'SafeLuaAPI/finally'

local function do_it(handle)
   handle:write[[
#include <luajit-2.0/lua.h>
#include "../template.h"
]]
   local c_code_emitter = generator.new(handle)
   c_code_emitter:generate(functions.api_functions_needing_wrappers)
   --generator.generate(handle, functions.auxlib_functions_needing_wrappers)
   --generator.generate(handle, functions.debug_functions_needing_wrappers)
end

local handle, err = io.open(arg[1], 'w')
if handle then
   do_it(handle)
   io.close(handle)
else
   print(err)
   os.exit(1)
end
