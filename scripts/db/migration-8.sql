ALTER TABLE maxscale_parameters ADD maxscale_threads INT;
UPDATE db_metadata SET version = 8;
