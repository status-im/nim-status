# status-nim

Nim implementation of the Status protocol: https://github.com/status-im/specs

Corresponds roughly to status-go: https://github.com/status-im/status-go which is consumed by status-react: https://github.com/status-im/status-react/



### Building

#### 1. Requirements
* Go - (used to build status-go)
```
# Linux
<TODO>

# macOS
brew install go
```

#### 2. Clone the repo and build `nim-status-client`
```
git clone https://github.com/status-im/nim-status
cd nim-status
make update
make
```

For more output use `make V=1 ...`.

Use 4 CPU cores with `make -j4 ...`.

**Troubleshooting**:

If the `make` command fails due to already installed Homebrew packages, such as:

```
Error: protobuf 3.11.4 is already installed
To upgrade to 3.11.4_1, run `brew upgrade protobuf`.
make[1]: *** [install-os-dependencies] Error 1
make: *** [vendor/status-go/build/bin/libstatus.a] Error 2
```

This can be fixed by uninstalling the package e.g. `brew uninstall protobuf` followed by rerunning `make`.

