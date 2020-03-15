# frozen_string_literal: true

require 'pathname'

module CleaeupVendor
  class Path < ::Pathname
    def recursive_entries
      return to_enum(:recursive_entries) unless block_given?

      glob('**/*', File::FNM_DOTMATCH) do |path|
        yield(Path.new(path)) unless path == self
      end
    end

    def match?(patterns)
      patterns.any? do |p|
        p.start_with?('**') && fnmatch?(p, File::FNM_EXTGLOB) || basename.fnmatch?(p, File::FNM_EXTGLOB) && gem_level?
      end
    end

    def gem_level?
      @gem_level ||= parent.glob('*.gemspec').any?
    end

    def include?(enum)
      descend.any? { |p| enum.include?(p) }
    end

    def summary
      entries = recursive_entries + [self]
      entries.map(&:stat)
    end
  end
end
