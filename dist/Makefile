#
# Copyright (C) 2020 Frank Kastenholz
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# Following variables shamelessly copied from the 
# Lua distribution makefile. We set them up here so 
# that we can use them throughout the Makefiles with
# consistent meaning/semantics/etc.

# Lua version and release.
export V= 5.3
export R= $V.5

# This works for a MAC. My MAC. if you run something else then you will
# have to foozle around with this.
OS_NAME= $(shell uname -s)
ifeq ($(OS_NAME), Darwin)
export OS_NAME= macosx
endif

ROOT= $(CURDIR)
INSTALL_TOP= $(ROOT)/../..
export LUA_ROOT=$(INSTALL_TOP)
export INSTALL_BIN= $(INSTALL_TOP)/bin
export INSTALL_INC= $(INSTALL_TOP)/include
export INSTALL_LIB= $(INSTALL_TOP)/lib
export INSTALL_MAN= $(INSTALL_TOP)/man/man1
export INSTALL_LMOD= $(INSTALL_TOP)/share/lua/$V
export INSTALL_CMOD= $(INSTALL_TOP)/lib/lua/$V

all:
	cd lua-5.3.5 && $(MAKE) -f Makefile-mycorona $(OS_NAME)
	cd luafilesystem-master && $(MAKE) -f Makefile-mycorona
	cd penlight-1.5.4 && $(MAKE) -f Makefile-mycorona
	cd date-master && $(MAKE) -f Makefile-mycorona
	cd gnuplot-5.2.8 && $(MAKE) -f Makefile-mycorona all

install: dummy
	cd lua-5.3.5 && $(MAKE) -f Makefile-mycorona install
	cd luafilesystem-master && $(MAKE) -f Makefile-mycorona install
	cd penlight-1.5.4 && $(MAKE) -f Makefile-mycorona install
	cd date-master && $(MAKE) -f Makefile-mycorona install
	cd gnuplot-5.2.8 && $(MAKE) -f Makefile-mycorona install

dummy:

clean:
	rm -f *~
	cd lua-5.3.5 && $(MAKE) -f Makefile-mycorona clean
	cd luafilesystem-master && $(MAKE) -f Makefile-mycorona clean
	cd penlight-1.5.4 && $(MAKE) -f Makefile-mycorona clean
	cd date-master && $(MAKE) -f Makefile-mycorona clean
	cd gnuplot-5.2.8 && $(MAKE) -f Makefile-mycorona clean
	cd ../.. && rm -rf lib bin include man share

echo:
	@echo "V= $(V)"
	@echo "R= $(R)"
	@echo "OS_NAME= $(OS_NAME)"
	@echo "ROOT= $(ROOT)"
	@echo "INSTALL_TOP= $(INSTALL_TOP)"
	@echo "LUA_ROOT= $(LUA_ROOT)"
	@echo "INSTALL_BIN= $(INSTALL_BIN)"
	@echo "INSTALL_INC= $(INSTALL_INC)"
	@echo "INSTALL_LIB= $(INSTALL_LIB)"
	@echo "INSTALL_MAN= $(INSTALL_MAN)"
	@echo "INSTALL_LMOD= $(INSTALL_LMOD)"
	@echo "INSTALL_CMOD= $(INSTALL_CMOD)"
	@echo "Lua 5.3.5:"
	@cd lua-5.3.5 && $(MAKE) -f Makefile-mycorona echo
	@echo "Lua File System:"
	@cd luafilesystem-master && $(MAKE) -f Makefile-mycorona echo
	@echo "Penlight:"
	@cd penlight-1.5.4 && $(MAKE) -f Makefile-mycorona echo
	@echo "Date:"
	@cd date-master && $(MAKE) -f Makefile-mycorona echo
