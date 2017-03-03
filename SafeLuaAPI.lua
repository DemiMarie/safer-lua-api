---
-- @author Demi Marie Obenour
-- @module SafeLuaAPI
-- @license MIT/X11
-- @license Apache 2.0
-- @copyright 2016
local SafeLuaAPI = {}

local string, assert, io, require, arg, print, os, pcall =
      string, assert, io, require, arg, print, os, pcall

local generator = require 'SafeLuaAPI/generator'
local functions = require 'SafeLuaAPI/functions'
local finally = require 'SafeLuaAPI/finally'


pcall(require, 'pl/strict')


local function do_it(handle, header_handle)
   handle:write[[
/* THIS IS A GENERATED FILE.  DO NOT EDIT. */
#include <luajit-2.0/lua.h>
#include <luajit-2.0/lauxlib.h>
#include "../template.h"
#include "bindings.h"
]]

   header_handle:write[[
/* THIS IS A GENERATED FILE.  DO NOT EDIT. */
#ifndef SAFE_LUA_API_H_INCLUDED
#define SAFE_LUA_API_H_INCLUDED SAFE_LUA_API_H_INCLUDED
]]

   assert(header_handle)
   local c_code_emitter = generator.new(handle, header_handle)
   c_code_emitter:generate(functions.api_functions_needing_wrappers)
   --generator.generate(handle, functions.auxlib_functions_needing_wrappers)
   --generator.generate(handle, functions.debug_functions_needing_wrappers)
   header_handle:write '#endif // !defined(SAFE_LUA_API_H_INCLUDED)\n'
end

local handle, err = io.open(arg[1], 'w')
if handle then
   local header_handle
   header_handle, err = io.open(string.gsub(arg[1], '%.c$', '.h'), 'w')
   if not header_handle then
      print(err)
      os.exit(1)
   end
   do_it(handle, header_handle)
   io.close(handle)
else
   print(err)
   os.exit(1)
end
