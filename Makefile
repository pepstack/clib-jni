#######################################################################
# Makefile
#   Build libclib
#
# Author: 350137278@qq.com
#
# Update: 2021-06-22
#
# Show all predefinitions of gcc:
#
#   https://blog.csdn.net/10km/article/details/49023471
#
#   $ gcc -posix -E -dM - < /dev/null
#
#######################################################################
# Linux, CYGWIN_NT, MSYS_NT, ...
shuname="$(shell uname)"
OSARCH=$(shell echo $(shuname)|awk -F '-' '{ print $$1 }')

# debug | release (default)
RELEASE = 1
BUILDCFG = release

# 32 | 64 (default)
BITS = 64

# Is MINGW(1) or not(0)
MINGW_FLAG = 0

###########################################################
# Compiler Specific Configuration

CC = gcc

# for gcc-8+
# -Wno-unused-const-variable
CFLAGS += -std=gnu99 -D_GNU_SOURCE -fPIC -Wall -Wno-unused-function -Wno-unused-variable
#......

LDFLAGS += -lpthread -lm
#......


###########################################################
# Architecture Configuration

ifeq ($(RELEASE), 0)
	# debug: make RELEASE=0
	CFLAGS += -D_DEBUG -g
	BUILDCFG = debug
else
	# release: make RELEASE=1
	CFLAGS += -DNDEBUG -O3
	BUILDCFG = release
endif

ifeq ($(BITS), 32)
	# 32bits: make BITS=32
	CFLAGS += -m32
	LDFLAGS += -m32
else
	ifeq ($(BITS), 64)
		# 64bits: make BITS=64
		CFLAGS += -m64
		LDFLAGS += -m64
	endif
endif


ifeq ($(OSARCH), MSYS_NT)
	MINGW_FLAG = 1
	ifeq ($(BITS), 64)
		CFLAGS += -D__MINGW64__
	else
		CFLAGS += -D__MINGW32__
	endif
else ifeq ($(OSARCH), MINGW64_NT)
	MINGW_FLAG = 1
	ifeq ($(BITS), 64)
		CFLAGS += -D__MINGW64__
	else
		CFLAGS += -D__MINGW32__
	endif
else ifeq ($(OSARCH), MINGW32_NT)
	MINGW_FLAG = 1
	ifeq ($(BITS), 64)
		CFLAGS += -D__MINGW64__
	else
		CFLAGS += -D__MINGW32__
	endif
endif


ifeq ($(OSARCH), CYGWIN_NT)
	ifeq ($(BITS), 64)
		CFLAGS += -D__CYGWIN64__ -D__CYGWIN__
	else
		CFLAGS += -D__CYGWIN32__ -D__CYGWIN__
	endif
endif


###########################################################
# Project Specific Configuration
PREFIX = .
DISTROOT = $(PREFIX)/dist
APPS_DISTROOT = $(DISTROOT)/apps

LIBCLOGGER_DIR = $(PREFIX)/deps/libclogger


# Given dirs for all source (*.c) files
SRC_DIR = $(PREFIX)/src
COMMON_DIR = $(SRC_DIR)/common
APPS_DIR = $(SRC_DIR)/apps


#----------------------------------------------------------
# clib

CLIB_DIR = $(SRC_DIR)/clib
CLIB_VERSION_FILE = $(CLIB_DIR)/VERSION
CLIB_VERSION = $(shell cat $(CLIB_VERSION_FILE))

CLIB_STATIC_LIB = libclib.a
CLIB_DYNAMIC_LIB = libclib.so.$(CLIB_VERSION)

CLIB_DISTROOT = $(DISTROOT)/libclib-$(CLIB_VERSION)
CLIB_DIST_LIBDIR=$(CLIB_DISTROOT)/lib/$(OSARCH)/$(BITS)/$(BUILDCFG)
#----------------------------------------------------------


# add other projects here:
#...


# Set all dirs for C source: './src/a ./src/b'
ALLCDIRS += $(SRCDIR) \
	$(COMMON_DIR) \
	$(CLIB_DIR)
#...


# Get pathfiles for C source files: './src/a/1.c ./src/b/2.c'
CSRCS := $(foreach cdir, $(ALLCDIRS), $(wildcard $(cdir)/*.c))

# Get names of object files: '1.o 2.o'
COBJS = $(patsubst %.c, %.o, $(notdir $(CSRCS)))


# Given dirs for all header (*.h) files
INCDIRS += -I$(PREFIX) \
	-I$(SRC_DIR) \
	-I$(COMMON_DIR) \
	-I$(LIBCLOGGER_DIR)/include \
	-I$(CLIB_DIR) \
#...


ifeq ($(MINGW_FLAG), 1)
	MINGW_CSRCS = $(COMMON_DIR)/win32/syslog-client.c
	MINGW_LINKS = -lws2_32
else
	MINGW_CSRCS =
	MINGW_LINKS = -lrt
endif

MINGW_COBJS = $(patsubst %.c, %.o, $(notdir $(MINGW_CSRCS)))

###########################################################
# Build Target Configuration
.PHONY: all apps clean cleanall dist


all: $(CLIB_DYNAMIC_LIB).$(OSARCH) $(CLIB_STATIC_LIB).$(OSARCH)

#...


#----------------------------------------------------------
# http://www.gnu.org/software/make/manual/make.html#Eval-Function

define COBJS_template =
$(basename $(notdir $(1))).o: $(1)
	$(CC) $(CFLAGS) -c $(1) $(INCDIRS) -o $(basename $(notdir $(1))).o
endef
#----------------------------------------------------------


$(foreach src,$(CSRCS),$(eval $(call COBJS_template,$(src))))

$(foreach src,$(MINGW_CSRCS),$(eval $(call COBJS_template,$(src))))


help:
	@echo
	@echo "Build all libs and apps as the following"
	@echo
	@echo "Build 64 bits release (default):"
	@echo "    $$ make clean && make"
	@echo
	@echo "Build 32 bits debug:"
	@echo "    $$ make clean && make RELEASE=0 BITS=32"
	@echo
	@echo "Dist target into default path:"
	@echo "    $$ make clean && make dist"
	@echo
	@echo "Dist target into given path:"
	@echo "    $$ make CLIB_DISTROOT=/path/to/YourInstallDir dist"
	@echo
	@echo "Build apps with all libs:"
	@echo "    $$ make clean && make apps"
	@echo
	@echo "Show make options:"
	@echo "    $$ make help"


#----------------------------------------------------------
$(CLIB_STATIC_LIB).$(OSARCH): $(COBJS) $(MINGW_COBJS)
	rm -f $@
	rm -f $(CLIB_STATIC_LIB)
	ar cr $@ $^
	ln -s $@ $(CLIB_STATIC_LIB)

$(CLIB_DYNAMIC_LIB).$(OSARCH): $(COBJS) $(MINGW_COBJS)
	$(CC) $(CFLAGS) -shared \
		-Wl,--soname=$(CLIB_DYNAMIC_LIB) \
		-Wl,--rpath='$(PREFIX):$(PREFIX)/lib:$(PREFIX)/../lib:$(PREFIX)/../libs/lib' \
		-o $@ \
		$^ \
		$(LDFLAGS) \
		$(MINGW_LINKS)
	ln -s $@ $(CLIB_DYNAMIC_LIB)
#----------------------------------------------------------


apps: dist test_clib.exe.$(OSARCH) test_clibdll.exe.$(OSARCH)


# -lrt for Linux
test_clib.exe.$(OSARCH): $(APPS_DIR)/test_clib/app_main.c
	@echo Building test_clib.exe.$(OSARCH)
	$(CC) $(CFLAGS) $< $(INCDIRS) \
	-o $@ \
	$(CLIB_STATIC_LIB) \
	$(LDFLAGS) \
	$(MINGW_LINKS)
	ln -sf $@ test_clib


test_clibdll.exe.$(OSARCH): $(APPS_DIR)/test_clib/app_main.c
	@echo Building test_clibdll.exe.$(OSARCH)
	$(CC) $(CFLAGS) $< $(INCDIRS) \
	-Wl,--rpath='$(PREFIX):$(PREFIX)/lib:$(PREFIX)/../lib:$(PREFIX)/../libs/lib' \
	-o $@ \
	$(CLIB_DYNAMIC_LIB) \
	$(LDFLAGS) \
	$(MINGW_LINKS)
	ln -sf $@ test_clibdll


dist: all
	@mkdir -p $(CLIB_DISTROOT)/include/common
	@mkdir -p $(CLIB_DISTROOT)/include/clib
	@mkdir -p $(CLIB_DIST_LIBDIR)
	@cp $(COMMON_DIR)/unitypes.h $(CLIB_DISTROOT)/include/common/
	@cp $(CLIB_DIR)/clib_api.h $(CLIB_DISTROOT)/include/clib/
	@cp $(CLIB_DIR)/clib_def.h $(CLIB_DISTROOT)/include/clib/
	@cp $(PREFIX)/$(CLIB_STATIC_LIB).$(OSARCH) $(CLIB_DIST_LIBDIR)/
	@cp $(PREFIX)/$(CLIB_DYNAMIC_LIB).$(OSARCH) $(CLIB_DIST_LIBDIR)/
	@cd $(CLIB_DIST_LIBDIR)/ && ln -sf $(PREFIX)/$(CLIB_STATIC_LIB).$(OSARCH) $(CLIB_STATIC_LIB)
	@cd $(CLIB_DIST_LIBDIR)/ && ln -sf $(PREFIX)/$(CLIB_DYNAMIC_LIB).$(OSARCH) $(CLIB_DYNAMIC_LIB)
	@cd $(CLIB_DIST_LIBDIR)/ && ln -sf $(CLIB_DYNAMIC_LIB) libclib.so


clean:
	-rm -f *.stackdump
	-rm -f $(COBJS) $(MINGW_COBJS)
	-rm -f $(CLIB_STATIC_LIB)
	-rm -f $(CLIB_DYNAMIC_LIB)
	-rm -f $(CLIB_STATIC_LIB).$(OSARCH)
	-rm -f $(CLIB_DYNAMIC_LIB).$(OSARCH)
	-rm -rf ./msvc/libclib/build
	-rm -rf ./msvc/libclib/target
	-rm -rf ./msvc/libclib_dll/build
	-rm -rf ./msvc/libclib_dll/target
	-rm -rf ./msvc/test_clib/build
	-rm -rf ./msvc/test_clib/target
	-rm -rf ./msvc/test_clibdll/build
	-rm -rf ./msvc/test_clibdll/target
	-rm -f test_clib.exe.$(OSARCH)
	-rm -f test_clibdll.exe.$(OSARCH)
	-rm -f test_clib
	-rm -f test_clibdll
	-rm -f ./msvc/*.VC.db


cleanall: clean
	-rm -rf $(DISTROOT)