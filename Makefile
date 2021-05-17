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
	chat \
        chat2_waku \
	clean \
	clean-build-dirs \
	clean-migration-files \
	clean-sqlcipher \
	deps \
	migrations \
	nat-libs-sub \
	rlnlib-sub \
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

LIBMINIUPNPC := $(shell pwd)/vendor/nim-waku/vendor/nim-nat-traversal/vendor/miniupnp/miniupnpc/libminiupnpc.a
LIBNATPMP := $(shell pwd)/vendor/nim-waku/vendor/nim-nat-traversal/vendor/libnatpmp-upstream/libnatpmp.a

# nat-libs target assumes libs are in vendor subdir of working directory;
# also, in msys2 environment miniupnpc's Makefile.mingw's invocation of
# `wingenminiupnpcstrings.exe` will fail if containing directory is not in PATH
$(LIBMINIUPNPC):
	cd vendor/nim-waku && \
		PATH="$$(pwd)/vendor/nim-nat-traversal/vendor/miniupnp/miniupnpc:$${PATH}" \
		$(ENV_SCRIPT) $(MAKE) USE_SYSTEM_NIM=1 nat-libs

$(LIBNATPMP): $(LIBMINIUPNPC)

nat-libs-sub: $(LIBMINIUPNPC) $(LIBNATPMP)

deps: | deps-common nat-libs-sub rlnlib-sub

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

# For release builds of e.g. `examples/chat.nim`, it would be good to support
# older versions of macOS (older relative to the machine that's used to build
# the executable); for that to work linking must be done against builds of
# OpenSSL, PCRE, rln, etc. that are properly built to support the same older
# version of macOS we desire to target. That means compiling them or
# downloading pre-built homebrew bottles for that older version of macOS,
# tweaking Rust compiler flags, etc. That logic should probably be triggered
# with respect to `RELEASE=true` and then setting up and/or overriding
# variables and running targets in this Makefile (via `$(MAKE) [target]`) to do
# steps that are unnecessary apart from release builds for macOS.
# MACOSX_DEPLOYMENT_TARGET ?= 10.14

RELEASE ?= false

ifneq ($(RELEASE),false)
 LOG_LEVEL ?= INFO
else
 LOG_LEVEL ?= DEBUG
endif
ifeq ($(LOG_LEVEL),)
 override LOG_LEVEL = DEBUG
endif

ifneq ($(RELEASE),false)
 RLN_CARGO_BUILD_FLAGS := --release
 RLN_TARGET_SUBDIR := release
 ifeq ($(detected_OS),Windows)
  WIN_STATIC := true
 else
  WIN_STATIC := false
 endif
else
 RLN_TARGET_SUBDIR := debug
 WIN_STATIC := false
endif
RLN_LIB_DIR := $(shell pwd)/vendor/nim-waku/vendor/rln/target/$(RLN_TARGET_SUBDIR)
RLN_STATIC ?= true
ifeq ($(RLN_STATIC),false)
 ifeq ($(detected_OS),Windows)
  RLN_LIB := $(RLN_LIB_DIR)/librln.$(SHARED_LIB_EXT).a
 else
  RLN_LIB := $(RLN_LIB_DIR)/librln.$(SHARED_LIB_EXT)
 endif
else
 RLN_LIB := $(RLN_LIB_DIR)/librln.a
endif

$(RLN_LIB):
	cd vendor/nim-waku && \
		cargo build \
			-vv \
			$(RLN_CARGO_BUILD_FLAGS) \
			--manifest-path vendor/rln/Cargo.toml

ifeq ($(detected_OS),macOS)
	install_name_tool -id \
		@rpath/librln.$(SHARED_LIB_EXT) \
		$(RLN_LIB_DIR)/librln.$(SHARED_LIB_EXT)
endif

rlnlib-sub: $(RLN_LIB)

# These SSL variables and logic work like those in nim-sqlcipher's Makefile
ifeq ($(detected_OS),macOS)
 SSL_INCLUDE_DIR ?= /usr/local/opt/openssl/include
 ifeq ($(SSL_INCLUDE_DIR),)
  override SSL_INCLUDE_DIR = /usr/local/opt/openssl/include
 endif
 SSL_LIB_DIR ?= /usr/local/opt/openssl/lib
 ifeq ($(SSL_LIB_DIR),)
  override SSL_LIB_DIR = /usr/local/opt/openssl/lib
 endif
else ifeq ($(detected_OS),Windows)
 SSL_INCLUDE_DIR ?= /mingw64/include/openssl
 ifeq ($(SSL_INCLUDE_DIR),)
  override SSL_INCLUDE_DIR = /mingw64/include/openssl
 endif
 SSL_LIB_DIR ?= /mingw64/lib
 ifeq ($(SSL_LIB_DIR),)
  override SSL_LIB_DIR = /mingw64/lib
 endif
else
 SSL_INCLUDE_DIR ?= /usr/include
 ifeq ($(SSL_INCLUDE_DIR),)
  override SSL_INCLUDE_DIR = /usr/include
 endif
 SSL_LIB_DIR ?= /usr/lib/x86_64-linux-gnu
 ifeq ($(SSL_LIB_DIR),)
  override SSL_LIB_DIR = /usr/lib/x86_64-linux-gnu
 endif
endif
SSL_STATIC ?= true
ifndef SSL_LDFLAGS
 ifeq ($(SSL_STATIC),false)
  ifeq ($(detected_OS),Windows)
   SSL_LDFLAGS := -L$(shell cygpath -m $(SSL_LIB_DIR)) -lssl -lcrypto
  else
   SSL_LDFLAGS := -L$(SSL_LIB_DIR) -lssl -lcrypto
  endif
 else
  ifeq ($(detected_OS),Windows)
   SSL_LDFLAGS := $(shell cygpath -m $(SSL_LIB_DIR)/libssl.a) $(shell cygpath -m $(SSL_LIB_DIR)/libcrypto.a)
  else
   SSL_LDFLAGS := $(SSL_LIB_DIR)/libssl.a $(SSL_LIB_DIR)/libcrypto.a
  endif
 endif
 ifeq ($(detected_OS),Windows)
  SSL_LDFLAGS += -lws2_32
 endif
endif
NIM_PARAMS += --define:ssl
ifneq ($(SSL_STATIC),false)
 ifeq ($(detected_OS),Windows)
  NIM_PARAMS += --dynlibOverride:ssl- --dynlibOverride:crypto- --define:noOpenSSLHacks --define:sslVersion:"("
 else
  NIM_PARAMS += --dynlibOverride:ssl --dynlibOverride:crypto
 endif
endif

SQLCIPHER_STATIC ?= true
ifeq ($(SQLCIPHER_STATIC),false)
 SQLCIPHER ?= vendor/nim-sqlcipher/lib/libsqlcipher.$(SHARED_LIB_EXT)
else
 SQLCIPHER ?= vendor/nim-sqlcipher/lib/libsqlcipher.a
endif

$(SQLCIPHER): | deps
	echo -e $(BUILD_MSG) "$@"
	+ cd vendor/nim-sqlcipher && \
		$(ENV_SCRIPT) $(MAKE) \
			SQLCIPHER_STATIC=$(SQLCIPHER_STATIC) \
			SSL_INCLUDE_DIR="$(SSL_INCLUDE_DIR)" \
			SSL_LIB_DIR="$(SSL_LIB_DIR)" \
			SSL_STATIC=$(SSL_STATIC) \
			USE_SYSTEM_NIM=1 \
			sqlcipher

sqlcipher: $(SQLCIPHER)

ifeq ($(detected_OS),macOS)
 PCRE_INCLUDE_DIR ?= /usr/local/opt/pcre/include
 ifeq ($(PCRE_INCLUDE_DIR),)
  override PCRE_INCLUDE_DIR = /usr/local/opt/pcre/include
 endif
 PCRE_LIB_DIR ?= /usr/local/opt/pcre/lib
 ifeq ($(PCRE_LIB_DIR),)
  override PCRE_LIB_DIR = /usr/local/opt/pcre/lib
 endif
else ifeq ($(detected_OS),Windows)
 PCRE_INCLUDE_DIR ?= /mingw64/include
 ifeq ($(PCRE_INCLUDE_DIR),)
  override PCRE_INCLUDE_DIR = /mingw64/include
 endif
 PCRE_LIB_DIR ?= /mingw64/lib
 ifeq ($(PCRE_LIB_DIR),)
  override PCRE_LIB_DIR = /mingw64/lib
 endif
else
 PCRE_INCLUDE_DIR ?= /usr/include
 ifeq ($(PCRE_INCLUDE_DIR),)
  override PCRE_INCLUDE_DIR = /usr/include
 endif
 PCRE_LIB_DIR ?= /usr/lib/x86_64-linux-gnu
 ifeq ($(PCRE_LIB_DIR),)
  override PCRE_LIB_DIR = /usr/lib/x86_64-linux-gnu
 endif
endif
PCRE_STATIC ?= true
ifndef PCRE_LDFLAGS
 ifeq ($(PCRE_STATIC),false)
  ifeq ($(detected_OS),Windows)
   PCRE_LDFLAGS := -L$(shell cygpath -m $(PCRE_LIB_DIR)) -lpcre
  else
   PCRE_LDFLAGS := -L$(PCRE_LIB_DIR) -lpcre
  endif
 else
  ifeq ($(detected_OS),Windows)
   PCRE_LDFLAGS := $(shell cygpath -m $(PCRE_LIB_DIR)/libpcre.a)
  else
   PCRE_LDFLAGS := $(PCRE_LIB_DIR)/libpcre.a
  endif
 endif
endif
ifneq ($(PCRE_STATIC),false)
 NIM_PARAMS += --define:usePcreHeader --dynlibOverride:pcre
else ifeq ($(detected_OS),Windows)
 # to avoid Nim looking for pcre64.dll since we assume msys2 environment
 NIM_PARAMS += --define:usePcreHeader
endif

ifeq ($(detected_OS),macOS)
 NCURSES_LIB_DIR ?= /usr/local/opt/ncurses/lib
 ifeq ($(NCURSES_LIB_DIR),)
  override NCURSES_LIB_DIR = /usr/local/opt/ncurses/lib
 endif
else ifeq ($(detected_OS),Windows)
 NCURSES_LIB_DIR ?= /mingw64/lib
 ifeq ($(NCURSES_LIB_DIR),)
  override NCURSES_LIB_DIR = /mingw64/lib
 endif
else
 NCURSES_LIB_DIR ?= /usr/lib/x86_64-linux-gnu
 ifeq ($(NCURSES_LIB_DIR),)
  override NCURSES_LIB_DIR = /usr/lib/x86_64-linux-gnu
 endif
endif
NCURSES_STATIC ?= true
ifndef NCURSES_LDFLAGS
 ifeq ($(NCURSES_STATIC),false)
  ifeq ($(detected_OS),Windows)
   NCURSES_LDFLAGS := -L$(shell cygpath -m $(NCURSES_LIB_DIR)) -lncursesw
  else ifeq ($(detected_OS),macOS)
   NCURSES_LDFLAGS := -L$(NCURSES_LIB_DIR) -lncursesw -rpath $(NCURSES_LIB_DIR)
  else
   NCURSES_LDFLAGS := -L$(NCURSES_LIB_DIR) -lncursesw
  endif
 else
  ifeq ($(detected_OS),Windows)
   NCURSES_LDFLAGS := $(shell cygpath -m $(NCURSES_LIB_DIR)/libncursesw.a)
  else ifeq ($(detected_OS),macOS)
   NCURSES_LDFLAGS := $(NCURSES_LIB_DIR)/libncursesw.a
  else
   NCURSES_LDFLAGS := $(NCURSES_LIB_DIR)/libncursesw.a $(NCURSES_LIB_DIR)/libtinfo.a
  endif
 endif
endif
ifneq ($(PCRE_STATIC),false)
 NIM_PARAMS += --dynlibOverride:ncursesw
endif

ifndef RLN_LDFLAGS
 ifeq ($(RLN_STATIC),false)
  ifeq ($(detected_OS),macOS)
   RLN_LDFLAGS := -L$(RLN_LIB_DIR) -lrln -rpath $(RLN_LIB_DIR)
  else ifeq ($(detected_OS),Windows)
   ifneq ($(WIN_STATIC),false)
    RLN_LDFLAGS := -L$(shell cygpath -m $(RLN_LIB_DIR)) -lrln -luserenv
   else
    RLN_LDFLAGS := -L$(shell cygpath -m $(RLN_LIB_DIR)) -lrln
   endif
  else
   RLN_LDFLAGS := -L$(RLN_LIB_DIR) -lrln
  endif
 else
  ifeq ($(detected_OS),Windows)
   RLN_LDFLAGS := $(shell cygpath -m $(RLN_LIB)) -luserenv
  else ifeq ($(detected_OS),macOS)
   RLN_LDFLAGS := $(RLN_LIB)
  else
   RLN_LDFLAGS := $(RLN_LIB) -lm
  endif
 endif
endif
# ifneq ($(RLN_STATIC),false)
# usually `--dynlibOverride` is used in case of static linking and so would be
# used conditionally (see commented `ifneq` above), but because
# `vendor/nim-waku/waku/v2/protocol/waku_rln_relay/rln.nim` specifies the
# library with a relative path prefix (which isn't valid relative to root of
# this repo) it needs to be used in the case of shared or static linking
ifeq ($(detected_OS),Windows)
 NIM_PARAMS += --dynlibOverride:vendor\\rln\\target\\debug\\rln
else
 NIM_PARAMS += --dynlibOverride:vendor/rln/target/debug/librln
endif
# endif

ifndef NIMSTATUS_CFLAGS
 ifneq ($(PCRE_STATIC),false)
  ifeq ($(detected_OS),Windows)
   NIMSTATUS_CFLAGS := -DPCRE_STATIC -I$(shell cygpath -m $(PCRE_INCLUDE_DIR))
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
 ifeq ($(RLN_STATIC),false)
  PATH_NIMBLE ?= $(RLN_LIB_DIR):$(shell pwd)/$(shell dirname $(SQLCIPHER)):$${PATH}
 else
  PATH_NIMBLE ?= $(shell pwd)/$(shell dirname $(SQLCIPHER)):$${PATH}
 endif
 ifeq ($(PCRE_STATIC),false)
  ifeq ($(SSL_STATIC),false)
   ifeq ($(RLN_STATIC),false)
    LD_LIBRARY_PATH_NIMBLE ?= $(shell pwd)/$(shell dirname $(SQLCIPHER)):$(PCRE_LIB_DIR):$(SSL_LIB_DIR):$(RLN_LIB_DIR)$${LD_LIBRARY_PATH:+:$${LD_LIBRARY_PATH}}
   else
    LD_LIBRARY_PATH_NIMBLE ?= $(shell pwd)/$(shell dirname $(SQLCIPHER)):$(PCRE_LIB_DIR):$(SSL_LIB_DIR)$${LD_LIBRARY_PATH:+:$${LD_LIBRARY_PATH}}
   endif
  else
   ifeq ($(RLN_STATIC),false)
    LD_LIBRARY_PATH_NIMBLE ?= $(shell pwd)/$(shell dirname $(SQLCIPHER)):$(PCRE_LIB_DIR):$(RLN_LIB_DIR)$${LD_LIBRARY_PATH:+:$${LD_LIBRARY_PATH}}
   else
    LD_LIBRARY_PATH_NIMBLE ?= $(shell pwd)/$(shell dirname $(SQLCIPHER)):$(PCRE_LIB_DIR)$${LD_LIBRARY_PATH:+:$${LD_LIBRARY_PATH}}
   endif
  endif
 else
  ifeq ($(SSL_STATIC),false)
   ifeq ($(RLN_STATIC),false)
    LD_LIBRARY_PATH_NIMBLE ?= $(shell pwd)/$(shell dirname $(SQLCIPHER)):$(SSL_LIB_DIR):$(RLN_LIB_DIR)$${LD_LIBRARY_PATH:+:$${LD_LIBRARY_PATH}}
   else
    LD_LIBRARY_PATH_NIMBLE ?= $(shell pwd)/$(shell dirname $(SQLCIPHER)):$(SSL_LIB_DIR)$${LD_LIBRARY_PATH:+:$${LD_LIBRARY_PATH}}
   endif
  else
   ifeq ($(RLN_STATIC),false)
    LD_LIBRARY_PATH_NIMBLE ?= $(shell pwd)/$(shell dirname $(SQLCIPHER)):$(RLN_LIB_DIR)$${LD_LIBRARY_PATH:+:$${LD_LIBRARY_PATH}}
   else
    LD_LIBRARY_PATH_NIMBLE ?= $(shell pwd)/$(shell dirname $(SQLCIPHER))$${LD_LIBRARY_PATH:+:$${LD_LIBRARY_PATH}}
   endif
  endif
 endif
else
 ifeq ($(RLN_STATIC),false)
  PATH_NIMBLE ?= $(RLN_LIB_DIR):$${PATH}
 else
  PATH_NIMBLE ?= $${PATH}
 endif
 ifeq ($(PCRE_STATIC),false)
  ifeq ($(SSL_STATIC),false)
   ifeq ($(RLN_STATIC),false)
    LD_LIBRARY_PATH_NIMBLE ?= $(PCRE_LIB_DIR):$(SSL_LIB_DIR):$(RLN_LIB_DIR)$${LD_LIBRARY_PATH:+:$${LD_LIBRARY_PATH}}
   else
    LD_LIBRARY_PATH_NIMBLE ?= $(PCRE_LIB_DIR):$(SSL_LIB_DIR)$${LD_LIBRARY_PATH:+:$${LD_LIBRARY_PATH}}
   endif
  else
   ifeq ($(RLN_STATIC),false)
    LD_LIBRARY_PATH_NIMBLE ?= $(PCRE_LIB_DIR):$(RLN_LIB_DIR)$${LD_LIBRARY_PATH:+:$${LD_LIBRARY_PATH}}
   else
    LD_LIBRARY_PATH_NIMBLE ?= $(PCRE_LIB_DIR)$${LD_LIBRARY_PATH:+:$${LD_LIBRARY_PATH}}
   endif
  endif
 else
  ifeq ($(SSL_STATIC),false)
   ifeq ($(RLN_STATIC),false)
    LD_LIBRARY_PATH_NIMBLE ?= $(SSL_LIB_DIR):$(RLN_LIB_DIR)$${LD_LIBRARY_PATH:+:$${LD_LIBRARY_PATH}}
   else
    LD_LIBRARY_PATH_NIMBLE ?= $(SSL_LIB_DIR)$${LD_LIBRARY_PATH}}
   endif
  else
   ifeq ($(RLN_STATIC),false)
    LD_LIBRARY_PATH_NIMBLE ?= $(RLN_LIB_DIR)$${LD_LIBRARY_PATH:+:$${LD_LIBRARY_PATH}}
   else
    LD_LIBRARY_PATH_NIMBLE ?= $${LD_LIBRARY_PATH}}
   endif
  endif
 endif
endif

ifeq ($(SQLCIPHER_STATIC),false)
 ifeq ($(detected_OS),Windows)
  SQLCIPHER_LDFLAGS := -L$(shell cygpath -m $(shell pwd)/$(shell dirname $(SQLCIPHER))) -lsqlcipher
 else
  SQLCIPHER_LDFLAGS := -L$(shell pwd)/$(shell dirname $(SQLCIPHER)) -lsqlcipher
 endif
else
 ifeq ($(detected_OS),Windows)
  SQLCIPHER_LDFLAGS := $(shell cygpath -m $(shell pwd)/$(SQLCIPHER))
 else
  SQLCIPHER_LDFLAGS := $(shell pwd)/$(SQLCIPHER)
 endif
endif

RUN_AFTER_BUILD ?= true

# MACOSX_DEPLOYMENT_TARGET="$(MACOSX_DEPLOYMENT_TARGET)" \

chat: $(SQLCIPHER) $(MIGRATIONS)
ifeq ($(detected_OS),macOS)
	LOG_LEVEL=$(LOG_LEVEL) \
	NCURSES_LDFLAGS="$(NCURSES_LDFLAGS)" \
	NCURSES_STATIC=$(NCURSES_STATIC) \
	NIMSTATUS_CFLAGS="$(NIMSTATUS_CFLAGS)" \
	PCRE_LDFLAGS="$(PCRE_LDFLAGS)" \
	PCRE_STATIC=$(PCRE_STATIC) \
	RELEASE=$(RELEASE) \
	RLN_LDFLAGS="$(RLN_LDFLAGS)" \
	RLN_LIB_DIR="$(RLN_LIB_DIR)" \
	RLN_STATIC=$(RLN_STATIC) \
	RUN_AFTER_BUILD=$(RUN_AFTER_BUILD) \
	SQLCIPHER_LDFLAGS="$(SQLCIPHER_LDFLAGS)" \
	SSL_LDFLAGS="$(SSL_LDFLAGS)" \
	SSL_STATIC=$(SSL_STATIC) \
	WIN_STATIC=$(WIN_STATIC) \
	$(ENV_SCRIPT) nimble chat
else ifeq ($(detected_OS),Windows)
	LOG_LEVEL=$(LOG_LEVEL) \
	NCURSES_LDFLAGS="$(NCURSES_LDFLAGS)" \
	NCURSES_STATIC=$(NCURSES_STATIC) \
	NIMSTATUS_CFLAGS="$(NIMSTATUS_CFLAGS)" \
	PATH="$(PATH_NIMBLE)" \
	PCRE_LDFLAGS="$(PCRE_LDFLAGS)" \
	PCRE_STATIC=$(PCRE_STATIC) \
	RELEASE=$(RELEASE) \
	RLN_LDFLAGS="$(RLN_LDFLAGS)" \
	RLN_LIB_DIR="$(RLN_LIB_DIR)" \
	RLN_STATIC=$(RLN_STATIC) \
	RUN_AFTER_BUILD=$(RUN_AFTER_BUILD) \
	SQLCIPHER_LDFLAGS="$(SQLCIPHER_LDFLAGS)" \
	SSL_LDFLAGS="$(SSL_LDFLAGS)" \
	SSL_STATIC=$(SSL_STATIC) \
	WIN_STATIC=$(WIN_STATIC) \
	$(ENV_SCRIPT) nimble chat
else
	LD_LIBRARY_PATH="$(LD_LIBRARY_PATH_NIMBLE)" \
	LOG_LEVEL=$(LOG_LEVEL) \
	NCURSES_LDFLAGS="$(NCURSES_LDFLAGS)" \
	NCURSES_STATIC=$(NCURSES_STATIC) \
	NIMSTATUS_CFLAGS="$(NIMSTATUS_CFLAGS)" \
	PCRE_LDFLAGS="$(PCRE_LDFLAGS)" \
	PCRE_STATIC=$(PCRE_STATIC) \
	RELEASE=$(RELEASE) \
	RLN_LDFLAGS="$(RLN_LDFLAGS)" \
	RLN_LIB_DIR="$(RLN_LIB_DIR)" \
	RLN_STATIC=$(RLN_STATIC) \
	RUN_AFTER_BUILD=$(RUN_AFTER_BUILD) \
	SQLCIPHER_LDFLAGS="$(SQLCIPHER_LDFLAGS)" \
	SSL_LDFLAGS="$(SSL_LDFLAGS)" \
	SSL_STATIC=$(SSL_STATIC) \
	WIN_STATIC=$(WIN_STATIC) \
	$(ENV_SCRIPT) nimble chat
endif

chat2_waku: $(SQLCIPHER) $(MIGRATIONS)
ifeq ($(detected_OS),macOS)
	LOG_LEVEL=$(LOG_LEVEL) \
	NIMSTATUS_CFLAGS="$(NIMSTATUS_CFLAGS)" \
	PCRE_LDFLAGS="$(PCRE_LDFLAGS)" \
	PCRE_STATIC=$(PCRE_STATIC) \
	RELEASE=$(RELEASE) \
	RLN_LDFLAGS="$(RLN_LDFLAGS)" \
	RLN_LIB_DIR="$(RLN_LIB_DIR)" \
	RLN_STATIC=$(RLN_STATIC) \
	RUN_AFTER_BUILD=$(RUN_AFTER_BUILD) \
	SQLCIPHER_LDFLAGS="$(SQLCIPHER_LDFLAGS)" \
	SSL_LDFLAGS="$(SSL_LDFLAGS)" \
	SSL_STATIC=$(SSL_STATIC) \
	WIN_STATIC=$(WIN_STATIC) \
	$(ENV_SCRIPT) nimble chat2_waku
else ifeq ($(detected_OS),Windows)
	LOG_LEVEL=$(LOG_LEVEL) \
	NIMSTATUS_CFLAGS="$(NIMSTATUS_CFLAGS)" \
	PATH="$(PATH_NIMBLE)" \
	PCRE_LDFLAGS="$(PCRE_LDFLAGS)" \
	PCRE_STATIC=$(PCRE_STATIC) \
	RELEASE=$(RELEASE) \
	RLN_LDFLAGS="$(RLN_LDFLAGS)" \
	RLN_LIB_DIR="$(RLN_LIB_DIR)" \
	RLN_STATIC=$(RLN_STATIC) \
	RUN_AFTER_BUILD=$(RUN_AFTER_BUILD) \
	SQLCIPHER_LDFLAGS="$(SQLCIPHER_LDFLAGS)" \
	SSL_LDFLAGS="$(SSL_LDFLAGS)" \
	SSL_STATIC=$(SSL_STATIC) \
	WIN_STATIC=$(WIN_STATIC) \
	$(ENV_SCRIPT) nimble chat2_waku
else
	LD_LIBRARY_PATH="$(LD_LIBRARY_PATH_NIMBLE)" \
	LOG_LEVEL=$(LOG_LEVEL) \
	NIMSTATUS_CFLAGS="$(NIMSTATUS_CFLAGS)" \
	PCRE_LDFLAGS="$(PCRE_LDFLAGS)" \
	PCRE_STATIC=$(PCRE_STATIC) \
	RELEASE=$(RELEASE) \
	RLN_LDFLAGS="$(RLN_LDFLAGS)" \
	RLN_LIB_DIR="$(RLN_LIB_DIR)" \
	RLN_STATIC=$(RLN_STATIC) \
	RUN_AFTER_BUILD=$(RUN_AFTER_BUILD) \
	SQLCIPHER_LDFLAGS="$(SQLCIPHER_LDFLAGS)" \
	SSL_LDFLAGS="$(SSL_LDFLAGS)" \
	SSL_STATIC=$(SSL_STATIC) \
	WIN_STATIC=$(WIN_STATIC) \
	$(ENV_SCRIPT) nimble chat2_waku
endif

test: $(SQLCIPHER) $(MIGRATIONS)
ifeq ($(detected_OS),macOS)
	LOG_LEVEL=$(LOG_LEVEL) \
	NIMSTATUS_CFLAGS="$(NIMSTATUS_CFLAGS)" \
	PCRE_LDFLAGS="$(PCRE_LDFLAGS)" \
	PCRE_STATIC=$(PCRE_STATIC) \
	RELEASE=$(RELEASE) \
	RLN_LDFLAGS="$(RLN_LDFLAGS)" \
	RLN_LIB_DIR="$(RLN_LIB_DIR)" \
	RLN_STATIC=$(RLN_STATIC) \
	RUN_AFTER_BUILD=$(RUN_AFTER_BUILD) \
	SQLCIPHER_LDFLAGS="$(SQLCIPHER_LDFLAGS)" \
	SSL_LDFLAGS="$(SSL_LDFLAGS)" \
	SSL_STATIC=$(SSL_STATIC) \
	WIN_STATIC=$(WIN_STATIC) \
	$(ENV_SCRIPT) nimble tests
else ifeq ($(detected_OS),Windows)
	LOG_LEVEL=$(LOG_LEVEL) \
	NIMSTATUS_CFLAGS="$(NIMSTATUS_CFLAGS)" \
	PATH="$(PATH_NIMBLE)" \
	PCRE_LDFLAGS="$(PCRE_LDFLAGS)" \
	PCRE_STATIC=$(PCRE_STATIC) \
	RELEASE=$(RELEASE) \
	RLN_LDFLAGS="$(RLN_LDFLAGS)" \
	RLN_LIB_DIR="$(RLN_LIB_DIR)" \
	RLN_STATIC=$(RLN_STATIC) \
	RUN_AFTER_BUILD=$(RUN_AFTER_BUILD) \
	SQLCIPHER_LDFLAGS="$(SQLCIPHER_LDFLAGS)" \
	SSL_LDFLAGS="$(SSL_LDFLAGS)" \
	SSL_STATIC=$(SSL_STATIC) \
	WIN_STATIC=$(WIN_STATIC) \
	$(ENV_SCRIPT) nimble tests
else
	LD_LIBRARY_PATH="$(LD_LIBRARY_PATH_NIMBLE)" \
	LOG_LEVEL=$(LOG_LEVEL) \
	NIMSTATUS_CFLAGS="$(NIMSTATUS_CFLAGS)" \
	PCRE_LDFLAGS="$(PCRE_LDFLAGS)" \
	PCRE_STATIC=$(PCRE_STATIC) \
	RELEASE=$(RELEASE) \
	RLN_LDFLAGS="$(RLN_LDFLAGS)" \
	RLN_LIB_DIR="$(RLN_LIB_DIR)" \
	RLN_STATIC=$(RLN_STATIC) \
	RUN_AFTER_BUILD=$(RUN_AFTER_BUILD) \
	SQLCIPHER_LDFLAGS="$(SQLCIPHER_LDFLAGS)" \
	SSL_LDFLAGS="$(SSL_LDFLAGS)" \
	SSL_STATIC=$(SSL_STATIC) \
	WIN_STATIC=$(WIN_STATIC) \
	$(ENV_SCRIPT) nimble tests
endif

endif # "variables.mk" was not included
