USE test_results_db;
CREATE TABLE performance_test_run (
  id INT AUTO_INCREMENT,
  jenkins_id INT,
  start_time DATETIME,
  box VARCHAR(256),
  product VARCHAR(256),
  mariadb_version VARCHAR(256),
  test_code_commit_id VARCHAR(256),
  job_name VARCHAR(256),
  machine_count INT,
  sysbench_params VARCHAR(256),
  mdbci_template BLOB,
  test_tool VARCHAR(256),
  product_under_test VARCHAR(256),
  PRIMARY KEY(id)
);

CREATE TABLE maxscale_parameters (
  id INT,
  target VARCHAR(256),
  maxscale_commit_id VARCHAR(256),
  maxscale_cnf BLOB,
  FOREIGN KEY (id) REFERENCES performance_test_run(id)
);

CREATE TABLE sysbench_results (
  id INT,
  `OLTP_test_statistics.queries_performed.read` FLOAT,
  `OLTP_test_statistics.queries_performed.write` FLOAT,
  `OLTP_test_statistics.queries_performed.other` FLOAT,
  `OLTP_test_statistics.queries_performed.total` FLOAT,
  `OLTP_test_statistics.transactions` FLOAT,
  `OLTP_test_statistics.read.write_requests` FLOAT,
  `OLTP_test_statistics.other_operations` FLOAT,
  `OLTP_test_statistics.ignored_errors` FLOAT,
  `OLTP_test_statistics.reconnects` FLOAT,
  `General_statistics.total_time` FLOAT,
  `General_statistics.total_number_of_events` FLOAT,
  `General_statistics.total_time_taken_by_event_execution` FLOAT,
  `General_statistics.response_time.min` FLOAT,
  `General_statistics.response_time.avg` FLOAT,
  `General_statistics.response_time.max` FLOAT,
  `General_statistics.response_time.approx.__95_percentile` FLOAT,
  `Threads_fairness.events.avg` FLOAT,
  `Threads_fairness.events.stddev` FLOAT,
  `Threads_fairness.execution_time.avg` FLOAT,
  `Threads_fairness.execution_time.stddev` FLOAT,
  FOREIGN KEY (id) REFERENCES performance_test_run(id)
);
