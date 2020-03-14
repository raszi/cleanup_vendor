require 'cleanup_vendor/version'

module CleanupVendor
  class Error < StandardError; end

  DEFAULTS = {
    extensions: %w[c cpp gem h hpp java log md mk o rdoc txt],
    filenames: %w[README Makefile LICENSE CHANGELOG .dockerignore .gitignore .rspec .travis.yml .yardopts],
    top_level_directories: %w[spec],
    directories: %w[.git .github]
  }.freeze

  class << self
    def run(dir, opts = {})
      summary = []

      filter(dir, DEFAULTS.merge(opts)) do |p|
        summary << collect_summary(dir, p) if opts[:summary]

        $stderr.puts "Removing #{p}..." if opts[:verbose]

        if opts[:print0]
          $stdout.write p.to_s
          $stdout.putc 0
        end

        FileUtils.remove_entry(p) unless opts[:dry_run]
      end

      print_summary(summary) if opts[:summary]
    end

    def filter(dir, opts = {})
      raise Error.new('Not a directory') unless dir && File.directory?(dir)
      return to_enum(:filter, dir, opts) unless block_given?

      extensions, filenames, directories, top_level_directories = get_options(opts)
      filtered = Set.new

      dir_entries(dir) do |p|
        next if p.basename.to_s == '.'
        next if p.descend.any? { |p| filtered.include?(p) }

        if match_filename?(filenames, p) || match_extension?(extensions, p) || match_directory?(directories, p) || match_top_level_directory?(top_level_directories, p)
          filtered << p
          yield(p)
        end
      end
    end

    def match_filename?(filenames, p)
      p.file? && filenames.include?(p.basename.to_s)
    end
    private :match_filename?

    def match_extension?(extensions, p)
      p.file? && extensions.include?(p.extname.delete('.'))
    end
    private :match_extension?

    def match_directory?(directories, p)
      p.directory? && directories.include?(p.basename.to_s)
    end
    private :match_directory?

    def match_top_level_directory?(directories, p)
      p.directory? && directories.include?(p.basename.to_s) && p.parent.glob('*.gemspec').any?
    end
    private :match_top_level_directory?

    def get_options(opts)
      %i[extensions filenames directories top_level_directories].map do |option|
        opts.fetch(option, []).to_set
      end
    end
    private :get_options

    def dir_entries(dir, &block)
      Pathname.new(dir).glob('**/*', File::FNM_DOTMATCH, &block)
    end
    private :dir_entries

    def format_summary(prefix, number)
      "\t#{prefix}\t#{number.to_s.rjust(20)}"
    end
    private :format_summary

    def collect_summary(dir, p)
      files = p.file? ? [p] : dir_entries(p).reject { |p| p.basename.to_s == '.' }
      files.map(&:stat)
    end
    private :collect_summary

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
