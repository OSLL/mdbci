ALTER TABLE results ADD core_dump_path VARCHAR(500);
UPDATE db_metadata SET version = 5;