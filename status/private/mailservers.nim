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

proc deleteMailserver*(db: DbConn, mailserver: Mailserver): DbResult[void]
  {.raises: [].} =

  try:
    var tblMailserver: Mailserver
    let query = fmt"""DELETE FROM   {mailserver.tableName}
                      WHERE         {MailserversCol.Id} = ?"""
    db.exec(query, mailserver.id)
    ok()
  except SqliteError: err OperationError
  except ValueError: err QueryBuildError


proc getMailservers*(db: DbConn): DbResult[seq[Mailserver]] =

  try:
    var tblMailserver: Mailserver
    let query = fmt"""SELECT    {MailserversCol.Id},
                                {MailserversCol.Name},
                                {MailserversCol.Address},
                                {MailserversCol.Password},
                                {MailserversCol.Fleet}
                      FROM      {tblMailserver.tableName}"""
    ok db.all(Mailserver, query)
  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc saveMailserver*(db: DbConn, mailserver: Mailserver): DbResult[void] =

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
    ok()
  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc saveMailservers*(db: DbConn, mailservers: seq[Mailserver]):
  DbResult[void] =

  for mailserver in mailservers:
    ?db.saveMailserver(mailserver)

  ok()
