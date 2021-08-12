{.push raises: [Defect].}

import # std libs
  std/[options, strformat]

import # vendor libs
  json_serialization,
  sqlcipher, web3/ethtypes

import # status modules
  ./common, ./conversions

type
  ContactType* {.pure.} = enum
    Id = "id",
    Address = "address",
    Name = "name",
    EnsVerified = "ensVerified",
    EnsVerifiedAt = "ensVerifiedAt",
    LastEnsClockValue = "lastEnsClockValue",
    EnsVerificationRetries = "ensVerificationRetries"
    Alias = "alias"
    Identicon = "identicon"
    Photo = "photoPath"
    LastUpdated = "lastUpdated"
    SystemTags = "systemTags"
    DeviceInfo = "deviceInfo"
    TributeToTalk = "tributeToTalk"
    LocalNickname = "localNickname"

  ContactsCol* {.pure.} = enum
    Id = "id",
    Address = "address",
    Name = "name",
    EnsVerified = "ens_verified",
    EnsVerifiedAt = "ens_verified_at",
    EnsVerificationRetries = "ens_verification_retries"
    Alias = "alias"
    Identicon = "identicon"
    Photo = "photo"
    LastUpdated = "last_updated"
    SystemTags = "system_tags"
    DeviceInfo = "device_info"
    TributeToTalk = "tribute_to_talk"
    LocalNickname = "local_nickname"
    LastEnsClockValue = "last_ens_clock_value"

  ContactDeviceInfoType* {.pure.} = enum
    InstallationId = "id",
    Timestamp = "timestamp",
    FCMToken = "fcmToken"

  ContactDeviceInfo* = object
    # The installation id of the device
    installationId* {.serializedFieldName($ContactDeviceInfoType.InstallationId).}: string
    # Represents the last time we received this info
    timestamp* {.serializedFieldName($ContactDeviceInfoType.Timestamp).}: int64
    # to be used for push notifications
    fcmToken* {.serializedFieldName($ContactDeviceInfoType.FCMToken).}: string

  # Contact has information about a "Contact". A contact is not necessarily one
  # that we added or added us, that's based on SystemTags.
  Contact* {.dbTableName("contacts").} = object
    # ID of the contact. It's a hex-encoded public key (prefixed with 0x).
    id* {.serializedFieldName($ContactType.Id), dbColumnName($ContactsCol.Id).}: string
    # Ethereum address of the contact
    address* {.serializedFieldName($ContactType.Address), dbColumnName($ContactsCol.Address).}: Option[Address]
    # ENS name of contact
    name* {.serializedFieldName($ContactType.Name), dbColumnName($ContactsCol.Name).}: Option[string]
    # Whether we verified the name of the contact
    ensVerified* {.serializedFieldName($ContactType.EnsVerified), dbColumnName($ContactsCol.EnsVerified).}: bool
    # the time we last verified the name
    ensVerifiedAt* {.serializedFieldName($ContactType.EnsVerifiedAt), dbColumnName($ContactsCol.EnsVerifiedAt).}: int64
    # last clock value of when we received an ENS name for the user
    lastEnsClockValue* {.serializedFieldName($ContactType.LastEnsClockValue), dbColumnName($ContactsCol.LastEnsClockValue).}: int64
    # how many times we retried the ENS
    ensVerificationRetries* {.serializedFieldName($ContactType.EnsVerificationRetries), dbColumnName($ContactsCol.EnsVerificationRetries).}: int64
    # Generated username name of the contact
    alias* {.serializedFieldName($ContactType.Alias), dbColumnName($ContactsCol.Alias).}: Option[string]
    # Identicon generated from public key
    identicon* {.serializedFieldName($ContactType.Identicon), dbColumnName($ContactsCol.Identicon).}: string
    # base64 encoded photo
    photo* {.serializedFieldName($ContactType.Photo), dbColumnName($ContactsCol.Photo).}: Option[string]
    # last time we received an update from the contact. Updates should be discarded if last updated is less than the one stored
    lastUpdated* {.serializedFieldName($ContactType.LastUpdated), dbColumnName($ContactsCol.LastUpdated).}: int64
    # contains information about whether we blocked/added/have been added
    systemTags* {.serializedFieldName($ContactType.SystemTags), dbColumnName($ContactsCol.SystemTags).}: seq[string]
    deviceInfo* {.serializedFieldName($ContactType.DeviceInfo), dbColumnName($ContactsCol.DeviceInfo).}: seq[ContactDeviceInfo]
    tributeToTalk* {.serializedFieldName($ContactType.TributeToTalk), dbColumnName($ContactsCol.TributeToTalk).}: Option[string]
    localNickname* {.serializedFieldName($ContactType.LocalNickname), dbColumnName($ContactsCol.LocalNickname).}: Option[string]

proc saveContact*(db: DbConn, contact: Contact): DbResult[void] =

  try:
    var tblContact: Contact
    let query = fmt"""INSERT INTO {tblContact.tableName} (
                        {ContactsCol.Id},
                        {ContactsCol.Address},
                        {ContactsCol.Name},
                        {ContactsCol.Alias},
                        {ContactsCol.Identicon},
                        {ContactsCol.Photo},
                        {ContactsCol.LastUpdated},
                        {ContactsCol.SystemTags},
                        {ContactsCol.DeviceInfo},
                        {ContactsCol.EnsVerified},
                        {ContactsCol.EnsVerifiedAt},
                        {ContactsCol.EnsVerificationRetries},
                        {ContactsCol.TributeToTalk},
                        {ContactsCol.LocalNickname},
                        {ContactsCol.LastEnsClockValue})
                  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"""

    db.exec(query,
            contact.id,
            contact.address,
            contact.name,
            contact.alias,
            contact.identicon,
            contact.photo,
            contact.lastUpdated,
            contact.systemTags,
            contact.deviceInfo,
            contact.ensVerified,
            contact.ensVerifiedAt,
            contact.ensVerificationRetries,
            contact.tributeToTalk,
            contact.localNickname,
            contact.lastEnsClockValue)
    ok()

  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc saveContacts*(db: DbConn, contacts: seq[Contact]): DbResult[void] =
  for contact in contacts:
    ?db.saveContact(contact)
  ok()

proc getContacts*(db: DbConn): DbResult[seq[Contact]] =

  try:
    var contact: Contact
    let query = fmt"""SELECT    *
                      FROM      {contact.tableName}"""
    ok db.all(Contact, query)
  except SerializationError: err DataAndTypeMismatch
  except SqliteError: err OperationError
  except ValueError: err QueryBuildError
