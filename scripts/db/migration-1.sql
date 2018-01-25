ALTER TABLE test_run ADD cmake_flags TEXT DEFAULT "NOT FOUND", ADD maxscale_source VARCHAR(256) DEFAULT "NOT FOUND";

UPDATE test_run SET cmake_flags="NOT FOUND" WHERE cmake_flags IS NULL;
UPDATE test_run SET maxscale_source="NOT FOUND" WHERE maxscale_source IS NULL;

CREATE TABLE IF NOT EXISTS db_version (
  version INT
);
TRUNCATE TABLE db_version;
INSERT INTO db_version (version) VALUES (1);
