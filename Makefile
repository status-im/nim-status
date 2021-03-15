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
	clean-migration-files \
	clean-sqlcipher \
	deps \
	migrations \
	nat-libs-sub \
	sqlcipher \
	test \
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

all: sqlcipher

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

clean: | clean-common clean-build-dirs clean-migration-files clean-sqlcipher

clean-build-dirs:
	rm -rf \
		test/build

clean-migration-files:
	rm -f \
		nim_status/migrations/sql_scripts_accounts.nim \
		nim_status/migrations/sql_scripts_app.nim

clean-sqlcipher:
	cd vendor/nim-sqlcipher && $(MAKE) clean-build-dirs
	cd vendor/nim-sqlcipher && $(MAKE) clean-sqlcipher

# nat-libs target assumes libs are in vendor subdir of working directory;
# also, in msys2 environment miniupnpc's Makefile.mingw's invocation of
# `wingenminiupnpcstrings.exe` will fail if containing directory is not in PATH
nat-libs-sub:
	cd vendor/nim-waku && \
		PATH="$$(pwd)/vendor/nim-nat-traversal/vendor/miniupnp/miniupnpc:$${PATH}" \
		$(ENV_SCRIPT) $(MAKE) USE_SYSTEM_NIM=1 nat-libs

deps: | deps-common nat-libs-sub

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

ifeq ($(SQLCIPHER_STATIC),false)
 SQLCIPHER ?= vendor/nim-sqlcipher/lib/libsqlcipher.$(SHARED_LIB_EXT)
else
 SQLCIPHER ?= vendor/nim-sqlcipher/lib/libsqlcipher.a
endif

$(SQLCIPHER): | deps
	echo -e $(BUILD_MSG) "$@"
	+ cd vendor/nim-sqlcipher && \
		$(ENV_SCRIPT) $(MAKE) USE_SYSTEM_NIM=1 sqlcipher

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
  PCRE_LDFLAGS := -L$(PCRE_LIB_DIR) -lpcre
 else
  PCRE_LDFLAGS := $(PCRE_LIB_DIR)/libpcre.a
 endif
endif
ifneq ($(PCRE_STATIC),false)
 NIM_PARAMS += --define:usePcreHeader --dynlibOverride:pcre
else ifeq ($(detected_OS),Windows)
 # to avoid Nim looking for pcre64.dll since we assume msys2 environment
 NIM_PARAMS += --define:usePcreHeader
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

MIGRATIONS ?= nim_status/migrations/sql_scripts_app.nim

$(MIGRATIONS): | deps
	$(ENV_SCRIPT) nim c $(NIM_PARAMS) --verbosity:0 nim_status/migrations/sql_generate.nim
	nim_status/migrations/sql_generate nim_status/migrations/accounts > nim_status/migrations/sql_scripts_accounts.nim
	nim_status/migrations/sql_generate nim_status/migrations/app > nim_status/migrations/sql_scripts_app.nim

migrations: clean-migration-files $(MIGRATIONS)

ifeq ($(SQLCIPHER_STATIC),false)
 PATH_TEST ?= $(shell pwd)/$(shell dirname $(SQLCIPHER)):$${PATH}
 ifeq ($(PCRE_STATIC),false)
  ifeq ($(SSL_STATIC),false)
   LD_LIBRARY_PATH_TEST ?= $(shell pwd)/$(shell dirname $(SQLCIPHER)):$(PCRE_LIB_DIR):$(SSL_LIB_DIR)$${LD_LIBRARY_PATH:+:$${LD_LIBRARY_PATH}}
  else
   LD_LIBRARY_PATH_TEST ?= $(shell pwd)/$(shell dirname $(SQLCIPHER)):$(PCRE_LIB_DIR)$${LD_LIBRARY_PATH:+:$${LD_LIBRARY_PATH}}
  endif
 else
  ifeq ($(SSL_STATIC),false)
   LD_LIBRARY_PATH_TEST ?= $(shell pwd)/$(shell dirname $(SQLCIPHER)):$(SSL_LIB_DIR)$${LD_LIBRARY_PATH:+:$${LD_LIBRARY_PATH}}
  else
   LD_LIBRARY_PATH_TEST ?= $(shell pwd)/$(shell dirname $(SQLCIPHER))$${LD_LIBRARY_PATH:+:$${LD_LIBRARY_PATH}}
  endif
 endif
else
 PATH_TEST ?= $${PATH}
 ifeq ($(PCRE_STATIC),false)
  ifeq ($(SSL_STATIC),false)
   LD_LIBRARY_PATH_TEST ?= $(PCRE_LIB_DIR):$(SSL_LIB_DIR)$${LD_LIBRARY_PATH:+:$${LD_LIBRARY_PATH}}
  else
   LD_LIBRARY_PATH_TEST ?= $(PCRE_LIB_DIR)$${LD_LIBRARY_PATH:+:$${LD_LIBRARY_PATH}}
  endif
 else
  ifeq ($(SSL_STATIC),false)
   LD_LIBRARY_PATH_TEST ?= $(SSL_LIB_DIR)$${LD_LIBRARY_PATH:+:$${LD_LIBRARY_PATH}}
  else
   LD_LIBRARY_PATH_TEST ?= $${LD_LIBRARY_PATH}}
  endif
 endif
endif

ifeq ($(SQLCIPHER_STATIC),false)
 ifeq ($(detected_OS),Windows)
  SQLCIPHER_LDFLAGS_TEST := -L$(shell cygpath -m $(shell pwd)/$(shell dirname $(SQLCIPHER))) -lsqlcipher
 else
  SQLCIPHER_LDFLAGS_TEST := -L$(shell pwd)/$(shell dirname $(SQLCIPHER)) -lsqlcipher
 endif
else
 ifeq ($(detected_OS),Windows)
  SQLCIPHER_LDFLAGS_TEST := $(shell cygpath -m $(shell pwd)/$(SQLCIPHER))
 else
  SQLCIPHER_LDFLAGS_TEST := $(shell pwd)/$(SQLCIPHER)
 endif
endif

ifeq ($(detected_OS),Linux)
 PLATFORM_FLAGS_TEST_C ?= -ldl
else ifeq ($(detected_OS),macOS)
 PLATFORM_FLAGS_TEST_C ?= -Wl,-headerpad_max_install_names
endif

test: $(SQLCIPHER) $(MIGRATIONS)
ifeq ($(detected_OS),macOS)
	NIMSTATUS_CFLAGS="$(NIMSTATUS_CFLAGS)" \
	PCRE_LDFLAGS="$(PCRE_LDFLAGS)" \
	PCRE_STATIC="$(PCRE_STATIC)" \
	SQLCIPHER_LDFLAGS="$(SQLCIPHER_LDFLAGS_TEST)" \
	SSL_LDFLAGS="$(SSL_LDFLAGS)" \
	SSL_STATIC="$(SSL_STATIC)" \
	$(ENV_SCRIPT) nimble tests
else ifeq ($(detected_OS),Windows)
	NIMSTATUS_CFLAGS="$(NIMSTATUS_CFLAGS)" \
	PATH="$(PATH_TEST)" \
	PCRE_LDFLAGS="$(PCRE_LDFLAGS)" \
	PCRE_STATIC="$(PCRE_STATIC)" \
	SQLCIPHER_LDFLAGS="$(SQLCIPHER_LDFLAGS_TEST)" \
	SSL_LDFLAGS="$(SSL_LDFLAGS)" \
	SSL_STATIC="$(SSL_STATIC)" \
	$(ENV_SCRIPT) nimble tests
else
	LD_LIBRARY_PATH="$(LD_LIBRARY_PATH_TEST)" \
	NIMSTATUS_CFLAGS="$(NIMSTATUS_CFLAGS)" \
	PCRE_LDFLAGS="$(PCRE_LDFLAGS)" \
	PCRE_STATIC="$(PCRE_STATIC)" \
	SQLCIPHER_LDFLAGS="$(SQLCIPHER_LDFLAGS_TEST)" \
	SSL_LDFLAGS="$(SSL_LDFLAGS)" \
	SSL_STATIC="$(SSL_STATIC)" \
	$(ENV_SCRIPT) nimble tests
endif

endif # "variables.mk" was not included
