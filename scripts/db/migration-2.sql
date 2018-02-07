ALTER TABLE test_run ADD logs_dir VARCHAR(256) DEFAULT NULL;

TRUNCATE TABLE db_metadata;
INSERT INTO db_metadata (version) VALUES (2);