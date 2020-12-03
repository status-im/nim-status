import # nim libs
  strformat

import # vendor libs
  sqlcipher, settings/types

proc migrate*(db: DbConn) =
  # TODO: implement proper migrations
  # Remove this query. Use status-go appdatabase/migrations/sql files instead
  var settings: Settings
  let settingSQL = fmt"""CREATE TABLE {settings.tableName} (
                        {settings.userAddress.columnName} VARCHAR NOT NULL,
                        {settings.chaosMode.columnName} BOOLEAN DEFAULT FALSE,
                        {settings.currency.columnName} VARCHAR DEFAULT 'usd',
                        {settings.currentNetwork.columnName} VARCHAR NOT NULL,
                        {settings.customBootnodes.columnName} BLOB,
                        {settings.customBootnodes_enabled.columnName} BLOB,
                        {settings.dappsAddress.columnName} VARCHAR NOT NULL,
                        {settings.eip1581Address.columnName} VARCHAR,
                        {settings.fleet.columnName} VARCHAR,
                        {settings.hideHomeTooltip.columnName} BOOLEAN DEFAULT FALSE,
                        {settings.installationId.columnName} VARCHAR NOT NULL,
                        {settings.keyUid.columnName} VARCHAR NOT NULL,
                        {settings.keycardInstance_uid.columnName} VARCHAR,
                        {settings.keycardPairedOn.columnName} UNSIGNED BIGINT,
                        {settings.keycardPairing.columnName} VARCHAR,
                        {settings.lastUpdated.columnName} UNSIGNED BIGINT,
                        {settings.latestDerivedPath.columnName} UNSIGNED INT DEFAULT 0,
                        {settings.logLevel.columnName} VARCHAR,
                        {settings.mnemonic.columnName} VARCHAR,
                        {settings.name.columnName} VARCHAR NOT NULL,
                        {settings.networks.columnName} BLOB NOT NULL,
                        {settings.nodeConfig.columnName} BLOB,
                        {settings.notificationsEnabled.columnName} BOOLEAN DEFAULT FALSE,
                        {settings.photoPath.columnName} BLOB NOT NULL,
                        {settings.pinnedMailservers.columnName} BLOB,
                        {settings.preferredName.columnName} VARCHAR,
                        {settings.previewPrivacy.columnName} BOOLEAN DEFAULT FALSE,
                        {settings.publicKey.columnName} VARCHAR NOT NULL,
                        {settings.rememberSyncing_choice.columnName} BOOLEAN DEFAULT FALSE,
                        {settings.signingPhrase.columnName} VARCHAR NOT NULL,
                        {settings.stickerPacksInstalled.columnName} BLOB,
                        {settings.stickersRecentStickers.columnName} BLOB,
                        {settings.syncingOnMobileNetwork.columnName} BOOLEAN DEFAULT FALSE,
                        synthetic_id VARCHAR DEFAULT 'id' PRIMARY KEY,
                        {settings.usernames.columnName} BLOB,
                        {settings.walletRootAddress.columnName} VARCHAR NOT NULL,
                        {settings.walletSetUpPassed.columnName} BOOLEAN DEFAULT FALSE,
                        {settings.walletVisibleTokens.columnName} VARCHAR
                      ) WITHOUT ROWID;
                      ALTER TABLE {settings.tableName} ADD COLUMN {settings.stickersPacksPending.columnName} BLOB;
                      ALTER TABLE {settings.tableName} ADD COLUMN {settings.wakuEnabled.columnName} BOOLEAN DEFAULT FALSE;
                      ALTER TABLE {settings.tableName} ADD COLUMN {settings.wakuBloomFilterMode.columnName} BOOLEAN DEFAULT FALSE;
                      ALTER TABLE {settings.tableName} ADD COLUMN {settings.appearance.columnName} INT NOT NULL DEFAULT 0;
                      ALTER TABLE {settings.tableName} ADD COLUMN {settings.remotePushNotificationsEnabled.columnName} BOOLEAN DEFAULT FALSE;
                      ALTER TABLE {settings.tableName} ADD COLUMN {settings.sendPushNotifications.columnName} BOOLEAN DEFAULT TRUE;
                      ALTER TABLE {settings.tableName} ADD COLUMN {settings.pushNotificationsServerEnabled.columnName} BOOLEAN DEFAULT FALSE;
                      ALTER TABLE {settings.tableName} ADD COLUMN {settings.pushNotificationsFromContactsOnly.columnName} BOOLEAN DEFAULT FALSE;
                      ALTER TABLE {settings.tableName} ADD COLUMN {settings.pushNotificationsBlockMentions.columnName} BOOLEAN DEFAULT FALSE;
                      ALTER TABLE {settings.tableName} ADD COLUMN {settings.webviewAllowPermissionRequests.columnName} BOOLEAN DEFAULT FALSE;
                      ALTER TABLE {settings.tableName} ADD COLUMN {settings.useMailservers.columnName} BOOLEAN DEFAULT TRUE;
                      """
  db.execScript(settingSQL)

proc initializeDB*(path, password: string):DbConn =
  result = openDatabase(path)
  result.key(password)
  result.migrate()
