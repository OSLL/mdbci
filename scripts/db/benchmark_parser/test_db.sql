DROP DATABASE IF EXISTS mdbci_dev_db_benchmark_parser_testing;
CREATE DATABASE mdbci_dev_db_benchmark_parser_testing;

USE mdbci_dev_db_benchmark_parser_testing;

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
  mdbci_template LONGTEXT,
  test_tool VARCHAR(256),
  product_under_test VARCHAR(256),
  PRIMARY KEY(id)
);

CREATE TABLE maxscale_parameters (
  id INT,
  target VARCHAR(256),
  maxscale_commit_id VARCHAR(256),
  maxscale_cnf LONGTEXT,
  FOREIGN KEY (id) REFERENCES performance_test_run(id)
);

CREATE TABLE sysbench_results (
  id INT,
  OLTP_test_statistics_queries_performed_read FLOAT,
  OLTP_test_statistics_queries_performed_write FLOAT,
  OLTP_test_statistics_queries_performed_other FLOAT,
  OLTP_test_statistics_queries_performed_total FLOAT,
  OLTP_test_statistics_transactions FLOAT,
  OLTP_test_statistics_read_write_requests FLOAT,
  OLTP_test_statistics_other_operations FLOAT,
  OLTP_test_statistics_ignored_errors FLOAT,
  OLTP_test_statistics_reconnects FLOAT,
  General_statistics_total_time FLOAT,
  General_statistics_total_number_of_events FLOAT,
  General_statistics_total_time_taken_by_event_execution FLOAT,
  General_statistics_response_time_min FLOAT,
  General_statistics_response_time_avg FLOAT,
  General_statistics_response_time_max FLOAT,
  General_statistics_response_time_approx__95_percentile FLOAT,
  Threads_fairness_events_avg FLOAT,
  Threads_fairness_events_stddev FLOAT,
  Threads_fairness_execution_time_avg FLOAT,
  Threads_fairness_execution_time_stddev FLOAT,
  FOREIGN KEY (id) REFERENCES performance_test_run(id)
);
