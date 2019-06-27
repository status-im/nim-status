# status-nim

Status-Nimbus interop.

Current setup: `nimbus -> expose bindings and shared library -> status-nim -> status-console-client`. Eventually this can expose a similar API as `status-go`, but for now interop with it is easier.

## Misc issues and how to solve them

Can't find `libnimbus_api.so`:

```
mv libnimbus_api.so /usr/local/lib/`
```

To run as a standalone process:

Change package name in `main.go` to `main`.

go-vendor issues:

```
> cp -r $GOPATH/src/github.com/status-im/status-nim/ $GOPATH/src/github.com/status-im/status-console-client/vendor/github.com/status-im/
```

Run from status-term-client:
```
# checkout nimbus-test branch/PR
make build

> ./bin/status-term-client -keyhex=0xe8b3b8a7cae540ace9bcaf6206e81387feb6415016aee75307976084f7751ed7 2>/tmp/status-term-client.log
```

Get predictable segfault (see `segfault.output`)
