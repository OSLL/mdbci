CREATE TABLE test_run (
  id INT AUTO_INCREMENT,
  jenkins_id INT,
  start_time DATETIME,
  target VARCHAR(256),
  box VARCHAR(256),
  product VARCHAR(256),
  mariadb_version VARCHAR(256),
  test_code_commit_id VARCHAR(256),
  maxscale_commit_id VARCHAR(256),
  job_name VARCHAR(256),
  PRIMARY KEY(id)
);

CREATE TABLE results (
  id INT,
  test VARCHAR(256),
  result INT,
  FOREIGN KEY (id) REFERENCES test_run(id)
);
