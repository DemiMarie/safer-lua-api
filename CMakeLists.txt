cmake_minimum_required(VERSION 2.7)
project(SafeLuaAPI)
enable_language(C C++)
option(USE_LUAJIT "Use LuaJIT instead of PUC Lua." ON)

function(genex_quote output_var arg)
  string(REPLACE ";" "\$<SEMICOLON>" retvar "${arg}")
  string(REPLACE "\$<" "\$<<" retvar "${retvar}")
  string(REPLACE ">" "\$<ANGLE_R>" retvar "${retvar}")
  string(REPLACE "\$<<" "\$\$<1:<>" retvar "${retvar}")
  string(REPLACE "[" "[\$<0:]>" retvar "${retvar}")
  string(REPLACE "]" "\$<0:[>]" retvar "${retvar}")
  set("${output_var}" "${retvar}" PARENT_SCOPE)
endfunction()

if(USE_LUAJIT)
   list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/Modules/")
   find_package(LuaJIT REQUIRED)
   add_definitions(-DUSE_LUAJIT)
   include_directories(BEFORE "${LuaJIT_INCLUDE_DIRS}")
   set(lua_command "luajit" CACHE FILEPATH "Path to LuaJIT")
else()
   find_package(Lua REQUIRED)
   include_directories(BEFORE "${LUA_INCLUDE_DIR}")
   set(lua_command "lua" CACHE FILEPATH "Path to Lua")
endif()

genex_quote(escaped_lua_command "${lua_command}")

option(BUILD_SHARED_LIBS "Enable shared libraries." ON)
option(BUILD_STATIC_LIBS "Enable static libraries." ON)
option(BUILD_AS_C++ "Build as C++ instead of C" OFF)

if(BUILD_AS_C++)
    set(SUFFIX "pp")
else()
    set(SUFFIX "")
endif()
set(c_stubs "${CMAKE_BINARY_DIR}/bindings.c${SUFFIX}")
add_custom_command(OUTPUT "${c_stubs}"
   COMMAND "${escaped_lua_command}"
   "${CMAKE_SOURCE_DIR}/SafeLuaAPI.lua" "${c_stubs}"
   DEPENDS SafeLuaAPI.lua SafeLuaAPI/generator.lua
   SafeLuaAPI/parse_prototype.lua SafeLuaAPI/finally.lua
   SafeLuaAPI/functions.lua SafeLuaAPI/ioexception.lua
   WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
   VERBATIM)
set(SRC_LIST "${c_stubs}" "src/SafeAPI.c${SUFFIX}")
set_source_files_properties("${c_stubs}" PROPERTIES GENERATED 1)
if(BUILD_SHARED_LIBS)
   add_library("${PROJECT_NAME}" SHARED ${SRC_LIST})
endif()
if(BUILD_STATIC_LIBS)
   add_library("${PROJECT_NAME}-static" STATIC ${SRC_LIST})
endif()
if(NOT BUILD_SHARED_LIBS AND NOT BUILD_STATIC_LIBS)
   message(FATAL_ERROR
      "Must enable either static or shared libraries.")
endif()
add_definitions(-fPIC -fvisibility=hidden -Bsymbolic -Wl,-z,relro,-z,now)
file(MAKE_DIRECTORY build)
genex_quote(binary_dir "${CMAKE_BINARY_DIR}")
add_custom_command(OUTPUT build
   COMMAND cmake ARGS make_directory "${binary_dir}")
