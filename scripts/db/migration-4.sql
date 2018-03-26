ALTER TABLE maxscale_parameters ADD maxscale_source VARCHAR(256) DEFAULT "NOT FOUND";

ALTER TABLE performance_test_run ADD test_tool_version VARCHAR(256) DEFAULT "NOT FOUND";

UPDATE db_metadata SET version = 4;
