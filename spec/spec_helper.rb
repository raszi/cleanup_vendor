# frozen_string_literal: true

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter %r{^/spec/}

    enable_coverage :branch if ENV.fetch('COVERAGE', nil) == 'branch'
  end
end

require 'bundler/setup'
require 'cleanup_vendor'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.order = :random
  Kernel.srand config.seed

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
