{.push raises: [Defect].}

import # std libs
  std/[json, options, strformat, strutils]

import # vendor libs
  json_serialization,
  json_serialization/[lexer, reader, writer],
  sqlcipher

type
  MailserverType* {.pure.} = enum
    Id = "id",
    Name = "name",
    Address = "address",
    Password = "password",
    Fleet = "fleet"

  MailserversCol* {.pure.} = enum
    Id = "id",
    Name = "name",
    Address = "address",
    Password = "password",
    Fleet = "fleet"

  Mailserver* {.dbTableName("mailservers").} = object
    id* {.serializedFieldName($MailserverType.Id), dbColumnName($MailserversCol.Id).}: string
    name* {.serializedFieldName($MailserverType.Name), dbColumnName($MailserversCol.Name).}: string
    address* {.serializedFieldName($MailserverType.Address), dbColumnName($MailserversCol.Address).}: string
    password* {.serializedFieldName($MailserverType.Password), dbColumnName($MailserversCol.Password).}: Option[string]
    fleet* {.serializedFieldName($MailserverType.Fleet), dbColumnName($MailserversCol.Fleet).}: string

proc deleteMailserver*(db: DbConn, mailserver: Mailserver) {.raises: [Defect,
  SqliteError].} =

  let query = fmt"""
                 DELETE FROM mailservers WHERE id = ?
                 """
  db.exec(query, mailserver.id)

proc getMailservers*(db: DbConn): seq[Mailserver] {.raises: [Defect,
  SqliteError].} =

  let query = """
              SELECT id, name, address, password, fleet FROM mailservers
              """
  db.all(Mailserver, query)

proc saveMailserver*(db: DbConn, mailserver: Mailserver) {.raises: [Defect,
  SqliteError, ref ValueError].} =

  let query = fmt"""
                 INSERT INTO mailservers(
                   {$MailserversCol.Id},
                   {$MailserversCol.Name},
                   {$MailserversCol.Address},
                   {$MailserversCol.Password},
                   {$MailserversCol.Fleet})
                 VALUES (?, ?, ?, ?, ?)
                 """
  db.exec(query,
          mailserver.id,
          mailserver.name,
          mailserver.address,
          (if mailserver.password.isSome(): mailserver.password.get() else: ""),
          mailserver.fleet)

proc saveMailservers*(db: DbConn, mailservers: seq[Mailserver]) {.raises:
  [Defect, SqliteError, ValueError].} =

  for mailserver in mailservers:
    db.saveMailserver(mailserver)
