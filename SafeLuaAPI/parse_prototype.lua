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
end

local pretty = require 'pl/pretty'
local _ENV = {}

function parse_prototype.extract_args(str)
   local start_of_argument_list, _, function_name, argument_list
      = find((str), '([%w_]+)%s*(%b())%s*$')
   if not start_of_argument_list then
      error(format('No argument list in %q', str), 2)
   end
   argument_list = argument_list:sub(2)
   local return_type
      = str:sub(1, start_of_argument_list - 1):gsub('^%s*',''):gsub('%s*$', '')
   local count = 0
   local start = 1
   local args = {}
   local argument_names = {}
   local argument_types = {}
   --print(('[ARGUMENT_LIST] %q'):format(argument_list))
   while true do
      --print(('[REMAINING ARGUMENT LIST] %q'):format(argument_list:sub(start)))
      local start_, end_ = find(argument_list, '[_%w%b()%*][_%w%b()%*%s]-[,%)]',
                                start)
      count = count + 1
      if not start_ then
         break
      end
      local this_argument = argument_list:sub(start_, end_ - 1)
      args[count] = this_argument
      local start_name, end_name, argument_name = assert(find(this_argument,
                                                              '%s*([%w_]+)%s*$'))
      --print(('[FOUND_ARGUMENT] %q'):format(args[count]))
      argument_names[count] = argument_name
      argument_types[count] = this_argument:sub(1, end_name)
      start = end_ + 1
   end
   --pretty.dump(args)
   return return_type, function_name, args, argument_names, argument_types
end


return parse_prototype
