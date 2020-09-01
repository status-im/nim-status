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
	bottles \
	bottles-dummy \
	bottles-macos \
	clean \
	clean-build-dirs \
	clean-data-dirs \
	create-data-dirs \
	deps \
	nim_status \
	status-go \
	test \
	test-c-shims \
	test-c-login \
	tests \
	tests-c \
	tests-nim \
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

ifeq ($(OS),Windows_NT)     # is Windows_NT on XP, 2000, 7, Vista, 10...
 detected_OS := Windows
else
 detected_OS := $(strip $(shell uname))
endif

ifeq ($(detected_OS),Darwin)
 BOTTLES_TARGET := bottles-macos
 MACOSX_DEPLOYMENT_TARGET := 10.13
 export MACOSX_DEPLOYMENT_TARGET
 CGO_CFLAGS := -mmacosx-version-min=10.13
 export CGO_CFLAGS
 CFLAGS := -mmacosx-version-min=10.13
 export CFLAGS
 LIBSTATUS_EXT := dylib
else ifeq ($(detected_OS),Windows)
 LIBSTATUS_EXT := dll
else
 BOTTLES_TARGET := bottles-dummy
 LIBSTATUS_EXT := so
endif

bottles: $(BOTTLES_TARGET)

bottles-dummy: ;

BOTTLE_OPENSSL := bottles/openssl/INSTALL_RECEIPT.json

$(BOTTLE_OPENSSL):
	rm -rf bottles/Downloads/openssl* bottles/openssl*
	mkdir -p bottles/Downloads
	cd bottles/Downloads && \
	wget -O openssl.tar.gz "https://bintray.com/homebrew/bottles/download_file?file_path=openssl%401.1-1.1.1g.high_sierra.bottle.tar.gz" && \
	tar xzf openssl* && \
	mv openssl@1.1/1.1.1g ../openssl

BOTTLE_PCRE := bottles/pcre/INSTALL_RECEIPT.json

$(BOTTLE_PCRE):
	rm -rf bottles/Downloads/pcre* bottles/pcre*
	mkdir -p bottles/Downloads
	cd bottles/Downloads && \
	wget -O pcre.tar.gz "https://bintray.com/homebrew/bottles/download_file?file_path=pcre-8.44.high_sierra.bottle.tar.gz" && \
	tar xzf pcre* && \
	mv pcre/8.44 ../pcre

bottles-macos: | $(BOTTLE_OPENSSL) $(BOTTLE_PCRE)
	rm -rf bottles/Downloads

ifeq ($(detected_OS),Darwin)
 NIM_DEP_LIBS := bottles/openssl/lib/libcrypto.a \
		 bottles/openssl/lib/libssl.a \
		 bottles/pcre/lib/libpcre.a
else ifeq ($(detected_OS),Linux)
 NIM_DEP_LIBS := -lcrypto -lssl -lpcre
endif

NIM_WINDOWS_PREBUILT_DLLS ?= DLLs/pcre.dll
NIM_WINDOWS_PREBUILT_DLLDIR := $(shell pwd)/$(shell dirname "$(NIM_WINDOWS_PREBUILT_DLLS)")

$(NIM_WINDOWS_PREBUILT_DLLS):
ifeq ($(detected_OS),Windows)
	echo -e "\e[92mFetching:\e[39m prebuilt DLLs from nim-lang.org"
	rm -rf DLLs
	mkdir -p DLLs
	cd DLLs && \
	wget https://nim-lang.org/download/dlls.zip && \
	unzip dlls.zip
endif

deps: | deps-common bottles $(NIM_WINDOWS_PREBUILT_DLLS)

update: | update-common

ifeq ($(detected_OS),Darwin)
 FRAMEWORKS := -framework CoreFoundation -framework CoreServices -framework IOKit -framework Security
 NIM_PARAMS := $(NIM_PARAMS) -L:"$(FRAMEWORKS)"
endif

# TODO: control debug/release builds with a Make var
# We need `-d:debug` to get Nim's default stack traces.
NIM_PARAMS += -d:debug

STATUSGO := vendor/status-go/build/bin/libstatus.$(LIBSTATUS_EXT)
STATUSGO_LIBDIR := $(shell pwd)/$(shell dirname "$(STATUSGO)")
export STATUSGO_LIBDIR

status-go: $(STATUSGO)
$(STATUSGO): | deps
	echo -e $(BUILD_MSG) "status-go"
	+ cd vendor/status-go && \
	  $(MAKE) statusgo-shared-library $(HANDLE_OUTPUT)

NIMSTATUS := build/nim_status.a

nim_status: | $(NIMSTATUS)
$(NIMSTATUS): | deps
	echo -e $(BUILD_MSG) "$@" && \
	$(ENV_SCRIPT) nim c \
		$(NIM_PARAMS) \
		--app:staticLib \
		--header \
		--noMain \
		-o:$@ \
		src/nim_status/c/nim_status.nim
	cp nimcache/debug/nim_status/nim_status.h build/nim_status.h
	mv nim_status.a build/

SHIMS := tests/c/build/shims.a

shims: | $(SHIMS)
$(SHIMS): | deps
	echo -e $(BUILD_MSG) "$@" && \
	$(ENV_SCRIPT) nim c \
		$(NIM_PARAMS) \
		--app:staticLib \
		--header \
		--noMain \
		-o:$@ \
		tests/c/shims.nim
	cp nimcache/debug/shims/shims.h tests/c/build/shims.h
	mv shims.a tests/c/build/

test-c-template: | $(STATUSGO) clean-data-dirs create-data-dirs
	mkdir -p tests/c/build
	echo "Compiling 'tests/c/$(TEST_NAME)'"
	$(ENV_SCRIPT) $(CC) \
		$(TEST_INCLUDES) \
		-I"$(CURDIR)/vendor/nimbus-build-system/vendor/Nim/lib" \
		tests/c/$(TEST_NAME).c \
		$(TEST_DEPS) \
		$(NIM_DEP_LIBS) \
		-L$(STATUSGO_LIBDIR) \
		-lstatus \
		$(FRAMEWORKS) \
		-lm \
		-pthread \
		-o tests/c/build/$(TEST_NAME)
	[[ $(detected_OS) = Darwin ]] && \
	install_name_tool -add_rpath \
		"$(STATUSGO_LIBDIR)" \
		tests/c/build/$(TEST_NAME) && \
	install_name_tool -change \
		libstatus.dylib \
		@rpath/libstatus.dylib \
		tests/c/build/$(TEST_NAME) || true
	echo "Executing 'tests/c/build/$(TEST_NAME)'"
ifeq ($(detected_OS),Darwin)
	./tests/c/build/$(TEST_NAME)
else ifeq ($(detected_OS),Windows)
	PATH="$(STATUSGO_LIBDIR):$(NIM_WINDOWS_PREBUILT_DLLDIR):/usr/bin:/bin:$$PATH" \
	./tests/c/build/$(TEST_NAME)
else
	LD_LIBRARY_PATH="$(STATUSGO_LIBDIR)" \
	./tests/c/build/$(TEST_NAME)
endif

SHIMS_INCLUDES := -I\"$(CURDIR)/tests/c/build\"

test-c-shims: | $(SHIMS)
	$(MAKE) TEST_DEPS=$(SHIMS) \
		TEST_INCLUDES=$(SHIMS_INCLUDES) \
		TEST_NAME=shims \
		test-c-template

LOGIN_INCLUDES := -I\"$(CURDIR)/build\"

test-c-login: | $(NIMSTATUS)
	$(MAKE) TEST_DEPS=$(NIMSTATUS) \
		TEST_INCLUDES=$(LOGIN_INCLUDES) \
		TEST_NAME=login \
		test-c-template

tests-c:
	$(MAKE) test-c-shims
	$(MAKE) test-c-login

tests-nim: | $(STATUSGO)
ifeq ($(detected_OS),Darwin)
	$(ENV_SCRIPT) nimble test
else ifeq ($(detected_OS),Windows)
	PATH="$(STATUSGO_LIBDIR):$(NIM_WINDOWS_PREBUILT_DLLDIR):/usr/bin:/bin:$$PATH" \
	$(ENV_SCRIPT) nimble test
else
	LD_LIBRARY_PATH="$(STATUSGO_LIBDIR)" \
	$(ENV_SCRIPT) nimble test
endif

tests: tests-nim tests-c

test: tests

clean: | clean-common clean-build-dirs clean-data-dirs
	rm -rf $(STATUSGO)
	rm -rf bottles
	rm -rf DLLs

clean-build-dirs:
	rm -rf build/*
	rm -rf tests/c/build/*
	rm -rf tests/nim/build/*

clean-data-dirs:
	rm -rf data
	rm -rf keystore
	rm -rf noBackup

create-data-dirs:
	mkdir -p data
	mkdir -p keystore
	mkdir -p noBackup

endif # "variables.mk" was not included
