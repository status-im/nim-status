import sqlcipher

proc migrate*(db: DbConn) =
  # TODO: implement proper migrations
  # Remove this query. Use status-go appdatabase/migrations/sql files instead
  let settingSQL = """CREATE TABLE settings (
                        address VARCHAR NOT NULL,
                        chaos_mode BOOLEAN DEFAULT false,
                        currency VARCHAR DEFAULT 'usd',
                        current_network VARCHAR NOT NULL,
                        custom_bootnodes BLOB,
                        custom_bootnodes_enabled BLOB,
                        dapps_address VARCHAR NOT NULL,
                        eip1581_address VARCHAR,
                        fleet VARCHAR,
                        hide_home_tooltip BOOLEAN DEFAULT false,
                        installation_id VARCHAR NOT NULL,
                        key_uid VARCHAR NOT NULL,
                        keycard_instance_uid VARCHAR,
                        keycard_paired_on UNSIGNED BIGINT,
                        keycard_pairing VARCHAR,
                        last_updated UNSIGNED BIGINT,
                        latest_derived_path UNSIGNED INT DEFAULT 0,
                        log_level VARCHAR,
                        mnemonic VARCHAR,
                        name VARCHAR NOT NULL,
                        networks BLOB NOT NULL,
                        node_config BLOB,
                        notifications_enabled BOOLEAN DEFAULT false,
                        photo_path BLOB NOT NULL,
                        pinned_mailservers BLOB,
                        preferred_name VARCHAR,
                        preview_privacy BOOLEAN DEFAULT false,
                        public_key VARCHAR NOT NULL,
                        remember_syncing_choice BOOLEAN DEFAULT false,
                        signing_phrase VARCHAR NOT NULL,
                        stickers_packs_installed BLOB,
                        stickers_recent_stickers BLOB,
                        syncing_on_mobile_network BOOLEAN DEFAULT false,
                        synthetic_id VARCHAR DEFAULT 'id' PRIMARY KEY,
                        usernames BLOB,
                        wallet_root_address VARCHAR NOT NULL,
                        wallet_set_up_passed BOOLEAN DEFAULT false,
                        wallet_visible_tokens VARCHAR
                      ) WITHOUT ROWID;
                      ALTER TABLE settings ADD COLUMN stickers_packs_pending BLOB;
                      ALTER TABLE settings ADD COLUMN waku_enabled BOOLEAN DEFAULT false;
                      ALTER TABLE settings ADD COLUMN waku_bloom_filter_mode BOOLEAN DEFAULT false;
                      ALTER TABLE settings ADD COLUMN appearance INT NOT NULL DEFAULT 0;
                      ALTER TABLE settings ADD COLUMN remote_push_notifications_enabled BOOLEAN DEFAULT FALSE;
                      ALTER TABLE settings ADD COLUMN send_push_notifications BOOLEAN DEFAULT TRUE;
                      ALTER TABLE settings ADD COLUMN push_notifications_server_enabled BOOLEAN DEFAULT FALSE;
                      ALTER TABLE settings ADD COLUMN push_notifications_from_contacts_only BOOLEAN DEFAULT FALSE;
                      ALTER TABLE settings ADD COLUMN push_notifications_block_mentions BOOLEAN DEFAULT FALSE;
                      ALTER TABLE settings ADD COLUMN webview_allow_permission_requests BOOLEAN DEFAULT FALSE;
                      ALTER TABLE settings ADD COLUMN use_mailservers BOOLEAN DEFAULT TRUE;
                      """
  db.execScript(settingSQL)

proc initializeDB*(path, password: string):DbConn =
  result = openDatabase(path)
  result.key(password)
  result.migrate()