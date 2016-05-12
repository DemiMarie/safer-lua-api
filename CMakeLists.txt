cmake_minimum_required(VERSION 2.7)
project(SafeLuaAPI)
enable_language(C)
option(USE_LUAJIT "Use LuaJIT instead of PUC Lua." ON)
if(USE_LUAJIT)
   list(APPEND CMAKE_MODULE_PATH
      "${CMAKE_SOURCE_DIR}/cmake/Modules/")
   find_package(LuaJIT REQUIRED)
   add_definitions(-DUSE_LUAJIT)
   include_directories(BEFORE "${LuaJIT_INCLUDE_DIRS}")
   set(lua_command "luajit")
else()
   find_package(Lua REQUIRED)
   include_directories(BEFORE "${LUA_INCLUDE_DIR}")
   set(lua_command "lua")
endif()
option(BUILD_SHARED_LIBS "Enable shared libraries." ON)
option(BUILD_STATIC_LIBS "Enable static libraries." ON)
set(c_stubs "${CMAKE_BINARY_DIR}/bindings.c")
add_custom_command(OUTPUT "${c_stubs}"
   COMMAND "${lua_command}" "${CMAKE_SOURCE_DIR}/SafeLuaAPI.lua" "${c_stubs}"
   DEPENDS SafeLuaAPI.lua SafeLuaAPI/generator.lua
   SafeLuaAPI/parse_prototype.lua SafeLuaAPI/finally.lua
   SafeLuaAPI/functions.lua SafeLuaAPI/ioexception.lua
   WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
   VERBATIM)
set(SRC_LIST "${c_stubs}" src/SafeAPI.c)
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
add_custom_command(OUTPUT build
   COMMAND cmake ARGS make_directory "${CMAKE_BINARY_DIR}")
