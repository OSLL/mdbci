# Report portal publication scripts

These scripts log test run results into the ReportPortal installation. Before using them
you should required dependencies and create configuration file. The following sections describe
the usage of all scripts in the `bin` subdirectory.

## upload_all_testruns.rb

Loads information about all test runs.

* The data source is the database.
* An example of a configuration file is `all_testruns_config_example.yml`.

## upload_testrun.rb

Loads information about one test run.

* The data source is the `parce_ctest_log.rb` result json-file.
* An example of a configuration file is `testrun_config_example.yml`.
