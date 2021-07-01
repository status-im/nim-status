CREATE TABLE IF NOT EXISTS accounts (
keyUid VARCHAR PRIMARY KEY,
name TEXT NOT NULL,
creationTimestamp BIG INT,
loginTimestamp BIG INT,
photoPath TEXT,
keycardPairing TEXT
) WITHOUT ROWID;
