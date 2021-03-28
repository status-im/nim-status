# nim-status
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
![Stability: experimental](https://img.shields.io/badge/Stability-experimental-orange.svg)
[![Tests (GitHub Actions)](https://github.com/status-im/nim-status/workflows/Tests/badge.svg?branch=master)](https://github.com/status-im/nim-status/actions?query=workflow%3ATests+branch%3Amaster)

Nim implementation of the [Status protocol](https://github.com/status-im/specs).

Corresponds roughly to [status-go](https://github.com/status-im/status-go), which is consumed by [status-react](https://github.com/status-im/status-react/).

## Installation
```
git clone https://github.com/status-im/nim-status
cd nim-status
make update
make
```

For more output use `make V=1 ...`.

Use 4 CPU cores with `make -j4 ...`.

## Usage

```nim
import nim_status
```

## License

Licensed and distributed under the [MIT License](https://github.com/status-im/nim-status/blob/master/LICENSE).
