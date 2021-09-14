CREATE TABLE chats (
    id VARCHAR PRIMARY KEY ON CONFLICT REPLACE,
    name VARCHAR NOT NULL,
    color VARCHAR NOT NULL DEFAULT '#a187d5',
    type INT NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    timestamp INT NOT NULL,
    deleted_at_clock_value INT NOT NULL DEFAULT 0,
    public_key BLOB,
    unviewed_message_count INT NOT NULL DEFAULT 0,
    last_clock_value INT NOT NULL DEFAULT 0,
    last_message BLOB,
    members BLOB,
    membership_updates BLOB,
    muted BOOLEAN DEFAULT FALSE,
    invitation_admin VARCHAR,
    profile VARCHAR,
    community_id TEXT DEFAULT "",
    accepted BOOLEAN DEFAULT false,
    joined INT DEFAULT 0,
    synced_to INTEGER DEFAULT 0,
    synced_from INTEGER DEFAULT 0,
    unviewed_mentions_count INT DEFAULT 0,
    description TEXT DEFAULT ""
);

CREATE TABLE contacts (
    id TEXT PRIMARY KEY ON CONFLICT REPLACE,
    address TEXT NOT NULL,
    name TEXT NOT NULL,
    ens_verified BOOLEAN DEFAULT FALSE,
    ens_verified_at INT NOT NULL DEFAULT 0,
    alias TEXT NOT NULL,
    identicon TEXT NOT NULL,
    photo TEXT NOT NULL,
    last_updated INT NOT NULL DEFAULT 0,
    system_tags BLOB,
    device_info BLOB,
    tribute_to_talk TEXT NOT NULL,
    last_ens_clock_value INT NOT NULL DEFAULT 0,
    local_nickname TEXT
);

CREATE TABLE user_messages (
    id VARCHAR PRIMARY KEY ON CONFLICT REPLACE,
    whisper_timestamp INTEGER NOT NULL,
    source TEXT NOT NULL,
    destination BLOB,
    text VARCHAR NOT NULL,
    content_type INT NOT NULL,
    username VARCHAR,
    timestamp INT NOT NULL,
    chat_id VARCHAR NOT NULL,
    local_chat_id VARCHAR NOT NULL,
    hide BOOLEAN DEFAULT FALSE,
    response_to VARCHAR,
    message_type INT,
    clock_value INT NOT NULL,
    seen BOOLEAN NOT NULL DEFAULT FALSE,
    outgoing_status VARCHAR,
    parsed_text BLOB,
    raw_payload BLOB,
    sticker_pack INT,
    sticker_hash VARCHAR,
    command_id VARCHAR,
    command_value VARCHAR,
    command_address VARCHAR,
    command_from VARCHAR,
    command_contract VARCHAR,
    command_transaction_hash VARCHAR,
    command_signature BLOB,
    command_state INT,
    replace_message TEXT NOT NULL DEFAULT "",
    rtl BOOLEAN NOT NULL DEFAULT FALSE,
    line_count INT NOT NULL DEFAULT 0,
    image_payload BLOB,
    image_type INT,
    image_base64 TEXT NOT NULL DEFAULT "",
    audio_payload BLOB,
    audio_type INT,
    audio_duration_ms INT,
    audio_base64 TEXT NOT NULL DEFAULT "",
    mentions BLOB,
    links BLOB,
    community_id TEXT DEFAULT "",
    gap_from INTEGER,
    gap_to INTEGER,
    mentioned BOOLEAN DEFAULT FALSE,
    edited_at INTEGER,
    deleted BOOL DEFAULT FALSE
);

CREATE INDEX idx_source ON user_messages(source);

CREATE TABLE raw_messages (
    id VARCHAR PRIMARY KEY ON CONFLICT REPLACE,
    local_chat_id VARCHAR NOT NULL,
    last_sent INT NOT NULL,
    send_count INT NOT NULL,
    sent BOOLEAN DEFAULT FALSE,
    resend_automatically BOOLEAN DEFAULT FALSE,
    message_type INT,
    recipients BLOB,
    payload BLOB,
    pow_target REAL default 0.02,
    skip_encryption BOOLEAN DEFAULT FALSE,
    send_push_notification BOOLEAN DEFAULT FALSE,
    skip_group_message_wrap BOOLEAN DEFAULT FALSE,
    send_on_personal_topic BOOLEAN DEFAULT FALSE,
    datasync_id BLOB
);

CREATE TABLE messenger_transactions_to_validate (
    message_id VARCHAR,
    command_id VARCHAR NOT NULL,
    transaction_hash VARCHAR PRIMARY KEY,
    retry_count INT,
    first_seen INT,
    signature BLOB NOT NULL,
    to_validate BOOLEAN DEFAULT TRUE,
    public_key BLOB
);

CREATE INDEX idx_messenger_transaction_to_validate ON messenger_transactions_to_validate(to_validate);

CREATE TABLE accounts (
    address VARCHAR PRIMARY KEY,
    wallet BOOLEAN,
    chat BOOLEAN,
    type TEXT,
    storage TEXT,
    pubkey BLOB,
    path TEXT,
    name TEXT,
    color TEXT,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    hidden BOOL NOT NULL DEFAULT FALSE
) WITHOUT ROWID;

CREATE UNIQUE INDEX unique_wallet_address ON accounts (wallet) WHERE (wallet);

CREATE UNIQUE INDEX unique_chat_address ON accounts (chat) WHERE (chat);

CREATE INDEX created_at_account ON accounts (created_at) WHERE (created_at);

CREATE TABLE browsers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    timestamp USGIGNED BIGINT,
    dapp BOOLEAN DEFAULT false,
    historyIndex UNSIGNED INT
) WITHOUT ROWID;

CREATE TABLE browsers_history (
    browser_id TEXT NOT NULL,
    history TEXT,
    FOREIGN KEY(browser_id) REFERENCES browsers(id) ON DELETE CASCADE
);

CREATE TABLE dapps (
    name TEXT PRIMARY KEY
) WITHOUT ROWID;

CREATE TABLE permissions (
    dapp_name TEXT NOT NULL,
    permission TEXT NOT NULL,
    FOREIGN KEY(dapp_name) REFERENCES dapps(name) ON DELETE CASCADE
);

CREATE TABLE transfers (
    network_id UNSIGNED BIGINT NOT NULL,
    hash VARCHAR NOT NULL,
    address VARCHAR NOT NULL,
    blk_hash VARCHAR NOT NULL,
    tx BLOB,
    sender VARCHAR,
    receipt BLOB,
    log BLOB,
    type VARCHAR NOT NULL,
    blk_number BIGINT NOT NULL,
    timestamp UNSIGNED BIGINT NOT NULL,
    loaded BOOL DEFAULT 1,
    FOREIGN KEY(network_id,address,blk_hash) REFERENCES blocks(network_id,address,blk_hash) ON DELETE CASCADE,
    CONSTRAINT unique_transfer_per_address_per_network UNIQUE (hash,address,network_id)
);

CREATE TABLE blocks (
    network_id UNSIGNED BIGINT NOT NULL,
    address VARCHAR NOT NULL,
    blk_number BIGINT NOT NULL,
    blk_hash BIGINT NOT NULL,
    loaded BOOL DEFAULT FALSE,
    CONSTRAINT unique_mapping_for_account_to_block_per_network UNIQUE (address,blk_hash,network_id)
);

CREATE TABLE blocks_ranges (
    network_id UNSIGNED BIGINT NOT NULL,
    address VARCHAR NOT NULL,
    blk_from BIGINT NOT NULL,
    blk_to BIGINT NOT NULL,
    balance BLOB,
    nonce INTEGER
);

CREATE TABLE mailservers (
    id VARCHAR PRIMARY KEY,
    name VARCHAR NOT NULL,
    address VARCHAR NOT NULL,
    password VARCHAR,
    fleet VARCHAR NOT NULL
) WITHOUT ROWID;

CREATE TABLE mailserver_request_gaps (
    gap_from UNSIGNED INTEGER NOT NULL,
    gap_to UNSIGNED INTEGER NOT NULL,
    id TEXT PRIMARY KEY,
    chat_id TEXT NOT NULL
) WITHOUT ROWID;

CREATE INDEX mailserver_request_gaps_chat_id_idx ON mailserver_request_gaps (chat_id);

CREATE TABLE mailserver_topics (
    topic VARCHAR PRIMARY KEY,
    chat_ids VARCHAR,
    last_request INTEGER DEFAULT 1,
    discovery BOOLEAN DEFAULT FALSE,
    negotiated BOOLEAN DEFAULT FALSE
) WITHOUT ROWID;

CREATE TABLE mailserver_chat_request_ranges (
    chat_id VARCHAR PRIMARY KEY,
    lowest_request_from INTEGER,
    highest_request_to INTEGER
) WITHOUT ROWID;

CREATE TABLE tokens (
    address VARCHAR NOT NULL,
    network_id UNSIGNED BIGINT NOT NULL,
    name TEXT NOT NULL,
    symbol VARCHAR NOT NULL,
    decimals UNSIGNED INT,
    color VARCHAR,
    PRIMARY KEY (address, network_id)
) WITHOUT ROWID;

CREATE TABLE settings (
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
    wallet_visible_tokens VARCHAR,
    stickers_packs_pending BLOB,
    waku_enabled BOOLEAN DEFAULT false,
    waku_bloom_filter_mode BOOLEAN DEFAULT false,
    appearance INT NOT NULL DEFAULT 0,
    remote_push_notifications_enabled BOOLEAN DEFAULT FALSE,
    send_push_notifications BOOLEAN DEFAULT TRUE,
    push_notifications_server_enabled BOOLEAN DEFAULT FALSE,
    push_notifications_from_contacts_only BOOLEAN DEFAULT FALSE,
    push_notifications_block_mentions BOOLEAN DEFAULT FALSE,
    webview_allow_permission_requests BOOLEAN DEFAULT FALSE,
    use_mailservers BOOLEAN DEFAULT TRUE,
    link_preview_request_enabled BOOLEAN DEFAULT TRUE,
    link_previews_enabled_sites BLOB,
    profile_pictures_visibility INT NOT NULL DEFAULT 1,
    anon_metrics_should_send BOOLEAN DEFAULT false,
    messages_from_contacts_only BOOLEAN DEFAULT FALSE,
    default_sync_period INTEGER DEFAULT 86400,
    current_user_status BLOB,
    send_status_updates BOOLEAN DEFAULT TRUE,
    gif_recents BLOB,
    gif_favorites BLOB
) WITHOUT ROWID;

CREATE TABLE pending_transactions (
    network_id UNSIGNED BIGINT NOT NULL,
    hash VARCHAR NOT NULL,
    timestamp UNSIGNED BIGINT NOT NULL,
    from_address VARCHAR NOT NULL,
    to_address VARCHAR,
    symbol VARCHAR,
    gas_price BLOB,
    gas_limit BLOB,
    value BLOB,
    data TEXT,
    type VARCHAR,
    additional_data TEXT,
    PRIMARY KEY (network_id, hash)
) WITHOUT ROWID;

CREATE TABLE favourites (
    address VARCHAR NOT NULL,
    name TEXT NOT NULL,
    PRIMARY KEY (address)
) WITHOUT ROWID;

CREATE TABLE local_notifications_preferences (
    service VARCHAR,
    event VARCHAR,
    identifier VARCHAR,
    enabled BOOLEAN DEFAULT false,
    PRIMARY KEY(service,event,identifier)
) WITHOUT ROWID;

CREATE TABLE bookmarks (
    url VARCHAR NOT NULL,
    name VARCHAR NOT NULL,
    image_url VARCHAR,
    PRIMARY KEY (url)
) WITHOUT ROWID;

CREATE INDEX idx_search_by_local_chat_id_sort_on_cursor ON user_messages (local_chat_id ASC, substr('0000000000000000000000000000000000000000000000000000000000000000' || clock_value, -64, 64) || id DESC);

CREATE TABLE emoji_reactions (
    id VARCHAR PRIMARY KEY ON CONFLICT REPLACE,
    clock_value INT NOT NULL,
    source TEXT NOT NULL,
    emoji_id INT NOT NULL,
    message_id VARCHAR NOT NULL,
    chat_id VARCHAR NOT NULL,
    local_chat_id VARCHAR NOT NULL,
    retracted INT DEFAULT 0
);

CREATE TABLE group_chat_invitations (
    id VARCHAR PRIMARY KEY ON CONFLICT REPLACE,
    source TEXT NOT NULL,
    chat_id VARCHAR NOT NULL,
    message VARCHAR NOT NULL,
    state INT DEFAULT 0,
    clock INT NOT NULL
);

CREATE INDEX emoji_reactions_message_id_local_chat_id_retracted_idx on emoji_reactions(message_id, local_chat_id, retracted);

CREATE INDEX seen_local_chat_id_idx ON user_messages(local_chat_id, seen);

CREATE TABLE chat_identity_last_published (
    chat_id VARCHAR NOT NULL PRIMARY KEY ON CONFLICT REPLACE,
    clock_value INT NOT NULL,
    hash BLOB NOT NULL
);

CREATE TABLE chat_identity_contacts (
    contact_id VARCHAR NOT NULL,
    image_type VARCHAR NOT NULL,
    clock_value INT NOT NULL,
    payload BLOB NOT NULL,
    UNIQUE(contact_id, image_type) ON CONFLICT REPLACE
);

CREATE TABLE communities_communities (
    id BLOB NOT NULL PRIMARY KEY ON CONFLICT REPLACE,
    private_key BLOB,
    description BLOB NOT NULL,
    joined BOOL NOT NULL DEFAULT FALSE,
    verified BOOL NOT NULL DEFAULT FALSE,
    muted BOOL NOT NULL DEFAULT FALSE,
    synced_at TIMESTAMP DEFAULT 0 NOT NULL
);

CREATE TABLE app_metrics (
    event VARCHAR NOT NULL,
    value TEXT NOT NULL,
    app_version VARCHAR NOT NULL,
    operating_system VARCHAR NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_id VARCHAR
);

CREATE TABLE status_updates (
    public_key TEXT PRIMARY KEY ON CONFLICT REPLACE,
    status_type INT NOT NULL DEFAULT 0,
    clock INT NOT NULL,
    custom_text TEXT DEFAULT ""
);

CREATE TABLE mvds_schema_migrations (version uint64,dirty bool);

CREATE TABLE mvds_peers (
    group_id BLOB NOT NULL,
    peer_id BLOB NOT NULL,
    PRIMARY KEY (group_id, peer_id) ON CONFLICT REPLACE
);

CREATE TABLE mvds_states (
    type INTEGER NOT NULL,
    send_count INTEGER NOT NULL,
    send_epoch INTEGER NOT NULL,
    group_id BLOB,
    peer_id BLOB NOT NULL,
    message_id BLOB NOT NULL,
    PRIMARY KEY (message_id, peer_id)
);

CREATE TABLE mvds_epoch (
    peer_id BLOB PRIMARY KEY,
    epoch INTEGER NOT NULL
);

CREATE TABLE mvds_messages (
    id BLOB PRIMARY KEY,
    group_id BLOB NOT NULL,
    timestamp INTEGER NOT NULL,
    body BLOB NOT NULL
);

CREATE TABLE status_protocol_go_schema_migrations (version uint64,dirty bool);

CREATE TABLE sessions (
    dhr BLOB,
    dhs_public BLOB,
    dhs_private BLOB,
    root_chain_key BLOB,
    send_chain_key BLOB,
    send_chain_n INTEGER,
    recv_chain_key BLOB,
    recv_chain_n INTEGER,
    step INTEGER,
    pn INTEGER,
    id BLOB NOT NULL PRIMARY KEY,
    keys_count INTEGER NOT NULL DEFAULT 0,
    UNIQUE(id) ON CONFLICT REPLACE
);

CREATE TABLE keys (
    public_key BLOB NOT NULL,
    msg_num INTEGER,
    message_key BLOB NOT NULL,
    seq_num INTEGER NOT NULL DEFAULT 0,
    session_id BLOB,
    UNIQUE (msg_num, message_key) ON CONFLICT REPLACE
);

CREATE TABLE bundles (
    identity BLOB NOT NULL,
    installation_id TEXT NOT NULL,
    private_key BLOB,
    signed_pre_key BLOB NOT NULL PRIMARY KEY ON CONFLICT IGNORE,
    timestamp UNSIGNED BIG INT NOT NULL,
    expired BOOLEAN DEFAULT 0,
    version INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE ratchet_info_v2 (
    bundle_id BLOB NOT NULL,
    ephemeral_key BLOB,
    identity BLOB NOT NULL,
    symmetric_key BLOB NOT NULL,
    installation_id TEXT NOT NULL,
    UNIQUE(bundle_id, identity, installation_id) ON CONFLICT REPLACE,
    FOREIGN KEY (bundle_id) REFERENCES bundles(signed_pre_key)
);

CREATE TABLE installations  (
    identity BLOB NOT NULL,
    installation_id TEXT NOT NULL,
    timestamp UNSIGNED BIG INT NOT NULL,
    enabled BOOLEAN DEFAULT 1,
    version INTEGER DEFAULT 0,
    UNIQUE(identity, installation_id) ON CONFLICT REPLACE
);

CREATE TABLE secrets (
    identity BLOB NOT NULL PRIMARY KEY ON CONFLICT IGNORE,
    secret BLOB NOT NULL
);

CREATE TABLE secret_installation_ids (
    id TEXT NOT NULL,
    identity_id BLOB NOT NULL,
    UNIQUE(id, identity_id) ON CONFLICT IGNORE,
    FOREIGN KEY (identity_id) REFERENCES secrets(identity)
);

CREATE TABLE contact_code_config (
    unique_constraint varchar(1) NOT NULL PRIMARY KEY DEFAULT 'X',
    last_published INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE waku_keys (
    chat_id TEXT PRIMARY KEY ON CONFLICT IGNORE,
    key BLOB NOT NULL
) WITHOUT ROWID;

CREATE TABLE installation_metadata  (
    identity BLOB NOT NULL,
    installation_id TEXT NOT NULL,
    name TEXT NOT NULL DEFAULT '',
    device_type TEXT NOT NULL DEFAULT '',
    fcm_token TEXT NOT NULL DEFAULT '',
    UNIQUE(identity, installation_id) ON CONFLICT REPLACE
);

CREATE TABLE push_notification_server_registrations (
    public_key BLOB NOT NULL,
    installation_id VARCHAR NOT NULL,
    version INT NOT NULL,
    registration BLOB,
    UNIQUE(public_key, installation_id) ON CONFLICT REPLACE
);

CREATE TABLE push_notification_server_identity (
    private_key BLOB NOT NULL,
    synthetic_id INT NOT NULL DEFAULT 0,
    UNIQUE(synthetic_id)
);

CREATE INDEX idx_push_notification_server_registrations_public_key ON push_notification_server_registrations(public_key);

CREATE INDEX idx_push_notification_server_registrations_public_key_installation_id ON push_notification_server_registrations(public_key, installation_id);

CREATE TABLE push_notification_client_servers (
    public_key BLOB NOT NULL,
    registered BOOLEAN DEFAULT FALSE,
    registered_at INT NOT NULL DEFAULT 0,
    last_retried_at INT NOT NULL DEFAULT 0,
    retry_count INT NOT NULL DEFAULT 0,
    access_token TEXT,
    server_type INT DEFAULT 2,
    UNIQUE(public_key) ON CONFLICT REPLACE
);

CREATE TABLE push_notification_client_queries (
    public_key BLOB NOT NULL,
    queried_at INT NOT NULL,
    query_id BLOB NOT NULL,
    UNIQUE(public_key,query_id) ON CONFLICT REPLACE
);

CREATE TABLE push_notification_client_info (
    public_key BLOB NOT NULL,
    server_public_key BLOB NOT NULL,
    installation_id TEXT NOT NULL,
    access_token TEXT NOT NULL,
    retrieved_at INT NOT NULL,
    version INT NOT NULL,
    UNIQUE(public_key, installation_id, server_public_key) ON CONFLICT REPLACE
);

CREATE TABLE push_notification_client_tracked_messages (
    message_id BLOB NOT NULL,
    chat_id TEXT NOT NULL,
    tracked_at INT NOT NULL,
    UNIQUE(message_id) ON CONFLICT IGNORE
);

CREATE TABLE push_notification_client_sent_notifications (
    message_id BLOB NOT NULL,
    public_key BLOB NOT NULL,
    hashed_public_key BLOB NOT NULL,
    installation_id TEXT NOT NULL,
    last_tried_at INT NOT NULL,
    retry_count INT NOT NULL DEFAULT 0,
    success BOOLEAN NOT NULL DEFAULT FALSE,
    error INT NOT NULL DEFAULT 0,
    chat_id TEXT,
    notification_type INT,
    UNIQUE(message_id, public_key, installation_id) ON CONFLICT REPLACE
);

CREATE TABLE push_notification_client_registrations (
    registration BLOB NOT NULL,
    contact_ids BLOB,
    synthetic_id INT NOT NULL DEFAULT 0,
    UNIQUE(synthetic_id) ON CONFLICT REPLACE
);

CREATE INDEX idx_push_notification_client_info_public_key ON push_notification_client_info(public_key, installation_id);

CREATE TABLE push_notification_server_notifications (
    id BLOB NOT NULL,
    UNIQUE(id)
);

CREATE TABLE transport_message_cache (
    id VARCHAR NOT NULL PRIMARY KEY ON CONFLICT REPLACE,
    timestamp INT NOT NULL
);

CREATE INDEX idx_datsync_id ON raw_messages(datasync_id);

CREATE TABLE communities_requests_to_join  (
    id BLOB NOT NULL,
    public_key VARCHAR NOT NULL,
    clock INT NOT NULL,
    ens_name VARCHAR NOT NULL DEFAULT "",
    chat_id VARCHAR NOT NULL DEFAULT "",
    community_id BLOB NOT NULL,
    state INT NOT NULL DEFAULT 0,
    PRIMARY KEY (id) ON CONFLICT REPLACE
);

CREATE TABLE ens_verification_records (
    public_key VARCHAR NOT NULL,
    name VARCHAR NOT NULL,
    verified BOOLEAN NOT NULL DEFAULT FALSE,
    verified_at INT NOT NULL DEFAULT 0,
    clock INT NOT NULL DEFAULT 0,
    verification_retries INT NOT NULL DEFAULT 0,
    next_retry INT NOT NULL DEFAULT 0,
    PRIMARY KEY (public_key) ON CONFLICT REPLACE
);

CREATE TABLE raw_message_confirmations (
    datasync_id BLOB NOT NULL,
    message_id BLOB NOT NULL,
    public_key BLOB NOT NULL,
    confirmed_at INT NOT NULL DEFAULT 0,
    PRIMARY KEY (message_id, public_key) ON CONFLICT REPLACE
);

CREATE TABLE wakuv2_keys (
    chat_id TEXT PRIMARY KEY ON CONFLICT IGNORE,
    key BLOB NOT NULL
) WITHOUT ROWID;

CREATE TABLE activity_center_notifications (
    id VARCHAR NOT NULL PRIMARY KEY,
    timestamp INT NOT NULL,
    notification_type INT NOT NULL,
    chat_id VARCHAR,
    read BOOLEAN NOT NULL DEFAULT FALSE,
    dismissed BOOLEAN NOT NULL DEFAULT FALSE,
    accepted BOOLEAN NOT NULL DEFAULT FALSE,
    message BLOB DEFAULT NULL,
    author TEXT,
    reply_message BLOB DEFAULT NULL
) WITHOUT ROWID;

CREATE INDEX activity_center_dimissed_accepted ON activity_center_notifications(dismissed, accepted);

CREATE INDEX activity_center_read ON activity_center_notifications(read);

CREATE TABLE pin_messages (
    id VARCHAR PRIMARY KEY NOT NULL,
    message_id VARCHAR NOT NULL,
    whisper_timestamp INTEGER NOT NULL,
    chat_id VARCHAR NOT NULL,
    local_chat_id VARCHAR NOT NULL,
    clock_value INT NOT NULL,
    pinned BOOLEAN NOT NULL,
    pinned_by TEXT
);

CREATE TABLE user_messages_edits (
    clock INTEGER NOT NULL,
    chat_id VARCHAR NOT NULL,
    message_id VARCHAR NOT NULL,
    source VARCHAR NOT NULL,
    text VARCHAR NOT NULL,
    id VARCHAR NOT NULL,
    PRIMARY KEY(id)
);

CREATE INDEX user_messages_edits_message_id_source ON user_messages_edits(message_id, source);

CREATE TABLE user_messages_deletes (
    clock INTEGER NOT NULL,
    chat_id VARCHAR NOT NULL,
    message_id VARCHAR NOT NULL,
    source VARCHAR NOT NULL,
    id VARCHAR NOT NULL,
    PRIMARY KEY(id)
);

CREATE INDEX user_messages_deletes_message_id_source ON user_messages_deletes(message_id, source);

CREATE TABLE tx_history_info (
    address VARCHAR NOT NULL PRIMARY KEY,
    balance int NOT NULL,
    tx_count NOT NULL,
    block_number INT NOT NULL
) WITHOUT ROWID;

CREATE TABLE tx_history (
    id VARCHAR NOT NULL PRIMARY KEY,
    address VARCHAR,
    tx_type VARCHAR NOT NULL,
    block_number INT NOT NULL,
    block_hash VARCHAR NOT NULL,
    timestamp INT NOT NULL,
    gas_price INT,
    gas_limit INT,
    gas_used INT,
    nonce INT,
    tx_status INT,
    input VARCHAR,
    tx_hash VARCHAR,
    value INT,
    from_addr VARCHAR,
    to_addr VARCHAR,
    contract VARCHAR,
    network_id int
) WITHOUT ROWID;
