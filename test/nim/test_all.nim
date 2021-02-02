import
  ./account,

  # `test/nim/accounts.nim` is presently disabled because
  # `nim_status/accounts.nim` is written w.r.t. the accounts table in
  # `accounts.sql` created by status-go vs. the accounts table in `[key].db`
  # created by status-go. See PR #147.
  # ./accounts,

  ./bip32,
  ./callrpc,
  ./chats,
  ./contacts,
  ./db_smoke,
  ./hybrid_smoke,

  # `test/nim/login_and_logout.nim` is presently disabled because
  # `nim_status/accounts.nim` uses a global mutable variable for `web3_conn`
  # (which can't be referenced within a chronos async function, e.g. an
  # `asyncTest`); it should instead be a property of an init'd Status object
  # (or something along those lines)
  # ./login_and_logout,

  ./mailservers,
  ./messages,
  ./migrations,
  ./pendingtxs,
  ./permissions,
  ./settings,
  ./shims,
  ./tokens,
  ./waku_smoke
