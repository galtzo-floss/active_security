# frozen_string_literal: true

# External Gems
require "sqlite3"
require "anonymous_active_record"
require "silent_stream"

# RSpec Configs
require "debug" if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.7") && ENV["CI"].nil? && ENV.fetch("DEBUG", "false").casecmp("true").zero?
require "config/active_record"
require "config/rspec/reset_defaults"
require "config/rspec/rspec_block_is_expected"
require "config/rspec/rspec_core"
require "config/rspec/silent_stream"
require "config/rspec/version_gem"

# Last thing before loading this gem is to setup code coverage
begin
  require "kettle-soup-cover"
  if Kettle::Soup::Cover::DO_COV
    # Requiring simplecov loads the project-local `.simplecov`.
    require "simplecov"
    require "kettle/soup/cover/config"
    SimpleCov.start
  end
  #   this next line has a side-effect of running `.simplecov`
rescue LoadError
  # We don't load code coverage tools outside the coverage workflow and local development
  nil
end

# External RSpec & related config
require "kettle/test/rspec"
# `kettle/test/rspec` installs harness helpers documented in spec/README.md.
# This gem gets loaded last
require "active_security"
RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
