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
	deps \
	nim_status \
	update \
	tests

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

ifeq ($(detected_OS), Darwin)
 BOTTLES_TARGET := bottles-macos
 MACOSX_DEPLOYMENT_TARGET := 10.13
 export MACOSX_DEPLOYMENT_TARGET
 CGO_CFLAGS := -mmacosx-version-min=10.13
 export CGO_CFLAGS
 CFLAGS := -mmacosx-version-min=10.13
 export CFLAGS
else
 BOTTLES_TARGET := bottles-dummy
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


ifeq ($(detected_OS), Darwin)
 NIM_PARAMS := $(NIM_PARAMS) -L:"-framework Foundation -framework Security -framework IOKit -framework CoreServices"
endif

# TODO: control debug/release builds with a Make var
# We need `-d:debug` to get Nim's default stack traces.
NIM_PARAMS += -d:debug

deps: | deps-common

update: | update-common

STATUSGO := vendor/status-go/build/bin/libstatus.a

$(STATUSGO): | deps
	echo -e $(BUILD_MSG) "status-go"
	+ cd vendor/status-go && \
	  $(MAKE) statusgo-library $(HANDLE_OUTPUT)

clean: | clean-common
	rm -rf build/*
	rm -rf $(STATUSGO)

NIMSTATUS := build/nim_status.a

$(NIMSTATUS): | build $(STATUSGO) deps
	echo -e $(BUILD_MSG) "$@" && \
		$(ENV_SCRIPT) nim c $(NIM_PARAMS) --app:staticLib --header --noMain --nimcache:nimcache/nim_status --passL:$(STATUSGO) -o:$@ src/nim_status.nim 
		cp nimcache/nim_status/nim_status.h build/.
		mv nim_status.a build/.

nim_status: $(NIMSTATUS)

tests: | $(NIMSTATUS)
	echo "Compiling 'test/test'" && \
	$(CC) -I"$(CURDIR)/build" -I"$(CURDIR)/vendor/nimbus-build-system/vendor/Nim/lib" test/test.c $(NIMSTATUS) $(STATUSGO) -lm -pthread -o test/test && \
	echo "Executing 'test/test'" && \
	./test/test

endif # "variables.mk" was not included
