# frozen_string_literal: true

require 'fileutils'
require 'yaml'
require 'set'

require 'cleanup_vendor/version'
require 'cleanup_vendor/path'

module CleanupVendor
  class Error < StandardError; end

  CONFIG_FILE = File.expand_path('defaults.yml', __dir__)
  DEFAULTS = YAML.safe_load(File.binread(CONFIG_FILE)).transform_keys(&:to_sym).freeze

  class << self
    def run(dir, opts = {})
      summary = []

      filter(dir, DEFAULTS.merge(opts)) do |p|
        summary << p.summary if opts[:summary]

        print_verbose(p) if opts[:verbose]
        print_path(p) if opts[:print0]

        FileUtils.remove_entry(p) unless opts[:dry_run]
      end

      print_summary(summary) if opts[:summary]
    end

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def filter(dir, opts = {})
      raise Error, 'Not a directory' unless File.directory?(dir.to_s)
      return to_enum(:filter, dir, opts) unless block_given?

      files, directories, filtered, exclude = get_options(opts)

      Path.new(dir).recursive_entries do |path|
        next if path.match?(exclude)
        next if path.include?(filtered)
        next unless path.file? && path.match?(files) || path.directory? && path.match?(directories)

        filtered << path
        yield(path)
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def get_options(options)
      options.values_at(:files, :directories, :filtered, :exclude).map do |v|
        (v || []).to_set
      end
    end
    private :get_options

    def format_summary(prefix, number)
      "\t#{prefix}\t#{number.to_s.rjust(20)}"
    end
    private :format_summary

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
