#!/usr/bin/make -f

MAKEFLAGS := -r
LUA := lua
CC := clang

override BUILDDIR := build
override shell_quote = ""'$(subst ','\'',$1)'#)'#
override builddir := $(call shell_quote,$(BUILDDIR))#
override target = ""'$(subst ','\'',$@)'#)'#
override source = ""'$(subst ','\'',$<)'#)'#
override LDFLAGS += -fPIC -fvisibility=hidden -Bsymbolic -Wl,-z,relro,-z,now

ifeq '$(CC)' 'clang'
override warnings := -Weverything
else
override warnings := -Wall -Wextra -Wshadow
endif


all: $(BUILDDIR)/bindings.so $(BUILDDIR)/bindings.a

%.so: %.o
	$(CC) -o $(target) $(source) -shared -lluajit-5.1 $(LDFLAGS)

%.a: %.o
	$(AR) rc $(target) $(source)

%.o: %.c
	$(CC) $(CFLAGS) -MMD -MP -MF$(target).dep -c -o $(target) \
	$(source) -fPIC $(warnings)

$(BUILDDIR)/bindings.c: SafeLuaAPI.lua SafeLuaAPI/*.lua $(BUILDDIR)
	$(LUA) -- $(source) $(target)

$(BUILDDIR):
	mkdir -- $(target) || :

.DELETE_ON_ERROR:

.PHONY: clean all docs

clean:
	rm -rf -- $(call shell_quote,$(BUILDDIR))

docs:
	ldoc SafeLuaAPI/generator.lua SafeLuaAPI/parse_prototype.lua \
	   SafeLuaAPI/finally.lua
	mv -- SafeLuaAPI/doc $(call shell_quote,$(BUILDDIR))

-include $(BUILDDIR)/*.dep
