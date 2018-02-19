# Class for load configuration from YAML-config file
class Config
  attr_reader :user, :password, :db_name, :project_name, :auth_token,
              :test_run_count, :repository_url, :logs_dir_url,
              :report_portal_url

  require 'yaml'

  def initialize(config_file_name, sections = %i[database report_portal])
    check_config_file(config_file_name)

    config = YAML.safe_load(File.read(config_file_name))

    @sections = sections

    database_root, report_portal_root = check_config_content(config)
    init_fields(database_root, report_portal_root)
  end

  private

  def init_fields(database_root, report_portal_root)
    @user = database_root['user']
    @password = database_root['password']
    @db_name = database_root['db_name']
    @test_run_count = database_root['test_run_count_to_import']
    @project_name = report_portal_root['project_name']
    @auth_token = report_portal_root['auth_token']
    @repository_url = report_portal_root['repository_url']
    @logs_dir_url = report_portal_root['logs_dir_url']
    @report_portal_url = report_portal_root['url']
  end

  def check_config_file(file_name)
    return if file_name.nil? || File.file?(file_name)

    puts "Error: config.yml file is not exist\n"
    print_config_example
    exit 1
  end

  def check_config_content(config)
    database = @sections.include?(:database) ? config['database'] : {}
    report_portal = @sections.include?(:report_portal) ? config['report_portal'] : {}

    if check_database_section(database) || check_report_portal_section(report_portal)
      puts "Error: incorrect config.yml file\n"
      print_config_example
      exit 1
    end

    return database, report_portal
  end

  def check_database_section(database)
    return false unless @sections.include?(:database)
    database['db_name'].nil? || database['user'].nil? ||
      database['password'].nil? || database['test_run_count_to_import'].nil?
  end

  def check_report_portal_section(report_portal)
    return false unless @sections.include?(:report_portal)
    report_portal['project_name'].nil? || report_portal['auth_token'].nil? ||
      report_portal['repository_url'].nil? || report_portal['logs_dir_url'].nil? ||
      report_portal['url'].nil?
  end

  def print_config_example
    puts 'Please, read the instructions about config-file in the README'
  end
end
