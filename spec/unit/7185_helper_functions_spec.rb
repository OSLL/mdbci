require 'rspec'
require 'fileutils'
require_relative '../spec_helper'
require_relative '../../core/out'
require_relative '../../core/session'
require_relative '../../core/helper'

PROVIDERS = %W(aws docker libvirt virtualbox)

TEST_PREFIX = File.basename(__FILE__, File.extname(__FILE__))

def paths_to_nodes(provider)
  return "#{TEST_PREFIX}_#{provider}_config"
end

def generate_config(provider)
  provider = 'ppc64' if provider == 'mdbci'
  provider = 'vbox' if provider == 'virtualbox'
  return <<EOF
{
  "cookbook_path" : "../recipes/cookbooks/",
  "aws_config" : "../aws-config.yml",
  "node0" :
  {
    "hostname" : "node0",
    "box" : "ubuntu_trusty_#{provider}"
  }
}
EOF
end


describe 'Helper functions' do

  before :all do
    $mdbci_exec_dir = File.absolute_path('.')
    $out = Out.new
    $session = Session.new
  end

  it 'execute bash command without output' do
    expect { execute_bash('echo test') }.to output(" INFO: test\n").to_stdout
  end

  it 'execute bash command without output' do
    execute_bash('echo test').should eql "test\n"
  end

  it 'execute bash command that not exists (popen raise)' do
    msg = "hello_world: command exited with non zero exit code -  in #{Dir.pwd}, message: No such file or directory - hello_world"
    lambda { execute_bash('hello_world') }.should raise_error msg
  end

  it 'execute bash command that not exists (non zero exit code)' do
    File.open("#{TEST_PREFIX}.sh", 'w') { |file| file.write 'exit 1' }
    error_msg = "sh 7185_helper_functions_spec.sh: command exited with non zero exit code - 1 in #{Dir.pwd}"
    lambda { execute_bash("sh #{TEST_PREFIX}.sh") }.should raise_error error_msg
    FileUtils.rm_rf "#{TEST_PREFIX}.sh"
  end

end

describe nil do
  PROVIDERS.each do |provider|
    template = "#{TEST_PREFIX}_#{provider}_config.json"
    config = template.to_s.chomp '.json'
    id_path = "#{config}/.vagrant/machines/node0/#{provider}"

    before :all do
      $out = Out.new
      $session = Session.new
      File.open(template, 'w') { |file| file.write generate_config(provider) }
      execute_bash("./mdbci --override --template #{template} generate #{config}")
      FileUtils.mkdir_p id_path
      File.open("#{id_path}/id", 'w') { |file| file.write '123456789' }
    end
    after :all do
      FileUtils.rm_rf template
      FileUtils.rm_rf config
    end
    it "get nodes #{provider}" do
      get_nodes(config).should eql ['node0']
    end
    it "get provider #{provider}" do
      get_provider(config).should eql provider
    end
    if provider != 'mdbci'
      it "get node machine id for node: node0, for provider: #{provider}" do
        get_node_machine_id(config, 'node0').should eql '123456789'
      end
    else
      it "get node machine id for node: node0, for provider: #{provider} thows error (mdbci has no id)" do
        lambda { get_node_machine_id(config, 'node0') }.should raise_error "getting id for #{config}/node0: action is not supported for machines with 'mdbci(ppc)' provider"
      end
    end
  end
end
