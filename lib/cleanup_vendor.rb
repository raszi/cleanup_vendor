# frozen_string_literal: true

require 'cleanup_vendor/version'

module CleanupVendor
  class Error < StandardError; end

  DEFAULTS = {
    extensions: %w[c cpp gem h hpp java log md mk o rdoc txt],
    filenames: %w[
      README Makefile LICENSE CHANGELOG .codeclimate.yml .dockerignore
      .gitignore .rubocop.yml .ruby-version .ruby-gemset .rspec .rspec_status
      .travis.yml .yardopts
    ],
    top_level_directories: %w[spec],
    directories: %w[.git .github]
  }.freeze

  class << self
    def run(dir, opts = {})
      summary = []

      filter(dir, DEFAULTS.merge(opts)) do |p|
        summary << collect_summary(p) if opts[:summary]

        print_verbose(p) if opts[:verbose]
        print_path(p) if opts[:print0]

        FileUtils.remove_entry(p) unless opts[:dry_run]
      end

      print_summary(summary) if opts[:summary]
    end

    def filter(dir, opts = {})
      raise Error, 'Not a directory' unless File.directory?(dir.to_s)
      return to_enum(:filter, dir, opts) unless block_given?

      file_opts, dir_opts = get_options(opts)
      filtered = Set.new

      dir_entries(dir) do |path|
        next if skip_path?(path, filtered)
        next unless match_file?(path, file_opts) || match_directory?(path, dir_opts)

        filtered << path
        yield(path)
      end
    end

    def skip_path?(path, filtered)
      path.basename.to_s == '.' || path.descend.any? { |p| filtered.include?(p) }
    end
    private :skip_path?

    def match_file?(path, filenames: [], extensions: [])
      return unless path.file?

      filenames.include?(path.basename.to_s) || extensions.include?(path.extname.delete('.'))
    end
    private :match_file?

    def match_directory?(path, directories: [], top_level_directories: [])
      return unless path.directory?

      basename = path.basename.to_s
      directories.include?(basename) || top_level_directories.include?(basename) && path.parent.glob('*.gemspec').any?
    end
    private :match_directory?

    def get_options(options)
      file_opts = transform_options(options, :filenames, :extensions)
      dir_opts = transform_options(options, :directories, :top_level_directories)
      [file_opts, dir_opts]
    end
    private :get_options

    def transform_options(options, *keys)
      options.slice(*keys).transform_values do |v|
        (v || []).to_set
      end
    end
    private :transform_options

    def dir_entries(dir, &block)
      Pathname.new(dir).glob('**/*', File::FNM_DOTMATCH, &block)
    end
    private :dir_entries

    def format_summary(prefix, number)
      "\t#{prefix}\t#{number.to_s.rjust(20)}"
    end
    private :format_summary

    def collect_summary(path)
      files = path.file? ? [path] : dir_entries(path).reject { |p| p.basename.to_s == '.' }
      files.map(&:stat)
    end
    private :collect_summary

    def print_verbose(path)
      $stderr.puts "Removing #{path}..."
    end
    private :print_verbose

    def print_path(path)
      $stdout.write path
      $stdout.putc 0
    end
    private :print_path

    def print_summary(summary)
      all_files = summary.flatten
      count = all_files.count
      blocks = all_files.map(&:blocks).sum
      bytes = all_files.map(&:size).sum

      $stderr.puts 'Summary:'
      $stderr.puts format_summary('Removed files:', count)
      $stderr.puts format_summary('Total blocks:', blocks)
      $stderr.puts format_summary('Total bytes:', bytes)
    end
    private :print_summary
  end
end
