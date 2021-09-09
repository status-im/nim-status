CREATE TABLE identity_images(
    key_uid VARCHAR,
    name VARCHAR,
    image_payload BLOB NOT NULL,
    width int,
    height int,
    file_size int,
    resize_target int,
    PRIMARY KEY (key_uid, name) ON CONFLICT REPLACE
) WITHOUT ROWID;

CREATE TABLE accounts(
    keyUid VARCHAR PRIMARY KEY,
    name TEXT NOT NULL,
    creationTimestamp BIG INT,
    loginTimestamp BIG INT,
    identicon TEXT,
    keycardPairing TEXT
) WITHOUT ROWID;
