# frozen_string_literal: true

describe 'generate command', :system do
  before(:example) do
    @test_dir = Dir.mktmpdir
  end

  after(:example) do
    FileUtils.rm_r @test_dir
  end

  def self.test_vagrantfile_validity_for_template(template)
    it 'generated Vagrantfile should be valid Ruby script' do
      config = mdbci_create_configuration(@test_dir, template)
      result = run_command("ruby -c #{File.join(config, 'Vagrantfile')}")
      expect(result).to be_success
    end
  end

  context 'when generate AWS node' do
    test_vagrantfile_validity_for_template('suse_13_aws_plain')
  end

  context 'when generate VirtualBox node' do
    test_vagrantfile_validity_for_template('centos_6_vbox_plain')
  end

  context 'when generate libvirt node' do
    test_vagrantfile_validity_for_template('centos_7_libvirt_plain')
  end
end
