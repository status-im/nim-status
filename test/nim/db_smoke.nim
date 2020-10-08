import sqlcipher

from os import parentDir
import strformat
import times

let db: DbConn = openDatabase(currentSourcePath.parentDir() & "/build/myDatabase")

let passwd = "qwerty"

key(db, passwd)

execScript(db, "create table if not exists Log (theTime text primary key)")

let date = getDateStr(now())
let time = getClockStr(now())

execScript(db, &"""insert into Log values("{date}:{time}")""")

echo rows(db, "select * from Log")
