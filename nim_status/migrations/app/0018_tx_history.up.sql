CREATE TABLE IF NOT EXISTS tx_history_info (
  address VARCHAR NOT NULL PRIMARY KEY,
  balance int NOT NULL,
  tx_count NOT NULL,
  block_number INT NOT NULL
) WITHOUT ROWID;

CREATE TABLE IF NOT EXISTS tx_history (
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
