#.rst:
# FindLuaJIT
# ---------
#
#
#
# Locate LuaJIT library This module defines
#
# ::
#
#   LuaJIT_FOUND, if false, do not try to link to Lua
#   LuaJIT_LIBRARIES
#   LuaJIT_INCLUDE_DIRS, where to find lua.h
#   LuaJIT_VERSION_STRING, the version of Lua found (since CMake 2.8.8)
#
#
#
# Note that the expected include convention is
#
# ::
#
#   #include "lua.h"
#
# and not
#
# ::
#
#   #include <luajit/lua.h>
#
# This is because, the LuaJIT location is not standardized and may exist in
# locations other than luajit-2.1/
#
#=============================================================================
# Copyright 2007-2009 Kitware, Inc.
# Copyright 2015 Demetrios Obenour
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# * Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
#
# * Neither the names of Kitware, Inc., the Insight Software Consortium,
#   nor the names of their contributors may be used to endorse or promote
#   products derived from this software without specific prior written
#   permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#=============================================================================

find_path(LuaJIT_INCLUDE_DIR
      NAMES luajit.h
      HINTS
      ENV LuaJIT_DIR
      PATH_SUFFIXES include/luajit-2.1 include/luajit-2.0 include/luajit include/lua include
      PATHS
      ~/.local
      ~/Library/Frameworks
      /Library/Frameworks
      /sw # Fink
      /opt/local # DarwinPorts
      /opt/csw # Blastwave
      /opt
      )

find_library(LuaJIT_LIBRARY
      NAMES luajit-5.1
      HINTS
      ENV LuaJIT_DIR
      PATH_SUFFIXES lib
      PATHS
      ~/.local
      ~/Library/Frameworks
      /Library/Frameworks
      /sw
      /opt/local
      /opt/csw
      /opt
      )

if(LuaJIT_LIBRARY)
# include the math library for Unix
   if(UNIX AND NOT APPLE AND NOT BEOS AND NOT HAIKU)
find_library(LuaJIT_MATH_LIBRARY m)
   set(LuaJIT_LIBRARIES "${LuaJIT_LIBRARY};${LuaJIT_MATH_LIBRARY}"
       CACHE STRING "LuaJIT Libraries")
# For Windows and Mac, don't need to explicitly include the math library
else()
   set(LuaJIT_LIBRARIES "${LuaJIT_LIBRARY}" CACHE STRING "LuaJIT Libraries")
   endif()
endif()
   if(LuaJIT_INCLUDE_DIR AND EXISTS "${LuaJIT_INCLUDE_DIR}/luajit.h")
   file(STRINGS "${LuaJIT_INCLUDE_DIR}/luajit.h" LuaJIT_VERSION_STRING
         REGEX "^#[ \t]*define[ \t]+LUAJIT_VERSION[ \t]*\"LuaJIT [^\"]+\"")
   string(REGEX REPLACE "^[ \t]*#[ \t]*define[ \t]+LUAJIT_VERSION[ \t]+\"LuaJIT ([^\"]+)\"" \\1
         LuaJIT_VERSION_STRING "${LuaJIT_VERSION_STRING}")
   unset(_version_str)
endif()
   set(LuaJIT_INCLUDE_DIRS "${LuaJIT_INCLUDE_DIR}")

include(FindPackageHandleStandardArgs)
# handle the QUIETLY and REQUIRED arguments and set _FOUND to TRUE if
# all listed variables are TRUE
   FIND_PACKAGE_HANDLE_STANDARD_ARGS(LuaJIT
         REQUIRED_VARS LuaJIT_LIBRARIES LuaJIT_INCLUDE_DIR
         VERSION_VAR LuaJIT_VERSION_STRING)

mark_as_advanced(LuaJIT_INCLUDE_DIR LuaJIT_LIBRARIES LuaJIT_LIBRARY LuaJIT_MATH_LIBRARY)
