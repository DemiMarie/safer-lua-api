---
-- @author Demi Marie Obenour
-- @copyright 2016
-- @license MIT/X11 OR Apache 2.0 (your choice)
-- @module generator
local ioexception = {}

local metatable = {
   __index = ioexception,
}

--[[
function ioexception.try(protected, catch)
   local vals = { pcall(protected) }
   if vals[1] then
]]
function ioexception.throw(level, errorstring, errorcode)
   local new_error = setmetatable({}, metatable)
   -- self.backtrace = debug.traceback(level)
   new_error.errorcode = errorcode
   new_error.errorstring = errorstring
   error(new_error, tonumber(level))
end

return setmetatable({}, metatable)
