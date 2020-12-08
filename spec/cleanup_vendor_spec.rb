# frozen_string_literal: true

require 'tempfile'

RSpec.describe CleanupVendor do
  let(:dir) { Pathname.new(Dir.mktmpdir('cleanup_vendor')) }

  it 'has a version number' do
    expect(CleanupVendor::VERSION).not_to be nil
  end

  describe '.run' do
    let!(:extensions) do
      %w[c cpp gem h hpp java log md mk o rdoc txt].map do |ext|
        file = Tempfile.create(['test', ".#{ext}"], Dir.mktmpdir('kept', dir))
        Pathname.new(file)
      end
    end

    let!(:files) do
      %w[README Makefile LICENSE].map do |file|
        f = File.join(dir, file)
        FileUtils.touch(f)
        Pathname.new(f)
      end
    end

    let!(:dirs) do
      %w[.git .github spec].map do |d|
        subdir = File.join(dir, d)
        Dir.mkdir(subdir)
        Tempfile.create('test', subdir)
        Pathname.new(subdir)
      end
    end

    let!(:non_top_level_directories) do
      topdir = Dir.mktmpdir('kept', dir)

      %w[spec].map do |d|
        subdir = File.join(topdir, d)
        Dir.mkdir(subdir)
        Tempfile.create('test', subdir)
        Pathname.new(subdir)
      end
    end

    let(:all_files_count) { files.count + 2 * dirs.count + extensions.count }

    before { FileUtils.touch(File.join(dir, 'kept.gemspec')) }
    after { FileUtils.remove_entry(dir) }

    context 'without dry-run' do
      it 'should remove all matching entries' do
        described_class.run(dir)

        files = dir.glob('**/*', File::FNM_DOTMATCH).reject { |p| p == dir }
        expect(files).to all(satisfy { |p| p.relative_path_from(dir).to_s.start_with?('kept') })
        expect(files).to include(*non_top_level_directories)
      end
    end

    context 'with dry run' do
      it 'should keep all the entries' do
        described_class.run(dir, dry_run: true)

        left_files = dir.glob('**/*', File::FNM_DOTMATCH)
        expect(left_files).to include(*files)
        expect(left_files).to include(*dirs)
        expect(left_files).to include(*extensions)
      end
    end

    context 'with verbose' do
      it 'should display what it removes' do
        expect { described_class.run(dir, verbose: true) }.to output(/Removing/).to_stderr
      end
    end

    context 'with print0' do
      it 'should display all the removed files separated by 0' do
        expect { described_class.run(dir, print0: true) }.to output(/\0/).to_stdout
      end
    end

    context 'with summary' do
      it 'should display a nice summary' do
        expected_count = all_files_count
        expect { described_class.run(dir, summary: true) }.to output(/Summary:\s+Removed files:\s+#{expected_count}/).to_stderr
      end
    end
  end

  describe '.filter' do
    it 'should throw an error when called with a nil' do
      expect { described_class.filter(nil) }.to raise_error(CleanupVendor::Error)
    end

    it 'should throw an error when called with a file' do
      expect { described_class.filter(__FILE__) }.to raise_error(CleanupVendor::Error)
    end

    context 'when called with a real directory' do
      let!(:rb_file) { Tempfile.create(['test', '.rb'], dir) }
      let!(:spec) { File.join(dir, 'spec').tap { |dir| Dir.mkdir(dir) } }
      let!(:orig_file) { Tempfile.create(['test', '_spec.rb.orig'], spec) }
      let!(:tmp_file) { Tempfile.create('test', dir) }
      let!(:fix_filename) { File.basename(tmp_file) }
      let!(:gemspec) { Tempfile.create(['test', '.gemspec'], dir) }

      it 'without options it should return with an empty list' do
        expect { described_class.filter(dir).to be_empty }
      end

      it 'should filter for extensions' do
        expect { |b| described_class.filter(dir, files: ['**/*.{rb}'], &b) }.to yield_with_args(Pathname.new(rb_file))
      end

      it 'should filter for directories' do
        expect { |b| described_class.filter(dir, directories: %w[spec], &b) }.to yield_with_args(Pathname.new(spec))
      end

      it 'should filter for filenames' do
        expect { |b| described_class.filter(dir, files: [fix_filename], &b) }.to yield_with_args(Pathname.new(tmp_file))
      end

      it 'should filter for exclusions' do
        expect { |b| described_class.filter(dir, exclude: [fix_filename], &b) }.to yield_with_args(Pathname.new(tmp_file))
      end
    end
  end
end
