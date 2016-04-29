local require = require
local find = string.find
local sub = string.sub
local match = string.match
local format = string.format
local reverse = string.reverse
local module = module
local error = error
local parse_prototype = {}
local assert = assert
local print = print
local gfind = string.gfind

if module then
   module 'parse_prototype'
else
   assert(false)
end

local _ENV = {}

function parse_prototype.extract_args(str)
   local start_of_argument_list, _, function_name, argument_list
      = find((str), '(%w+)%s*(%b())%s*$')
   if not start_of_argument_list then
      error(format('No argument list in %q', str), 2)
   end
   argument_list = argument_list:sub(2, #argument_list - 1)
   local return_type = str:sub(1, start_of_argument_list - 1)
   local count = 0
   local start = 1
   local args = {}
   while true do
      local start_, end_ = find(argument_list, '[_%w%b()%*%s]+', start)
      count = count + 1
      if not start_ then
         break
      end
      args[count] = argument_list:sub(start_, end_)
      start = end_ + 1
   end
   return return_type, function_name, argument_list, args
end

return parse_prototype
