local io = io
local require = require
module 'SafeLuaAPI'

local generator = require 'SafeLuaAPI/generator'
local functions = require 'SafeLuaAPI/functions'
local finally = require 'SafeLuaAPI/finally'

local function do_it(handle)
   handle:write[[
#include <luajit-2.0/lua.h>
#include "template.h"
]]
   generator.generate(handle, functions.api_functions_needing_wrappers)
   --generator.generate(handle, functions.auxlib_functions_needing_wrappers)
   --generator.generate(handle, functions.debug_functions_needing_wrappers)
end

local handle = io.open('generated.c', 'w')
do_it(handle)
io.close(handle)
