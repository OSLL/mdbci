ALTER TABLE performance_test_run ADD sysbench_threads INT;
ALTER TABLE maxscale_parameters ADD maxscale_cnf_file_name VARCHAR(500);
UPDATE db_metadata SET version = 7;
