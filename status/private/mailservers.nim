{.push raises: [Defect].}

import # std libs
  std/[json, options, strformat, strutils]

import # vendor libs
  json_serialization,
  json_serialization/[lexer, reader, writer],
  sqlcipher

import # nim-status modules
  ./common

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

  MailserverDbError* = object of StatusError

proc deleteMailserver*(db: DbConn, mailserver: Mailserver) {.raises:
  [MailserverDbError].} =

  const errorMsg = "Error deleting mailserver"
  try:
    var tblMailserver: Mailserver
    let query = fmt"""DELETE FROM   {mailserver.tableName}
                      WHERE         {MailserversCol.Id} = ?"""
    db.exec(query, mailserver.id)
  except SqliteError as e:
    raise (ref MailserverDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref MailserverDbError)(parent: e, msg: errorMsg)


proc getMailservers*(db: DbConn): seq[Mailserver] {.raises: [Defect,
  MailserverDbError].} =

  const errorMsg = "Error getting mailservers"
  try:
    var tblMailserver: Mailserver
    let query = fmt"""SELECT    {MailserversCol.Id},
                                {MailserversCol.Name},
                                {MailserversCol.Address},
                                {MailserversCol.Password},
                                {MailserversCol.Fleet}
                      FROM      {tblMailserver.tableName}"""
    db.all(Mailserver, query)
  except SqliteError as e:
    raise (ref MailserverDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref MailserverDbError)(parent: e, msg: errorMsg)

proc saveMailserver*(db: DbConn, mailserver: Mailserver) {.raises: [Defect,
  MailserverDbError].} =

  const errorMsg = "Error getting mailservers"
  try:
    var tblMailserver: Mailserver
    let query = fmt"""INSERT INTO   {tblMailserver.tableName} (
                                    {MailserversCol.Id},
                                    {MailserversCol.Name},
                                    {MailserversCol.Address},
                                    {MailserversCol.Password},
                                    {MailserversCol.Fleet})
                      VALUES        (?, ?, ?, ?, ?)"""
    db.exec(query,
            mailserver.id,
            mailserver.name,
            mailserver.address,
            (if mailserver.password.isSome(): mailserver.password.get() else: ""),
            mailserver.fleet)
  except SqliteError as e:
    raise (ref MailserverDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref MailserverDbError)(parent: e, msg: errorMsg)

proc saveMailservers*(db: DbConn, mailservers: seq[Mailserver]) {.raises:
  [Defect, MailserverDbError].} =

  for mailserver in mailservers:
    db.saveMailserver(mailserver)
