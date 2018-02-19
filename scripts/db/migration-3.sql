ALTER TABLE results ADD test_time FLOAT DEFAULT 0;

UPDATE results SET test_time = 0 WHERE test_time IS NULL;

UPDATE db_metadata SET version = 3;
