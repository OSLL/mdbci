# frozen_string_literal: true

require 'models/configuration'
require 'tmpdir'
require 'fileutils'
require 'json'

describe Configuration do
  # rubocop:disable Metrics/MethodLength
  def with_fake_config(provider = '', data = {})
    dir = Dir.mktmpdir
    begin
      real_template = "#{dir}/template-content"
      File.open(real_template, 'w') do |file|
        file.write(JSON.generate(data))
      end
      File.open("#{dir}/template", 'w') do |file|
        file.write(real_template)
      end
      File.open("#{dir}/provider", 'w') do |file|
        file.write(provider)
      end
      FileUtils.touch("#{dir}/Vagrantfile")
      yield dir
    ensure
      FileUtils.remove_entry(dir)
    end
  end
  # rubocop:enable Metrics/MethodLength

  describe '.config_directory?' do
    context 'when given non-exiting path' do
      [nil, '', 'unknown'].each do |incorrect_path|
        it 'should return false' do
          expect(Configuration.config_directory?(incorrect_path)).to be_falsy
        end
      end
    end

    context 'when given correct-looking directory' do
      it 'should return true' do
        with_fake_config do |config|
          expect(Configuration.config_directory?(config)).to be_truthy
        end
      end
    end
  end

  describe '#initialize' do
    context 'when given incorrect path' do
      it 'should raise error' do
        expect { Configuration.new('') }.to raise_error(ArgumentError)
      end
    end

    context 'when given correct path' do
      it 'should store absolute path to the configuration' do
        with_fake_config('libvirt', { 'test' => true }) do |config_path|
          config = Configuration.new("/../#{config_path}")
          expect(config.path).to eq(config_path)
          expect(config.provider).to eq('libvirt')
          expect(config.template).to include('test')
        end
      end
    end

    context 'when provider is given mdbci' do
      it 'should raise error' do
        with_fake_config('mdbci') do |config_path|
          expect { Configuration.new(config_path) }.to raise_error(ArgumentError)
        end
      end
    end

    context 'when template file is broken' do
      it 'should raise error' do
        with_fake_config do |config_path|
          File.open("#{config_path}/template", 'w') do |template_path|
            template_path.write(config_path)
          end
          expect { Configuration.new(config_path).to raise_error(ArgumentError) }
        end
      end
    end
  end

  describe '#node_names' do
    context 'when configuration contains several nodes' do
      it 'should return all of them' do
        with_fake_config('libvirt',
                         { 'test' => { 'box' => 'test' }, 'info' => { 'box' => 'test' } }) do |path|
          config = Configuration.new(path)
          expect(config.node_names).to eq(%w[test info])
        end
      end
    end
  end

  describe '#aws_keypair_name?' do
    context 'when there is no keypair file' do
      it 'should state it' do
        with_fake_config('aws') do |config_path|
          config = Configuration.new(config_path)
          expect(config.aws_keypair_name?).to be_falsy
        end
      end
    end

    context 'when there is an empty keypair file' do
      it 'should state that there is no such file' do
        with_fake_config('aws') do |config_path|
          FileUtils.touch("#{config_path}/#{Configuration::AWS_KEYPAIR_NAME}")
          config = Configuration.new(config_path)
          expect(config.aws_keypair_name?).to be_falsy
        end
      end
    end

    context 'when there is a correct keypair file' do
      it 'should state that there is true' do
        with_fake_config('aws') do |config_path|
          keypair_name = 'testing_the_key'
          File.open("#{config_path}/#{Configuration::AWS_KEYPAIR_NAME}", 'w') do |file|
            file.write(keypair_name)
          end
          config = Configuration.new(config_path)
          expect(config.aws_keypair_name?).to be_truthy
        end
      end
    end
  end

  describe '#aws_keypair_name' do
    context 'when there is no keypair file' do
      it 'should return empty text' do
        with_fake_config do |config_path|
          config = Configuration.new(config_path)
          expect(config.aws_keypair_name).to eq('')
        end
      end
    end

    context 'wher there is such a file' do
      it 'should provide file contents' do
        with_fake_config do |config_path|
          keypair_name = 'testing_the_key'
          File.open("#{config_path}/#{Configuration::AWS_KEYPAIR_NAME}", 'w') do |file|
            file.write(keypair_name)
          end
          config = Configuration.new(config_path)
          expect(config.aws_keypair_name).to eq(keypair_name)
        end
      end
    end
  end

  describe '#box_names' do
    context 'when no node name is passed' do
      it 'should return list of all boxes' do
        with_fake_config('aws', { 'test' => { 'box' => 'test_one' },
                                  'info' => { 'box' => 'test_two' } }) do |config_path|
          config = Configuration.new(config_path)
          expect(config.box_names).to eq(%w[test_one test_two])
        end
      end
    end

    context 'when nodes have same provider' do
      it 'should return only one provider name' do
        with_fake_config('aws', { 'test' => { 'box' => 'test' },
                                  'info' => { 'box' => 'test' }}) do |config_path|
          config = Configuration.new(config_path)
          expect(config.box_names).to eq(['test'])
        end
      end
    end

    context 'when node name is passed' do
      it 'should return box name for the node' do
        with_fake_config('aws', { 'test' => { 'box' => 'test_box' },
                                  'info' => { 'box' => 'info_box' }}) do |config_path|
          config = Configuration.new(config_path)
          expect(config.box_names('info')).to eq(['info_box'])
        end
      end
    end
  end
end
