---
-- ## SafeLuaAPI compiler, resource cleanup utlities
--
-- @author Demi Marie Obenour
-- @copyright 2016
-- @license MIT/X11
-- @module finally
local finally = {}

local open, close = io.open, io.close
local rename, remove = os.rename, os.remove
local error = error
local rawget = rawget

if rawget(_G, 'setfenv') then
   setfenv(1, nil)
end

local function finally_helper(cleanup, cleanup_arg, is_okay, ...)
   cleanup(cleanup_arg, is_okay)
   if is_okay then
      return ...
   else
      error(...)
   end
end

local function finally_(protected, cleanup, cleanup_arg, ...)
   return finally_helper(cleanup, cleanup_arg, pcall(protected, ...))
end

finally.finally = finally_

function finally.with_file(filename, mode, function_, ...)
   local handle = open(filename, mode)
   return finally_(function_, close, handle, handle, ...)
end

return finally
