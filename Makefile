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
LINK_PCRE := 0

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
 detected_OS := $(strip $(shell uname)) # e.g. Linux
endif

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

# nim-nat-traversal assumes nat-libs are available in its parent's vendor
nat-libs-sub: # could we just pub nat-libs in nim-status' vendor?
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
 STATUSGO_LIB_DIR := $(CURDIR)/$(dir $(STATUSGO))
else
 STATUSGO_LIB_DIR := $(dir $(STATUSGO))
endif

$(STATUSGO): | deps
	echo -e $(BUILD_MSG) "status-go"
	+ cd vendor/status-go && \
		$(MAKE) statusgo-shared-library $(HANDLE_OUTPUT)

status-go: $(STATUSGO)

# These SSL variables and logic work like those in nim-sqlcipher's Makefile
SSL_INCLUDE_DIR ?= /usr/include
ifeq ($(SSL_INCLUDE_DIR),)
 override SSL_INCLUDE_DIR = /usr/include
endif
SSL_LIB_DIR ?= /usr/lib/x86_64-linux-gnu
ifeq ($(SSL_LIB_DIR),)
 override SSL_LIB_DIR = /usr/lib/x86_64-linux-gnu
endif

SSL_CFLAGS ?= -I$(SSL_INCLUDE_DIR)
SSL_STATIC ?= true
ifndef SSL_LDFLAGS
 ifeq ($(SSL_STATIC),false)
  SSL_LDFLAGS := -L$(SSL_LIB_DIR) -lcrypto
 else
  SSL_LDFLAGS := -L$(SSL_LIB_DIR) $(SSL_LIB_DIR)/libcrypto.a
 endif
 ifeq ($(detected_OS),Windows)
  SSL_LDFLAGS += -lws2_32
 endif
endif

SQLCIPHER ?= vendor/nim-sqlcipher/sqlcipher/sqlite.nim

$(SQLCIPHER): | deps
	echo -e $(BUILD_MSG) "Nim wrapper for SQLCipher"
	+ cd vendor/nim-sqlcipher && \
		$(ENV_SCRIPT) $(MAKE) USE_SYSTEM_NIM=1 sqlite.nim
	# USE_SYSTEM_NIM=1 results in one spurious and error-causing line at
	# the top of vendor/nim-sqlcipher/sqlcipher/sqlite.nim
	# !!! bump to latest nimbus-build-system to pick up a fix and drop
	# usage of tail+mv below !!!
	tail -n +2 vendor/nim-sqlcipher/sqlcipher/sqlite.nim \
		> vendor/nim-sqlcipher/sqlcipher/sqlite.nim.2
	mv vendor/nim-sqlcipher/sqlcipher/sqlite.nim.2 \
		vendor/nim-sqlcipher/sqlcipher/sqlite.nim

sqlcipher: $(SQLCIPHER)

PCRE_INCLUDE_DIR ?= /usr/include
ifeq ($(PCRE_INCLUDE_DIR),)
 override PCRE_INCLUDE_DIR = /usr/include
endif
PCRE_LIB_DIR ?= /usr/lib/x86_64-linux-gnu
ifeq ($(PCRE_LIB_DIR),)
 override PCRE_LIB_DIR = /usr/lib/x86_64-linux-gnu
endif

PCRE_STATIC ?= true
ifndef PCRE_CFLAGS
 ifneq ($(PCRE_STATIC),false)
  ifeq ($(detected_OS),Windows)
   PCRE_CFLAGS := -DPCRE_STATIC -I$(PCRE_INCLUDE_DIR)
  else
   PCRE_CFLAGS := -I$(PCRE_INCLUDE_DIR)
  endif
 endif
endif
ifndef PCRE_LDFLAGS
 ifeq ($(PCRE_STATIC),false)
  # on Windows (at least) need to check if the libpcre being dynamically linked
  # is the one spec'd here or something else that Nim has in mind
  PCRE_LDFLAGS := -L$(PCRE_LIB_DIR) -lpcre
 else
  NIM_PARAMS += --define:usePcreHeader
  PCRE_LDFLAGS := -L$(PCRE_LIB_DIR) $(PCRE_LIB_DIR)/libpcre.a
 endif
endif

NIMSTATUS ?= build/nim_status.a

$(NIMSTATUS): $(SQLCIPHER)
	echo -e $(BUILD_MSG) "$@"
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

test-c-template: $(STATUSGO) clean-data-dirs create-data-dirs
	echo "Compiling 'test/c/$(TEST_NAME)'"
	+ mkdir -p test/c/build
	$(ENV_SCRIPT) $(CC) \
		$(PCRE_CFLAGS) \
		$(SSL_CFLAGS) \
		$(TEST_INCLUDES) \
		-I"$(CURDIR)/vendor/nimbus-build-system/vendor/Nim/lib" \
		test/c/$(TEST_NAME).c \
		$(TEST_DEPS) \
		$(PCRE_LDFLAGS) \
		$(SSL_LDFLAGS) \
		-L$(STATUSGO_LIB_DIR) \
		-lstatus \
		-lm \
		-pthread \
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
	PATH="$(STATUSGO_LIB_DIR):$$PATH" \
	./test/c/build/$(TEST_NAME)
else
	LD_LIBRARY_PATH="$(STATUSGO_LIB_DIR)$${LD_LIBRARY_PATH:+:$${LD_LIBRARY_PATH}}" \
	./test/c/build/$(TEST_NAME)
endif

SHIMS_FOR_TEST_C_INCLUDES ?= -I\"$(CURDIR)/test/c/build\"

LOGIN_TEST_INCLUDES ?= -I\"$(CURDIR)/build\"

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
	PCRE_STATIC="$(PCRE_STATIC)" \
	PCRE_CFLAGS="$(PCRE_CFLAGS)" \
	SSL_CFLAGS="$(SSL_CFLAGS)" \
	PCRE_LDFLAGS="$(PCRE_LDFLAGS)" \
	SSL_LDFLAGS="$(SSL_LDFLAGS)" \
	STATUSGO_LIB_DIR="$(STATUSGO_LIB_DIR)" \
	$(ENV_SCRIPT) nimble tests
else ifeq ($(detected_OS),Windows)
	PATH="$(STATUSGO_LIB_DIR):$$PATH" \
	PCRE_STATIC="$(PCRE_STATIC)" \
	PCRE_CFLAGS="$(PCRE_CFLAGS)" \
	SSL_CFLAGS="$(SSL_CFLAGS)" \
	PCRE_LDFLAGS="$(PCRE_LDFLAGS)" \
	SSL_LDFLAGS="$(SSL_LDFLAGS)" \
	STATUSGO_LIB_DIR="$(STATUSGO_LIB_DIR)" \
	$(ENV_SCRIPT) nimble tests
else
	LD_LIBRARY_PATH="$(STATUSGO_LIB_DIR)$${LD_LIBRARY_PATH:+:$${LD_LIBRARY_PATH}}" \
	PCRE_STATIC="$(PCRE_STATIC)" \
	PCRE_CFLAGS="$(PCRE_CFLAGS)" \
	SSL_CFLAGS="$(SSL_CFLAGS)" \
	PCRE_LDFLAGS="$(PCRE_LDFLAGS)" \
	SSL_LDFLAGS="$(SSL_LDFLAGS)" \
	STATUSGO_LIB_DIR="$(STATUSGO_LIB_DIR)" \
	$(ENV_SCRIPT) nimble tests
endif

test: test-nim test-c

endif # "variables.mk" was not included
