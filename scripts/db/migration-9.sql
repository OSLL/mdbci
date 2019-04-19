ALTER TABLE results ADD leak_summary LONGTEXT;
UPDATE db_metadata SET version = 9;
