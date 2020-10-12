# Copyright (c) 2020 Status Research & Development GmbH. Licensed under
# either of:
# - Apache License, version 2.0
# - MIT license
# at your option. This file may not be copied, modified, or distributed except
# according to those terms.

SHELL := bash # the shell used internally by Make

# used inside the included makefiles
BUILD_SYSTEM_DIR := vendor/nimbus-build-system

# we don't want an error here, so we can handle things later, in the ".DEFAULT" target
-include $(BUILD_SYSTEM_DIR)/makefiles/variables.mk

.PHONY: \
	all \
	clean \
	clean-build-dirs \
	clean-data-dirs \
	clean-status-go \
	create-data-dirs \
	deps \
	nat-libs-sub \
	nim_status \
	shims \
	status-go \
	sqlcipher \
	test \
	test-c \
	test-c-template \
	test-nim \
	update

ifeq ($(NIM_PARAMS),)
# "variables.mk" was not included, so we update the submodules.
GIT_SUBMODULE_UPDATE := git submodule update --init --recursive
.DEFAULT:
	+@ echo -e "Git submodules not found. Running '$(GIT_SUBMODULE_UPDATE)'.\n"; \
		$(GIT_SUBMODULE_UPDATE); \
		echo
# Now that the included *.mk files appeared, and are newer than this file, Make will restart itself:
# https://www.gnu.org/software/make/manual/make.html#Remaking-Makefiles
#
# After restarting, it will execute its original goal, so we don't have to start a child Make here
# with "$(MAKE) $(MAKECMDGOALS)". Isn't hidden control flow great?

else # "variables.mk" was included. Business as usual until the end of this file.

all: nim_status

# must be included after the default target
-include $(BUILD_SYSTEM_DIR)/makefiles/targets.mk

ifeq ($(OS),Windows_NT) # is Windows_NT on XP, 2000, 7, Vista, 10...
 detected_OS := Windows
else ifeq ($(strip $(shell uname)),Darwin)
 detected_OS := macOS
else
 detected_OS := $(strip $(shell uname)) # e.g. Linux
endif

# TODO: control debug/release builds with a Make var
# We need `-d:debug` to get Nim's default stack traces.
NIM_PARAMS += -d:debug

# nim-nat-traversal assumes nat-libs are available in its parent's vendor
nat-libs-sub: # could we just pub nat-libs in nim-status' vendor?
	cd vendor/nim-waku && $(MAKE) nat-libs

deps: | deps-common nat-libs nat-libs-sub

update: | update-common

clean-build-dirs:
	rm -rf build
	rm -rf test/c/build
	rm -rf test/nim/build

clean-data-dirs:
	rm -rf data
	rm -rf keystore
	rm -rf noBackup

clean-status-go:
	rm -rf $(dir $(STATUSGO))*

clean: | clean-common clean-build-dirs clean-data-dirs clean-status-go

create-data-dirs:
	mkdir -p data
	mkdir -p keystore
	mkdir -p noBackup

# SQLITE_CDEFS ?= -DSQLITE_HAS_CODEC -DSQLITE_TEMP_STORE=3
# export SQLITE_CDEFS
# SQLITE_CFLAGS ?= -pthread
# export SQLITE_CFLAGS
# SQLITE_LDFLAGS ?= -pthread
# export SQLITE_LDFLAGS

# SSL_INCLUDE_DIR ?= /usr/include
# ifeq ($(SSL_INCLUDE_DIR),)
#  override SSL_INCLUDE_DIR = /usr/include
# endif
# SSL_LIB_DIR ?= /usr/lib/x86_64-linux-gnu
# ifeq ($(SSL_LIB_DIR),)
#  override SSL_LIB_DIR = /usr/lib/x86_64-linux-gnu
# endif

# SSL_STATIC ?= true
# SSL_CFLAGS ?= -I$(SSL_INCLUDE_DIR)
# export SSL_CFLAGS
# ifndef SSL_LDFLAGS
#  ifeq ($(SSL_STATIC),false)
#   SSL_LDFLAGS := -L$(SSL_LIB_DIR) -lcrypto
#  else
#   SSL_LDFLAGS := -L$(SSL_LIB_DIR) $(SSL_LIB_DIR)/libcrypto.a
#  endif
#  ifeq ($(detected_OS),Windows)
#   SSL_LDFLAGS += -lws2_32
#  endif
# endif
# export SSL_LDFLAGS

ifeq ($(detected_OS),macOS)
 LIBSTATUS_EXT := dylib
else ifeq ($(detected_OS),Windows)
 LIBSTATUS_EXT := dll
else
 LIBSTATUS_EXT := so
endif
STATUSGO := vendor/status-go/build/bin/libstatus.$(LIBSTATUS_EXT)
STATUSGO_LIB_DIR := $(CURDIR)/$(dir "$(STATUSGO)")
export STATUSGO_LIB_DIR

$(STATUSGO): | deps
	echo -e $(BUILD_MSG) "status-go"
	+ cd vendor/status-go && \
		$(MAKE) statusgo-shared-library $(HANDLE_OUTPUT)

status-go: $(STATUSGO)

SQLCIPHER ?= vendor/nim-sqlcipher/sqlcipher/sqlite.nim

# Are all the make variables (e.g. SSL_LIB_DIR) picked up by the submake
# automatically or do we need to pass them explicitly here and set them up like
# in nim-sqlcipher's Makefile?
$(SQLCIPHER): | deps
	echo -e $(BUILD_MSG) "Nim wrapper for SQLCipher"
	+ cd vendor/nim-sqlcipher && \
		$(MAKE) sqlite.nim $(HANDLE_OUTPUT)

sqlcipher: $(SQLCIPHER)

# !!!!!!!!!!!!!! SEE IF WE CAN GET RID OF THIS !!!!!!!!!!!!!!
#
# ifeq ($(detected_OS),macOS)
#  FRAMEWORKS := -framework CoreFoundation -framework CoreServices -framework IOKit -framework Security
#  NIM_PARAMS := $(NIM_PARAMS) -L:"$(FRAMEWORKS)"
# endif

PCRE_STATIC ?= true
PCRE_CFLAGS ?=
export PCRE_CFLAGS
ifndef PCRE_LDFLAGS
 ifeq ($(PCRE_STATIC),false)
  PCRE_LDFLAGS := -L$(PCRE_LIB_DIR) -lpcre
 else
  PCRE_LDFLAGS := -L$(PCRE_LIB_DIR) $(PCRE_LIB_DIR)/libpcre.a
 endif
endif
export PCRE_LDFLAGS

NIMSTATUS := build/nim_status.a

$(NIMSTATUS): $(SQLCIPHER)
	echo -e $(BUILD_MSG) "$@" && \
	$(ENV_SCRIPT) nim c \
		$(NIM_PARAMS) \
		--app:staticLib \
		--header \
		--noMain \
		-o:$@ \
		src/nim_status/c/nim_status.nim
	mkdir -p build
	cp nimcache/debug/nim_status/nim_status.h build/nim_status.h
	mv nim_status.a build/

nim_status: $(NIMSTATUS)

SHIMS := test/c/build/shims.a

$(SHIMS): $(SQLCIPHER)
	echo -e $(BUILD_MSG) "$@" && \
	$(ENV_SCRIPT) nim c \
		$(NIM_PARAMS) \
		--app:staticLib \
		--header \
		--noMain \
		-o:$@ \
		test/c/shims.nim
	mkdir -p test/c/build
	cp nimcache/debug/shims/shims.h test/c/build/shims.h
	mv shims.a test/c/build/

shims: $(SHIMS)

test-c-template: $(STATUSGO) clean-data-dirs create-data-dirs
	echo "Compiling 'test/c/$(TEST_NAME)'"
	$(ENV_SCRIPT) $(CC) \
		$(TEST_INCLUDES) \
		-I"$(CURDIR)/vendor/nimbus-build-system/vendor/Nim/lib" \
		test/c/$(TEST_NAME).c \
		$(TEST_DEPS) \
		$(NIM_DEP_LIBS) \
		-L$(STATUSGO_LIB_DIR) \
		-lstatus \
		$(FRAMEWORKS) \
		-lm \
		-pthread \
		-o test/c/build/$(TEST_NAME)
	[[ $$? = 0 ]] && \
	(([[ $(detected_OS) = macOS ]] && \
	install_name_tool -add_rpath \
		"$(STATUSGO_LIB_DIR)" \
		test/c/build/$(TEST_NAME) && \
	install_name_tool -change \
		libstatus.dylib \
		@rpath/libstatus.dylib \
		test/c/build/$(TEST_NAME)) || true)
	echo "Executing 'test/c/build/$(TEST_NAME)'"
ifeq ($(detected_OS),macOS)
	./test/c/build/$(TEST_NAME)
else ifeq ($(detected_OS),Windows)
	PATH="$(STATUSGO_LIB_DIR):$$PATH" \
	./test/c/build/$(TEST_NAME)
else
	LD_LIBRARY_PATH="$(STATUSGO_LIB_DIR)" \
	./test/c/build/$(TEST_NAME)
endif

SHIMS_INCLUDES := -I\"$(CURDIR)/test/c/build\"

LOGIN_INCLUDES := -I\"$(CURDIR)/build\"

test-c:
	$(MAKE) $(SHIMS)
	$(MAKE) TEST_DEPS=$(SHIMS) \
		TEST_INCLUDES=$(SHIMS_INCLUDES) \
		TEST_NAME=shims \
		test-c-template

	$(MAKE) $(NIMSTATUS)
	$(MAKE) TEST_DEPS=$(NIMSTATUS) \
		TEST_INCLUDES=$(LOGIN_INCLUDES) \
		TEST_NAME=login \
		test-c-template

test-nim: $(STATUSGO)
ifeq ($(detected_OS),macOS)
	$(ENV_SCRIPT) nimble tests
else ifeq ($(detected_OS),Windows)
	PATH="$(STATUSGO_LIB_DIR):$$PATH" \
	$(ENV_SCRIPT) nimble tests
else
	LD_LIBRARY_PATH="$(STATUSGO_LIB_DIR)$${LD_LIBRARY_PATH:+:$${LD_LIBRARY_PATH}}" \
	$(ENV_SCRIPT) nimble tests
endif

test: test-nim test-c

endif # "variables.mk" was not included
