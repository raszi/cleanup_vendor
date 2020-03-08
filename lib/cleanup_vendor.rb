require 'cleanup_vendor/version'

module CleanupVendor
  class Error < StandardError; end

  DIRECTORIES = %w[.git .github spec]
  EXTENSIONS = %w[c cpp gem h hpp java log md mk o rdoc txt]
  FILENAMES = %w[README Makefile LICENSE CHANGELOG .dockerignore .gitignore .rspec .travis.yml .yardopts]

  def self.cleanup(directory, directories: DIRECTORIES, extensions: EXTENSIONS, filenames: FILENAMES)
    dir = directory || 'vendor/bundle/ruby'

    filter(dir, directories: directories, extensions: extensions, filenames: filenames) do |f|
      FileUtils.remove_entry(f)
    end
  end

  def self.filter(dir, directories: [], extensions: [], filenames: [], &block)
    raise Error.new('Not a directory') unless dir && File.directory?(dir)

    return to_enum(:filter, dir, directories: directories, extensions: extensions, filenames: filenames) unless block_given?

    Dir.chdir(dir)

    Dir.glob('**/*') do |f|
      basename = File.basename(f)

      if File.file?(f)
        if filenames.include?(basename) || extensions.include?(File.extname(basename).delete('.'))
          yield(f)
        end
      end

      if File.directory?(f) && directories.include?(basename)
        yield(f)
      end
    end
  end
end
