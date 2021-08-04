import # std libs
  std/[os, strformat, times, unittest]

import # vendor libs
  chronos, sqlcipher

import # status lib
  ../status/private/database

import # test modules
  ./test_helpers

procSuite "db_smoke":
  asyncTest "db_smoke":
    let password = "qwerty"
    let path = currentSourcePath.parentDir() & "/build/my.db"
    removeFile(path)
    let db = openDatabase(path)

    key(db, password)
    execScript(db, "CREATE TABLE if not exists Log (theTime TEXT PRIMARY KEY)")

    let date = getDateStr(now())
    let time = getClockStr(now())

    execScript(db, &"""INSERT INTO Log VALUES("{date}:{time}")""")

    echo all(db, "SELECT * FROM Log")

    # true / FALSE can be upper or lower case
    let settingsSQL = fmt"""
    CREATE TABLE if not exists Settings (
      fooMode BOOLEAN DEFAULT false,
      barMode BOOLEAN DEFAULT true,
      bazMode BOOLEAN DEFAULT FALSE,
      quuxMode BOOLEAN DEFAULT TRUE,
      id VARCHAR PRIMARY KEY
    ) WITHOUT ROWID;
    """

    db.execScript(settingsSQL)

    let foo = true
    let bar = false
    let baz = true
    let quux = false

    let id = "bools test"

    exec(
      db,
      """INSERT INTO Settings (fooMode, barMode, bazMode, quuxMode, id) VALUES (?, ?, ?, ?, ?)""",
      foo, bar, baz, quux, id & " 1"
    )

    exec(
      db,
      """INSERT INTO Settings (fooMode, bazMode, id) VALUES (?, ?, ?)""",
      foo, baz, id & " 2"
    )

    exec(
      db,
      """INSERT INTO Settings (barMode, quuxMode, id) VALUES (?, ?, ?)""",
      bar, quux, id & " 3"
    )

    exec(
      db,
      """INSERT INTO Settings (id) VALUES (?)""",
      id & " 4"
    )

    echo ""
    echo "==BOOLS TEST=="
    echo all(db, "SELECT * FROM Settings")
    echo ""
    echo fromDbValue(all(db, "SELECT * FROM Settings")[0][0], bool)
    echo fromDbValue(all(db, "SELECT * FROM Settings")[0][1], bool)
    echo fromDbValue(all(db, "SELECT * FROM Settings")[0][2], bool)
    echo fromDbValue(all(db, "SELECT * FROM Settings")[0][3], bool)
    echo fromDbValue(all(db, "SELECT * FROM Settings")[1][0], bool)
    echo fromDbValue(all(db, "SELECT * FROM Settings")[1][1], bool)
    echo fromDbValue(all(db, "SELECT * FROM Settings")[1][2], bool)
    echo fromDbValue(all(db, "SELECT * FROM Settings")[1][3], bool)
    echo fromDbValue(all(db, "SELECT * FROM Settings")[2][0], bool)
    echo fromDbValue(all(db, "SELECT * FROM Settings")[2][1], bool)
    echo fromDbValue(all(db, "SELECT * FROM Settings")[2][2], bool)
    echo fromDbValue(all(db, "SELECT * FROM Settings")[2][3], bool)
    echo fromDbValue(all(db, "SELECT * FROM Settings")[3][0], bool)
    echo fromDbValue(all(db, "SELECT * FROM Settings")[3][1], bool)
    echo fromDbValue(all(db, "SELECT * FROM Settings")[3][2], bool)
    echo fromDbValue(all(db, "SELECT * FROM Settings")[3][3], bool)

    close(db)
    removeFile(path)
