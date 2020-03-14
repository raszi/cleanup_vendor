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

      filter(dir, DEFAULTS.merge(opts)) do |f|
        summary << collect_summary(dir, f) if opts[:summary]

        puts "Removing #{f}..." if opts[:dry_run] || opts[:verbose]
        FileUtils.remove_entry(f) unless opts[:dry_run]
      end

      print_summary(summary) if opts[:summary]
    end

    def filter(dir, opts = {})
      raise Error.new('Not a directory') unless dir && File.directory?(dir)
      return to_enum(:filter, dir, opts) unless block_given?

      extensions, filenames, directories, top_level_directories = get_options(opts)

      dir_entries(dir) do |f|
        basename = File.basename(f)

        if File.file?(f)
          if filenames.include?(basename) || extensions.include?(File.extname(basename).delete('.'))
            yield(f)
          end
        end

        if File.directory?(f)
          if directories.include?(basename)
            yield(f)
          elsif top_level_directories.include?(basename)
            tld = File.join(dir, File.dirname(f))
            yield(f) unless dir_entries(tld, '*.gemspec').empty?
          end
        end
      end
    end

    def get_options(opts)
      %i[extensions filenames directories top_level_directories].map do |option|
        opts.fetch(option, [])
      end
    end
    private :get_options

    def dir_entries(dir, pattern = '**/*', &block)
      Dir.chdir(dir) do
        Dir.glob(pattern, File::FNM_DOTMATCH, &block)
      end
    end
    private :dir_entries

    def format_summary(prefix, number)
      "\t#{prefix}\t#{number.to_s.rjust(20)}"
    end
    private :format_summary

    def collect_summary(dir, f)
      files = File.file?(f) ? [f] : dir_entries(f).grep_v('.').map { |file| File.join(f, file) }
      files.map { |f| File.stat(File.join(dir, f)) }
    end
    private :collect_summary

    def print_summary(summary)
      all_files = summary.flatten
      count = all_files.count
      blocks = all_files.map(&:blocks).sum
      bytes = all_files.map(&:size).sum

      puts 'Summary:'
      puts format_summary('Removed files:', count)
      puts format_summary('Total blocks:', blocks)
      puts format_summary('Total bytes:', bytes)
    end
    private :print_summary
  end
end
