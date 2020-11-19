# Copyright (c) 2020 Status Research & Development GmbH. Licensed under
# either of:
# - Apache License, version 2.0
# - MIT license
# at your option. This file may not be copied, modified, or distributed except
# according to those terms.

SHELL := bash # the shell used internally by Make

# used inside the included makefiles
BUILD_SYSTEM_DIR := vendor/nimbus-build-system

# Deactivate nimbus-build-system LINK_PCRE logic in favor of PCRE variables
# defined later in this Makefile.
export LINK_PCRE := 0

# we don't want an error here, so we can handle things later, in the ".DEFAULT" target
-include $(BUILD_SYSTEM_DIR)/makefiles/variables.mk

.PHONY: \
	all \
	clean \
	clean-build-dirs \
	clean-data-dirs \
	clean-sqlcipher \
	clean-status-go \
	create-data-dirs \
	deps \
	nat-libs-sub \
	nim_status \
	shims-for-test-c \
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
 # e.g. Linux
 detected_OS := $(strip $(shell uname))
endif

clean: | clean-common clean-build-dirs clean-data-dirs clean-sqlcipher clean-status-go

clean-build-dirs:
	rm -rf \
		build \
		test/c/build \
		test/nim/build

clean-data-dirs:
	rm -rf \
		data \
		keystore \
		noBackup

clean-sqlcipher:
	rm -rf \
		$(shell dirname $(shell dirname $(SQLCIPHER)))/nimcache \
		$(shell dirname $(shell dirname $(SQLCIPHER)))/sqlcipher \
		$(shell dirname $(shell dirname $(SQLCIPHER)))/sqlite

clean-status-go:
	rm -rf $(shell dirname $(STATUSGO))/*

create-data-dirs:
	mkdir -p \
		data \
		keystore \
		noBackup

# nim-nat-traversal assumes nat-libs are available in its parent's vendor
nat-libs-sub:
	cd vendor/nim-waku && \
		$(ENV_SCRIPT) $(MAKE) USE_SYSTEM_NIM=1 nat-libs

deps: | deps-common nat-libs nat-libs-sub

update: | update-common

ifndef SHARED_LIB_EXT
 ifeq ($(detected_OS),macOS)
   SHARED_LIB_EXT := dylib
 else ifeq ($(detected_OS),Windows)
   SHARED_LIB_EXT := dll
 else
   SHARED_LIB_EXT := so
 endif
endif

# should be an absolute path when supplied by user
ifndef STATUSGO
 STATUSGO := vendor/status-go/build/bin/libstatus.$(SHARED_LIB_EXT)
 STATUSGO_LIB_DIR := $(shell pwd)/$(shell dirname $(STATUSGO))
else
 STATUSGO_LIB_DIR := $(shell dirname $(STATUSGO))
endif

$(STATUSGO): | deps
	echo -e $(BUILD_MSG) "status-go"
	+ cd vendor/status-go && \
		$(MAKE) statusgo-shared-library $(HANDLE_OUTPUT)

status-go: $(STATUSGO)

# These SSL variables and logic work like those in nim-sqlcipher's Makefile
SSL_STATIC ?= true
SSL_INCLUDE_DIR ?= /usr/include
ifeq ($(SSL_INCLUDE_DIR),)
 override SSL_INCLUDE_DIR = /usr/include
endif
SSL_LIB_DIR ?= /usr/lib/x86_64-linux-gnu
ifeq ($(SSL_LIB_DIR),)
 override SSL_LIB_DIR = /usr/lib/x86_64-linux-gnu
endif
ifndef SSL_LDFLAGS
 ifeq ($(SSL_STATIC),false)
  SSL_LDFLAGS := -L$(SSL_LIB_DIR) -lssl -lcrypto
 else
  SSL_LDFLAGS := $(SSL_LIB_DIR)/libssl.a $(SSL_LIB_DIR)/libcrypto.a
 endif
 ifeq ($(detected_OS),Windows)
  SSL_LDFLAGS += -lws2_32
 endif
endif
NIM_PARAMS += --define:ssl
ifneq ($(SSL_STATIC),false)
 NIM_PARAMS += --dynlibOverride:ssl
endif

SQLCIPHER ?= vendor/nim-sqlcipher/sqlcipher/sqlite.nim

$(SQLCIPHER): | deps
	echo -e $(BUILD_MSG) "Nim wrapper for SQLCipher"
	+ cd vendor/nim-sqlcipher && \
		$(ENV_SCRIPT) $(MAKE) USE_SYSTEM_NIM=1 sqlite.nim

sqlcipher: $(SQLCIPHER)

PCRE_STATIC ?= true
PCRE_INCLUDE_DIR ?= /usr/include
ifeq ($(PCRE_INCLUDE_DIR),)
 override PCRE_INCLUDE_DIR = /usr/include
endif
PCRE_LIB_DIR ?= /usr/lib/x86_64-linux-gnu
ifeq ($(PCRE_LIB_DIR),)
 override PCRE_LIB_DIR = /usr/lib/x86_64-linux-gnu
endif
ifndef PCRE_LDFLAGS
 ifeq ($(PCRE_STATIC),false)
  ifeq ($(detected_OS),Windows)
   PCRE_LDFLAGS := -L$(PCRE_LIB_DIR) -lpcre64
  else
   PCRE_LDFLAGS := -L$(PCRE_LIB_DIR) -lpcre
  endif
 else
  PCRE_LDFLAGS := $(PCRE_LIB_DIR)/libpcre.a
 endif
endif
ifneq ($(PCRE_STATIC),false)
 NIM_PARAMS += --define:usePcreHeader --dynlibOverride:pcre
endif

ifndef NIMSTATUS_CFLAGS
 ifneq ($(PCRE_STATIC),false)
  ifeq ($(detected_OS),Windows)
   NIMSTATUS_CFLAGS := -DPCRE_STATIC -I$(PCRE_INCLUDE_DIR)
  else
   NIMSTATUS_CFLAGS := -I$(PCRE_INCLUDE_DIR)
  endif
 endif
endif
ifneq ($(NIMSTATUS_CFLAGS),)
 NIM_PARAMS += --passC:"$(NIMSTATUS_CFLAGS)"
endif

NIMSTATUS ?= build/nim_status.a

$(NIMSTATUS): $(SQLCIPHER)
	echo -e $(BUILD_MSG) "$@"
	+ mkdir -p build
	$(ENV_SCRIPT) nim c $(NIM_PARAMS) \
		--app:staticLib \
		--header \
		--nimcache:nimcache/nim_status \
		--noMain \
		--threads:on \
		--tlsEmulation:off \
		-o:$@ \
		nim_status/c/nim_status.nim
	cp nimcache/nim_status/nim_status.h build/nim_status.h
	mv nim_status.a build/

nim_status: $(NIMSTATUS)

SHIMS_FOR_TEST_C ?= test/c/build/shims.a

$(SHIMS_FOR_TEST_C): $(SQLCIPHER)
	echo -e $(BUILD_MSG) "$@"
	+ mkdir -p test/c/build
	$(ENV_SCRIPT) nim c $(NIM_PARAMS) \
		--app:staticLib \
		--header \
		--nimcache:nimcache/shims \
		--noMain \
		--threads:on \
		--tlsEmulation:off \
		-o:$@ \
		test/c/shims.nim
	cp nimcache/shims/shims.h test/c/build/shims.h
	mv shims.a test/c/build/

shims-for-test-c: $(SHIMS_FOR_TEST_C)

# Currently assumes the _STATIC variables are all false or all not false
# LD_LIBRARY_PATH is supplied when running tests on Linux
# PATH is supplied when running tests on Windows
ifeq ($(PCRE_STATIC),false)
 ifeq ($(SQLITE_STATIC),false)
  ifeq ($(SSL_STATIC),false)
   LD_LIBRARY_PATH_TEST ?= $(PCRE_LIB_DIR):$(shell pwd)/$(shell dirname $(SQLCIPHER)):$(SSL_LIB_DIR):$(STATUSGO_LIB_DIR)$${LD_LIBRARY_PATH:+:$${LD_LIBRARY_PATH}}
   PATH_TEST ?= $(shell cygpath $(shell dirname $(PCRE_LIB_DIR))):$(shell cygpath $(PCRE_LIB_DIR)):$(shell pwd)/$(shell dirname $(SQLCIPHER)):$(shell cygpath $(shell dirname $(SSL_LIB_DIR))):$(shell cygpath $(SSL_LIB_DIR)):$(STATUSGO_LIB_DIR):$${PATH}
  endif
 endif
else
 LD_LIBRARY_PATH_TEST ?= $(STATUSGO_LIB_DIR)$${LD_LIBRARY_PATH:+:$${LD_LIBRARY_PATH}}
 PATH_TEST ?= $(STATUSGO_LIB_DIR):$${PATH}
endif

ifeq ($(detected_OS),Linux)
 PLATFORM_FLAGS_TEST_C ?= -ldl
endif

test-c-template: $(STATUSGO) clean-data-dirs create-data-dirs
	echo "Compiling 'test/c/$(TEST_NAME)'"
	+ mkdir -p test/c/build
	$(ENV_SCRIPT) $(CC) \
		$(TEST_INCLUDES) \
		-I"$(shell pwd)/vendor/nimbus-build-system/vendor/Nim/lib" \
		test/c/$(TEST_NAME).c \
		$(TEST_DEPS) \
		$(PCRE_LDFLAGS) \
		$(SSL_LDFLAGS) \
		-L$(STATUSGO_LIB_DIR) \
		-lstatus \
		-lm \
		-pthread \
		$(PLATFORM_FLAGS_TEST_C) \
		-o test/c/build/$(TEST_NAME) $(HANDLE_OUTPUT)
	[[ $$? = 0 ]] && \
	(([[ $(detected_OS) = macOS ]] && \
	install_name_tool -add_rpath \
		"$(STATUSGO_LIB_DIR)" \
		test/c/build/$(TEST_NAME) $(HANDLE_OUTPUT) && \
	install_name_tool -change \
		libstatus.dylib \
		@rpath/libstatus.dylib \
		test/c/build/$(TEST_NAME) $(HANDLE_OUTPUT)) || true)
	echo "Executing 'test/c/build/$(TEST_NAME)'"
ifeq ($(detected_OS),macOS)
	./test/c/build/$(TEST_NAME)
else ifeq ($(detected_OS),Windows)
	PATH="$(PATH_TEST)" \
	./test/c/build/$(TEST_NAME)
else
	LD_LIBRARY_PATH="$(LD_LIBRARY_PATH_TEST)" \
	./test/c/build/$(TEST_NAME)
endif

SHIMS_FOR_TEST_C_INCLUDES ?= -I\"$(shell pwd)/test/c/build\"

LOGIN_TEST_INCLUDES ?= -I\"$(shell pwd)/build\"

test-c:
	rm -rf test/c/build
	$(MAKE) $(SHIMS_FOR_TEST_C)
	$(MAKE) TEST_DEPS=$(SHIMS_FOR_TEST_C) \
		TEST_INCLUDES=$(SHIMS_FOR_TEST_C_INCLUDES) \
		TEST_NAME=shims \
		test-c-template

	rm -rf test/c/build
	$(MAKE) $(NIMSTATUS)
	$(MAKE) TEST_DEPS=$(NIMSTATUS) \
		TEST_INCLUDES=$(LOGIN_TEST_INCLUDES) \
		TEST_NAME=login \
		test-c-template

test-nim: $(STATUSGO) $(SQLCIPHER)
ifeq ($(detected_OS),macOS)
	NIMSTATUS_CFLAGS="$(NIMSTATUS_CFLAGS)" \
	PCRE_LDFLAGS="$(PCRE_LDFLAGS)" \
	PCRE_STATIC="$(PCRE_STATIC)" \
	SSL_LDFLAGS="$(SSL_LDFLAGS)" \
	SSL_STATIC="$(SSL_STATIC)" \
	STATUSGO_LIB_DIR="$(STATUSGO_LIB_DIR)" \
	$(ENV_SCRIPT) nimble tests
else ifeq ($(detected_OS),Windows)
	NIMSTATUS_CFLAGS="$(NIMSTATUS_CFLAGS)" \
	PATH="$(PATH_TEST)" \
	PCRE_LDFLAGS="$(PCRE_LDFLAGS)" \
	PCRE_STATIC="$(PCRE_STATIC)" \
	SSL_LDFLAGS="$(SSL_LDFLAGS)" \
	SSL_STATIC="$(SSL_STATIC)" \
	STATUSGO_LIB_DIR="$(STATUSGO_LIB_DIR)" \
	$(ENV_SCRIPT) nimble tests
else
	LD_LIBRARY_PATH="$(LD_LIBRARY_PATH_TEST)" \
	NIMSTATUS_CFLAGS="$(NIMSTATUS_CFLAGS)" \
	PCRE_LDFLAGS="$(PCRE_LDFLAGS)" \
	PCRE_STATIC="$(PCRE_STATIC)" \
	SSL_LDFLAGS="$(SSL_LDFLAGS)" \
	SSL_STATIC="$(SSL_STATIC)" \
	STATUSGO_LIB_DIR="$(STATUSGO_LIB_DIR)" \
	$(ENV_SCRIPT) nimble tests
endif

test: test-nim test-c

endif # "variables.mk" was not included
