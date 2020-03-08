require 'tempfile'

RSpec.describe CleanupVendor do
  it 'has a version number' do
    expect(CleanupVendor::VERSION).not_to be nil
  end

  describe '.cleanup' do
    let(:dir) { Dir.mktmpdir('cleanup_vendor') }

    let!(:extensions) do
      %w[c cpp gem h hpp java log md mk o rdoc txt].map do |ext|
        Tempfile.create(['test', ".#{ext}"], Dir.mktmpdir('subdir', dir))
      end
    end

    let!(:files) do
      %w[README Makefile LICENSE].each do |file|
        FileUtils.touch(File.join(dir, file))
      end
    end

    let!(:dirs) do
      %w[spec].map do |d|
        subdir = File.join(dir, d)
        Dir.mkdir(subdir)
        Tempfile.create('test', subdir)
      end
    end

    after { FileUtils.remove_entry(dir) }

    it 'should remove all matching entries' do
      described_class.cleanup(dir)

      Dir.chdir(dir)
      expect(Dir.glob('**/*')).to all(satisfy { |f| File.directory?(f) && f.start_with?('subdir') })
    end
  end

  describe '.filter' do
    it 'should throw an error when called with a nil' do
      expect { described_class.filter(nil) }.to raise_error(CleanupVendor::Error)
    end

    it 'should throw an error when called with a file' do
      expect { described_class.filter(__FILE__) }.to raise_error(CleanupVendor::Error)
    end

    it 'should return an empty list by default' do
      expect { described_class.filter('.').to be_empty }
    end

    context 'when called with a real directory' do
      let(:dir) { File.expand_path('../..', __FILE__) }

      it { expect { |b| described_class.filter(dir, extensions: %w[rb], &b) }.to yield_control }

      it 'should filter for extensions' do
        entries = described_class.filter(dir, extensions: %w[rb])

        expect(entries).to all(satisfy { |f| File.file?(f) && f.end_with?('rb') })
      end

      it 'should filter for directories' do
        entries = described_class.filter(dir, directories: %w[spec])

        expect(entries).to all(satisfy { |f| File.directory?(f) && File.basename(f) == 'spec' })
      end

      it 'should filter for filenames' do
        expect { |b| described_class.filter(dir, filenames: %w[cleanup_vendor.gemspec], &b) }.to yield_with_args('cleanup_vendor.gemspec')
      end
    end
  end
end
