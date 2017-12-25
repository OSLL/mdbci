require 'models/configuration'
require 'tmpdir'
require 'fileutils'

describe Configuration do

  def with_fake_config
    dir = Dir.mktmpdir
    begin
      FileUtils.touch("#{dir}/template")
      FileUtils.touch("#{dir}/provider")
      FileUtils.touch("#{dir}/Vagrantfile")
      yield dir
    ensure
      FileUtils.remove_entry(dir)
    end
  end

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
        with_fake_config do |config_path|
          config = Configuration.new("/../#{config_path}")
          expect(config.path).to eq(config_path)
        end
      end
    end
  end
end
